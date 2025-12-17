<#
.SYNOPSIS
    Advanced ADB & Fastboot GUI Tool - A comprehensive utility for managing Android devices.
.DESCRIPTION
    This PowerShell script provides a rich graphical user interface for interacting with devices via ADB (Android Debug Bridge) and Fastboot.
    It features a two-panel layout with a custom dark theme, with device info/reboot controls on the left, and a tabbed interface for all other tools on the right.
    The tool can automatically detect and download the required platform-tools if they are not found.
.NOTES
    ADB & Fastboot GUI v1.6 - Created by: Zachary Whiteman & Google Gemini AI.
    Date: 7/15/2025 - 4:34 AM
    Requires PowerShell 5.1 or higher (Tested with PowerShell 7).
    Run with an active internet connection for the initial setup to download necessary tools.
#>

# ---[ Initial Setup & Assembly Loading ]---
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName Microsoft.VisualBasic
}
catch {
    Write-Warning "Failed to load required .NET Assemblies. Please ensure you are running on a Windows system with .NET Framework installed."
    Read-Host "Press Enter to exit."
    exit
}

# ---[ ENABLE VISUAL STYLES FOR NATIVE LOOK & FEEL ]---
# This ensures standard dialogs and controls are themed correctly by the OS.
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---[ Global Variables & Configuration ]---
$script:platformToolsPath = Join-Path $PSScriptRoot "platform-tools"
$script:adbPath = Join-Path $script:platformToolsPath "adb.exe"
$script:fastbootPath = Join-Path $script:platformToolsPath "fastboot.exe"
$script:commandsFilePath = Join-Path $PSScriptRoot "quick_commands.json"
$script:desktopPath = [System.Environment]::GetFolderPath('Desktop')
$script:deviceStatus = "Disconnected"
$script:deviceSerial = "N/A"
$script:quickCommands = New-Object System.Collections.Generic.List[psobject]

# ---[ Theme & Styling ]---
$theme = @{
    Background = [System.Drawing.Color]::FromArgb(255, 28, 28, 30)
    ControlBackground = [System.Drawing.Color]::FromArgb(255, 45, 45, 48)
    ControlDarker = [System.Drawing.Color]::FromArgb(255, 60, 60, 63)
    Foreground = [System.Drawing.Color]::FromArgb(255, 220, 220, 220)
    ForegroundDim = [System.Drawing.Color]::FromArgb(255, 150, 150, 150)
    Accent = [System.Drawing.Color]::FromArgb(255, 0, 122, 204)
    AccentBright = [System.Drawing.Color]::FromArgb(255, 28, 151, 234)
    Border = [System.Drawing.Color]::FromArgb(255, 80, 80, 80)
    Red = [System.Drawing.Color]::FromArgb(255, 204, 64, 64)
    Green = [System.Drawing.Color]::FromArgb(255, 100, 180, 100)
    Blue = [System.Drawing.Color]::FromArgb(255, 80, 160, 220)
    Orange = [System.Drawing.Color]::FromArgb(255, 218, 140, 60)
}
$fontRegular = New-Object System.Drawing.Font("Segoe UI", 9)
$fontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# ---[ Core Functions ]---

Function Write-Log {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = $theme.Foreground,
        [bool]$IsBold = $false
    )
    if ($script:outputBox) {
        $script:outputBox.SelectionStart = $script:outputBox.TextLength
        $script:outputBox.SelectionLength = 0
        $script:outputBox.SelectionColor = $Color
        $script:outputBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 9, ($IsBold ? [System.Drawing.FontStyle]::Bold : [System.Drawing.FontStyle]::Regular))
        $script:outputBox.AppendText("$(Get-Date -Format 'HH:mm:ss') > $Message`n")
        $script:outputBox.ScrollToCaret()
    }
}

Function Run-Command {
    param(
        [string]$Executable,
        [string]$Arguments,
        [bool]$ShowErrorDialog = $true,
        [bool]$LogOutput = $true
    )
    if ($LogOutput) { Write-Log "Executing: $($Executable.Split('\')[-1]) $Arguments" -Color $theme.ForegroundDim }
    try {
        $fullCommand = "& `"$Executable`" $Arguments"
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -Command `"$fullCommand`"" -PassThru -Wait -NoNewWindow -RedirectStandardOutput "stdout.tmp" -RedirectStandardError "stderr.tmp"
        
        $output = Get-Content "stdout.tmp" -Raw -ErrorAction SilentlyContinue
        $errorOutput = Get-Content "stderr.tmp" -Raw -ErrorAction SilentlyContinue
        Remove-Item "stdout.tmp", "stderr.tmp" -ErrorAction SilentlyContinue

        if ($errorOutput) {
            if ($LogOutput) { Write-Log "Error: $errorOutput" -Color $theme.Red }
            if ($ShowErrorDialog) { [System.Windows.Forms.MessageBox]::Show($errorOutput, "Command Error", "OK", "Error") }
        }
        if ($output -and $LogOutput) { Write-Log "Output: $output" -Color $theme.Blue }
        return $output
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($LogOutput) { Write-Log "Execution failed: $errorMessage" -Color $theme.Red }
        if ($ShowErrorDialog) { [System.Windows.Forms.MessageBox]::Show($errorMessage, "Execution Failed", "OK", "Error") }
        return $null
    }
}

