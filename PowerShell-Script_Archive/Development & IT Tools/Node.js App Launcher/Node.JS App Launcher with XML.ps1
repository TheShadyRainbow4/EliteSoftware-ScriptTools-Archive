<#
.SYNOPSIS
    A GUI launcher for Node.js applications, with a UI defined by an external XML file.
.DESCRIPTION
    This script provides a graphical interface to run common npm commands for a Node.js project.
    It reads its UI configuration from 'ui.xml' and assumes it is running from the project's root directory.
    Node.js App Launcher v1.2.0.0 - Created by: Zachary Whiteman & Google Gemini Ai.
    Date: 8/20/2025 - 10:51 AM
.NOTES
    Requires PowerShell 5.1 or higher. Place this script and 'ui.xml' in the root of your Node.js project.
#>

#region Assembly Loading and Initial Setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
#endregion

#region Core Variables
# The script now assumes it's in the project root. No more folder browsing.
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectPath = $scriptPath 
$xmlPath = Join-Path $scriptPath "ui.xml"
$devServerProcess = $null
# Hardcoded path to your .env template file.
$envTemplatePath = "H:\Program Files\New+\Templates\.env.local"
#endregion

#region UI Generation from XML
try {
    [xml]$uiXml = Get-Content -Path $xmlPath
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Could not find or load ui.xml. Make sure it's in the same directory as the script.", "Error", "OK", "Error")
    exit
}

# Select the specific project from the XML file
$projectNode = $uiXml.projects.project | Where-Object { $_.name -eq "NodeJsAppLauncher" }
if (-not $projectNode) {
    [System.Windows.Forms.MessageBox]::Show("Could not find project 'NodeJsAppLauncher' in ui.xml.", "Error", "OK", "Error")
    exit
}

$formNode = $projectNode.form

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = $formNode.title
$mainForm.Width = [int]$formNode.width
$mainForm.Height = [int]$formNode.height
$mainForm.FormBorderStyle = 'FixedSingle'
$mainForm.MaximizeBox = $false
$mainForm.StartPosition = 'CenterScreen'

# Create a hash table to store controls for easy access
$controls = @{}

# Dynamically create all controls from XML
$formNode.ChildNodes | Where-Object { $_.NodeType -eq 'Element' } | ForEach-Object {
    $node = $_
    # The 'header' is now a regular control, but we handle its name specially.
    $typeName = $node.GetAttribute('type')
    if ([string]::IsNullOrEmpty($typeName)) {
        Write-Warning "Skipping a control node in XML because it's missing the 'type' attribute."
        return
    }
    
    $controlType = "System.Windows.Forms.$($typeName)"
    $control = $null
    try {
        $control = New-Object $controlType -ErrorAction Stop
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to create control of type '$controlType' for node named '$($node.name)'. Check ui.xml.", "UI Error", "OK", "Error")
        return
    }
    
    # Set properties from XML attributes
    $control.Name = $node.name
    $control.Text = $node.text
    $control.Location = New-Object System.Drawing.Point([int]$node.x, [int]$node.y)
    $control.Width = [int]$node.width
    $control.Height = [int]$node.height

    if ($node.font) {
        $fontDetails = $node.font -split ',\s*'
        $fontFamily = $fontDetails[0]
        $fontSize = [float]$fontDetails[1]
        $fontStyle = if ($fontDetails.Count -gt 2) { [System.Drawing.FontStyle]$fontDetails[2] } else { [System.Drawing.FontStyle]::Regular }
        $control.Font = New-Object System.Drawing.Font($fontFamily, $fontSize, $fontStyle)
    }
    if ($node.foreColor) { $control.ForeColor = [System.Drawing.Color]::$($node.foreColor) }
    if ($node.backColor) { $control.BackColor = [System.Drawing.Color]::$($node.backColor) }
    if ($node.multiline) { $control.Multiline = [bool]::Parse($node.multiline); $control.ScrollBars = 'Vertical' }
    if ($node.readonly) { $control.ReadOnly = [bool]::Parse($node.readonly) }
    if ($node.enabled) { $control.Enabled = [bool]::Parse($node.enabled) }
    
    $mainForm.Controls.Add($control)
    $controls[$control.Name] = $control
}

# After all controls are created, parent the headerLabel to the headerPanel
if ($controls.ContainsKey('headerPanel') -and $controls.ContainsKey('headerLabel')) {
    $controls['headerPanel'].Controls.Add($controls['headerLabel'])
    # Adjust label's location to be relative to the panel
    $controls['headerLabel'].Location = New-Object System.Drawing.Point(10, 10) 
}
#endregion

#region Functions and Event Handlers

