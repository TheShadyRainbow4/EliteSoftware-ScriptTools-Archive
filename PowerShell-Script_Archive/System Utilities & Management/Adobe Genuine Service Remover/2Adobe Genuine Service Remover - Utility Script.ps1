<#
.SYNOPSIS
    A GUI-based utility to forcefully stop, delete, and clean up the Adobe Genuine Service.
.DESCRIPTION
    This script now actively hunts and terminates known Adobe background processes before attempting to delete service files.
.NOTES
    Version: 1.2.0.0
    Author: Zachary Whiteman & Google Gemini AI
    Changes:
    - Added a pre-emptive strike against common Adobe background processes (e.g., CoreSync, CCXProcess).
#>

#================================================================================
# SCRIPT INITIALIZATION AND DEPENDENCY CHECK
#================================================================================

# Self-elevate the script to run as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $MyInvocation.MyCommand.Path)
    exit
}

# Load necessary .NET assemblies for the GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable visual styles to make the GUI match the system theme
[System.Windows.Forms.Application]::EnableVisualStyles()

#================================================================================
# GUI CREATION
#================================================================================

# Main Form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Adobe Genuine Service Remover v1.2"
$mainForm.Size = New-Object System.Drawing.Size(420, 250)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = 'FixedSingle'
$mainForm.MaximizeBox = $false

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Size = New-Object System.Drawing.Size(380, 20)
$statusLabel.Text = "Status: Ready for process termination..."
$mainForm.Controls.Add($statusLabel)

# Output Text Box (for detailed logs)
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 40)
$outputBox.Size = New-Object System.Drawing.Size(380, 120)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$mainForm.Controls.Add($outputBox)

# Removal Button
$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(140, 170)
$removeButton.Size = New-Object System.Drawing.Size(120, 30)
$removeButton.Text = "Kill & Nuke"
$mainForm.Controls.Add($removeButton)

# Function to update the log
function Write-Log {
    param($message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $outputBox.AppendText("[$timestamp] $message`r`n")
    $outputBox.SelectionStart = $outputBox.Text.Length
    $outputBox.ScrollToCaret()
    $mainForm.Update()
}

#================================================================================
# CORE LOGIC
#================================================================================

$removeButton.Add_Click({
    $removeButton.Enabled = $false
    $statusLabel.Text = "Status: In progress..."

    try {
        # --- PRE-EMPTIVE STRIKE on known Adobe background processes ---
        $knownProcesses = @("AdobeIPCBroker", "CCXProcess", "CCLibrary", "CoreSync", "AGMService", "AdobeCollabSync", "AdobeGCClient", "Adobe Genuine Helper", "Adobe Genuine Launcher", "AGSService", "AGCInvokerUtility", "agshelper",)
        Write-Log "Hunting for known Adobe background processes..."
        foreach ($procName in $knownProcesses) {
            $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($process) {
                Write-Log "Found process '$procName'. Terminating..."
                Stop-Process -Name $procName -Force
                Write-Log "Process '$procName' terminated."
            }
        }
        Write-Log "Process hunt complete."

        # --- Service Deletion (will fail if already gone, which is OK) ---
        $serviceNames = @("AdobeIPCBroker", "CCXProcess", "CCLibrary", "CoreSync", "AGMService", "AdobeCollabSync", "AdobeGCClient", "Adobe Genuine Helper", "Adobe Genuine Launcher", "AGSService", "AGCInvokerUtility", "agshelper",)
        foreach ($serviceName in $serviceNames) {
            Write-Log "Checking for service: $serviceName..."
            if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
                Write-Log "Attempting to delete service '$serviceName'..."
                sc.exe delete $serviceName | Out-Null
                Write-Log "Delete command sent for service '$serviceName'."
            } else {
                Write-Log "Service '$serviceName' not found or already deleted."
            }
        }

        # --- File Deletion ---
        $targetDir = "$env:ProgramFiles(x86)\Common Files\Adobe\AdobeGCClient"
        Write-Log "Checking for directory: $targetDir"
        if (Test-Path $targetDir) {
            Write-Log "Directory found. Attempting to remove..."
            try {
                Remove-Item -Path $targetDir -Recurse -Force -ErrorAction Stop
                Write-Log "SUCCESS: Directory successfully removed."
            } catch {
                Write-Log "ERROR: Failed to remove directory. $_.Exception.Message"
            }
        } else {
            Write-Log "Directory not found. Nothing to remove."
        }
        
        $statusLabel.Text = "Status: Removal process completed!"
        Write-Log "------------------------------------"
        Write-Log "Process finished."

    } catch {
        $statusLabel.Text = "Status: A critical error occurred!"
        Write-Log "ERROR: $($_.Exception.Message)"
    } finally {
        $removeButton.Enabled = $true
    }
})

#================================================================================
# SHOW THE GUI
#================================================================================

[void]$mainForm.ShowDialog()
