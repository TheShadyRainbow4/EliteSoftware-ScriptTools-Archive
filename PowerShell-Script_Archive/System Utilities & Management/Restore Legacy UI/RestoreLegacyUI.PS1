<#
.SYNOPSIS
    Reunion 7 Legacy UI Restorer (TI Mode)
    
.DESCRIPTION
    Replaces display.dll and updates registry for Classic Display settings.
    ASSUMES SCRIPT IS RUNNING AS TRUSTEDINSTALLER.
    Does not attempt to change Registry Ownership.
#>

# 1. Load Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 2. Enable Visual Styles
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Configuration ---
$TargetDLL = "$env:SystemRoot\System32\display.dll"
$TargetMUI = "$env:SystemRoot\System32\en-US\display.dll.mui"
$SourceDLL = Join-Path $PSScriptRoot "display.dll"
$SourceMUI = Join-Path $PSScriptRoot "display.dll.mui"
$TbConf    = Join-Path $PSScriptRoot "TbConf.exe"

# --- Functions ---

Function Take-File-Ownership {
    # Only for files, just in case.
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        try {
            Start-Process -FilePath "takeown.exe" -ArgumentList "/F `"$FilePath`" /A" -NoNewWindow -PassThru -Wait | Out-Null
            Start-Process -FilePath "icacls.exe" -ArgumentList "`"$FilePath`" /grant Administrators:F" -NoNewWindow -PassThru -Wait | Out-Null
        } catch {}
    }
}

Function Hot-Swap-File {
    param([string]$Source, [string]$Destination)
    
    # We still ensure file access, but rely on TI permissions mostly
    Take-File-Ownership $Destination
    
    try {
        Copy-Item $Source $Destination -Force -ErrorAction Stop
        return $true
    } catch {
        try {
            # Locked file workaround: Rename live file -> Copy new one
            $BackupName = "$Destination.old_$(Get-Random)"
            Move-Item $Destination $BackupName -Force -ErrorAction Stop
            Copy-Item $Source $Destination -Force -ErrorAction Stop
            return $true
        } catch {
            return $false
        }
    }
}

Function Restore-Display {
    try {
        # 1. Validation
        if (-not (Test-Path $SourceDLL) -or -not (Test-Path $SourceMUI)) {
            [System.Windows.Forms.MessageBox]::Show("Build 1511 'display.dll' files missing.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        $StatusLabel.Text = "Status: Modifying System Files..."
        $Form.Refresh()

        # 2. Hot-Swap System Files
        $DllSuccess = Hot-Swap-File -Source $SourceDLL -Destination $TargetDLL
        $MuiSuccess = Hot-Swap-File -Source $SourceMUI -Destination $TargetMUI

        if (-not $DllSuccess -or -not $MuiSuccess) {
            throw "Could not replace display.dll. File heavily locked."
        }

        # 3. Registry Injection (Direct Access - No Ownership Tricks)
        $StatusLabel.Text = "Status: Injecting Registry Keys..."
        $Form.Refresh()

        $ClsidPath = "HKLM:\SOFTWARE\Classes\CLSID\{C555438B-3C23-4769-A71F-B6D3D9B6053A}"
        if (-not (Test-Path $ClsidPath)) { New-Item -Path $ClsidPath -Force | Out-Null }
        
        Set-ItemProperty -Path $ClsidPath -Name "(default)" -Value "Display Settings"
        Set-ItemProperty -Path $ClsidPath -Name "System.ApplicationName" -Value "Microsoft.Display"
        
        $InProcPath = Join-Path $ClsidPath "InProcServer32"
        if (-not (Test-Path $InProcPath)) { New-Item -Path $InProcPath -Force | Out-Null }
        Set-ItemProperty -Path $InProcPath -Name "(default)" -Value "C:\Windows\System32\display.dll"
        Set-ItemProperty -Path $InProcPath -Name "ThreadingModel" -Value "Apartment"

        # 4. Context Menu Override
        $CmdPath = "HKLM:\SOFTWARE\Classes\DesktopBackground\Shell\Display\command"
        
        if (Test-Path $CmdPath) {
            # Direct Nuke of DelegateExecute (Assumes TI Access)
            Remove-ItemProperty -Path $CmdPath -Name "DelegateExecute" -ErrorAction SilentlyContinue
            
            # Direct Set of Command
            Set-ItemProperty -Path $CmdPath -Name "(default)" -Value "explorer.exe shell:::{C555438B-3C23-4769-A71F-B6D3D9B6053A}" -Force
        }

        # 5. Optional: TbConf
        if (Test-Path $TbConf) {
            Copy-Item $TbConf "$env:SystemRoot\TbConf.exe" -Force
            $StatusLabel.Text = "Status: TbConf Installed."
        }

        $StatusLabel.Text = "Status: Complete!"
        
        $Result = [System.Windows.Forms.MessageBox]::Show("Restoration Complete.`n`nRestart Explorer to apply?", "Success", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        
        if ($Result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Stop-Process -Name explorer
        }
    
    } catch {
        $Err = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Error: $Err", "Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# --- GUI Construction ---
try {
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Reunion 7 UI Replicator"
    $Form.Size = New-Object System.Drawing.Size(400, 280) 
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = "FixedDialog"
    $Form.MaximizeBox = $false

    $Label = New-Object System.Windows.Forms.Label
    $Label.Location = New-Object System.Drawing.Point(20, 20)
    $Label.Size = New-Object System.Drawing.Size(350, 80)
    $Label.Text = "This tool replaces display.dll and restores the classic UI.`nRUN AS TRUSTEDINSTALLER.`nEnsure files are in the root folder."

    $BtnRestore = New-Object System.Windows.Forms.Button
    $BtnRestore.Location = New-Object System.Drawing.Point(100, 115)
    $BtnRestore.Size = New-Object System.Drawing.Size(180, 40)
    $BtnRestore.Text = "Restore Classic Display"
    $BtnRestore.FlatStyle = [System.Windows.Forms.FlatStyle]::System 
    $BtnRestore.Add_Click({ Restore-Display })

    $StatusLabel = New-Object System.Windows.Forms.Label
    $StatusLabel.Location = New-Object System.Drawing.Point(20, 175)
    $StatusLabel.Size = New-Object System.Drawing.Size(350, 30)
    $StatusLabel.Text = "Status: Waiting..."
    $StatusLabel.TextAlign = "MiddleCenter"

    $Form.Controls.Add($Label)
    $Form.Controls.Add($BtnRestore)
    $Form.Controls.Add($StatusLabel)

    $Form.ShowDialog()
} catch {
    Write-Host "GUI Crash: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Safety Pause ---
Write-Host "Script Execution Finished. Press Enter to exit..."
Read-Host