Function Check-And-Install-Tools {
    if (-not (Test-Path $script:adbPath) -or -not (Test-Path $script:fastbootPath)) {
        Write-Log "Platform-tools not found." -Color $theme.Orange
        $result = [System.Windows.Forms.MessageBox]::Show("ADB/Fastboot not found. Download now?", "Setup Required", "YesNo", "Question")
        if ($result -eq "Yes") {
            $downloadUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
            $zipPath = Join-Path $PSScriptRoot "platform-tools.zip"
            Write-Log "Downloading..."
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($downloadUrl, $zipPath)
                Write-Log "Download complete. Extracting..."
                [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $PSScriptRoot)
                Write-Log "Extraction complete." -Color $theme.Green -IsBold $true
                Remove-Item $zipPath
            } catch { Write-Log "Download/Extraction failed: $($_.Exception.Message)" -Color $theme.Red; return $false }
        } else { return $false }
    }
    Write-Log "Platform-tools found." -Color $theme.Green
    return $true
}

Function Update-DeviceInfoDisplay {
    if ($script:deviceStatus -eq "ADB Mode") {
        $model = (Run-Command $script:adbPath "-s $script:deviceSerial shell getprop ro.product.model" -LogOutput $false).Trim()
        $androidVersion = (Run-Command $script:adbPath "-s $script:deviceSerial shell getprop ro.build.version.release" -LogOutput $false).Trim()
        $sdkVersion = (Run-Command $script:adbPath "-s $script:deviceSerial shell getprop ro.build.version.sdk" -LogOutput $false).Trim()
        $batteryOutput = (Run-Command $script:adbPath "-s $script:deviceSerial shell dumpsys battery" -LogOutput $false)
        $batteryLevel = ($batteryOutput | Select-String 'level:' | ForEach-Object { $_.ToString().Split(':')[1].Trim() })
        
        $script:deviceInfoLabel.Text = "Device Detected in ADB mode:`n`n" +
                                     "  Model: $model`n" +
                                     "  Android Version: $androidVersion (API $sdkVersion)`n" +
                                     "  Battery Level: $batteryLevel%"
    } elseif ($script:deviceStatus -eq "Fastboot Mode") {
        $script:deviceInfoLabel.Text = "Device Detected in Fastboot mode.`n`nReady for advanced flashing operations."
    } else {
        $script:deviceInfoLabel.Text = "No device connected.`n`nPlease connect a device and ensure USB Debugging is enabled, then click 'Refresh Device Status'."
    }
}

Function Refresh-Device-Status {
    $script:mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $script:statusLabel.Text = "Status: Checking..."; $script:statusLabel.ForeColor = $theme.Orange
    [System.Windows.Forms.Application]::DoEvents()

    $fastbootOutput = Run-Command $script:fastbootPath "devices" -ShowErrorDialog $false -LogOutput $false
    if ($fastbootOutput -and $fastbootOutput.Trim() -ne "") {
        $script:deviceSerial = $fastbootOutput.Split([char]9)[0]
        $script:deviceStatus = "Fastboot Mode"
        $script:statusLabel.Text = "Status: Connected (Fastboot)"; $script:statusLabel.ForeColor = $theme.Blue
        $script:serialLabel.Text = "Serial: $script:deviceSerial"
        Write-Log "Device detected in Fastboot mode: $script:deviceSerial" -Color $theme.Blue
    } else {
        Run-Command $script:adbPath "start-server" -ShowErrorDialog $false -LogOutput $false
        $adbOutput = Run-Command $script:adbPath "devices" -ShowErrorDialog $false -LogOutput $false
        $deviceLine = $adbOutput -split '\r?\n' | Where-Object { $_ -match '\tdevice$' }
        if ($deviceLine) {
            $script:deviceSerial = $deviceLine.Split([char]9)[0]
            $script:deviceStatus = "ADB Mode"
            $model = (Run-Command $script:adbPath "-s $script:deviceSerial shell getprop ro.product.model" -ShowErrorDialog $false -LogOutput $false).Trim()
            $script:statusLabel.Text = "Status: Connected (ADB)"; $script:statusLabel.ForeColor = $theme.Green
            $script:serialLabel.Text = "Serial: $script:deviceSerial ($model)"
            Write-Log "Device detected in ADB mode: $script:deviceSerial ($model)" -Color $theme.Green
        } else {
            $script:deviceStatus = "Disconnected"
            $script:deviceSerial = "N/A"
            $script:statusLabel.Text = "Status: Disconnected"; $script:statusLabel.ForeColor = $theme.Red
            $script:serialLabel.Text = "Serial: N/A"
            Write-Log "No device detected." -Color $theme.Red
        }
    }
    Update-DeviceInfoDisplay
    $script:mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
}

# ---[ GUI Construction ]---

$script:mainForm = New-Object System.Windows.Forms.Form
$script:mainForm.Text = "ADB & Fastboot GUI Tool"
$script:mainForm.Size = New-Object System.Drawing.Size(950, 750)
$script:mainForm.MinimumSize = New-Object System.Drawing.Size(850, 650)
$script:mainForm.StartPosition = "CenterScreen"
$script:mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
$script:mainForm.BackColor = $theme.Background

# --- Main Layout Panel ---
$mainLayout = New-Object System.Windows.Forms.TableLayoutPanel; $mainLayout.Dock = "Fill"; $mainLayout.ColumnCount = 2; $mainLayout.RowCount = 1
$mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 35)))
$mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 65)))
$script:mainForm.Controls.Add($mainLayout)

