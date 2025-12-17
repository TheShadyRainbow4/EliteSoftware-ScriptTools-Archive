<#
.SYNOPSIS
A PowerShell script to act as a GUI-based launcher and host for Node.js applications on IIS.
It provides a GUI to run 'npm install', 'npm run dev', manage environment files, and configure an IIS website.

.DESCRIPTION
This script is designed to be placed directly within a Node.js project folder.
When executed, it checks for Node.js and npm, and if they exist, it displays a GUI.
The GUI allows the user to install dependencies, run the development server, host the app on IIS,
and dynamically edit an .env.local file.
It features an integrated console, a marquee progress bar during operations, and a status indicator light (Red/Yellow/Green).
This version runs npm commands as background jobs, capturing their output directly into the GUI.
The console window of the main GUI is minimized on startup.
Error messages are still logged to the console, and it will remain open if the GUI is closed due to an error.

.CREDITS
Created by: Zachary Whiteman & Google Gemini Ai. (8/19/2025 - 3:25 PM EDT)
Updated by: Gemini on 9/14/2025

.NOTES
Requires PowerShell 7 or higher.
The IIS integration functionality requires the WebAdministration module, which can be installed via the PowerShell Gallery.
Run 'Install-Module -Name WebAdministration' from an elevated PowerShell terminal to install the module.
#>

# Add a function to ensure the console window stays open on crash.
function global:Wait-For-Key {
    Write-Host "Press any key to close this window..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}
# Set a trap to call the function on script termination due to error.
trap {
    Write-Error $_.Exception.Message
    Wait-For-Key
}

# Add a function to minimize the console window.
function Minimize-Console {
    $code = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
    $minimize = Add-Type -MemberDefinition $code -Name WindowHelper -Namespace ConsoleHelper -PassThru
    $windowHandle = (Get-Process -Id $PID).MainWindowHandle
    if ($windowHandle -ne [IntPtr]::Zero) {
        $minimize::ShowWindow($windowHandle, 2) # 2 corresponds to SW_MINIMIZE
    }
}

# Add a function to check for Node.js and npm dependencies.
function Check-Dependencies {
    try {
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            $msg = "Node.js is not found on your system. Please install it from `https://nodejs.org/` to continue."
            [System.Windows.Forms.MessageBox]::Show($msg, "Dependency Missing", 'OK', 'Error')
            throw $msg
        }
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            $msg = "npm is not found on your system. It should be installed with Node.js. Please reinstall Node.js."
            [System.Windows.Forms.MessageBox]::Show($msg, "Dependency Missing", 'OK', 'Error')
            throw $msg
        }
    } catch {
        Write-Error "Dependency check failed: $_"
        exit
    }
}

# --- SCRIPT INITIALIZATION ---

# Minimize the console window on startup.
Minimize-Console

# Run the dependency check.
Check-Dependencies

# Global variables for managing the background process
$script:currentJob = $null
$script:serverUrl = $null
$script:depsInstalled = $false
$script:configPath = "C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftwareCorp\NodeIISLauncher\config.xml"

# Load the required .NET assemblies.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Enable visual styles for system theming as per user preference.
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- GUI FORM AND CONTROLS CREATION ---

# Create the main form.
$form = New-Object System.Windows.Forms.Form
$form.Text = "EliteSoftware Node.Js Deployer"
$form.Size = New-Object System.Drawing.Size(400, 520) # Increased height for new controls
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle' # Prevent resizing
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Create the two-tone header panel.
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size($form.Width, 50)
$headerPanel.Dock = 'Top'
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 12, 100, 160)
$form.Controls.Add($headerPanel)

# Add the title label to the header panel.
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Node.js / iis Deployment Launcher"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Location = New-Object System.Drawing.Point(10, 15)
$titleLabel.AutoSize = $true
$headerPanel.Controls.Add($titleLabel)

# Create the status indicator panel.
$statusIndicator = New-Object System.Windows.Forms.Panel
$statusIndicator.Size = New-Object System.Drawing.Size(20, 20)
$statusIndicator.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($statusIndicator)

# Create the progress bar.
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(40, 60)
$progressBar.Size = New-Object System.Drawing.Size(334, 20)
$progressBar.Style = 'Marquee'
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# Create a rich text box for output display.
$outputTextBox = New-Object System.Windows.Forms.RichTextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 90) # Moved down
$outputTextBox.Size = New-Object System.Drawing.Size(364, 150)
$outputTextBox.Anchor = 'Top, Left, Right, Bottom'
$outputTextBox.ReadOnly = $true
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = 'Vertical'
$outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputTextBox.BackColor = [System.Drawing.Color]::Black
$outputTextBox.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($outputTextBox)

