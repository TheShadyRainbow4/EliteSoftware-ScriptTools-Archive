<#
 .SYNOPSIS
     A PowerShell script to act as a simple launcher and installer for Node.js applications.
     It provides a GUI to run 'npm install', 'npm run dev', and a guided UI to build standalone executables using a modern electron-vite workflow or pkg.

 .DESCRIPTION
     This script is designed to be placed directly within a Node.js project folder.
     When executed, it checks for Node.js and npm and displays a GUI.
     For Electron projects, it will detect if the project is configured for a modern build process with 'electron-vite'.
     If not, it will offer to automatically install 'electron', 'electron-builder', and 'electron-vite', and configure the 'package.json' file with the necessary scripts and settings.
     This provides a one-click setup for a stable, modern packaging workflow. It also retains the option to use 'pkg' for non-Electron command-line applications.
     The script features an integrated console, background job handling, and status indicators to provide a seamless, automated experience.

 .CREDITS
     Created by: Zachary Whiteman & Google Gemini Ai. (9/19/2025 - 4:41 PM EDT)
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
$script:onSuccessAction = $null

# Load the required .NET assemblies.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable visual styles for system theming as per user preference.
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- GUI FORM AND CONTROLS CREATION ---

# Create the main form.
$form = New-Object System.Windows.Forms.Form
$form.Text = "Node.js App Launcher"
$form.Size = New-Object System.Drawing.Size(400, 480) # Height remains the same
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
$titleLabel.Text = "Node.Js App Launcher"
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
$installButton.Text = "Run npm install"
$installButton.Location = New-Object System.Drawing.Point(10, 250)
$installButton.Size = New-Object System.Drawing.Size(115, 40)
$installButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($installButton)

# Create the "npm run dev" button.
$devButton = New-Object System.Windows.Forms.Button
$devButton.Text = "Run npm run dev"
$devButton.Location = New-Object System.Drawing.Point(135, 250)
$devButton.Size = New-Object System.Drawing.Size(120, 40)
$devButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($devButton)

# Create the close button.
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Location = New-Object System.Drawing.Point(265, 250)
$closeButton.Size = New-Object System.Drawing.Size(109, 40)
$closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($closeButton)

# Create the "Stop Server" button.
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Process"
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
$browserButton.Text = "Open Browser"
$browserButton.Location = New-Object System.Drawing.Point(265, 295)
$browserButton.Size = New-Object System.Drawing.Size(109, 40)
$browserButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$browserButton.Enabled = $false
$form.Controls.Add($browserButton)

# Create the "Package (React TS)" button.
$packageReactButton = New-Object System.Windows.Forms.Button
$packageReactButton.Text = "Package (React TS)"
$packageReactButton.Location = New-Object System.Drawing.Point(10, 340)
$packageReactButton.Size = New-Object System.Drawing.Size(177, 40)
$packageReactButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($packageReactButton)

# Create the "Package (Angular TS)" button.
$packageAngularButton = New-Object System.Windows.Forms.Button
$packageAngularButton.Text = "Package (Angular TS)"
$packageAngularButton.Location = New-Object System.Drawing.Point(197, 340)
$packageAngularButton.Size = New-Object System.Drawing.Size(177, 40)
$packageAngularButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($packageAngularButton)

# Create the "Detect Framework" button.
$detectButton = New-Object System.Windows.Forms.Button
$detectButton.Text = "Detect Framework"
$detectButton.Location = New-Object System.Drawing.Point(10, 390)
$detectButton.Size = New-Object System.Drawing.Size(177, 30)
$detectButton.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($detectButton)