# --- Left Column: Device Info & Reboot ---
$leftGroup = New-Object System.Windows.Forms.GroupBox; $leftGroup.Text = "Device Connection & Reboot"; $leftGroup.Dock = "Fill"; $leftGroup.Padding = New-Object System.Windows.Forms.Padding(10)
$leftGroup.ForeColor = $theme.Foreground; $leftGroup.Font = $fontBold
$mainLayout.Controls.Add($leftGroup, 0, 0)
$leftTable = New-Object System.Windows.Forms.TableLayoutPanel; $leftTable.Dock = "Fill"; $leftTable.ColumnCount = 2; $leftTable.RowCount = 4
$leftTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
for ($i = 0; $i -lt 3; $i++) { $leftTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) }
$leftGroup.Controls.Add($leftTable)

$script:deviceInfoLabel = New-Object System.Windows.Forms.Label; $script:deviceInfoLabel.Dock = "Fill"; $script:deviceInfoLabel.Font = $fontBold; $script:deviceInfoLabel.ForeColor = $theme.Foreground; $script:deviceInfoLabel.Padding = New-Object System.Windows.Forms.Padding(5)
$leftTable.SetColumnSpan($script:deviceInfoLabel, 2)
$leftTable.Controls.Add($script:deviceInfoLabel, 0, 0)

# --- Right Column: Tabbed Tools ---
$rightGroup = New-Object System.Windows.Forms.GroupBox; $rightGroup.Text = "Tools & Management"; $rightGroup.Dock = "Fill"; $rightGroup.Padding = New-Object System.Windows.Forms.Padding(10)
$rightGroup.ForeColor = $theme.Foreground; $rightGroup.Font = $fontBold
$mainLayout.Controls.Add($rightGroup, 1, 0)

$tabControl = New-Object System.Windows.Forms.TabControl; $tabControl.Dock = "Fill"; $tabControl.Appearance = "Normal"; $tabControl.DrawMode = "OwnerDrawFixed"
$tabControl.add_DrawItem({
    param($sender, $e)
    $tabPage = $sender.TabPages[$e.Index]
    $tabRect = $e.Bounds
    
    # CRASH FIX: Create a RectangleF object for the DrawString method to avoid a type casting error in PowerShell.
    $rectF = New-Object System.Drawing.RectangleF($tabRect.X, $tabRect.Y, $tabRect.Width, $tabRect.Height)

    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush $theme.Background), $e.Bounds)
    $textBrush = if ($e.State -band [System.Windows.Forms.DrawItemState]::Selected) { (New-Object System.Drawing.SolidBrush $theme.AccentBright) } else { (New-Object System.Drawing.SolidBrush $theme.Foreground) }
    $stringFormat = New-Object System.Drawing.StringFormat; $stringFormat.Alignment = "Center"; $stringFormat.LineAlignment = "Center"
    
    # Use the new RectangleF object here.
    $e.Graphics.DrawString($tabPage.Text, $fontRegular, $textBrush, $rectF, $stringFormat)
    $textBrush.Dispose(); $stringFormat.Dispose()
})
$rightGroup.Controls.Add($tabControl)

# --- Function to Style Buttons ---
Function Style-Button {
    param($button)
    $button.FlatStyle = "Flat"
    $button.BackColor = $theme.ControlBackground
    $button.ForeColor = $theme.Foreground
    $button.Font = $fontRegular
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.BorderColor = $theme.Border
    $button.FlatAppearance.MouseOverBackColor = $theme.ControlDarker
    $button.FlatAppearance.MouseDownBackColor = $theme.Accent
}

# --- Add Reboot Buttons to Left Panel ---
$rebootBootloaderButton = New-Object System.Windows.Forms.Button; $rebootBootloaderButton.Text = "Reboot to Bootloader"; $rebootBootloaderButton.Dock = "Fill"; $rebootBootloaderButton.add_Click({ Run-Command $script:adbPath "-s $script:deviceSerial reboot bootloader" })
$rebootRecoveryButton = New-Object System.Windows.Forms.Button; $rebootRecoveryButton.Text = "Reboot to Recovery"; $rebootRecoveryButton.Dock = "Fill"; $rebootRecoveryButton.add_Click({ Run-Command $script:adbPath "-s $script:deviceSerial reboot recovery" })
$rebootFastbootButton = New-Object System.Windows.Forms.Button; $rebootFastbootButton.Text = "Reboot Device (Fastboot)"; $rebootFastbootButton.Dock = "Fill"; $rebootFastbootButton.add_Click({ Run-Command $script:fastbootPath "-s $script:deviceSerial reboot" })
$rebootAdbButton = New-Object System.Windows.Forms.Button; $rebootAdbButton.Text = "Reboot Device (ADB)"; $rebootAdbButton.Dock = "Fill"; $rebootAdbButton.add_Click({ Run-Command $script:adbPath "-s $script:deviceSerial reboot" })
$refreshButton = New-Object System.Windows.Forms.Button; $refreshButton.Text = "Refresh Device Status"; $refreshButton.Dock = "Fill"; $refreshButton.add_Click({ Refresh-Device-Status })
$leftTable.SetColumnSpan($refreshButton, 2)
$leftTable.Controls.Add($rebootBootloaderButton, 0, 1); $leftTable.Controls.Add($rebootRecoveryButton, 1, 1)
$leftTable.Controls.Add($rebootFastbootButton, 0, 2); $leftTable.Controls.Add($rebootAdbButton, 1, 2)
$leftTable.Controls.Add($refreshButton, 0, 3)
@($rebootBootloaderButton, $rebootRecoveryButton, $rebootFastbootButton, $rebootAdbButton, $refreshButton) | ForEach-Object { Style-Button $_ }

