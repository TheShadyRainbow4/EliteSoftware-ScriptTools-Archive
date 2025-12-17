# =================================================================
# SCRIPT NAME: AeroResurrector_v25_SyntaxFix.ps1
# DESCRIPTION: 1. Fixes "Invalid Syntax" by using Array Argument Lists.
#              2. Checks Key Existence before Exporting.
#              3. Uses STRICT PWSH 7.
# =================================================================

# 0. LAUNCHER
Param([switch]$AsTrustedInstaller)

if (-not $AsTrustedInstaller) {
    try {
        $code = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();'
        $win32 = Add-Type -MemberDefinition $code -Name "Win32ShowWindow" -Namespace Win32Functions -PassThru
        $handle = $win32::GetConsoleWindow()
        $win32::ShowWindow($handle, 0)
    } catch {}

    if (-not (Get-Command "NSudo.exe" -ErrorAction SilentlyContinue)) { [System.Windows.Forms.MessageBox]::Show("NSudo.exe missing.", "Error", "OK", "Error"); Exit }
    
    # Strict PWSH Check
    $TargetShell = "powershell.exe"
    if (Get-Command "pwsh.exe" -ErrorAction SilentlyContinue) { $TargetShell = "pwsh.exe" }
    else { [System.Windows.Forms.MessageBox]::Show("PowerShell 7 (pwsh) missing.", "Error", "OK", "Error"); Exit }

    $CurrentScript = $MyInvocation.MyCommand.Path
    $Args = "-U:T -P:E -ShowWindowMode:Show $TargetShell -ExecutionPolicy Bypass -NoProfile -File `"$CurrentScript`" -AsTrustedInstaller"
    Start-Process "NSudo.exe" -ArgumentList $Args -Wait
    Exit
}

# =================================================================
# PAYLOAD
# =================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURATION ---
$TargetFiles = @("desk.cpl", "display.dll", "deskmon.dll", "themeui.dll", "en-US\desk.cpl.mui", "en-US\display.dll.mui", "en-US\deskmon.dll.mui", "en-US\themeui.dll.mui") 
$DisplayGUID = "{C555438B-3C23-4769-A71F-B6D3D9B6053A}"

# --- PATHS ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackupRoot = Join-Path -Path $ScriptDir -ChildPath "Backup"
$RealSys32  = "$env:windir\System32"
$RealSys64  = "$env:windir\SysWOW64" 

Function Log-Msg ($Text) { try { $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Text`r`n"); $txtLog.ScrollToCaret() } catch {} }

# --- REGISTRY HELPER (ROBUST) ---
Function Run-RegExport ($Key, $File) {
    # Check if Key exists first to avoid syntax errors on missing keys
    if (-not (Test-Path "Registry::$Key")) {
        Log-Msg "⚠️ Key Missing (Skipping): $Key"
        return $false
    }

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo.FileName = "reg.exe"
    # Pass arguments as an array to ensure Quotes are handled perfectly
    $p.StartInfo.ArgumentList.Add("export")
    $p.StartInfo.ArgumentList.Add($Key)
    $p.StartInfo.ArgumentList.Add($File)
    $p.StartInfo.ArgumentList.Add("/y")
    
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError = $true
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.CreateNoWindow = $true
    $p.Start() | Out-Null
    $p.WaitForExit()
    
    $err = $p.StandardError.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($err)) { 
        Log-Msg "❌ REG ERROR: $err" 
        return $false
    }
    return $true
}

Function Run-RegImport ($File) {
    if (-not (Test-Path $File)) { Log-Msg "⚠️ Import File Missing: $File"; return }
    
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo.FileName = "reg.exe"
    $p.StartInfo.ArgumentList.Add("import")
    $p.StartInfo.ArgumentList.Add($File)
    
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError = $true
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.CreateNoWindow = $true
    $p.Start() | Out-Null
    $p.WaitForExit()
    
    if ($p.ExitCode -eq 0) { Log-Msg "✅ Imported: $(Split-Path $File -Leaf)" }
    else { Log-Msg "❌ Import Failed: $(Split-Path $File -Leaf)" }
}

# --- WORKER FUNCTIONS ---

Function Start-Harvest {
    $DestFolder = $txtSource.Text
    if (-not (Test-Path $DestFolder)) { New-Item -Path $DestFolder -ItemType Directory | Out-Null }
    Log-Msg "--- HARVESTING ---"
    
    # 1. FILES
    $Archs = @{ "System32" = $RealSys32; "SysWOW64" = $RealSys64 }
    foreach ($ArchName in $Archs.Keys) {
        $SysPath = $Archs[$ArchName]
        $DestArch = Join-Path $DestFolder $ArchName
        foreach ($RelPath in $TargetFiles) {
            $SrcFile = Join-Path $SysPath $RelPath
            $DstFile = Join-Path $DestArch $RelPath
            $DstParent = Split-Path $DstFile -Parent
            if (Test-Path $SrcFile) {
                if (-not (Test-Path $DstParent)) { New-Item -Path $DstParent -ItemType Directory -Force | Out-Null }
                Copy-Item -Path $SrcFile -Destination $DstFile -Force
                Log-Msg "Harvested: $ArchName\$RelPath"
            }
        }
    }
    
    # 2. REGISTRY
    Log-Msg "Harvesting Registry..."
    
    # A. The Sidebar/Resolution Page Behavior
    # We harvest from HKLM Software Classes because that's where the physical defaults live
    Run-RegExport "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\$DisplayGUID" (Join-Path $DestFolder "Harvested_CLSID_HKLM.reg") | Out-Null
    Run-RegExport "HKEY_CLASSES_ROOT\CLSID\$DisplayGUID" (Join-Path $DestFolder "Harvested_CLSID_HKCR.reg") | Out-Null
    
    # B. The Control Panel NameSpace Icon
    Run-RegExport "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\$DisplayGUID" (Join-Path $DestFolder "Harvested_NameSpace.reg") | Out-Null
    
    [System.Windows.Forms.MessageBox]::Show("Harvest Complete.", "Success", "OK", "Information")
}

Function Start-Backup {
    Log-Msg "--- BACKING UP TARGET ---"
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $CurrentBackupDir = Join-Path -Path $BackupRoot -ChildPath $Timestamp
    New-Item -Path $CurrentBackupDir -ItemType Directory -Force | Out-Null
    
    # 1. FILES
    $Archs = @{ "System32" = $RealSys32; "SysWOW64" = $RealSys64 }
    foreach ($ArchName in $Archs.Keys) {
        $SysPath = $Archs[$ArchName]
        $ArchBackupDir = Join-Path $CurrentBackupDir $ArchName
        foreach ($RelPath in $TargetFiles) {
            $SrcFile = Join-Path $SysPath $RelPath
            $DstFile = Join-Path $ArchBackupDir $RelPath
            $DstParent = Split-Path $DstFile -Parent
            if (Test-Path $SrcFile) {
                if (-not (Test-Path $DstParent)) { New-Item -Path $DstParent -ItemType Directory -Force | Out-Null }
                Copy-Item -Path $SrcFile -Destination $DstFile -Force
                Log-Msg "Backed up: $ArchName\$RelPath"
            }
        }
    }
    
    # 2. REGISTRY BACKUP (Robust)
    Log-Msg "Backing up Registry Keys..."
    
    # CLSID (Check both locations)
    if (Run-RegExport "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\$DisplayGUID" (Join-Path $CurrentBackupDir "Target_CLSID_HKLM.reg")) { Log-Msg "✅ Backed up CLSID (HKLM)" }
    if (Run-RegExport "HKEY_CLASSES_ROOT\CLSID\$DisplayGUID" (Join-Path $CurrentBackupDir "Target_CLSID_HKCR.reg")) { Log-Msg "✅ Backed up CLSID (HKCR)" }

    # NameSpace
    if (Run-RegExport "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\$DisplayGUID" (Join-Path $CurrentBackupDir "Target_NameSpace.reg")) { Log-Msg "✅ Backed up NameSpace" }

    Refresh-Backups
    [System.Windows.Forms.MessageBox]::Show("Backup Complete.", "Success", "OK", "Information")
}

Function Start-Install {
    $res = [System.Windows.Forms.MessageBox]::Show("Overwrite system files?", "Confirm Install", "YesNo", "Warning")
    if ($res -eq "No") { return }

    $SourceRoot = $txtSource.Text
    Log-Msg "Killing Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Log-Msg "--- INSTALLING FILES ---"
    $Archs = @{ "System32" = $RealSys32; "SysWOW64" = $RealSys64 }
    $SourceArchs = @{ "System32" = (Join-Path $SourceRoot "System32"); "SysWOW64" = (Join-Path $SourceRoot "SysWOW64") }

    foreach ($ArchName in $Archs.Keys) {
        $SysPath = $Archs[$ArchName]
        $SrcPath = $SourceArchs[$ArchName]
        foreach ($RelPath in $TargetFiles) {
            $FileSrc = Join-Path $SrcPath $RelPath
            $FileDst = Join-Path $SysPath $RelPath
            if (Test-Path $FileSrc) {
                try {
                    Copy-Item -Path $FileSrc -Destination $FileDst -Force -ErrorAction Stop
                    Log-Msg "Installed: $ArchName\$RelPath"
                } catch { Log-Msg "FAILED: $ArchName\$RelPath" }
            }
        }
    }
    
    Log-Msg "--- REGISTERING DLLS ---"
    $RegSvr32_x64 = Join-Path $RealSys32 "regsvr32.exe"
    $RegSvr32_x86 = Join-Path $RealSys64 "regsvr32.exe"
    foreach ($File in $TargetFiles) {
        if ($File -like "*.dll" -and -not ($File -like "*.mui")) {
            Start-Process $RegSvr32_x64 -ArgumentList "/s `"$((Join-Path $RealSys32 $File))`"" -Wait -NoNewWindow
            Start-Process $RegSvr32_x86 -ArgumentList "/s `"$((Join-Path $RealSys64 $File))`"" -Wait -NoNewWindow
        }
    }
    
    if ($chkReg.Checked) { 
        Log-Msg "--- IMPORTING REGISTRY ---"
        Run-RegImport (Join-Path $SourceRoot "Harvested_CLSID_HKLM.reg")
        Run-RegImport (Join-Path $SourceRoot "Harvested_CLSID_HKCR.reg")
        Run-RegImport (Join-Path $SourceRoot "Harvested_NameSpace.reg")

        # --- FORCE BLANK STRING ---
        Log-Msg "Enforcing Legacy DelegateExecute..."
        
        # We need to map the drive to be sure we can set the property
        if (-not (Get-PSDrive HKCR -ErrorAction SilentlyContinue)) { New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null }
        
        $CmdKey = "HKCR:\CLSID\$DisplayGUID\shell\open\command"
        if (Test-Path $CmdKey) {
             # Set to Empty String (Important: Pass explicit empty string)
             Set-ItemProperty -Path $CmdKey -Name "DelegateExecute" -Value "" -Force
             
             # Set Default to desk.cpl
             Set-ItemProperty -Path $CmdKey -Name "(default)" -Value "rundll32.exe shell32.dll,Control_RunDLL desk.cpl" -Force
             Log-Msg "✅ FORCED DelegateExecute to Empty."
        } else {
             Log-Msg "⚠️ Command Key missing! Import might have failed."
        }
    }

    Start-Process "explorer.exe"
    [System.Windows.Forms.MessageBox]::Show("Installation Complete!", "Success", "OK", "Information")
}

Function Start-Restore {
    $SelectedBackup = $cmbBackups.SelectedItem
    if ([string]::IsNullOrWhiteSpace($SelectedBackup)) { Log-Msg "Select a backup."; return }
    $BackupPath = Join-Path $BackupRoot $SelectedBackup
    Log-Msg "--- RESTORING FROM: $SelectedBackup ---"
    
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    $Archs = @{ "System32" = $RealSys32; "SysWOW64" = $RealSys64 }
    
    foreach ($ArchName in $Archs.Keys) {
        $SysPath = $Archs[$ArchName]
        $ArchBackupDir = Join-Path $BackupPath $ArchName
        $BasePathLen = $ArchBackupDir.Length; if (-not $ArchBackupDir.EndsWith("\")) { $BasePathLen++ }

        if (Test-Path $ArchBackupDir) {
            $FilesToRestore = Get-ChildItem -Path $ArchBackupDir -Recurse -File
            foreach ($File in $FilesToRestore) {
                if ($File.FullName.Length -gt $BasePathLen) {
                    $RelativePath = $File.FullName.Substring($BasePathLen)
                    $DestinationPath = Join-Path $SysPath $RelativePath
                    try {
                        Copy-Item -Path $File.FullName -Destination $DestinationPath -Force -ErrorAction Stop
                        Log-Msg "Restored: $ArchName\$RelativePath"
                    } catch { Log-Msg "❌ FAILED: $DestinationPath" }
                }
            }
        }
    }
    
    # Restore Registry
    Run-RegImport (Join-Path $BackupPath "Target_CLSID_HKLM.reg")
    Run-RegImport (Join-Path $BackupPath "Target_CLSID_HKCR.reg")
    Run-RegImport (Join-Path $BackupPath "Target_NameSpace.reg")
    
    Start-Process "explorer.exe"
    [System.Windows.Forms.MessageBox]::Show("Restore Complete.", "Restored", "OK", "Information")
}

Function Refresh-Backups {
    $cmbBackups.Items.Clear()
    if (Test-Path $BackupRoot) { $Dirs = Get-ChildItem -Path $BackupRoot -Directory | Sort-Object CreationTime -Descending; foreach ($Dir in $Dirs) { $cmbBackups.Items.Add($Dir.Name) } }
    if ($cmbBackups.Items.Count -gt 0) { $cmbBackups.SelectedIndex = 0 }
}
Function Browse-Folder { $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; $FolderBrowser.SelectedPath = $ScriptDir; if ($FolderBrowser.ShowDialog() -eq "OK") { $txtSource.Text = $FolderBrowser.SelectedPath } }

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Aero Resurrector V25 (SYNTAX FIXED)"
$Form.Size = "550,700"
$Form.StartPosition = "CenterScreen"
$Form.BackColor = "#F0F0F0"
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$grpSrc = New-Object System.Windows.Forms.GroupBox; $grpSrc.Text = "1. Harvest Files (Donor PC)"; $grpSrc.Location = "10,10"; $grpSrc.Size = "515,80"; $Form.Controls.Add($grpSrc)
$txtSource = New-Object System.Windows.Forms.TextBox; $txtSource.Location = "10,25"; $txtSource.Size = "410,25"; $txtSource.Text = (Join-Path $ScriptDir "Source"); $grpSrc.Controls.Add($txtSource)
$btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Text = "..."; $btnBrowse.Location = "430,24"; $btnBrowse.Size = "75,25"; $btnBrowse.Add_Click({ Browse-Folder }); $grpSrc.Controls.Add($btnBrowse)
$btnHarvest = New-Object System.Windows.Forms.Button; $btnHarvest.Text = "Harvest Files & Registry from THIS PC"; $btnHarvest.Location = "10,50"; $btnHarvest.Size = "495,25"; $btnHarvest.BackColor = "LightBlue"; $btnHarvest.Add_Click({ Start-Harvest }); $grpSrc.Controls.Add($btnHarvest)

$grpInst = New-Object System.Windows.Forms.GroupBox; $grpInst.Text = "2. Installation (Target PC)"; $grpInst.Location = "10,100"; $grpInst.Size = "515,120"; $Form.Controls.Add($grpInst)
$btnTargetBackup = New-Object System.Windows.Forms.Button; $btnTargetBackup.Text = "⚠️ BACKUP TARGET SYSTEM (Do this first!)"; $btnTargetBackup.Location = "10,20"; $btnTargetBackup.Size = "495,30"; $btnTargetBackup.BackColor = "Gold"; $btnTargetBackup.Add_Click({ Start-Backup }); $grpInst.Controls.Add($btnTargetBackup)
$chkReg = New-Object System.Windows.Forms.CheckBox; $chkReg.Text = "Import Registry & FORCE Legacy Behavior"; $chkReg.Checked = $true; $chkReg.Location = "10,55"; $chkReg.AutoSize = $true; $grpInst.Controls.Add($chkReg)
$btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "INSTALL FILES & IMPORT REGISTRY"; $btnInstall.Location = "10,80"; $btnInstall.Size = "495,30"; $btnInstall.BackColor = "LightGreen"; $btnInstall.Add_Click({ Start-Install }); $grpInst.Controls.Add($btnInstall)

$grpRest = New-Object System.Windows.Forms.GroupBox; $grpRest.Text = "3. Emergency Restore"; $grpRest.Location = "10,230"; $grpRest.Size = "515,80"; $Form.Controls.Add($grpRest)
$lblRest = New-Object System.Windows.Forms.Label; $lblRest.Text = "Select Backup:"; $lblRest.Location = "10,25"; $lblRest.AutoSize = $true; $grpRest.Controls.Add($lblRest)
$cmbBackups = New-Object System.Windows.Forms.ComboBox; $cmbBackups.Location = "100,22"; $cmbBackups.Size = "300,25"; $grpRest.Controls.Add($cmbBackups)
$btnRestore = New-Object System.Windows.Forms.Button; $btnRestore.Text = "RESTORE"; $btnRestore.Location = "410,20"; $btnRestore.Size = "95,25"; $btnRestore.BackColor = "LightSalmon"; $btnRestore.Add_Click({ Start-Restore }); $grpRest.Controls.Add($btnRestore)
$btnRefresh = New-Object System.Windows.Forms.Button; $btnRefresh.Text = "↻"; $btnRefresh.Location = "410,50"; $btnRefresh.Size = "95,20"; $btnRefresh.Add_Click({ Refresh-Backups }); $grpRest.Controls.Add($btnRefresh)

$txtLog = New-Object System.Windows.Forms.TextBox; $txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.Location = "10,320"; $txtLog.Size = "515,330"; $Form.Controls.Add($txtLog)

Refresh-Backups
[void]$Form.ShowDialog()