# Create the "Setup .env" button.
$envButton = New-Object System.Windows.Forms.Button
$envButton.Text = "Setup .env.local"
$envButton.Location = New-Object System.Drawing.Point(197, 390)
$envButton.Size = New-Object System.Drawing.Size(177, 30)
$envButton.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($envButton)

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
            if ($script:currentJob.State -eq 'Completed') {
                # If the installer or packager just finished successfully
                if ($script:currentJob.Name -in @("installer", "packager", "dependencyInstaller", "globalInstaller")) {
                    $script:depsInstalled = $true
                    Update-StatusIndicator('installed')
                }
                # If a success action is defined, run it.
                $action = $script:onSuccessAction
                $script:onSuccessAction = $null # Clear it after getting it to prevent re-running
                if ($action) {
                    & $action
                }
            }
        }
        $outputTextBox.ScrollToCaret()

        # Clean up the job and reset the UI
        Remove-Job -Job $script:currentJob
        $script:currentJob = $null
        $installButton.Enabled = $true
        $devButton.Enabled = $true
        $packageReactButton.Enabled = $true
        $packageAngularButton.Enabled = $true
        $stopButton.Enabled = $false
    }
})

# Function to stop any currently running job
$StopCurrentJob = {
    if ($script:currentJob) {
        try {
            Stop-Job -Job $script:currentJob -ErrorAction Stop
            Remove-Job -Job $script:currentJob -ErrorAction Stop
        } catch {
            Write-Warning "Could not stop/remove job. It may have already completed. Error: $($_.Exception.Message)"
        } finally {
            $jobTimer.Stop()
            $progressBar.Visible = $false
            $outputTextBox.AppendText("`n`n>>> Process has been stopped by user. <<<`n`n")
            $outputTextBox.ScrollToCaret()

            # Reset state
            $script:currentJob = $null
            $script:serverUrl = $null
            $script:onSuccessAction = $null
            $stopButton.Enabled = $false
            $browserButton.Enabled = $false
            $installButton.Enabled = $true
            $devButton.Enabled = $true
            $packageReactButton.Enabled = $true
            $packageAngularButton.Enabled = $true

            if ($script:depsInstalled) {
                Update-StatusIndicator('installed')
            } else {
                Update-StatusIndicator('stopped')
            }
        }
    }
}


# --- SCRIPT CONFIGURATION AND PACKAGING ---
function Run-Task {
    param(
        [scriptblock]$ScriptBlock,
        [string]$JobName,
        [string]$UiMessage,
        [scriptblock]$OnSuccessAction = $null
    )
    if ($script:currentJob) {
        [System.Windows.Forms.MessageBox]::Show("Another process is already running.", "Busy", 'OK', 'Warning')
        return
    }

    # Set up UI
    $installButton.Enabled = $false; $devButton.Enabled = $false; $packageReactButton.Enabled = $false; $packageAngularButton.Enabled = $false
    $stopButton.Enabled = $true
    $browserButton.Enabled = $false
    $outputTextBox.AppendText("`n`n>>> $UiMessage`n")
    if ($JobName -like "*Installer") {
        $outputTextBox.AppendText("NOTE: It is normal to see 'npm warn' messages during this process.`n`n")
    }
    $progressBar.Visible = $true

    # Set the continuation action
    $script:onSuccessAction = $OnSuccessAction

    # Start the job
    $script:currentJob = Start-Job -ScriptBlock $ScriptBlock -Name $JobName
    $jobTimer.Start()
}