# --- Tab 1: App Management ---
$appMgmtTab = New-Object System.Windows.Forms.TabPage("App Management"); $appMgmtTab.BackColor = $theme.Background
$tabControl.TabPages.Add($appMgmtTab)
# ... (Content for this tab)

# --- Tab 2: Device Utilities ---
$utilsTab = New-Object System.Windows.Forms.TabPage("Device Utilities"); $utilsTab.BackColor = $theme.Background
$tabControl.TabPages.Add($utilsTab)
# ... (Content for this tab)

# --- Tab 3: Power User (Quick Commands) ---
$powerTab = New-Object System.Windows.Forms.TabPage("Power User"); $powerTab.BackColor = $theme.Background
$tabControl.TabPages.Add($powerTab)
# ... (Content for this tab)

# --- Tab 4: Advanced ---
$advancedTab = New-Object System.Windows.Forms.TabPage("Advanced"); $advancedTab.BackColor = $theme.Background
$tabControl.TabPages.Add($advancedTab)
# ... (Content for this tab)

# --- Populate App Management Tab ---
$appMgmtTable = New-Object System.Windows.Forms.TableLayoutPanel; $appMgmtTable.Dock = "Fill"; $appMgmtTable.ColumnCount = 2; $appMgmtTable.RowCount = 3
$appMgmtTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40)))
$appMgmtTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$appMgmtTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40)))
$appMgmtTab.Controls.Add($appMgmtTable)
$installApkButton = New-Object System.Windows.Forms.Button; $installApkButton.Text = "Install APK..."; $installApkButton.Dock = "Fill"
$installApkButton.add_Click({ $fileDialog = New-Object System.Windows.Forms.OpenFileDialog; $fileDialog.Filter = "APK Files (*.apk)|*.apk"; if ($fileDialog.ShowDialog() -eq "OK") { Run-Command $script:adbPath "-s $script:deviceSerial install -r `"$($fileDialog.FileName)`"" } })
$appMgmtTable.SetColumnSpan($installApkButton, 2); $appMgmtTable.Controls.Add($installApkButton, 0, 0)
$script:packageListView = New-Object System.Windows.Forms.ListView; $script:packageListView.View = "Details"; $script:packageListView.FullRowSelect = $true; $script:packageListView.Dock = "Fill"
$script:packageListView.BackColor = $theme.ControlBackground; $script:packageListView.ForeColor = $theme.Foreground; $script:packageListView.Font = $fontRegular; $script:packageListView.BorderStyle = "None"
$script:packageListView.Columns.Add("Package Name", 250); $script:packageListView.Columns.Add("APK Path", 350)
$appMgmtTable.SetColumnSpan($script:packageListView, 2); $appMgmtTable.Controls.Add($script:packageListView, 0, 1)
$listPackagesButton = New-Object System.Windows.Forms.Button; $listPackagesButton.Text = "List All Packages"; $listPackagesButton.Dock = "Fill"
$listPackagesButton.add_Click({
    $script:packageListView.Items.Clear(); Write-Log "Fetching package list..."
    $packages = Run-Command $script:adbPath "-s $script:deviceSerial shell pm list packages -f"
    if ($packages) { foreach ($line in ($packages -split '\r?\n')) { if ($line -match 'package:(.*)=(.*)') { $item = New-Object System.Windows.Forms.ListViewItem($matches[2].Trim()); $item.SubItems.Add($matches[1].Trim()); $script:packageListView.Items.Add($item) | Out-Null } } }
    Write-Log "Package list updated." -Color $theme.Green
})
$uninstallPackageButton = New-Object System.Windows.Forms.Button; $uninstallPackageButton.Text = "Uninstall Selected"; $uninstallPackageButton.Dock = "Fill"
$uninstallPackageButton.add_Click({ if ($script:packageListView.SelectedItems.Count -gt 0) { $pkg = $script:packageListView.SelectedItems[0].Text; if ([System.Windows.Forms.MessageBox]::Show("Uninstall '$pkg'?", "Confirm", "YesNo", "Warning") -eq "Yes") { Run-Command $script:adbPath "-s $script:deviceSerial uninstall $pkg"; $listPackagesButton.PerformClick() } } else { [void][System.Windows.Forms.MessageBox]::Show("Select a package first.") } })
$appMgmtTable.Controls.Add($listPackagesButton, 0, 2); $appMgmtTable.Controls.Add($uninstallPackageButton, 1, 2)
@($installApkButton, $listPackagesButton, $uninstallPackageButton) | ForEach-Object { Style-Button $_ }

# --- Populate Device Utilities Tab ---
$utilsTable = New-Object System.Windows.Forms.TableLayoutPanel; $utilsTable.Dock = "Fill"; $utilsTable.ColumnCount = 3; $utilsTable.RowCount = 1
$utilsTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33)))
$utilsTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33)))
$utilsTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33)))
$utilsTab.Controls.Add($utilsTable)
$infoGroup = New-Object System.Windows.Forms.GroupBox; $infoGroup.Text = "Device Info"; $infoGroup.Dock = "Fill"; $infoGroup.Padding = New-Object System.Windows.Forms.Padding(10); $infoGroup.ForeColor = $theme.Foreground; $infoGroup.Font = $fontBold; $utilsTable.Controls.Add($infoGroup, 0, 0)
$appUtilGroup = New-Object System.Windows.Forms.GroupBox; $appUtilGroup.Text = "App Utilities"; $appUtilGroup.Dock = "Fill"; $appUtilGroup.Padding = New-Object System.Windows.Forms.Padding(10); $appUtilGroup.ForeColor = $theme.Foreground; $appUtilGroup.Font = $fontBold; $utilsTable.Controls.Add($appUtilGroup, 1, 0)
$fileGroup = New-Object System.Windows.Forms.GroupBox; $fileGroup.Text = "Media & File"; $fileGroup.Dock = "Fill"; $fileGroup.Padding = New-Object System.Windows.Forms.Padding(10); $fileGroup.ForeColor = $theme.Foreground; $fileGroup.Font = $fontBold; $utilsTable.Controls.Add($fileGroup, 2, 0)
$infoFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $infoFlow.Dock = "Fill"; $infoFlow.FlowDirection = "TopDown"; $infoGroup.Controls.Add($infoFlow)
$appUtilFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $appUtilFlow.Dock = "Fill"; $appUtilFlow.FlowDirection = "TopDown"; $appUtilGroup.Controls.Add($appUtilFlow)
$fileFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $fileFlow.Dock = "Fill"; $fileFlow.FlowDirection = "TopDown"; $fileGroup.Controls.Add($fileFlow)
$infoButtons = @(
    (New-Object System.Windows.Forms.Button -Property @{Text="Get Battery Status"; AutoSize=$true; Tag="shell dumpsys battery"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Get Screen Resolution"; AutoSize=$true; Tag="shell wm size"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Get IP Address"; AutoSize=$true; Tag="shell ip addr show wlan0"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="List Device Features"; AutoSize=$true; Tag="shell pm list features"})
)
$infoButtons | ForEach-Object { $btn = $_; $btn.add_Click({ Run-Command $script:adbPath "-s $script:deviceSerial $($btn.Tag)" }); $infoFlow.Controls.Add($btn); Style-Button $btn }
$appUtilButtons = @(
    (New-Object System.Windows.Forms.Button -Property @{Text="Force Stop App..."; AutoSize=$true; Tag="force-stop"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Clear App Data..."; AutoSize=$true; Tag="clear-data"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Grant Permission..."; AutoSize=$true; Tag="grant"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Revoke Permission..."; AutoSize=$true; Tag="revoke"})
)
$appUtilButtons | ForEach-Object { $btn = $_; $btn.add_Click({ # Complex logic here
    if ($_.Tag -eq 'grant' -or $_.Tag -eq 'revoke') {
        $pkg = [Microsoft.VisualBasic.Interaction]::InputBox("Package name:", $_.Text); if (!$pkg) { return }; $perm = [Microsoft.VisualBasic.Interaction]::InputBox("Permission:", $_.Text); if ($perm) { Run-Command $script:adbPath "-s $script:deviceSerial shell pm $($_.Tag) $pkg $perm" }
    } else {
        $pkg = [Microsoft.VisualBasic.Interaction]::InputBox("Package name:", $_.Text); if ($pkg) { Run-Command $script:adbPath "-s $script:deviceSerial shell am $($_.Tag) $pkg" }
    }
}); $appUtilFlow.Controls.Add($btn); Style-Button $btn }
$fileButtons = @(
    (New-Object System.Windows.Forms.Button -Property @{Text="Take Screenshot"; AutoSize=$true; Tag="screenshot"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Record Screen (15s)"; AutoSize=$true; Tag="record"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Push File..."; AutoSize=$true; Tag="push"}),
    (New-Object System.Windows.Forms.Button -Property @{Text="Pull File..."; AutoSize=$true; Tag="pull"})
)
$fileButtons | ForEach-Object { $btn = $_; $btn.add_Click({ # Complex logic here
    switch ($_.Tag) {
        "screenshot" { $remotePath = "/sdcard/screenshot.png"; $localPath = Join-Path $script:desktopPath "screenshot_$(Get-Date -Format 'yyyyMMddHHmmss').png"; Run-Command $script:adbPath "-s $script:deviceSerial shell screencap -p `"$remotePath`""; Run-Command $script:adbPath "-s $script:deviceSerial pull `"$remotePath`" `"$localPath`""; Run-Command $script:adbPath "-s $script:deviceSerial shell rm `"$remotePath`""; Write-Log "Screenshot saved to Desktop." -Color $theme.Green }
        "record" { $remotePath = "/sdcard/record.mp4"; $localPath = Join-Path $script:desktopPath "record_$(Get-Date -Format 'yyyyMMddHHmmss').mp4"; Write-Log "Recording..."; Run-Command $script:adbPath "-s $script:deviceSerial shell screenrecord --time-limit 15 `"$remotePath`""; Run-Command $script:adbPath "-s $script:deviceSerial pull `"$remotePath`" `"$localPath`""; Run-Command $script:adbPath "-s $script:deviceSerial shell rm `"$remotePath`""; Write-Log "Recording saved to Desktop." -Color $theme.Green }
        "push" { $openDialog = New-Object System.Windows.Forms.OpenFileDialog; if ($openDialog.ShowDialog() -eq "OK") { $remoteDest = [Microsoft.VisualBasic.Interaction]::InputBox("Destination:", "Push", "/sdcard/Download/"); if ($remoteDest) { Run-Command $script:adbPath "-s $script:deviceSerial push `"$($openDialog.FileName)`" `"$remoteDest`"" } } }
        "pull" { $remoteFile = [Microsoft.VisualBasic.Interaction]::InputBox("Full path on device:", "Pull"); if ($remoteFile) { $saveDialog = New-Object System.Windows.Forms.SaveFileDialog; $saveDialog.FileName = $remoteFile.Split('/')[-1]; if ($saveDialog.ShowDialog() -eq "OK") { Run-Command $script:adbPath "-s $script:deviceSerial pull `"$remoteFile`" `"$($saveDialog.FileName)`"" } } }
    }
}); $fileFlow.Controls.Add($btn); Style-Button $btn }