# Create the "npm install" button.
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "NPM Install"
$installButton.Location = New-Object System.Drawing.Point(10, 250)
$installButton.Size = New-Object System.Drawing.Size(115, 40)
$installButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($installButton)

# Create the "npm run dev" button.
$devButton = New-Object System.Windows.Forms.Button
$devButton.Text = "NPM Run Dev"
$devButton.Location = New-Object System.Drawing.Point(135, 250)
$devButton.Size = New-Object System.Drawing.Size(120, 40)
$devButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($devButton)

# Create the close button.
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Terminate"
$closeButton.Location = New-Object System.Drawing.Point(265, 250)
$closeButton.Size = New-Object System.Drawing.Size(109, 40)
$closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($closeButton)

# Create the "Stop Server" button.
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Server"
$stopButton.Location = New-Object System.Drawing.Point(10, 295)
$stopButton.Size = New-Object System.Drawing.Size(245, 40)
$stopButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$stopButton.Enabled = $false
$form.Controls.Add($stopButton)
# Store the default button color for later use
$defaultButtonColor = $stopButton.BackColor
$defaultButtonForeColor = $stopButton.ForeColor

# Create the "Open Browser" button.
$browserButton = New-Object System.Windows.Forms.Button
$browserButton.Text = "Open in Browser"
$browserButton.Location = New-Object System.Drawing.Point(265, 295)
$browserButton.Size = New-Object System.Drawing.Size(109, 40)
$browserButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$browserButton.Enabled = $false
$form.Controls.Add($browserButton)

# Create the "Setup .env" button.
$envButton = New-Object System.Windows.Forms.Button
$envButton.Text = "Set Api Key"
$envButton.Location = New-Object System.Drawing.Point(10, 340)
$envButton.Size = New-Object System.Drawing.Size(364, 25)
$envButton.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($envButton)

# --- NEW IIS CONTROLS ---
# IIS Group Box
$iisGroupBox = New-Object System.Windows.Forms.GroupBox
$iisGroupBox.Text = "IIS Hosting Settings"
$iisGroupBox.Location = New-Object System.Drawing.Point(10, 370)
$iisGroupBox.Size = New-Object System.Drawing.Size(364, 75)
$iisGroupBox.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($iisGroupBox)

# Port Label
$portLabel = New-Object System.Windows.Forms.Label
$portLabel.Text = "Port:"
$portLabel.Location = New-Object System.Drawing.Point(10, 25)
$portLabel.AutoSize = $true
$iisGroupBox.Controls.Add($portLabel)

# Port TextBox
$portTextBox = New-Object System.Windows.Forms.TextBox
$portTextBox.Location = New-Object System.Drawing.Point(50, 22)
$portTextBox.Size = New-Object System.Drawing.Size(70, 20)
$portTextBox.Text = "80"
$iisGroupBox.Controls.Add($portTextBox)

# Bindings Label
$bindingsLabel = New-Object System.Windows.Forms.Label
$bindingsLabel.Text = "Bindings:"
$bindingsLabel.Location = New-Object System.Drawing.Point(135, 25)
$bindingsLabel.AutoSize = $true
$iisGroupBox.Controls.Add($bindingsLabel)

# Bindings TextBox
$bindingsTextBox = New-Object System.Windows.Forms.TextBox
$bindingsTextBox.Location = New-Object System.Drawing.Point(195, 22)
$bindingsTextBox.Size = New-Object System.Drawing.Size(155, 20)
$bindingsTextBox.Text = "PlaceHolder.EliteSoftware.Zach"
$iisGroupBox.Controls.Add($bindingsTextBox)

# Host in IIS Button
$iisButton = New-Object System.Windows.Forms.Button
$iisButton.Text = "Host in Internet Information Services (iis)"
$iisButton.Location = New-Object System.Drawing.Point(10, 450)
$iisButton.Size = New-Object System.Drawing.Size(364, 25)
$iisButton.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($iisButton)

# --- STATUS AND JOB HANDLING ---