function Show-PackagingForm {
    param ([string]$Framework)

    $packagingForm = New-Object System.Windows.Forms.Form
    $packagingForm.Text = "Build Executable for $Framework"
    $packagingForm.Size = New-Object System.Drawing.Size(420, 480)
    $packagingForm.StartPosition = 'CenterParent'
    $packagingForm.FormBorderStyle = 'FixedDialog'
    $packagingForm.MaximizeBox = $false
    $packagingForm.MinimizeBox = $false

    $font = New-Object System.Drawing.Font("Arial", 9)

    # --- Packager Selection ---
    $packagerGroup = New-Object System.Windows.Forms.GroupBox; $packagerGroup.Text = "Packager"; $packagerGroup.Location = New-Object System.Drawing.Point(10, 10); $packagerGroup.Size = New-Object System.Drawing.Size(385, 55); $packagerGroup.Font = $font
    $ebRadio = New-Object System.Windows.Forms.RadioButton; $ebRadio.Text = "electron-builder (Recommended)"; $ebRadio.Location = New-Object System.Drawing.Point(15, 20); $ebRadio.Checked = $true; $ebRadio.AutoSize = $true
    $pkgRadio = New-Object System.Windows.Forms.RadioButton; $pkgRadio.Text = "pkg (for CLI apps)"; $pkgRadio.Location = New-Object System.Drawing.Point(220, 20); $pkgRadio.AutoSize = $true
    $packagerGroup.Controls.AddRange(@($ebRadio, $pkgRadio))

    # --- Common Options (Now for electron-builder override) ---
    $commonOptionsGroup = New-Object System.Windows.Forms.GroupBox; $commonOptionsGroup.Text = "Build Overrides (Optional)"; $commonOptionsGroup.Location = New-Object System.Drawing.Point(10, 70); $commonOptionsGroup.Size = New-Object System.Drawing.Size(385, 80); $commonOptionsGroup.Font = $font
    # Output Directory
    $outputDirLabel = New-Object System.Windows.Forms.Label; $outputDirLabel.Text = "Output Directory:"; $outputDirLabel.Location = New-Object System.Drawing.Point(15, 25); $outputDirLabel.Size = New-Object System.Drawing.Size(120, 20); $outputDirLabel.Font = $font
    $outputDirTextBox = New-Object System.Windows.Forms.TextBox; $outputDirTextBox.Location = New-Object System.Drawing.Point(135, 22); $outputDirTextBox.Size = New-Object System.Drawing.Size(140, 20); $outputDirTextBox.Font = $font; $outputDirTextBox.PlaceholderText = "Default: dist-bundle"
    $browseOutputDirButton = New-Object System.Windows.Forms.Button; $browseOutputDirButton.Text = "Browse..."; $browseOutputDirButton.Location = New-Object System.Drawing.Point(285, 20); $browseOutputDirButton.Size = New-Object System.Drawing.Size(75, 25)
    # Executable Name
    $exeNameLabel = New-Object System.Windows.Forms.Label; $exeNameLabel.Text = "Executable Name:"; $exeNameLabel.Location = New-Object System.Drawing.Point(15, 55); $exeNameLabel.Size = New-Object System.Drawing.Size(120, 20); $exeNameLabel.Font = $font
    $exeNameTextBox = New-Object System.Windows.Forms.TextBox; $exeNameTextBox.Location = New-Object System.Drawing.Point(135, 52); $exeNameTextBox.Size = New-Object System.Drawing.Size(225, 20); $exeNameTextBox.Font = $font
    $commonOptionsGroup.Controls.AddRange(@($outputDirLabel, $outputDirTextBox, $browseOutputDirButton, $exeNameLabel, $exeNameTextBox))
    try {
        $pkgJson = Get-Content (Join-Path $PSScriptRoot "package.json") -Raw | ConvertFrom-Json
        if ($pkgJson.build.productName) { $exeNameTextBox.PlaceholderText = $pkgJson.build.productName }
        elseif ($pkgJson.productName) { $exeNameTextBox.PlaceholderText = $pkgJson.productName }
        elseif ($pkgJson.name) { $exeNameTextBox.PlaceholderText = $pkgJson.name }
    } catch { }

    # --- electron-builder Options ---
    $ebOptionsGroup = New-Object System.Windows.Forms.GroupBox; $ebOptionsGroup.Text = "electron-builder Options"; $ebOptionsGroup.Location = New-Object System.Drawing.Point(10, 155); $ebOptionsGroup.Size = New-Object System.Drawing.Size(385, 140); $ebOptionsGroup.Font = $font
    $platformGroup = New-Object System.Windows.Forms.GroupBox; $platformGroup.Text = "Target Platforms"; $platformGroup.Location = New-Object System.Drawing.Point(10, 20); $platformGroup.Size = New-Object System.Drawing.Size(365, 50); $platformGroup.Font = $font
    $winCheckBox = New-Object System.Windows.Forms.CheckBox; $winCheckBox.Text = "Windows (.exe)"; $winCheckBox.Location = New-Object System.Drawing.Point(15, 20); $winCheckBox.Checked = $true; $winCheckBox.AutoSize = $true
    $macCheckBox = New-Object System.Windows.Forms.CheckBox; $macCheckBox.Text = "macOS (.app)"; $macCheckBox.Location = New-Object System.Drawing.Point(125, 20); $macCheckBox.AutoSize = $true
    $linuxCheckBox = New-Object System.Windows.Forms.CheckBox; $linuxCheckBox.Text = "Linux"; $linuxCheckBox.Location = New-Object System.Drawing.Point(235, 20); $linuxCheckBox.AutoSize = $true
    $platformGroup.Controls.AddRange(@($winCheckBox, $macCheckBox, $linuxCheckBox))
    $archGroup = New-Object System.Windows.Forms.GroupBox; $archGroup.Text = "Target Architectures"; $archGroup.Location = New-Object System.Drawing.Point(10, 80); $archGroup.Size = New-Object System.Drawing.Size(365, 50); $archGroup.Font = $font
    $x64CheckBox = New-Object System.Windows.Forms.CheckBox; $x64CheckBox.Text = "x64 (Intel)"; $x64CheckBox.Location = New-Object System.Drawing.Point(15, 20); $x64CheckBox.Checked = $true; $x64CheckBox.AutoSize = $true
    $arm64CheckBox = New-Object System.Windows.Forms.CheckBox; $arm64CheckBox.Text = "arm64 (Apple Silicon)"; $arm64CheckBox.Location = New-Object System.Drawing.Point(125, 20); $arm64CheckBox.AutoSize = $true
    $archGroup.Controls.AddRange(@($x64CheckBox, $arm64CheckBox))
    $ebOptionsGroup.Controls.AddRange(@($platformGroup, $archGroup))

    # --- pkg Options ---
    $pkgOptionsGroup = New-Object System.Windows.Forms.GroupBox; $pkgOptionsGroup.Text = "pkg Options"; $pkgOptionsGroup.Location = New-Object System.Drawing.Point(10, 155); $pkgOptionsGroup.Size = New-Object System.Drawing.Size(385, 80); $pkgOptionsGroup.Visible = $false; $pkgOptionsGroup.Font = $font
    $pkgTargetsLabel = New-Object System.Windows.Forms.Label; $pkgTargetsLabel.Text = "Targets:"; $pkgTargetsLabel.Location = New-Object System.Drawing.Point(15, 25); $pkgTargetsLabel.Size = New-Object System.Drawing.Size(60, 20)
    $pkgTargetsTextBox = New-Object System.Windows.Forms.TextBox; $pkgTargetsTextBox.Text = "node16-win-x64"; $pkgTargetsTextBox.Location = New-Object System.Drawing.Point(80, 22); $pkgTargetsTextBox.Size = New-Object System.Drawing.Size(280, 20)
    $pkgHelpLabel = New-Object System.Windows.Forms.Label; $pkgHelpLabel.Text = "(e.g., node16-win-x64,node16-linux-x64 - see pkg docs for more)"; $pkgHelpLabel.Location = New-Object System.Drawing.Point(77, 45); $pkgHelpLabel.Size = New-Object System.Drawing.Size(290, 20)
    $pkgOptionsGroup.Controls.AddRange(@($pkgTargetsLabel, $pkgTargetsTextBox, $pkgHelpLabel))
    
    # Hide build step checkbox for electron-builder as it's now integrated in the 'package' script.
    $buildInfoLabel = New-Object System.Windows.Forms.Label; $buildInfoLabel.Text = "The 'npm run build' step is now automatically run by the 'package' script."; $buildInfoLabel.Location = New-Object System.Drawing.Point(15, 305); $buildInfoLabel.AutoSize = $true
    $buildInfoLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Italic)

    # Action Buttons
    $startPackagingButton = New-Object System.Windows.Forms.Button; $startPackagingButton.Text = "Start Packaging"; $startPackagingButton.Location = New-Object System.Drawing.Point(160, 340); $startPackagingButton.Size = New-Object System.Drawing.Size(120, 30)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(290, 340); $cancelButton.Size = New-Object System.Drawing.Size(85, 30)
    $packagingForm.CancelButton = $cancelButton

    $packagingForm.Controls.AddRange(@($packagerGroup, $commonOptionsGroup, $ebOptionsGroup, $pkgOptionsGroup, $buildInfoLabel, $startPackagingButton, $cancelButton))

    # --- Event Handlers for Packaging Form ---
    $Radio_CheckedChanged = { 
        $ebOptionsGroup.Visible = $ebRadio.Checked
        $pkgOptionsGroup.Visible = $pkgRadio.Checked
        $commonOptionsGroup.Text = if ($ebRadio.Checked) { "Build Overrides (Optional)" } else { "Common Options" }
        $outputDirTextBox.PlaceholderText = if ($ebRadio.Checked) { "Default: dist-bundle" } else { "" }
    }
    $ebRadio.add_CheckedChanged($Radio_CheckedChanged)
    $pkgRadio.add_CheckedChanged($Radio_CheckedChanged)

    $browseOutputDirButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; $folderBrowser.Description = "Select the output directory for the packaged application"
        if ($folderBrowser.ShowDialog() -eq 'OK') { $outputDirTextBox.Text = $folderBrowser.SelectedPath }
    })

    $startPackagingButton.Add_Click({
        $packageCommand = ""
        if ($ebRadio.Checked) {
            # --- electron-builder command ---
            if (-not ($winCheckBox.Checked -or $macCheckBox.Checked -or $linuxCheckBox.Checked)) { [System.Windows.Forms.MessageBox]::Show("Please select at least one target platform.", "Input Required", 'OK', 'Warning'); return }
            $commandArgs = New-Object System.Collections.ArrayList
            if ($winCheckBox.Checked) { $commandArgs.Add("--win") | Out-Null }
            if ($macCheckBox.Checked) { $commandArgs.Add("--mac") | Out-Null }
            if ($linuxCheckBox.Checked) { $commandArgs.Add("--linux") | Out-Null }
            if ($x64CheckBox.Checked) { $commandArgs.Add("--x64") | Out-Null }
            if ($arm64CheckBox.Checked) { $commandArgs.Add("--arm64") | Out-Null }

            # Add optional overrides for values in package.json
            if ($exeNameTextBox.Text) { $commandArgs.Add("'--config.productName=""$($exeNameTextBox.Text)""'") | Out-Null }
            if ($outputDirTextBox.Text) { $commandArgs.Add("'--config.directories.output=""$($outputDirTextBox.Text)""'") | Out-Null }

            $packageCommand = "npm run package -- --publish never $($commandArgs -join ' ')"

        } elseif ($pkgRadio.Checked) {
            # --- pkg command ---
            if (-not $outputDirTextBox.Text) { [System.Windows.Forms.MessageBox]::Show("Please select an output directory.", "Input Required", 'OK', 'Warning'); return }
            if (-not (Get-Command pkg -ErrorAction SilentlyContinue)) {
                $msg = "'pkg' command not found. It must be installed globally.`n`nWould you like to install it now? (This will run 'npm install -g pkg')"
                $result = [System.Windows.Forms.MessageBox]::Show($msg, "Dependency Missing", 'YesNo', 'Question')
                if ($result -eq 'Yes') {
                    $packagingForm.Close()
                    Run-Task -ScriptBlock { npm install -g pkg 2>&1 } `
                             -JobName "globalInstaller" `
                             -UiMessage "Installing pkg globally..." `
                             -OnSuccessAction {
                                 [System.Windows.Forms.MessageBox]::Show("'pkg' has been installed successfully.`n`nPlease open the packaging window again to continue.", "Install Complete", 'OK', 'Information')
                             }
                }
                return
            }
            if (-not $pkgTargetsTextBox.Text) { [System.Windows.Forms.MessageBox]::Show("Please provide at least one target for pkg.", "Input Required", 'OK', 'Warning'); return }
            $pkgExeName = if ($exeNameTextBox.Text) { $exeNameTextBox.Text } else { $exeNameTextBox.PlaceholderText }
            $outputPath = Join-Path $outputDirTextBox.Text $pkgExeName
            if ($pkgTargetsTextBox.Text -like "*win*" -and [System.IO.Path]::GetExtension($outputPath) -ne ".exe") { $outputPath += ".exe" }
            $packageCommand = "pkg . --targets $($pkgTargetsTextBox.Text) --output '""$outputPath""'"
        }

        $packagingForm.Close() # Close the options form before starting the job.
        Run-Task -ScriptBlock { Invoke-Expression -Command $using:packageCommand 2>&1 } -JobName "packager" -UiMessage "Starting packaging process for $Framework...`nThis may take a while."
    })

    $cancelButton.Add_Click({ $packagingForm.Close() })
    $packagingForm.ShowDialog($form) | Out-Null
}

# --- BUTTON CLICK EVENT HANDLERS ---
$installButton.Add_Click({
    Run-Task -ScriptBlock { npm install 2>&1 } -JobName "installer" -UiMessage "Running 'npm install'..."
})

$devButton.Add_Click({
    $script:serverUrl = $null
    Run-Task -ScriptBlock { npm run dev 2>&1 } -JobName "devServer" -UiMessage "Starting dev server..."
})

$packageButton_Click = {
    param($Framework)

    $packageJsonPath = Join-Path $PSScriptRoot "package.json"
    if (-not (Test-Path $packageJsonPath)) { [System.Windows.Forms.MessageBox]::Show("Could not find package.json.", "File Not Found", 'OK', 'Error'); return }
    try { $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json }
    catch { [System.Windows.Forms.MessageBox]::Show("Failed to parse package.json. Error: $($_.Exception.Message)", "Error", 'OK', 'Error'); return }

    # --- Modern electron-vite workflow check ---
    $allDeps = @()
    if ($packageJson.dependencies) { $allDeps += $packageJson.dependencies.PSObject.Properties.Name }
    if ($packageJson.devDependencies) { $allDeps += $packageJson.devDependencies.PSObject.Properties.Name }

    $isEviteConfigured = ($allDeps -contains 'electron-vite') `
        -and ($allDeps -contains 'electron') `
        -and ($allDeps -contains 'electron-builder') `
        -and ($packageJson.scripts.build -eq 'electron-vite build')

    $continuation = { Show-PackagingForm -Framework $Framework }

    if ($isEviteConfigured) {
        & $continuation
    } else {
        $message = "Your project is not configured for the modern Electron packaging workflow.`n`nThis requires 'electron', 'electron-builder', and 'electron-vite'.`n`nWould you like to automatically install these dependencies and configure your package.json?"
        $result = [System.Windows.Forms.MessageBox]::Show($message, "Automatic Setup Required", 'YesNo', 'Question')

        if ($result -eq 'Yes') {
            $depsToInstall = @('electron', 'electron-builder', 'electron-vite') | Where-Object { $_ -notin $allDeps }
            
            # Modify package.json in memory
            if (-not $packageJson.scripts) { $packageJson | Add-Member -MemberType NoteProperty -Name "scripts" -Value (New-Object -TypeName PSObject) }
            $packageJson.scripts | Add-Member -MemberType NoteProperty -Name "build" -Value "electron-vite build" -Force
            $packageJson.scripts | Add-Member -MemberType NoteProperty -Name "package" -Value "npm run build && electron-builder" -Force

            if (-not $packageJson.build) {
                $appName = if ($packageJson.productName) { $packageJson.productName } else { $packageJson.name }
                $buildConfig = @{
                    appId = "com.example.$($appName)"
                    productName = $appName
                    directories = @{
                        output = "dist-bundle"
                    }
                    files = @( "dist-electron/**/*" )
                } | ConvertTo-Json -Depth 5
                $packageJson | Add-Member -MemberType NoteProperty -Name "build" -Value (ConvertFrom-Json $buildConfig)
            }
            
            # Save changes to package.json
            $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
            $outputTextBox.AppendText("`n>>> Configured package.json for electron-vite workflow.`n")

            # Install any missing dependencies
            if ($depsToInstall.Count -gt 0) {
                $installString = $depsToInstall -join ' '
                Run-Task -ScriptBlock { npm install $using:installString --save-dev 2>&1 } `
                         -JobName "dependencyInstaller" `
                         -UiMessage "Installing modern build dependencies ($installString)..." `
                         -OnSuccessAction $continuation
            } else {
                # All deps were present, just config was wrong.
                & $continuation
            }
        }
    }
}
$packageReactButton.Add_Click({ & $packageButton_Click -Framework "React" })
$packageAngularButton.Add_Click({ & $packageButton_Click -Framework "Angular" })