# --- Populate Power User Tab ---
$powerGroup = New-Object System.Windows.Forms.GroupBox; $powerGroup.Text = "Quick Commands"; $powerGroup.Dock = "Fill"; $powerGroup.Padding = New-Object System.Windows.Forms.Padding(10); $powerGroup.ForeColor = $theme.Foreground; $powerGroup.Font = $fontBold; $powerTab.Controls.Add($powerGroup)
$powerTable = New-Object System.Windows.Forms.TableLayoutPanel; $powerTable.Dock = "Fill"; $powerTable.ColumnCount = 2; $powerTable.RowCount = 1
$powerTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$powerTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::AutoSize)))
$powerGroup.Controls.Add($powerTable)
$script:commandsListBox = New-Object System.Windows.Forms.ListBox; $script:commandsListBox.Dock = "Fill"; $script:commandsListBox.BackColor = $theme.ControlBackground; $script:commandsListBox.ForeColor = $theme.Foreground; $script:commandsListBox.Font = $fontRegular; $script:commandsListBox.BorderStyle = "None"
$powerTable.Controls.Add($script:commandsListBox, 0, 0)
$commandButtonsFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $commandButtonsFlow.Dock = "Fill"; $commandButtonsFlow.FlowDirection = "TopDown"; $commandButtonsFlow.AutoSize = $true; $powerTable.Controls.Add($commandButtonsFlow, 1, 0)
$runQuickCommandButton = New-Object System.Windows.Forms.Button; $runQuickCommandButton.Text = "Run"; $runQuickCommandButton.AutoSize = $true
$addQuickCommandButton = New-Object System.Windows.Forms.Button; $addQuickCommandButton.Text = "Add New..."; $addQuickCommandButton.AutoSize = $true
$editQuickCommandButton = New-Object System.Windows.Forms.Button; $editQuickCommandButton.Text = "Edit..."; $editQuickCommandButton.AutoSize = $true
$removeQuickCommandButton = New-Object System.Windows.Forms.Button; $removeQuickCommandButton.Text = "Remove"; $removeQuickCommandButton.AutoSize = $true
$commandButtonsFlow.Controls.AddRange(@($runQuickCommandButton, $addQuickCommandButton, $editQuickCommandButton, $removeQuickCommandButton))
@($runQuickCommandButton, $addQuickCommandButton, $editQuickCommandButton, $removeQuickCommandButton) | ForEach-Object { Style-Button $_ }
$runQuickCommandButton.add_Click({ $idx = $script:commandsListBox.SelectedIndex; if ($idx -ge 0) { $cmd = $script:quickCommands[$idx]; $exe = if ($cmd.Type -eq "Fastboot") { $script:fastbootPath } else { $script:adbPath }; Run-Command $exe "-s $script:deviceSerial $($cmd.Command)" } })
$addQuickCommandButton.add_Click({ $new = Show-CommandDialog -Title "Add New"; if ($new) { $script:quickCommands.Add($new); Save-QuickCommands; Load-QuickCommands } })
$editQuickCommandButton.add_Click({ $idx = $script:commandsListBox.SelectedIndex; if ($idx -ge 0) { $upd = Show-CommandDialog -Title "Edit" -ExistingCommand $script:quickCommands[$idx]; if ($upd) { $script:quickCommands[$idx] = $upd; Save-QuickCommands; Load-QuickCommands } } })
$removeQuickCommandButton.add_Click({ $idx = $script:commandsListBox.SelectedIndex; if ($idx -ge 0) { if ([System.Windows.Forms.MessageBox]::Show("Remove '$($script:commandsListBox.SelectedItem)'?", "Confirm", "YesNo", "Warning") -eq "Yes") { $script:quickCommands.RemoveAt($idx); Save-QuickCommands; Load-QuickCommands } } })