function Write-OutputBox {
    param($text)
    if ($controls.outputBox.InvokeRequired) {
        $controls.outputBox.Invoke([Action[string]] { Write-OutputBox -text $text }, $text)
    } else {
        $controls.outputBox.AppendText("$text`r`n")
    }
}

function Run-Process {
    param([string]$command, [string[]]$arguments, [string]$workingDirectory)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $command
    $process.StartInfo.Arguments = $arguments
    $process.StartInfo.WorkingDirectory = $workingDirectory
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.CreateNoWindow = $true
    $process.EnableRaisingEvents = $true
    Register-ObjectEvent -InputObject $process -EventName "OutputDataReceived" -Action { Write-OutputBox -text $EventArgs.Data } | Out-Null
    Register-ObjectEvent -InputObject $process -EventName "ErrorDataReceived" -Action { Write-OutputBox -text "ERROR: $($EventArgs.Data)" } | Out-Null
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    return $process
}

$controls.btnInstall.Add_Click({
    Write-OutputBox "Starting 'npm install'..."
    $controls.btnInstall.Enabled = $false
    $controls.btnRunDev.Enabled = $false
    $process = Run-Process -command "npm.cmd" -arguments "install" -workingDirectory $script:projectPath
    $job = Start-Job { param($p) $p.WaitForExit() } -ArgumentList $process
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($job.State -eq 'Completed') {
            Write-OutputBox "'npm install' finished."
            $mainForm.Invoke([Action]{
                $controls.btnInstall.Enabled = $true
                $controls.btnRunDev.Enabled = $true
            })
            Unregister-Event -SourceIdentifier $job.StateChanged.SourceIdentifier
            $job | Remove-Job
        }
    } | Out-Null
})

$controls.btnRunDev.Add_Click({
    Write-OutputBox "Starting 'npm run dev'..."
    $script:devServerProcess = Run-Process -command "npm.cmd" -arguments "run dev" -workingDirectory $script:projectPath
    $controls.btnRunDev.Enabled = $false
    $controls.btnStop.Enabled = $true
    $controls.btnBrowser.Enabled = $true
    $controls.statusIndicator.ForeColor = [System.Drawing.Color]::LimeGreen
    # Change Stop button color to indicate server is running
    $controls.btnStop.BackColor = [System.Drawing.Color]::Red
})

$controls.btnStop.Add_Click({
    if ($script:devServerProcess -and -not $script:devServerProcess.HasExited) {
        try {
            taskkill /F /T /PID $script:devServerProcess.Id | Out-Null
            Write-OutputBox "Server process stopped."
        } catch {
            Write-OutputBox "Failed to stop the server process. It may have already closed."
        }
    } else {
        Write-OutputBox "Server is not running."
    }
    $controls.btnRunDev.Enabled = $true
    $controls.btnStop.Enabled = $false
    $controls.btnBrowser.Enabled = $false
    $controls.statusIndicator.ForeColor = [System.Drawing.Color]::Red
    # Reset Stop button color to default
    $controls.btnStop.UseVisualStyleBackColor = $true
    $script:devServerProcess = $null
})

$controls.btnBrowser.Add_Click({
    $url = "http://localhost:3000" 
    Write-OutputBox "Opening $url in your default browser..."
    [System.Diagnostics.Process]::Start($url)
})

# Updated .env button logic to copy from a template
$controls.btnEnv.Add_Click({
    if (-not (Test-Path $script:envTemplatePath)) {
        Write-OutputBox "ERROR: .env template file not found at '$($script:envTemplatePath)'"
        return
    }
    $destEnvPath = Join-Path $script:projectPath ".env"
    try {
        Copy-Item -Path $script:envTemplatePath -Destination $destEnvPath -ErrorAction Stop
        Write-OutputBox ".env file created from template."
        Write-OutputBox "Opening .env file for editing..."
        Invoke-Item $destEnvPath
    } catch {
        Write-OutputBox "ERROR: Failed to copy .env template. $_"
    }
})

$OnClose = {
    if ($script:devServerProcess -and -not $script:devServerProcess.HasExited) {
        $confirm = [System.Windows.Forms.MessageBox]::Show("The dev server is still running. Do you want to stop it before closing?", "Confirm Exit", "YesNo", "Warning")
        if ($confirm -eq "Yes") {
            taskkill /F /T /PID $script:devServerProcess.Id | Out-Null
        }
    }
    $mainForm.Close()
}
$controls.btnClose.Add_Click($OnClose)
$mainForm.Add_FormClosing($OnClose)

#endregion

#region Show Form
# Write the project path to the output box on startup.
$mainForm.Add_Shown({
    Write-OutputBox "Project directory set to: $($script:projectPath)"
})
[void]$mainForm.ShowDialog()
#endregion