$detectButton.Add_Click({
    $packageJsonPath = Join-Path $PSScriptRoot "package.json"
    $angularJsonPath = Join-Path $PSScriptRoot "angular.json"
    $outputTextBox.AppendText("`n`n>>> Detecting framework...`n")
    if (-not (Test-Path $packageJsonPath)) { $outputTextBox.AppendText("`n>>> ERROR: package.json not found in the current directory. <<<`n"); $outputTextBox.ScrollToCaret(); [System.Windows.Forms.MessageBox]::Show("Could not find package.json. Make sure this script is in the root of your Node.js project.", "File Not Found", 'OK', 'Error'); return }
    try {
        $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
        $allDependencies = @(); if ($packageJson.dependencies) { $allDependencies += $packageJson.dependencies.PSObject.Properties.Name }; if ($packageJson.devDependencies) { $allDependencies += $packageJson.devDependencies.PSObject.Properties.Name }
        $isReact = $allDependencies -contains 'react' -and $allDependencies -contains 'react-dom'
        $isAngular = ($allDependencies -contains '@angular/core') -or (Test-Path $angularJsonPath)
        if ($isReact) { $outputTextBox.AppendText(">>> Framework detected: React`n"); [System.Windows.Forms.MessageBox]::Show("This appears to be a React project.", "Framework Detected", 'OK', 'Information') }
        elseif ($isAngular) { $outputTextBox.AppendText(">>> Framework detected: Angular`n"); [System.Windows.Forms.MessageBox]::Show("This appears to be an Angular project.", "Framework Detected", 'OK', 'Information') }
        else { $outputTextBox.AppendText(">>> Framework not detected. Could not identify as React or Angular.`n"); [System.Windows.Forms.MessageBox]::Show("Could not definitively identify the framework as React or Angular based on dependencies.", "Detection Complete", 'OK', 'Warning') }
    } catch { $outputTextBox.AppendText("`n>>> ERROR: Failed to parse package.json. Error: $($_.Exception.Message) <<<`n"); [System.Windows.Forms.MessageBox]::Show("Failed to read or parse package.json.`n`nError: $($_.Exception.Message)", "Error", 'OK', 'Error') }
    $outputTextBox.ScrollToCaret()
})