# --- Populate Advanced Tab ---
$flashGroup = New-Object System.Windows.Forms.GroupBox; $flashGroup.Text = "Fastboot & Recovery Operations"; $flashGroup.Dock = "Fill"; $flashGroup.Padding = New-Object System.Windows.Forms.Padding(10); $flashGroup.ForeColor = $theme.Foreground; $flashGroup.Font = $fontBold; $advancedTab.Controls.Add($flashGroup)
$flashFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $flashFlow.Dock = "Fill"; $flashFlow.FlowDirection = "TopDown"; $flashGroup.Controls.Add($flashFlow)
$flashWarningLabel = New-Object System.Windows.Forms.Label; $flashWarningLabel.Text = "WARNING: Incorrect operations can permanently damage your device."; $flashWarningLabel.ForeColor = $theme.Red; $flashWarningLabel.Font = $fontBold; $flashWarningLabel.AutoSize = $true; $flashFlow.Controls.Add($flashWarningLabel)
$flashFlow.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text="Fastboot Flashing (Device must be in Bootloader/Fastboot Mode)"; AutoSize=$true; Margin = New-Object System.Windows.Forms.Padding(0,10,0,0); ForeColor=$theme.Foreground; Font=$fontRegular}))
$flashFunction = { param([string]$partition)
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog; $fileDialog.Title = "Select .img for $partition"; $fileDialog.Filter = "Image Files (*.img)|*.img|*.*|*.*"
    if ($fileDialog.ShowDialog() -eq "OK") { if ([System.Windows.Forms.MessageBox]::Show("Flash `"$($fileDialog.SafeFileName)`" to '$partition'?", "Confirm", "YesNo", "Warning") -eq "Yes") { Run-Command $script:fastbootPath "-s $script:deviceSerial flash $partition `"$($fileDialog.FileName)`"" } }
}
$flashBootButton = New-Object System.Windows.Forms.Button -Property @{Text="Flash Boot Image..."; AutoSize=$true}; $flashBootButton.add_Click({ & $flashFunction "boot" })
$flashRecoveryButton = New-Object System.Windows.Forms.Button -Property @{Text="Flash Recovery Image..."; AutoSize=$true}; $flashRecoveryButton.add_Click({ & $flashFunction "recovery" })
$flashSystemButton = New-Object System.Windows.Forms.Button -Property @{Text="Flash System Image..."; AutoSize=$true}; $flashSystemButton.add_Click({ & $flashFunction "system" })
$flashFlow.Controls.Add($flashBootButton); $flashFlow.Controls.Add($flashRecoveryButton); $flashFlow.Controls.Add($flashSystemButton)
$flashFlow.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text="ADB Sideload (Device must be in Recovery Mode)"; AutoSize=$true; Margin = New-Object System.Windows.Forms.Padding(0,20,0,0); ForeColor=$theme.Foreground; Font=$fontRegular}))
$sideloadButton = New-Object System.Windows.Forms.Button; $sideloadButton.Text = "Sideload ZIP/APK..."; $sideloadButton.AutoSize = $true
$sideloadButton.add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog; $fileDialog.Title = "Select update to sideload"; $fileDialog.Filter = "Update Files (*.zip;*.apk)|*.zip;*.apk|*.*|*.*"
    if ($fileDialog.ShowDialog() -eq "OK") { if ([System.Windows.Forms.MessageBox]::Show("Ensure device is in Recovery with 'Apply update from ADB' selected. Continue?", "Confirm", "YesNo", "Warning") -eq "Yes") { Run-Command $script:adbPath "-s $script:deviceSerial sideload `"$($fileDialog.FileName)`"" } }
})
$flashFlow.Controls.Add($sideloadButton)
@($flashBootButton, $flashRecoveryButton, $flashSystemButton, $sideloadButton) | ForEach-Object { Style-Button $_ }

# --- Status Bar & Output Box ---
$statusBar = New-Object System.Windows.Forms.StatusStrip; $statusBar.Dock = "Bottom"; $statusBar.BackColor = $theme.Background; $statusBar.ForeColor = $theme.Foreground; $statusBar.Font = $fontRegular
$script:statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel("Status: Initializing...")
$script:serialLabel = New-Object System.Windows.Forms.ToolStripStatusLabel("Serial: N/A")
$statusBar.Items.AddRange(@($script:statusLabel, $script:serialLabel))
$script:mainForm.Controls.Add($statusBar)

$script:outputBox = New-Object System.Windows.Forms.RichTextBox
$script:outputBox.Dock = "Bottom"; $script:outputBox.Height = 180; $script:outputBox.Font = New-Object System.Drawing.Font("Consolas", 9); $script:outputBox.ReadOnly = $true; $script:outputBox.BackColor = $theme.ControlBackground; $script:outputBox.ForeColor = $theme.Foreground; $script:outputBox.BorderStyle = "None"
$script:mainForm.Controls.Add($script:outputBox)

# ---[ Full Function Definitions ]---
Function Load-QuickCommands {
    $script:quickCommands.Clear()
    if (Test-Path $script:commandsFilePath) {
        try {
            $jsonContent = Get-Content $script:commandsFilePath -Raw
            $commandsFromFile = $jsonContent | ConvertFrom-Json
            if ($null -ne $commandsFromFile) {
                if ($commandsFromFile -is [psobject]) { $commandsFromFile = @($commandsFromFile) }
                foreach ($command in $commandsFromFile) { $script:quickCommands.Add($command) }
            }
        } catch { Write-Log "Error loading quick commands file." -Color $theme.Red }
    }
    if ($script:quickCommands.Count -eq 0) {
        $shizuku = [pscustomobject]@{Name="Start Shizuku Service"; Command="shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh"; Type="ADB"}
        $script:quickCommands.Add($shizuku); Save-QuickCommands
    }
    $script:commandsListBox.Items.Clear()
    foreach ($command in $script:quickCommands) { $script:commandsListBox.Items.Add($command.Name) | Out-Null }
}
Function Save-QuickCommands {
    try { $script:quickCommands | ConvertTo-Json -Depth 5 | Out-File -FilePath $script:commandsFilePath -Encoding UTF8 }
    catch { Write-Log "Failed to save quick commands." -Color $theme.Red }
}
Function Show-CommandDialog { param([string]$Title, [psobject]$ExistingCommand = $null)
    $dialog = New-Object System.Windows.Forms.Form; $dialog.Text = $Title; $dialog.Size = New-Object System.Drawing.Size(400, 250); $dialog.StartPosition = "CenterParent"; $dialog.FormBorderStyle = "FixedDialog"; $dialog.MaximizeBox = $false; $dialog.MinimizeBox = $false; $dialog.BackColor = $theme.Background
    $nameLabel = New-Object System.Windows.Forms.Label; $nameLabel.Text = "Name:"; $nameLabel.Location = New-Object System.Drawing.Point(10, 15); $nameLabel.AutoSize = $true; $nameLabel.ForeColor = $theme.Foreground; $nameLabel.Font = $fontRegular
    $nameBox = New-Object System.Windows.Forms.TextBox; $nameBox.Location = New-Object System.Drawing.Point(10, 35); $nameBox.Size = New-Object System.Drawing.Size(360, 20); $nameBox.BackColor = $theme.ControlBackground; $nameBox.ForeColor = $theme.Foreground; $nameBox.Font = $fontRegular; $nameBox.BorderStyle = "FixedSingle"
    $commandLabel = New-Object System.Windows.Forms.Label; $commandLabel.Text = "Command Arguments:"; $commandLabel.Location = New-Object System.Drawing.Point(10, 70); $commandLabel.AutoSize = $true; $commandLabel.ForeColor = $theme.Foreground; $commandLabel.Font = $fontRegular
    $commandBox = New-Object System.Windows.Forms.TextBox; $commandBox.Location = New-Object System.Drawing.Point(10, 90); $commandBox.Size = New-Object System.Drawing.Size(360, 20); $commandBox.BackColor = $theme.ControlBackground; $commandBox.ForeColor = $theme.Foreground; $commandBox.Font = $fontRegular; $commandBox.BorderStyle = "FixedSingle"
    $typeLabel = New-Object System.Windows.Forms.Label; $typeLabel.Text = "Type:"; $typeLabel.Location = New-Object System.Drawing.Point(10, 125); $typeLabel.AutoSize = $true; $typeLabel.ForeColor = $theme.Foreground; $typeLabel.Font = $fontRegular
    $typeComboBox = New-Object System.Windows.Forms.ComboBox; $typeComboBox.Location = New-Object System.Drawing.Point(10, 145); $typeComboBox.Items.AddRange(@("ADB", "Fastboot")); $typeComboBox.DropDownStyle = "DropDownList"; $typeComboBox.BackColor = $theme.ControlBackground; $typeComboBox.ForeColor = $theme.Foreground; $typeComboBox.FlatStyle = "Flat"
    $saveButton = New-Object System.Windows.Forms.Button; $saveButton.Text = "Save"; $saveButton.Location = New-Object System.Drawing.Point(210, 180); $saveButton.DialogResult = "OK"
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(290, 180); $cancelButton.DialogResult = "Cancel"
    Style-Button $saveButton; Style-Button $cancelButton
    if ($ExistingCommand) { $nameBox.Text = $ExistingCommand.Name; $commandBox.Text = $ExistingCommand.Command; $typeComboBox.SelectedItem = $ExistingCommand.Type } else { $typeComboBox.SelectedIndex = 0 }
    $dialog.Controls.AddRange(@($nameLabel, $nameBox, $commandLabel, $commandBox, $typeLabel, $typeComboBox, $saveButton, $cancelButton)); $dialog.AcceptButton = $saveButton; $dialog.CancelButton = $cancelButton
    if ($dialog.ShowDialog($script:mainForm) -eq "OK") { if (-not $nameBox.Text -or -not $commandBox.Text) { [void][System.Windows.Forms.MessageBox]::Show("Name and Command required."); return $null }; return [pscustomobject]@{Name = $nameBox.Text; Command = $commandBox.Text; Type = $typeComboBox.SelectedItem} }
    return $null
}

# ---[ Form Load & Finalization ]---
$script:mainForm.Add_Shown({
    if (-not (Check-And-Install-Tools)) { $script:mainForm.Close(); return }
    Load-QuickCommands
    Refresh-Device-Status
})

# Hide console window
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
$showWindow = Add-Type -memberDefinition $windowcode -name Win32ShowWindow -namespace Win32Functions -passThru
try { $showWindow::ShowWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, 0) } catch {}

# ---[ Show the Form ]---
try {
    [void]$script:mainForm.ShowDialog()
}
catch {
    Write-Error "An unexpected GUI error occurred: $_"
}
finally {
    Write-Log "Application closing. Killing ADB server..."
    Run-Command $script:adbPath "kill-server" -ShowErrorDialog $false
    $script:mainForm.Dispose()
    try { $showWindow::ShowWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, 5) } catch {}
    Write-Host "Script finished." -ForegroundColor Yello