# Function to update the status indicator color
function Update-StatusIndicator($status) {
    switch ($status) {
        'running' {
            $statusIndicator.BackColor = [System.Drawing.Color]::LimeGreen
            $stopButton.BackColor = [System.Drawing.Color]::Crimson
            $stopButton.ForeColor = [System.Drawing.Color]::White
        }
        'installed' {
            $statusIndicator.BackColor = [System.Drawing.Color]::Yellow
            $stopButton.BackColor = $defaultButtonColor
            $stopButton.ForeColor = $defaultButtonForeColor
        }
        'stopped' {
            $statusIndicator.BackColor = [System.Drawing.Color]::Red
            $stopButton.BackColor = $defaultButtonColor
            $stopButton.ForeColor = $defaultButtonForeColor
        }
        default {
            $statusIndicator.BackColor = [System.Drawing.Color]::Gray
        }
    }
}

# This timer will periodically check the status of the running job
$jobTimer = New-Object System.Windows.Forms.Timer
$jobTimer.Interval = 250 # Check every 250 milliseconds

$jobTimer.Add_Tick({
    if ($null -eq $script:currentJob) {
        $jobTimer.Stop()
        return
    }

    # Receive any new output from the job's streams
    $output = Receive-Job -Job $script:currentJob
    if ($output) {
        $outputString = $output | Out-String
        $outputTextBox.AppendText($outputString)
        $outputTextBox.ScrollToCaret()

        # If this is the dev server job, scan for a URL
        if ($script:currentJob.Name -eq "devServer" -and !$script:serverUrl) {
            # Strip ANSI escape codes (color codes) from the output before searching for a URL
            $cleanedOutput = $outputString -replace "\x1B\[[0-?]*[ -/]*[@-~]"
            $match = $cleanedOutput | Select-String -Pattern 'http[s]?://[^\s,]+'
            if ($match) {
                $script:serverUrl = $match.Matches[0].Value
                $outputTextBox.AppendText("`n`n>>> Server URL found: $($script:serverUrl) <<<`n`n")
                $outputTextBox.ScrollToCaret()
                $browserButton.Enabled = $true
                Update-StatusIndicator('running')
            }
        }
    }

    # Check if the job has finished
    if ($script:currentJob.State -in @('Completed', 'Failed', 'Stopped')) {
        $jobTimer.Stop()
        $progressBar.Visible = $false
        
        if ($script:currentJob.State -eq 'Failed') {
            $outputTextBox.AppendText("`n`n>>> Job failed. <<<`n`n")
            $script:depsInstalled = $false
            Update-StatusIndicator('stopped')
        } else {
            $outputTextBox.AppendText("`n`n>>> Job finished. <<<`n`n")
            # If the installer just finished successfully
            if ($script:currentJob.Name -eq "installer") {
                $script:depsInstalled = $true
                Update-StatusIndicator('installed')
            }
        }
        $outputTextBox.ScrollToCaret()

        # Clean up the job and reset the UI
        Remove-Job -Job $script:currentJob -Force
        $script:currentJob = $null
        $installButton.Enabled = $true
        $devButton.Enabled = $true
        $stopButton.Enabled = $false
    }
})

# Function to stop any currently running job
$StopCurrentJob = {
    if ($script:currentJob) {
        $jobTimer.Stop()
        $progressBar.Visible = $false
        Stop-Job -Job $script:currentJob
        Remove-Job -Job $script:currentJob -Force
        $outputTextBox.AppendText("`n`n>>> Process has been stopped by user. <<<`n`n")
        $outputTextBox.ScrollToCaret()

        # Reset state
        $script:currentJob = $null
        $script:serverUrl = $null
        $stopButton.Enabled = $false
        $browserButton.Enabled = $false
        $installButton.Enabled = $true
        $devButton.Enabled = $true
        
        # Update status based on whether deps were installed
        if ($script:depsInstalled) {
            Update-StatusIndicator('installed')
        } else {
            Update-StatusIndicator('stopped')
        }
    }
}

# --- BUTTON CLICK EVENT HANDLERS ---

$installButton.Add_Click({
    $installButton.Enabled = $false
    $devButton.Enabled = $false
    $stopButton.Enabled = $false
    $browserButton.Enabled = $false
    $outputTextBox.Text = "Running 'npm install'...`n"
    $progressBar.Visible = $true
    
    # Start 'npm install' as a background job
    $script:currentJob = Start-Job -ScriptBlock { npm install 2>&1 } -Name "installer"
    $jobTimer.Start()
})

