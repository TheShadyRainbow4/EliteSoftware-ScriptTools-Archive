# =================================================================================================
# MSDT Preservation Tool
#
# Author: Gemini
# Version: 1.3
# Description: A GUI tool to disable the redirection of MSDT troubleshooters to the "Get Help"
#              app, back up the troubleshooter files, and manage related settings.
# =================================================================================================

#region Admin Rights Check
# -------------------------------------------------------------------------------------------------
# 📝 Note: This section ensures the script runs with administrative privileges, which are
# required for modifying the HKEY_LOCAL_MACHINE registry hive and accessing system folders.
# -------------------------------------------------------------------------------------------------
function Get-IsAdmin {
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Error "Failed to check for admin rights: $_"
        return $false
    }
}

if (-not (Get-IsAdmin)) {
    try {
        $arguments = "& `"$($MyInvocation.MyCommand.Definition)`""
        Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
        exit
    }
    catch {
        Write-Error "Failed to relaunch as administrator: $_"
        exit 1
    }
}
#endregion

#region Core GUI Script
# -------------------------------------------------------------------------------------------------
# 📝 Note: This section defines the main GUI application using Windows Forms. It loads the
# required .NET assemblies and sets up all the UI elements and their corresponding event handlers.
# -------------------------------------------------------------------------------------------------

try {
    # Load required assemblies
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Enable modern visual styles for controls
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    # --- Global Variables ---
    $script:RedirectRegKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msdt.exe"
    $script:TroubleshootingPolicyRegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $script:TroubleshootingPolicyRegValueName = "EnableLegacyTroubleshooting"
    $script:TroubleshooterPath = "C:\Windows\diagnostics"
    $script:MsdtExePath = "C:\Windows\System32\msdt.exe"
    $script:DesktopPath = [System.Environment]::GetFolderPath('Desktop')
    $script:AppConfigPath = "C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftware\MSDTPreservationTool"

    # Create config directory if it doesn't exist
    if (-not (Test-Path $script:AppConfigPath)) {
        New-Item -Path $script:AppConfigPath -ItemType Directory -Force | Out-Null
    }

    # --- Form Creation ---
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Text = "MSDT Preservation Tool"
    $mainForm.Size = New-Object System.Drawing.Size(500, 420)
    $mainForm.StartPosition = "CenterScreen"
    $mainForm.FormBorderStyle = "FixedSingle"
    $mainForm.MaximizeBox = $false
    $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($script:MsdtExePath)

    # --- UI Elements ---

    # Main Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "MSDT Troubleshooter Management"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(12, 12)
    $titleLabel.AutoSize = $true
    $mainForm.Controls.Add($titleLabel)

    # Description Label
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = "Use these options to control the MSDT engine and back up files."
    $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $descLabel.Location = New-Object System.Drawing.Point(12, 40)
    $descLabel.AutoSize = $true
    $mainForm.Controls.Add($descLabel)

    # GroupBox for Actions
    $actionsGroup = New-Object System.Windows.Forms.GroupBox
    $actionsGroup.Text = "Actions"
    $actionsGroup.Location = New-Object System.Drawing.Point(12, 70)
    $actionsGroup.Size = New-Object System.Drawing.Size(460, 120)
    $mainForm.Controls.Add($actionsGroup)

    # Enable Legacy Troubleshooters Button
    $enableLegacyButton = New-Object System.Windows.Forms.Button
    $enableLegacyButton.Text = "Enable Legacy Troubleshooters"
    $enableLegacyButton.Location = New-Object System.Drawing.Point(15, 25)
    $enableLegacyButton.Size = New-Object System.Drawing.Size(210, 35)
    $actionsGroup.Controls.Add($enableLegacyButton)

    # Use Get Help App Button
    $useGetHelpButton = New-Object System.Windows.Forms.Button
    $useGetHelpButton.Text = "Use 'Get Help' App (Default)"
    $useGetHelpButton.Location = New-Object System.Drawing.Point(235, 25)
    $useGetHelpButton.Size = New-Object System.Drawing.Size(210, 35)
    $actionsGroup.Controls.Add($useGetHelpButton)

    # Backup Button
    $backupButton = New-Object System.Windows.Forms.Button
    $backupButton.Text = "Backup All Troubleshooters"
    $backupButton.Location = New-Object System.Drawing.Point(15, 70)
    $backupButton.Size = New-Object System.Drawing.Size(210, 35)
    $actionsGroup.Controls.Add($backupButton)

    # Copy Path Button
    $copyPathButton = New-Object System.Windows.Forms.Button
    $copyPathButton.Text = "Copy Troubleshooter Path"
    $copyPathButton.Location = New-Object System.Drawing.Point(235, 70)
    $copyPathButton.Size = New-Object System.Drawing.Size(210, 35)
    $actionsGroup.Controls.Add($copyPathButton)

    # GroupBox for Status Log
    $logGroup = New-Object System.Windows.Forms.GroupBox
    $logGroup.Text = "Status Log"
    $logGroup.Location = New-Object System.Drawing.Point(12, 200)
    $logGroup.Size = New-Object System.Drawing.Size(460, 160)
    $mainForm.Controls.Add($logGroup)

    # Status Log RichTextBox
    $statusLog = New-Object System.Windows.Forms.RichTextBox
    $statusLog.Location = New-Object System.Drawing.Point(10, 20)
    $statusLog.Size = New-Object System.Drawing.Size(440, 130)
    $statusLog.ReadOnly = $true
    $statusLog.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusLog.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $logGroup.Controls.Add($statusLog)

    # --- Functions ---
    
    function Log-Message {
        param(
            [string]$Message,
            [System.Drawing.Color]$Color = [System.Drawing.Color]::Black
        )
        $timestamp = Get-Date -Format "HH:mm:ss"
        $statusLog.SelectionStart = $statusLog.TextLength
        $statusLog.SelectionLength = 0
        $statusLog.SelectionColor = $Color
        $statusLog.AppendText("[$timestamp] $Message`n")
        $statusLog.ScrollToCaret()
    }
    
    function Check-RedirectStatus {
        $policyValue = (Get-ItemProperty -Path $script:TroubleshootingPolicyRegKeyPath -Name $script:TroubleshootingPolicyRegValueName -ErrorAction SilentlyContinue).$($script:TroubleshootingPolicyRegValueName)
        
        if ($policyValue -eq 1) {
            Log-Message "Status: Legacy Troubleshooters are ENABLED." -Color Green
            $enableLegacyButton.Enabled = $false
            $useGetHelpButton.Enabled = $true
        } else {
            Log-Message "Status: Configured to use 'Get Help' app (Default)." -Color Red
            $enableLegacyButton.Enabled = $true
            $useGetHelpButton.Enabled = $false
        }
    }
    

    # --- Event Handlers ---

    $enableLegacyButton.Add_Click({
        try {
            Log-Message "Attempting to enable legacy troubleshooters..."

            # 1. Set the system policy to enable legacy troubleshooters
            if (-not (Test-Path $script:TroubleshootingPolicyRegKeyPath)) {
                New-Item -Path $script:TroubleshootingPolicyRegKeyPath -Force | Out-Null
            }
            Set-ItemProperty -Path $script:TroubleshootingPolicyRegKeyPath -Name $script:TroubleshootingPolicyRegValueName -Value 1 -Type DWord -Force
            Log-Message "System policy set to allow legacy troubleshooters."

            # 2. Remove the IFEO debugger key for msdt.exe as a fallback/secondary measure
            if (Test-Path $script:RedirectRegKey) {
                # Backup the key before removing it
                $backupFile = Join-Path $script:AppConfigPath -ChildPath "msdt_redirect_backup.reg"
                $process = Start-Process "reg.exe" -ArgumentList "export `"$($script:RedirectRegKey -replace 'HKLM:\\', 'HKEY_LOCAL_MACHINE\')`" `"$backupFile`" /y" -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    Log-Message "Registry key (Image File Execution) backed up."
                } else {
                    Log-Message "Failed to back up registry key (Image File Execution)." -Color Red
                }
                Remove-Item -Path $script:RedirectRegKey -Recurse -Force
                Log-Message "Removed direct msdt.exe redirect key."
            }
            
            Log-Message "SUCCESS: Legacy Troubleshooters have been enabled." -Color Green
        }
        catch {
            Log-Message "ERROR: Failed to enable legacy troubleshooters. $_" -Color Red
        }
        finally {
            Check-RedirectStatus
        }
    })

    $useGetHelpButton.Add_Click({
        try {
            Log-Message "Attempting to restore 'Get Help' app redirect..."

            # 1. Remove the system policy value
            if ((Get-ItemProperty -Path $script:TroubleshootingPolicyRegKeyPath -Name $script:TroubleshootingPolicyRegValueName -ErrorAction SilentlyContinue)) {
                Remove-ItemProperty -Path $script:TroubleshootingPolicyRegKeyPath -Name $script:TroubleshootingPolicyRegValueName -Force
                Log-Message "System policy for legacy troubleshooters removed."
            }

            # 2. Restore the IFEO debugger key
            $backupFile = Join-Path $script:AppConfigPath -ChildPath "msdt_redirect_backup.reg"
            if (-not (Test-Path $script:RedirectRegKey)) {
                if (Test-Path $backupFile) {
                    $process = Start-Process "reg.exe" -ArgumentList "import `"$backupFile`"" -Wait -PassThru
                     if ($process.ExitCode -eq 0) {
                        Log-Message "Direct msdt.exe redirect restored from backup."
                    } else {
                        Log-Message "Failed to restore msdt.exe redirect from backup." -Color Red
                    }
                } else {
                    Log-Message "No backup found for msdt.exe key. Manually recreating..."
                    New-Item -Path $script:RedirectRegKey -Force | Out-Null
                    New-ItemProperty -Path $script:RedirectRegKey -Name "Debugger" -Value "C:\Windows\System32\LaunchHelp.exe" -PropertyType String -Force | Out-Null
                    Log-Message "Direct msdt.exe redirect restored manually."
                }
            }
            
            Log-Message "SUCCESS: 'Get Help' app redirect has been restored." -Color Green
        }
        catch {
            Log-Message "ERROR: Failed to restore redirect. $_" -Color Red
        }
        finally {
            Check-RedirectStatus
        }
    })

    $backupButton.Add_Click({
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
            $backupFolderName = "MSDT_Preservation_Backup_$timestamp"
            $backupRootPath = Join-Path -Path $script:DesktopPath -ChildPath $backupFolderName
            
            Log-Message "Starting targeted backup process..."
            Log-Message "Creating backup root folder: `"$backupRootPath`""
            
            # Create the mirrored Windows folder structure
            $backupWindowsPath = Join-Path -Path $backupRootPath -ChildPath "Windows"
            $backupSystem32Path = Join-Path -Path $backupWindowsPath -ChildPath "System32"
            New-Item -Path $backupSystem32Path -ItemType Directory -Force | Out-Null
            
            Log-Message "Backing up core MSDT executable..."
            Copy-Item -Path $script:MsdtExePath -Destination $backupSystem32Path -Force

            Log-Message "Backing up related diagnostic DLLs from System32..."
            $diagDlls = Get-ChildItem -Path "C:\Windows\System32" -Filter "*.dll" | Where-Object { $_.Name -like 'diag*' -or $_.Name -like 'sdiag*' }
            
            if ($diagDlls) {
                foreach ($dll in $diagDlls) {
                    Log-Message "Copying $($dll.Name)..."
                    Copy-Item -Path $dll.FullName -Destination $backupSystem32Path -Force
                }
                Log-Message "$($diagDlls.Count) related DLLs copied." -Color Blue
            } else {
                Log-Message "No specific diagnostic DLLs found to back up." -Color Yellow
            }

            Log-Message "Backing up troubleshooter packages (maintaining structure)..."
            $backupDiagnosticsPath = Join-Path -Path $backupWindowsPath -ChildPath "diagnostics"
            Copy-Item -Path $script:TroubleshooterPath -Destination $backupDiagnosticsPath -Recurse -Force

            Log-Message "SUCCESS: Targeted backup completed successfully." -Color Green
            Log-Message "Backup saved to: `"$backupRootPath`""
        }
        catch {
            Log-Message "ERROR: Backup failed. $_" -Color Red
        }
    })

    $copyPathButton.Add_Click({
        try {
            Set-Clipboard -Value $script:TroubleshooterPath
            Log-Message "SUCCESS: Path `"$($script:TroubleshooterPath)`" copied to clipboard." -Color Green
        }
        catch {
            Log-Message "ERROR: Could not copy path to clipboard. $_" -Color Red
        }
    })
    
    # --- Form Load and Show ---
    $mainForm.Add_Shown({ 
        Log-Message "MSDT Preservation Tool Initialized."
        Log-Message "Running with Administrator privileges." -Color Blue
        Check-RedirectStatus
    })
    [void]$mainForm.ShowDialog()

}
catch {
    # Broad error handler for the entire script
    $errorMessage = "A critical error occurred: $_"
    [System.Windows.Forms.MessageBox]::Show($errorMessage, "Fatal Error", "OK", "Error")
}
#endregion