$browserButton.Add_Click({
    if ($script:serverUrl) {
        try { Start-Process $script:serverUrl } catch { [System.Windows.Forms.MessageBox]::Show("Failed to open URL: $($script:serverUrl)`n`nError: $($_.Exception.Message)", "Error", 'OK', 'Error') }
    }
})

$stopButton.Add_Click({ & $StopCurrentJob })

$envButton.Add_Click({
    # --- IMPORTANT: UPDATE THIS PATH ---
    $sourceEnvPath = "C:\path\to\your\master\.env.local"
    # ------------------------------------
    $destEnvPath = Join-Path $PSScriptRoot ".env.local"
    if (-not (Test-Path $sourceEnvPath)) { [System.Windows.Forms.MessageBox]::Show("Source .env.local file not found at:`n$sourceEnvPath`n`nPlease update the path in the script.", "Error: Path Not Configured", 'OK', 'Error'); return }
    try { Copy-Item -Path $sourceEnvPath -Destination $destEnvPath -Force -ErrorAction Stop; $outputTextBox.AppendText("`n>>> Successfully copied .env.local file. <<<`n"); $outputTextBox.ScrollToCaret() }
    catch { [System.Windows.Forms.MessageBox]::Show("Failed to copy file.`n`nError: $($_.Exception.Message)", "Error", 'OK', 'Error') }
})

$closeButton.Add_Click({ & $StopCurrentJob; $form.Close() })
$form.Add_FormClosing({ & $StopCurrentJob })

# --- SHOW THE GUI ---
Update-StatusIndicator('stopped')
[void]$form.ShowDialog()