$devButton.Add_Click({
    if ($script:currentJob) {
        [System.Windows.Forms.MessageBox]::Show("Another process is already running. Please stop it first.", "Warning", 'OK', 'Warning')
        return
    }
    
    $installButton.Enabled = $false
    $devButton.Enabled = $false
    $stopButton.Enabled = $true
    $browserButton.Enabled = $false
    $script:serverUrl = $null
    $outputTextBox.Text = "Starting dev server...`n"
    $progressBar.Visible = $true
    
    # Start 'npm run dev' as a background job.
    $script:currentJob = Start-Job -ScriptBlock { npm run dev 2>&1 } -Name "devServer"
    $jobTimer.Start()
})

$browserButton.Add_Click({
    if ($script:serverUrl) {
        try {
            Start-Process $script:serverUrl
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to open URL: $($script:serverUrl)`n`nError: $($_.Exception.Message)", "Error", 'OK', 'Error')
        }
    }
})

$stopButton.Add_Click({
    & $StopCurrentJob
})

$envButton.Add_Click({
    # Create the API Key form
    $apiKeyForm = New-Object System.Windows.Forms.Form
    $apiKeyForm.Text = "Enter API Key"
    $apiKeyForm.Size = New-Object System.Drawing.Size(300, 150)
    $apiKeyForm.StartPosition = 'CenterParent'
    $apiKeyForm.FormBorderStyle = 'FixedDialog'
    $apiKeyForm.MaximizeBox = $false
    $apiKeyForm.MinimizeBox = $false
    $apiKeyForm.ShowInTaskbar = $false
    
    $apiKeyLabel = New-Object System.Windows.Forms.Label
    $apiKeyLabel.Text = "Enter your Gemini API key below:"
    $apiKeyLabel.Location = New-Object System.Drawing.Point(10, 20)
    $apiKeyLabel.AutoSize = $true
    $apiKeyForm.Controls.Add($apiKeyLabel)
    
    $apiKeyTextBox = New-Object System.Windows.Forms.TextBox
    $apiKeyTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $apiKeyTextBox.Size = New-Object System.Drawing.Size(264, 20)
    $apiKeyForm.Controls.Add($apiKeyTextBox)
    
    $applyButton = New-Object System.Windows.Forms.Button
    $applyButton.Text = "Apply Key"
    $applyButton.Location = New-Object System.Drawing.Point(10, 80)
    $applyButton.Size = New-Object System.Drawing.Size(264, 25)
    $applyButton.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
    $apiKeyForm.Controls.Add($applyButton)
    
    $applyButton.Add_Click({
        $apiKey = $apiKeyTextBox.Text.Trim()
        $keyName = "GEMINI_API_KEY"
        $envFile = Join-Path $PSScriptRoot ".env.local"

        if ([string]::IsNullOrEmpty($apiKey)) {
            [System.Windows.Forms.MessageBox]::Show("Please enter a valid API key.", "Warning", 'OK', 'Warning')
            return
        }

        try {
            # Check if the file exists and if the key is already in it
            $existingContent = if (Test-Path $envFile) { Get-Content $envFile -Encoding UTF8 } else { @() }
            $keyExists = $existingContent -match "^\s*$($keyName)\s*="
            
            if ($keyExists) {
                # Update the existing line
                $updatedContent = $existingContent -replace "^\s*$($keyName)\s*=.+", "$($keyName)='$($apiKey)'"
                $updatedContent | Set-Content -Path $envFile -Encoding UTF8
                $outputTextBox.AppendText("`n>>> Successfully updated existing API key in .env.local <<<`n")
            } else {
                # Append the new key
                "$($keyName)='$($apiKey)'" | Out-File -FilePath $envFile -Append -Encoding UTF8
                $outputTextBox.AppendText("`n>>> Successfully appended API key to .env.local <<<`n")
            }

            $outputTextBox.ScrollToCaret()
            $apiKeyForm.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to write to .env.local file.`n`nError: $($_.Exception.Message)", "Error", 'OK', 'Error')
        }
    })
    
    [void]$apiKeyForm.ShowDialog()
})

$iisButton.Add_Click({
    # Check for WebAdministration module dependency
    try {
        Import-Module WebAdministration -ErrorAction Stop
    } catch {
        [System.Windows.Forms.MessageBox]::Show("The 'WebAdministration' module is not installed or available. Please install it from the PowerShell Gallery.", "Module Missing", 'OK', 'Error')
        return
    }

    $appRoot = $PSScriptRoot
    $siteName = (Split-Path $appRoot -Leaf) + "_NodeSite"
    $appPoolName = "NodeAppPool_" + (Split-Path $appRoot -Leaf)
    $port = $portTextBox.Text.Trim()
    $bindings = $bindingsTextBox.Text.Trim()
    
    if ([string]::IsNullOrEmpty($port) -or [string]::IsNullOrEmpty($bindings)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid Port and Bindings.", "Input Required", 'OK', 'Warning')
        return
    }

    $outputTextBox.AppendText("`n>>> Configuring IIS for application '$siteName' on port $port with bindings '$bindings' <<<`n")
    $outputTextBox.ScrollToCaret()
    
    try {
        # Create or get the application pool
        $existingAppPool = Get-Item "IIS:\AppPools\$appPoolName" -ErrorAction SilentlyContinue
        if ($existingAppPool) {
            $outputTextBox.AppendText(">>> App pool '$appPoolName' already exists. Reusing it. <<<`n")
        } else {
            New-Item "IIS:\AppPools\$appPoolName" | Out-Null
            $outputTextBox.AppendText(">>> App pool '$appPoolName' created. <<<`n")
        }
        
        # Set the App Pool to No Managed Code (for Node.js)
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedRuntimeVersion -Value ""
        
        # Check if the site already exists
        $existingSite = Get-Item "IIS:\Sites\$siteName" -ErrorAction SilentlyContinue
        
        if ($existingSite) {
            # Site exists, update its properties
            Set-ItemProperty "IIS:\Sites\$siteName" -Name physicalPath -Value $appRoot
            Set-ItemProperty "IIS:\Sites\$siteName" -Name bindings -Value @{protocol="http"; bindingInformation="$bindings`:$port`:"}
            Set-WebConfigurationProperty -PSPath "IIS:\Sites\$siteName" -Filter "system.webServer/httpErrors" -Name "existingResponse" -Value "PassThrough"
            Set-ItemProperty "IIS:\Sites\$siteName" -Name applicationPool -Value $appPoolName
            Start-Website -Name $siteName
            $outputTextBox.AppendText(">>> Existing site '$siteName' updated and started successfully. <<<`n")
        } else {
            # Site does not exist, create a new one
            New-Website -Name $siteName -PhysicalPath $appRoot -Port ([int]$port) -HostHeader $bindings -ApplicationPool $appPoolName
            $outputTextBox.AppendText(">>> New site '$siteName' created and started successfully. <<<`n")
        }
        $outputTextBox.ScrollToCaret()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to configure IIS.`n`nError: $($_.Exception.Message)", "IIS Configuration Error", 'OK', 'Error')
    }
})

$closeButton.Add_Click({
    & $StopCurrentJob
    $form.Close()
})

# Add a handler for when the form is closed via the 'X' button
$form.Add_FormClosing({
    & $StopCurrentJob
    
    # Save current settings to a file
    $configData = [PSCustomObject]@{
        Port = $portTextBox.Text
        Bindings = $bindingsTextBox.Text
    }
    
    $configDir = Split-Path $script:configPath
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory | Out-Null
    }
    $configData | Export-CliXml -Path $script:configPath -Force
})

# --- SHOW THE GUI ---
# Load settings from file if they exist
if (Test-Path $script:configPath) {
    try {
        $savedConfig = Import-CliXml -Path $script:configPath
        $portTextBox.Text = $savedConfig.Port
        $bindingsTextBox.Text = $savedConfig.Bindings
    } catch {
        $outputTextBox.AppendText("`n`n>>> Failed to load saved settings. Using defaults. <<<`n`n")
    }
}

# Check for .env.local file on startup
$envFilePath = Join-Path $PSScriptRoot ".env.local"
if (-not (Test-Path $envFilePath)) {
    $outputTextBox.AppendText("`n`n>>> Warning: The .env.local file was not found. Please click 'Setup .env' to create it. <<<`n`n")
    $envButton.BackColor = [System.Drawing.Color]::Gold
    $envButton.ForeColor = [System.Drawing.Color]::Black
}

# Set initial status indicator state
Update-StatusIndicator('stopped')

# This line will block the script until the form is closed.
[void]$form.ShowDialog()
