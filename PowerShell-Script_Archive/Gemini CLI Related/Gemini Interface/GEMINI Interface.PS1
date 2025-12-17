# ---------------------------------------------------------
# PROJECT NAME: GEMINI Interface
# VERSION NUMBER (MUST ALWAYS BE 4 VALUES): 1.5.0.0 
#
#  VERSIONING RULES A.B.C.D  A= Major B= Secondary C= Minor D= Quick Bug Fix
#
# Scope / Purpose: (Listed Below)
#
# GEMINI Interface for PowerShell WinForms Application / Applets
# Basic starting point for Zachary Whiteman's custom GUI Tools
# When Developing using this app never remove elements from the template codebase EVER always Comment them out and leave functionality in-tact. this will ensure all projects remain cohesive throughout feature changes and project evolution.
#
#  Developer Notes / Prerequisite Information: (Listed Below)
#
# NOTES FOR GEMINI: Ensure all above requirements are met and strictly adhered to. NEVER remove or change any of this header information aside from the "PROJECT NAME:" and "VERSION NUMBER (MUST ALWAYS BE 4 VALUES):" lines and the last lines "CHANGELOG:"
#
# CHANGELOG:
# (Changelog is now maintained externally in Resources\Documentation\CHANGELOG.txt)
#
# ---------------------------------------------------------

# ---------------------------------------------------------
# LOGGING MODULE (Mandatory Injection)
# ---------------------------------------------------------
$ScriptBaseDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ConfigDirName = "Gemini_Interface_Logs"
# Build all paths relative to the script's location
$LoggingBaseDir = [System.IO.Path]::Combine($ScriptBaseDir, $ConfigDirName)
$LogFilesDir = [System.IO.Path]::Combine($LoggingBaseDir, "Log Files")
$ErrorLogDir = [System.IO.Path]::Combine($LogFilesDir, "Error Logs")
$HistoricalLogDir = [System.IO.Path]::Combine($LogFilesDir, "Historical Logs")
$HistoricalErrorLogDir = [System.IO.Path]::Combine($ErrorLogDir, "Historical Logs")
$Global:LiveLogFile = [System.IO.Path]::Combine($LogFilesDir, "LiveLog.json")

# Ensure all the folders we need actually exist
@($LoggingBaseDir, $LogFilesDir, $ErrorLogDir, $HistoricalLogDir, $HistoricalErrorLogDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# LOGGING FUNCTIONS
function Move-OldLogs {
    # Archive the main LiveLog.json
    if (Test-Path $Global:LiveLogFile) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $destination = [System.IO.Path]::Combine($HistoricalLogDir, "LiveLog-$timestamp.json")
            Move-Item -Path $Global:LiveLogFile -Destination $destination -Force
        }
        catch {
            Write-Warning "Could not archive old LiveLog.json: $($_.Exception.Message)"
        }
    }

    # Archive old Error Logs
    $oldErrorLogs = Get-ChildItem -Path $ErrorLogDir -Filter "*.json"
    foreach ($log in $oldErrorLogs) {
        try {
            $destination = [System.IO.Path]::Combine($HistoricalErrorLogDir, $log.Name)
            Move-Item -Path $log.FullName -Destination $destination -Force
        }
        catch {
            Write-Warning "Could not archive error log $($log.Name): $($_.Exception.Message)"
        }
    }
}

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL")]
        [string]$Severity = "INFO"
    )

    # Console Output for User Visibility
    $consoleColor = switch ($Severity) {
        "INFO" { "White" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "FATAL" { "Magenta" }
    }
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [$Severity] $Message" -ForegroundColor $consoleColor

    if ($Severity -eq "WARN") { Write-Warning $Message }

    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Severity  = $Severity
        Message   = $Message
    }

    try {
        $logEntry | ConvertTo-Json -Compress | Add-Content -Path $Global:LiveLogFile
    }
    catch {
        Write-Warning "Failed to write to LiveLog: $($_.Exception.Message)"
    }
}

function Write-ErrorLog {
    param (
        [string]$ContextMessage,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    Write-Error -ErrorRecord $ErrorRecord

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $fileNameTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    $errorDetails = @{
        Timestamp      = $timestamp
        Context        = $ContextMessage
        Exception_Type = $ErrorRecord.Exception.GetType().FullName
        Exception_Msg  = $ErrorRecord.Exception.Message
        StackTrace     = $ErrorRecord.Exception.StackTrace
        Script_Line    = $ErrorRecord.InvocationInfo.ScriptLineNumber
        Line_Content   = $ErrorRecord.InvocationInfo.Line
    }

    try {
        $errorJson = $errorDetails | ConvertTo-Json -Depth 5
        $destination = [System.IO.Path]::Combine($ErrorLogDir, "ErrorLog-$fileNameTimestamp.json")
        $errorJson | Out-File -FilePath $destination -Encoding UTF8
        
        Write-Log -Message "An error occurred. Details in ErrorLog-$fileNameTimestamp.json. Context: $ContextMessage" -Severity "ERROR"
    }
    catch {
        Write-Warning "Could not write to error log: $($_.Exception.Message)"
    }
}

# RUN AT STARTUP
Move-OldLogs
Write-Log -Message "Script started. Logging system initialized."

try {
    # 1. Load the necessary .NET assemblies.
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 2. Enable Visual Styles.
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # ---------------------------------------------------------
    # P/Invoke: Console Window Management
    # ---------------------------------------------------------
    $ConsoleToggleDef = @"
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
"@
    $Win32 = Add-Type -MemberDefinition $ConsoleToggleDef -Name "Win32" -Namespace Win32Functions -PassThru

    $SW_HIDE = 0
    $SW_SHOW = 5
    $ConsoleVisible = $false
    
    # Hide Console on Start
    $hwnd = $Win32::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) { $Win32::ShowWindowAsync($hwnd, $SW_HIDE) | Out-Null }

    function Toggle-Console {
        $hwnd = $Win32::GetConsoleWindow()
        if ($hwnd -ne [IntPtr]::Zero) {
            if ($script:ConsoleVisible) {
                $Win32::ShowWindowAsync($hwnd, $SW_HIDE) | Out-Null
                $script:ConsoleVisible = $false
            }
            else {
                $Win32::ShowWindowAsync($hwnd, $SW_SHOW) | Out-Null
                $script:ConsoleVisible = $true
            }
        }
    }

    # ---------------------------------------------------------
    # Global Resources & Configuration Paths
    # ---------------------------------------------------------
    
    # Get Script Directory
    $scriptPath = $PSScriptRoot
    if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = $pwd.Path }
    
    $ResourcesDir = [System.IO.Path]::Combine($scriptPath, "Resources")
    $IconsDir = [System.IO.Path]::Combine($ResourcesDir, "Icons")
    $HtmlDir = [System.IO.Path]::Combine($ResourcesDir, "HTML")
    $ConfigDir = [System.IO.Path]::Combine($ResourcesDir, "CONFIGURATION")
    $ConfigFile = [System.IO.Path]::Combine($ConfigDir, "settings.json")
    $DocDir = [System.IO.Path]::Combine($ResourcesDir, "Documentation")

    # Ensure Config Dir Exists
    if (-not (Test-Path $ConfigDir)) { New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null }

    # --- 🎨 VISUAL CONFIGURATION ---
    $Color_Control = [System.Drawing.SystemColors]::Control
    $Color_ControlLight = [System.Drawing.SystemColors]::ControlLight
    $Color_White = [System.Drawing.Color]::White
    $Color_TealDark = [System.Drawing.Color]::FromArgb(0, 128, 128)
    $Color_TealLight = [System.Drawing.Color]::FromArgb(0, 160, 160)
    $Color_Accent = [System.Drawing.Color]::FromArgb(0, 100, 100)

    # -----------------------------------------------------------------------------
    # PERSISTENCE SYSTEM
    # -----------------------------------------------------------------------------
    $Global:Settings = @{
        AppIcon      = "Main1"
        FontName     = "Segoe UI"
        FontSize     = 9.0
        FontStyle    = "Regular"
        ViewMode     = "Details"
        SortBy       = "Name"
        GroupBy      = "None"
        SplitTree    = 200 
        SplitMeta    = 400 
        ShowConsole  = $false
        InfoPanelPos = "Right" 
    }

    function Load-Config {
        if (Test-Path $ConfigFile) {
            try {
                $json = Get-Content $ConfigFile -Raw | ConvertFrom-Json
                foreach ($prop in $json.PSObject.Properties) {
                    $Global:Settings[$prop.Name] = $prop.Value
                }
            }
            catch { Write-Warning "Failed to load config: $_" }
        }
    }

    function Save-Config {
        try {
            $Global:Settings | ConvertTo-Json | Set-Content $ConfigFile -Force
        }
        catch { Write-Warning "Failed to save config: $_" }
    }

    Load-Config

    # Sync Console State with Config
    if ($Global:Settings.ShowConsole) { Toggle-Console }

    # ---------------------------------------------------------
    # GEMINI API INTEGRATION
    # ---------------------------------------------------------
    function Invoke-GeminiAPI {
        param(
            [string]$Prompt,
            [string]$Model = "gemini-1.5-flash"
        )
        
        Write-Log "Invoking Gemini API calling Model: $Model" "INFO"

        $ApiKey = $env:GEMINI_API_KEY
        if ([string]::IsNullOrEmpty($ApiKey)) {
            $ApiKey = [Environment]::GetEnvironmentVariable("GEMINI_API_KEY", "User")
        }
        
        # Check specific environment variables based on context or failover
        if ($Model -match "jules" -or [string]::IsNullOrEmpty($ApiKey)) {
            $julesKey = $env:JULES_API_KEY
            if (-not [string]::IsNullOrEmpty($julesKey)) { $ApiKey = $julesKey }
        }

        # User added VERTEX_API_KEY as another potential source
        if ([string]::IsNullOrEmpty($ApiKey)) {
            $vertexKey = $env:VERTEX_API_KEY
            if (-not [string]::IsNullOrEmpty($vertexKey)) { $ApiKey = $vertexKey }
        }

        if ([string]::IsNullOrEmpty($ApiKey)) {
            $msg = "GEMINI_API_KEY not found in Environment Variables."
            Write-Log $msg "ERROR"
            return "Error: $msg - Please set your API usage."
        }

        # Handle Model Alias
        $apiModel = $Model
        if ($Model -eq "Jules") { $apiModel = "gemini-1.5-flash" } 
        
        # Robust Model Mapping (Future Proofed for Dec 2025)
        # Maps fancy display names to actual API IDs
        switch -Regex ($Model) {
            "Gemini 3.0 Pro" { $apiModel = "gemini-3.0-pro-exp" }
            "Gemini 3.0 Ultra" { $apiModel = "gemini-3.0-ultra-exp" }
            "Gemini 2.5 Flash" { $apiModel = "gemini-2.5-flash-exp" } 
            "Gemini 2.5 Flash-Lite" { $apiModel = "gemini-2.5-flash-lite-exp" }
            "Nano Banana" { $apiModel = "gemini-nanobanana-exp" }
            "Jules" { $apiModel = "gemini-3.0-flash-exp" }
            default {
                # Fallback / Normalization
                if ($apiModel -notmatch "^[a-z0-9-]+$") {
                    $apiModel = $apiModel.ToLower().Replace(" ", "-")
                }
            }
        }

        $Url = "https://generativelanguage.googleapis.com/v1beta/models/${apiModel}:generateContent?key=$ApiKey"
        
        # JSON Handling by ConvertTo-Json
        # $Prompt is automatically escaped by ConvertTo-Json

        $Body = @{
            contents = @(
                @{
                    parts = @(
                        @{ text = $Prompt }
                    )
                }
            )
        } | ConvertTo-Json -Depth 5 -Compress

        try {
            $Response = Invoke-RestMethod -Uri $Url -Method Post -Body $Body -ContentType "application/json" -ErrorAction Stop
            
            # Extract Text
            if ($Response.candidates -and $Response.candidates[0].content -and $Response.candidates[0].content.parts) {
                $Text = $Response.candidates[0].content.parts[0].text
                Write-Log "Gemini API Response Received." "INFO"
                return $Text
            }
            else {
                Write-Log "Gemini API returned unexpected response structure." "WARN"
                return "Error: Unexpected API Response format."
            }
        }
        catch {
            Write-ErrorLog "Gemini API Call Failed" $_
            return "Error: API Call Failed - $($_.Exception.Message)"
        }
    }

    # ---------------------------------------------------------
    # Main Form Setup
    # ---------------------------------------------------------
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Text = "PowerShell GUI Template - Master Edition"
    $mainForm.Width = 1200
    $mainForm.Height = 850
    $mainForm.StartPosition = "CenterScreen"
    
    try {
        $style = [System.Drawing.FontStyle]::Regular
        if ($Global:Settings.FontStyle -match "Bold") { $style = $style -bor [System.Drawing.FontStyle]::Bold }
        if ($Global:Settings.FontStyle -match "Italic") { $style = $style -bor [System.Drawing.FontStyle]::Italic }
        $mainForm.Font = New-Object System.Drawing.Font($Global:Settings.FontName, [float]$Global:Settings.FontSize, $style)
    }
    catch {
        $mainForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    }

    # -----------------------------------------------------------------------------
    # ICON LOADING LOGIC
    # -----------------------------------------------------------------------------
    function Load-Icon {
        param([string]$Name, [int]$Size = 0)
        $Path = Join-Path $IconsDir $Name
        if (Test-Path $Path) {
            try {
                if ($Size -gt 0) { return New-Object System.Drawing.Icon($Path, $Size, $Size) }
                else { return New-Object System.Drawing.Icon($Path) }
            }
            catch {}
        }
        return $null
    }

    # Pre-load Icons
    $Icon_Main1 = Load-Icon "Gemini 2.0-2.5.ico" # REPLACES MAIN1
    $Icon_Main2 = Load-Icon "Gemini 1.5-2.0.ico" # REPLACES MAIN2
    $Icon_Main3 = Load-Icon "Gemini 1.0-1.5.ico" # REPLACES MAIN3
    $Icon_Help = Load-Icon "HELP.ico"
    $Icon_Options = Load-Icon "OPTIONS.ico"
    $Icon_App = Load-Icon "APPEARANCE.ico"
    $Icon_Good = Load-Icon "GOOD.ico"
    $Icon_Bad = Load-Icon "BAD.ico"
    $Icon_NoStatus = Load-Icon "NO-STATUS.ico"
    $Icon_Info = Load-Icon "INFORMATION.ico"
    $Icon_UAC = Load-Icon "UAC.ico"
    $Icon_Zip = Load-Icon "COMPRESSED-FILE.ico"

    function Get-IconObj {
        param($Name)
        switch ($Name) {
            "Main1" { return $Icon_Main1 }
            "Main2" { return $Icon_Main2 }
            "Main3" { return $Icon_Main3 }
            default { return $Icon_Main1 }
        }
    }

    $mainForm.Icon = Get-IconObj $Global:Settings.AppIcon

    # -----------------------------------------------------------------------------
    # UI HELPERS
    # -----------------------------------------------------------------------------
    function Create-GradientHeader {
        param($ParentForm, $TitleText, $IconObj)
        
        $HeaderPanel = New-Object System.Windows.Forms.Panel
        $HeaderPanel.Dock = "Top"
        $HeaderPanel.Height = 80 
        $HeaderPanel.BackColor = $Color_TealDark
        
        $HeaderPanel.Add_Paint({
                param($sender, $e)
                $rect = $sender.ClientRectangle
                $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $Color_TealLight, $Color_TealDark, 90)
                $e.Graphics.FillRectangle($brush, $rect)
            })
        
        $ParentForm.Controls.Add($HeaderPanel)

        $TextX = 20
        $Pic = New-Object System.Windows.Forms.PictureBox
        $Pic.Size = New-Object System.Drawing.Size(64, 64)
        $Pic.Location = New-Object System.Drawing.Point(10, 8)
        $Pic.SizeMode = "Zoom"
        $Pic.BackColor = [System.Drawing.Color]::Transparent

        # Force the icon if provided
        if ($IconObj -ne $null) {
            $Pic.Image = $IconObj.ToBitmap()
            $HeaderPanel.Controls.Add($Pic)
            $TextX = 80
        }
        
        $lblShadow = New-Object System.Windows.Forms.Label
        $lblShadow.Text = $TitleText
        $lblShadow.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
        $lblShadow.ForeColor = [System.Drawing.Color]::Black
        $lblShadow.BackColor = [System.Drawing.Color]::Transparent
        $lblShadow.AutoSize = $true
        $lblShadow.Location = New-Object System.Drawing.Point(($TextX + 2), 22)
        $HeaderPanel.Controls.Add($lblShadow)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = $TitleText
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = [System.Drawing.Color]::White
        $lblTitle.BackColor = [System.Drawing.Color]::Transparent
        $lblTitle.AutoSize = $true
        $lblTitle.Location = New-Object System.Drawing.Point($TextX, 20)
        $HeaderPanel.Controls.Add($lblTitle)
        $lblTitle.BringToFront()
    }

    # Custom Alert Function
    function Show-CustomAlert {
        param($Title, $Message, $IconObj)
        
        $AlertForm = New-Object System.Windows.Forms.Form
        $AlertForm.Text = $Title
        $AlertForm.Size = New-Object System.Drawing.Size(500, 300)
        $AlertForm.StartPosition = "CenterParent"
        $AlertForm.FormBorderStyle = "FixedDialog"
        $AlertForm.MaximizeBox = $false
        $AlertForm.MinimizeBox = $false
        $AlertForm.BackColor = $Color_White
        
        # Explicitly set the window icon if provided
        if ($IconObj -ne $null) { 
            $AlertForm.Icon = $IconObj 
        }

        # Pass the IconObj to the Header to draw it
        Create-GradientHeader $AlertForm $Title $IconObj

        $lblMsg = New-Object System.Windows.Forms.Label
        $lblMsg.Text = $Message
        $lblMsg.Dock = "Fill"
        $lblMsg.TextAlign = "MiddleCenter"
        $lblMsg.Padding = New-Object System.Windows.Forms.Padding(20)
        $lblMsg.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $AlertForm.Controls.Add($lblMsg)
        $lblMsg.BringToFront()

        $pnlBot = New-Object System.Windows.Forms.Panel
        $pnlBot.Dock = "Bottom"
        $pnlBot.Height = 50
        $pnlBot.BackColor = $Color_ControlLight
        $AlertForm.Controls.Add($pnlBot)

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "OK"
        $btnOk.DialogResult = "OK"
        $btnOk.Location = New-Object System.Drawing.Point(380, 10)
        $btnOk.Size = New-Object System.Drawing.Size(90, 30)
        $btnOk.UseVisualStyleBackColor = $true
        $pnlBot.Controls.Add($btnOk)
        $AlertForm.AcceptButton = $btnOk

        $AlertForm.ShowDialog() | Out-Null
    }

    function Apply-FontRecursively {
        param ($ctrl, $newFont)
        $ctrl.Font = $newFont
        if ($ctrl -is [System.Windows.Forms.ToolStrip]) { $ctrl.Font = $newFont }
        foreach ($child in $ctrl.Controls) { Apply-FontRecursively $child $newFont }
    }

    # -----------------------------------------------------------------------------
    # ADVANCED SETTINGS SYSTEM
    # -----------------------------------------------------------------------------
    function Show-AdvancedSettings {
        $AdvForm = New-Object System.Windows.Forms.Form
        $AdvForm.Text = "Advanced Settings"
        $AdvForm.Size = New-Object System.Drawing.Size(750, 650) # Increased Size
        $AdvForm.StartPosition = "CenterParent"
        $AdvForm.BackColor = $Color_Control
        if ($Icon_Options) { $AdvForm.Icon = $Icon_Options }

        Create-GradientHeader $AdvForm "Advanced Settings" $Icon_App

        $AdvTab = New-Object System.Windows.Forms.TabControl
        $AdvTab.Dock = "Fill"
        $AdvTab.Padding = New-Object System.Drawing.Point(15, 8)
        $AdvForm.Controls.Add($AdvTab)
        $AdvTab.BringToFront()

        # --- Tab: Appearance ---
        $pgAppearance = New-Object System.Windows.Forms.TabPage("Appearance")
        $pgAppearance.Padding = New-Object System.Windows.Forms.Padding(20)
        $pgAppearance.BackColor = $Color_White
        $AdvTab.TabPages.Add($pgAppearance)

        $grpIcons = New-Object System.Windows.Forms.GroupBox
        $grpIcons.Text = "Application Icon Selection"
        $grpIcons.Size = New-Object System.Drawing.Size(650, 150)
        $grpIcons.Location = New-Object System.Drawing.Point(20, 20)
        $pgAppearance.Controls.Add($grpIcons)

        function Add-IconOption {
            param($Key, $Text, $IconObj, $X)
            $pic = New-Object System.Windows.Forms.PictureBox
            $pic.Size = New-Object System.Drawing.Size(48, 48)
            $pic.Location = New-Object System.Drawing.Point($X, 30)
            $pic.SizeMode = "Zoom"
            if ($IconObj) { $pic.Image = $IconObj.ToBitmap() }
            $grpIcons.Controls.Add($pic)

            $radio = New-Object System.Windows.Forms.RadioButton
            $radio.Text = $Text
            $radio.AutoSize = $true
            $radio.Location = New-Object System.Drawing.Point($X, 90)
            $radio.Tag = $Key
            
            if ($Global:Settings.AppIcon -eq $Key) { $radio.Checked = $true }

            $radio.Add_CheckedChanged({
                    if ($radio.Checked) {
                        $Global:Settings.AppIcon = $radio.Tag
                        $mainForm.Icon = Get-IconObj $radio.Tag
                    }
                })
            $grpIcons.Controls.Add($radio)
        }

        Add-IconOption "Main1" "Gemini 2.0+" $Icon_Main1 50
        Add-IconOption "Main2" "Gemini 1.5+" $Icon_Main2 250
        Add-IconOption "Main3" "Gemini 1.0+" $Icon_Main3 450

        $chkConsole = New-Object System.Windows.Forms.CheckBox
        $chkConsole.Text = "Show Console Window (Instant)"
        $chkConsole.AutoSize = $true
        $chkConsole.Location = New-Object System.Drawing.Point(30, 190)
        $chkConsole.Checked = $Global:Settings.ShowConsole
        $chkConsole.Add_CheckedChanged({
                $Global:Settings.ShowConsole = $chkConsole.Checked
                Toggle-Console
            })
        $pgAppearance.Controls.Add($chkConsole)

        $grpLayout = New-Object System.Windows.Forms.GroupBox
        $grpLayout.Text = "Layout Options"
        $grpLayout.Size = New-Object System.Drawing.Size(300, 120)
        $grpLayout.Location = New-Object System.Drawing.Point(20, 230)
        $pgAppearance.Controls.Add($grpLayout)

        $radRight = New-Object System.Windows.Forms.RadioButton
        $radRight.Text = "Info Panel on Right"
        $radRight.Location = New-Object System.Drawing.Point(20, 30)
        $radRight.AutoSize = $true
        $radRight.Checked = ($Global:Settings.InfoPanelPos -ne "Bottom")
        $grpLayout.Controls.Add($radRight)

        $radBottom = New-Object System.Windows.Forms.RadioButton
        $radBottom.Text = "Info Panel on Bottom"
        $radBottom.Location = New-Object System.Drawing.Point(20, 60)
        $radBottom.AutoSize = $true
        $radBottom.Checked = ($Global:Settings.InfoPanelPos -eq "Bottom")
        $grpLayout.Controls.Add($radBottom)

        # --- Tab: Fonts (FIXED LAYOUT) ---
        $pgFonts = New-Object System.Windows.Forms.TabPage("Fonts")
        $pgFonts.Padding = New-Object System.Windows.Forms.Padding(20)
        $pgFonts.BackColor = $Color_White
        $AdvTab.TabPages.Add($pgFonts)

        # Row 1: Font Family
        $lblFont = New-Object System.Windows.Forms.Label
        $lblFont.Text = "Font Family:"
        $lblFont.AutoSize = $true
        $lblFont.Location = New-Object System.Drawing.Point(20, 20)
        $pgFonts.Controls.Add($lblFont)

        $lstFonts = New-Object System.Windows.Forms.ComboBox
        $lstFonts.DropDownStyle = "DropDownList"
        $lstFonts.Location = New-Object System.Drawing.Point(20, 45)
        $lstFonts.Size = New-Object System.Drawing.Size(300, 30)
        
        # Optimize Font Loading (Don't hang the UI)
        $fontTask = {
            $fonts = [System.Drawing.FontFamily]::Families
            foreach ($f in $fonts) { $lstFonts.Items.Add($f.Name) | Out-Null }
            $lstFonts.SelectedItem = $Global:Settings.FontName
        }
        # Populate immediately but safely
        $fonts = [System.Drawing.FontFamily]::Families
        foreach ($f in $fonts) { $lstFonts.Items.Add($f.Name) | Out-Null }
        if ($lstFonts.Items.Contains($Global:Settings.FontName)) {
            $lstFonts.SelectedItem = $Global:Settings.FontName
        }
        else {
            $lstFonts.SelectedIndex = 0
        }
        
        $pgFonts.Controls.Add($lstFonts)

        # Row 1 Right: Size
        $lblSize = New-Object System.Windows.Forms.Label
        $lblSize.Text = "Size (pt):"
        $lblSize.AutoSize = $true
        $lblSize.Location = New-Object System.Drawing.Point(350, 20)
        $pgFonts.Controls.Add($lblSize)

        $nudSize = New-Object System.Windows.Forms.NumericUpDown
        $nudSize.Location = New-Object System.Drawing.Point(350, 45)
        $nudSize.Size = New-Object System.Drawing.Size(100, 30)
        $nudSize.DecimalPlaces = 1
        $nudSize.Minimum = 6
        $nudSize.Maximum = 72
        $nudSize.Value = $Global:Settings.FontSize
        $pgFonts.Controls.Add($nudSize)

        # Row 2: Styles (Moved Down to avoid collision)
        $chkBold = New-Object System.Windows.Forms.CheckBox
        $chkBold.Text = "Bold"
        $chkBold.AutoSize = $true
        $chkBold.Location = New-Object System.Drawing.Point(20, 90)
        $chkBold.Checked = ($Global:Settings.FontStyle -match "Bold")
        $pgFonts.Controls.Add($chkBold)

        $chkItalic = New-Object System.Windows.Forms.CheckBox
        $chkItalic.Text = "Italic"
        $chkItalic.AutoSize = $true
        $chkItalic.Location = New-Object System.Drawing.Point(100, 90)
        $chkItalic.Checked = ($Global:Settings.FontStyle -match "Italic")
        $pgFonts.Controls.Add($chkItalic)

        # Row 3: Preview
        $grpPreview = New-Object System.Windows.Forms.GroupBox
        $grpPreview.Text = "Live Preview"
        $grpPreview.Location = New-Object System.Drawing.Point(20, 130)
        $grpPreview.Size = New-Object System.Drawing.Size(650, 150)
        $pgFonts.Controls.Add($grpPreview)

        $txtPreview = New-Object System.Windows.Forms.TextBox
        $txtPreview.Multiline = $true
        $txtPreview.Text = "The quick brown fox jumps over the lazy dog.`r`n1234567890"
        $txtPreview.Dock = "Fill"
        $txtPreview.ScrollBars = "Vertical"
        $grpPreview.Controls.Add($txtPreview)

        # Update Preview Function
        $UpdatePreview = {
            try {
                $s = [System.Drawing.FontStyle]::Regular
                if ($chkBold.Checked) { $s = $s -bor [System.Drawing.FontStyle]::Bold }
                if ($chkItalic.Checked) { $s = $s -bor [System.Drawing.FontStyle]::Italic }
                $f = New-Object System.Drawing.Font($lstFonts.SelectedItem, [float]$nudSize.Value, $s)
                $txtPreview.Font = $f
            }
            catch {}
        }

        $lstFonts.Add_SelectedIndexChanged($UpdatePreview)
        $nudSize.Add_ValueChanged($UpdatePreview)
        $chkBold.Add_CheckedChanged($UpdatePreview)
        $chkItalic.Add_CheckedChanged($UpdatePreview)
        
        # Trigger initial preview
        & $UpdatePreview

        # --- Tab: Status (FIXED ICONS) ---
        $pgStatus = New-Object System.Windows.Forms.TabPage("Status & Tests")
        $pgStatus.Padding = New-Object System.Windows.Forms.Padding(20)
        $pgStatus.BackColor = $Color_White
        $AdvTab.TabPages.Add($pgStatus)
        
        $lblTest = New-Object System.Windows.Forms.Label
        $lblTest.Text = "Test System Alert Icons:"
        $lblTest.AutoSize = $true
        $lblTest.Location = New-Object System.Drawing.Point(20, 20)
        $lblTest.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $pgStatus.Controls.Add($lblTest)

        function Add-StatusBtn {
            param($Y, $Text, $IconObj)
            $btn = New-Object System.Windows.Forms.Button
            $btn.Text = "  $Text"
            $btn.TextImageRelation = "ImageBeforeText"
            if ($IconObj) { $btn.Image = $IconObj.ToBitmap() }
            $btn.ImageAlign = "MiddleLeft"
            $btn.Size = New-Object System.Drawing.Size(250, 50)
            $btn.Location = New-Object System.Drawing.Point(20, $Y)
            $btn.UseVisualStyleBackColor = $true
            
            # Store the Icon object in the TAG property to ensure it passes into the closure correctly
            $btn.Tag = $IconObj 

            $btn.Add_Click({
                    param($sender, $e) 
                    # Retrieve the specific icon from the sender's Tag
                    $clickedIcon = $sender.Tag
                    Show-CustomAlert "System Test: $Text" "This is a demonstration of the $Text alert system.`n`nThe icon matches the source." $clickedIcon
                })
            $pgStatus.Controls.Add($btn)
        }

        Add-StatusBtn 60 "Good Status" $Icon_Good
        Add-StatusBtn 120 "Bad Status" $Icon_Bad
        Add-StatusBtn 180 "No Status" $Icon_NoStatus
        Add-StatusBtn 240 "UAC Required" $Icon_UAC

        # --- Bottom ---
        $BotPanel = New-Object System.Windows.Forms.Panel
        $BotPanel.Dock = "Bottom"
        $BotPanel.Height = 50
        $BotPanel.BackColor = $Color_ControlLight
        $AdvForm.Controls.Add($BotPanel)

        $btnApply = New-Object System.Windows.Forms.Button
        $btnApply.Text = "Apply"
        $btnApply.Location = New-Object System.Drawing.Point(530, 10)
        $btnApply.Size = New-Object System.Drawing.Size(90, 30)
        $btnApply.UseVisualStyleBackColor = $true
        $btnApply.Add_Click({
                # Save Layout
                if ($radBottom.Checked) { $Global:Settings.InfoPanelPos = "Bottom" }
                else { $Global:Settings.InfoPanelPos = "Right" }
            
                # Save Fonts
                $Global:Settings.FontName = $lstFonts.SelectedItem
                $Global:Settings.FontSize = $nudSize.Value
                $styleStr = "Regular"
                if ($chkBold.Checked) { $styleStr = "Bold" }
                if ($chkItalic.Checked) { 
                    if ($styleStr -eq "Regular") { $styleStr = "Italic" } else { $styleStr += ", Italic" }
                }
                $Global:Settings.FontStyle = $styleStr
            
                # Apply Font
                try {
                    $s = [System.Drawing.FontStyle]::Regular
                    if ($chkBold.Checked) { $s = $s -bor [System.Drawing.FontStyle]::Bold }
                    if ($chkItalic.Checked) { $s = $s -bor [System.Drawing.FontStyle]::Italic }
                    $newFont = New-Object System.Drawing.Font($lstFonts.SelectedItem, [float]$nudSize.Value, $s)
                    Apply-FontRecursively $mainForm $newFont
                }
                catch {}

                Save-Config
                [System.Windows.Forms.MessageBox]::Show("Settings Saved and Applied.", "Configuration")
            })
        $BotPanel.Controls.Add($btnApply)

        $btnCls = New-Object System.Windows.Forms.Button
        $btnCls.Text = "Close"
        $btnCls.Location = New-Object System.Drawing.Point(630, 10)
        $btnCls.Size = New-Object System.Drawing.Size(90, 30)
        $btnCls.UseVisualStyleBackColor = $true
        $btnCls.Add_Click({ $AdvForm.Close() })
        $BotPanel.Controls.Add($btnCls)

        $AdvForm.ShowDialog() | Out-Null
    }

    # -----------------------------------------------------------------------------
    # GUIDANCE SYSTEM
    # -----------------------------------------------------------------------------
    function Show-GuidanceSystem {
        $HelpForm = New-Object System.Windows.Forms.Form
        $HelpForm.Text = "System Guidance"
        $HelpForm.Size = New-Object System.Drawing.Size(800, 600)
        $HelpForm.StartPosition = "CenterScreen"
        $HelpForm.BackColor = $Color_Control
        if ($Icon_Help) { $HelpForm.Icon = $Icon_Help }

        Create-GradientHeader $HelpForm "Guidance System" $Icon_Help

        $TabControl = New-Object System.Windows.Forms.TabControl
        $TabControl.Dock = "Fill"
        $TabControl.Padding = New-Object System.Drawing.Point(10, 5)
        $HelpForm.Controls.Add($TabControl)
        $TabControl.BringToFront()

        function Add-Tab {
            param($Title, $Content)
            $Page = New-Object System.Windows.Forms.TabPage
            $Page.Text = $Title
            $Page.BackColor = $Color_White
            
            $Txt = New-Object System.Windows.Forms.TextBox
            $Txt.Multiline = $true
            $Txt.ReadOnly = $true
            $Txt.ScrollBars = "Vertical"
            $Txt.Dock = "Fill"
            $Txt.Font = New-Object System.Drawing.Font("Consolas", 10)
            $Txt.Text = $Content
            $Txt.BorderStyle = "None"
            
            $PadPanel = New-Object System.Windows.Forms.Panel
            $PadPanel.Dock = "Fill"
            $PadPanel.Padding = New-Object System.Windows.Forms.Padding(15)
            $PadPanel.Controls.Add($Txt)
            $Page.Controls.Add($PadPanel)
            $TabControl.TabPages.Add($Page)
        }

        # Changelog Reader
        $clPath = Join-Path $DocDir "CHANGELOG.txt"
        $clContent = if (Test-Path $clPath) { Get-Content $clPath -Raw } else { "Changelog not found." }
        Add-Tab "Changelog" $clContent

        Add-Tab "General Usage" "How to drive this thing:`r`n`r`n1. Push buttons.`r`n2. Watch things happen.`r`n3. Don't panic."
        Add-Tab "Troubleshooting" "If it breaks:`r`n`r`n- Did you try turning it off and on again?`r`n- Did you scream at the monitor?"
        Add-Tab "Legacy Notes" "Frutiger Aero remains the superior design language.`r`nFlat design is a crime against humanity."

        $BotPanel = New-Object System.Windows.Forms.Panel
        $BotPanel.Dock = "Bottom"
        $BotPanel.Height = 50
        $BotPanel.BackColor = $Color_ControlLight
        $HelpForm.Controls.Add($BotPanel)

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "Close"
        $btnOk.Location = New-Object System.Drawing.Point(680, 10)
        $btnOk.Size = New-Object System.Drawing.Size(90, 30)
        $btnOk.UseVisualStyleBackColor = $true
        $btnOk.Add_Click({ $HelpForm.Close() })
        $BotPanel.Controls.Add($btnOk)

        $HelpForm.ShowDialog() | Out-Null
    }

    function Add-ClickLogic {
        param ($obj, $name)
        $obj.Add_Click({
                Write-Log "UI Interaction: Button '$name' clicked." "INFO"
                [System.Windows.Forms.MessageBox]::Show("Functionality for '$name' goes here.`n`nLocate the event handler in the script to add your logic.", "Template Action")
            })
    }

    # ---------------------------------------------------------
    # EXPLORER RESOURCES: ImageLists for ALL Sizes
    # ---------------------------------------------------------
    $ilSmall = New-Object System.Windows.Forms.ImageList; $ilSmall.ImageSize = New-Object System.Drawing.Size(16, 16)
    $ilMedium = New-Object System.Windows.Forms.ImageList; $ilMedium.ImageSize = New-Object System.Drawing.Size(32, 32)
    $ilLarge = New-Object System.Windows.Forms.ImageList; $ilLarge.ImageSize = New-Object System.Drawing.Size(48, 48)
    $ilExtra = New-Object System.Windows.Forms.ImageList; $ilExtra.ImageSize = New-Object System.Drawing.Size(128, 128)

    function Add-ListIcon {
        param($Key, $Name, $FallbackColor)
        $ico = Load-Icon $Name
        if ($ico) {
            $ilSmall.Images.Add($Key, $ico)
            $ilMedium.Images.Add($Key, $ico)
            $ilLarge.Images.Add($Key, $ico)
            $ilExtra.Images.Add($Key, $ico)
        }
        else {
            $bmp = New-Object System.Drawing.Bitmap(48, 48)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.Clear($FallbackColor)
            $g.Dispose()
            $ilSmall.Images.Add($Key, $bmp)
            $ilMedium.Images.Add($Key, $bmp)
            $ilLarge.Images.Add($Key, $bmp)
            $ilExtra.Images.Add($Key, $bmp)
        }
    }
    
    Add-ListIcon "Folder" "FOLDER.ico" ([System.Drawing.Color]::Gold)
    Add-ListIcon "File" "Gemini 2.0-2.5.ico" ([System.Drawing.Color]::WhiteSmoke)
    Add-ListIcon "C-Drive" "C-HDD-DRIVE.ico" ([System.Drawing.Color]::Teal)
    Add-ListIcon "Drive" "HDD-DRIVE.ico" ([System.Drawing.Color]::Gray)
    Add-ListIcon "Zip" "COMPRESSED-FILE.ico" ([System.Drawing.Color]::Yellow)

    # ---------------------------------------------------------
    # 1. MenuStrip
    # ---------------------------------------------------------
    $menuStrip = New-Object System.Windows.Forms.MenuStrip
    $menuStrip.Dock = "Top"

    $menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
    $menuStrip.Items.Add($menuFile) | Out-Null
    $itemNew = $menuFile.DropDownItems.Add("New Project")
    Add-ClickLogic $itemNew "New Project"
    $itemOpen = $menuFile.DropDownItems.Add("Open...")
    Add-ClickLogic $itemOpen "Open..."
    $menuFile.DropDownItems.Add("-") | Out-Null
    $itemExit = $menuFile.DropDownItems.Add("Exit")
    $itemExit.Add_Click({ $mainForm.Close() })

    $menuView = New-Object System.Windows.Forms.ToolStripMenuItem("View")
    $menuStrip.Items.Add($menuView) | Out-Null
    
    $itemConsole = $menuView.DropDownItems.Add("Toggle Console Window")
    $itemConsole.Add_Click({
            Toggle-Console
        })

    $itemViewRef = $menuView.DropDownItems.Add("Refresh Views")
    Add-ClickLogic $itemViewRef "Refresh"

    $menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Help")
    $menuStrip.Items.Add($menuHelp) | Out-Null
    $itemGuide = $menuHelp.DropDownItems.Add("Guidance System")
    if ($Icon_Help) { $itemGuide.Image = $Icon_Help.ToBitmap() }
    $itemGuide.Add_Click({ Show-GuidanceSystem })
    $itemAbout = $menuHelp.DropDownItems.Add("About")

    # ---------------------------------------------------------
    # 2. ToolStrip
    # ---------------------------------------------------------
    $toolStrip = New-Object System.Windows.Forms.ToolStrip
    $toolStrip.Dock = "Top"
    
    $tsBtnRun = New-Object System.Windows.Forms.ToolStripButton("Quick Run")
    $tsBtnRun.DisplayStyle = "ImageAndText"
    if ($Icon_Good) { $tsBtnRun.Image = $Icon_Good.ToBitmap() } 
    Add-ClickLogic $tsBtnRun "Quick Run Toolbar Button"
    $toolStrip.Items.Add($tsBtnRun) | Out-Null

    $tsSep = New-Object System.Windows.Forms.ToolStripSeparator
    $toolStrip.Items.Add($tsSep) | Out-Null

    $tsDropDown = New-Object System.Windows.Forms.ToolStripDropDownButton("Options")
    $tsDropDown.DisplayStyle = "ImageAndText"
    if ($Icon_Options) { $tsDropDown.Image = $Icon_Options.ToBitmap() }
    
    $tsDropItem1 = $tsDropDown.DropDownItems.Add("Advanced Settings")
    $tsDropItem1.Add_Click({ Show-AdvancedSettings })
    
    $tsDropItem2 = $tsDropDown.DropDownItems.Add("Reset Layout")
    Add-ClickLogic $tsDropItem2 "Reset Layout"
    
    $toolStrip.Items.Add($tsDropDown) | Out-Null
    $mainForm.Controls.Add($toolStrip)
    $mainForm.Controls.Add($menuStrip)

    # ---------------------------------------------------------
    # About Dialog
    # ---------------------------------------------------------
    $itemAbout.Add_Click({
            $aboutForm = New-Object System.Windows.Forms.Form
            $aboutForm.Text = "About"
            $aboutForm.Width = 400
            $aboutForm.Height = 300
            $aboutForm.StartPosition = "CenterParent"
            $aboutForm.FormBorderStyle = "FixedDialog"
            $aboutForm.MaximizeBox = $false
            $aboutForm.MinimizeBox = $false
            if ($Icon_Info) { $aboutForm.Icon = $Icon_Info }

            $aboutTop = New-Object System.Windows.Forms.Panel
            $aboutTop.Dock = "Top"
            $aboutTop.Height = 60
            $aboutTop.BackColor = [System.Drawing.Color]::Teal 
        
            $aboutTitle = New-Object System.Windows.Forms.Label
            $aboutTitle.Text = "EliteSoftware Template"
            $aboutTitle.ForeColor = "White"
            $aboutTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
            $aboutTitle.AutoSize = $true
            $aboutTitle.Location = New-Object System.Drawing.Point(15, 15)
            $aboutTop.Controls.Add($aboutTitle)

            $aboutBot = New-Object System.Windows.Forms.Panel
            $aboutBot.Dock = "Bottom"
            $aboutBot.Height = 50
            $aboutBot.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220) 

            $btnDone = New-Object System.Windows.Forms.Button
            $btnDone.Text = "Done"
            $btnDone.UseVisualStyleBackColor = $true
            $btnDone.Location = New-Object System.Drawing.Point(300, 12)
            $btnDone.Add_Click({ $aboutForm.Close() })
            $aboutBot.Controls.Add($btnDone)

            $aboutMid = New-Object System.Windows.Forms.Panel
            $aboutMid.Dock = "Fill"
            $aboutMid.BackColor = "White"

            $aboutDesc = New-Object System.Windows.Forms.Label
            $aboutDesc.Text = "Version 1.4.4.0`n`nComplex GUI Template with Icon Extraction."
            $aboutDesc.AutoSize = $true
            $aboutDesc.Location = New-Object System.Drawing.Point(20, 20)
            $aboutMid.Controls.Add($aboutDesc)

            $aboutForm.Controls.Add($aboutMid)
            $aboutForm.Controls.Add($aboutTop)
            $aboutForm.Controls.Add($aboutBot)
        
            $aboutForm.ShowDialog()
        })

    # ---------------------------------------------------------
    # Bottom Panel
    # ---------------------------------------------------------
    $bottomPanel = New-Object System.Windows.Forms.Panel
    $bottomPanel.Height = 60  
    $bottomPanel.Dock = "Bottom" 
    $bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220) 
    $mainForm.Controls.Add($bottomPanel)

    $btnWidth = 85
    $btnHeight = 30
    $btnY = 15 

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run"
    $btnRun.Size = New-Object System.Drawing.Size($btnWidth, $btnHeight)
    $btnRun.Location = New-Object System.Drawing.Point(20, $btnY)
    $btnRun.UseVisualStyleBackColor = $true
    Add-ClickLogic $btnRun "Run Button"
    $bottomPanel.Controls.Add($btnRun)

    $btnStop = New-Object System.Windows.Forms.Button
    $btnStop.Text = "Stop"
    $btnStop.Size = New-Object System.Drawing.Size($btnWidth, $btnHeight)
    $btnStop.Location = New-Object System.Drawing.Point((20 + $btnWidth + 10), $btnY)
    $btnStop.UseVisualStyleBackColor = $true
    Add-ClickLogic $btnStop "Stop Button"
    $bottomPanel.Controls.Add($btnStop)

    $btnExit = New-Object System.Windows.Forms.Button
    $btnExit.Text = "Exit"
    $btnExit.Size = New-Object System.Drawing.Size($btnWidth, $btnHeight)
    $btnExit.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $btnExit.Location = New-Object System.Drawing.Point(($mainForm.Width - $btnWidth - 40), $btnY)
    $btnExit.UseVisualStyleBackColor = $true
    $btnExit.Add_Click({ $mainForm.Close() })
    $bottomPanel.Controls.Add($btnExit)

    # ---------------------------------------------------------
    # MAIN TABS SETUP
    # ---------------------------------------------------------
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Dock = "Fill"
    
    $tabHome = New-Object System.Windows.Forms.TabPage("Home")
    $tabHome.UseVisualStyleBackColor = $true
    
    $tabModern = New-Object System.Windows.Forms.TabPage("Modern Browser")
    $tabModern.UseVisualStyleBackColor = $true
    
    $tabLegacy = New-Object System.Windows.Forms.TabPage("Legacy Browser")
    $tabLegacy.UseVisualStyleBackColor = $true

    $tabGemini = New-Object System.Windows.Forms.TabPage("Gemini Chat")
    $tabGemini.UseVisualStyleBackColor = $true

    $tabExplorer = New-Object System.Windows.Forms.TabPage("File Explorer")
    $tabExplorer.UseVisualStyleBackColor = $true

    $tabControl.Controls.Add($tabHome)
    $tabControl.Controls.Add($tabGemini)
    $tabControl.Controls.Add($tabModern)
    $tabControl.Controls.Add($tabLegacy)
    $tabControl.Controls.Add($tabExplorer)
    
    $mainForm.Controls.Add($tabControl)
    $tabControl.BringToFront()

    # ---------------------------------------------------------
    # TAB 1: HOME (DASHBOARD)
    # ---------------------------------------------------------
    $dashPanel = New-Object System.Windows.Forms.Panel
    $dashPanel.Dock = "Fill"
    $dashPanel.BackColor = $Color_White
    $tabHome.Controls.Add($dashPanel)

    $dashHeader = New-Object System.Windows.Forms.Panel
    $dashHeader.Dock = "Top"
    $dashHeader.Height = 100
    $dashHeader.BackColor = [System.Drawing.Color]::Teal
    $dashPanel.Controls.Add($dashHeader)
    
    $logoSmall = New-Object System.Windows.Forms.PictureBox
    $logoSmall.Size = New-Object System.Drawing.Size(64, 64)
    $logoSmall.Location = New-Object System.Drawing.Point(30, 18)
    $logoSmall.SizeMode = "Zoom"
    if ($Icon_Main1) { $logoSmall.Image = $Icon_Main1.ToBitmap() }
    $dashHeader.Controls.Add($logoSmall)

    $dashTitle = New-Object System.Windows.Forms.Label
    $dashTitle.Text = "Welcome to EliteSoftware"
    $dashTitle.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $dashTitle.ForeColor = "White"
    $dashTitle.AutoSize = $true
    $dashTitle.Location = New-Object System.Drawing.Point(110, 25)
    $dashHeader.Controls.Add($dashTitle)

    $statusGroup = New-Object System.Windows.Forms.GroupBox
    $statusGroup.Text = "System Status"
    $statusGroup.Location = New-Object System.Drawing.Point(30, 120)
    $statusGroup.Size = New-Object System.Drawing.Size(400, 200)
    $dashPanel.Controls.Add($statusGroup)

    function Add-StatusIndicator {
        param($Parent, $Text, $IconObj, $Y)
        $p = New-Object System.Windows.Forms.Panel
        $p.Size = New-Object System.Drawing.Size(350, 40)
        $p.Location = New-Object System.Drawing.Point(20, $Y)
        
        $pic = New-Object System.Windows.Forms.PictureBox
        $pic.Size = New-Object System.Drawing.Size(32, 32)
        $pic.SizeMode = "Zoom"
        if ($IconObj) { $pic.Image = $IconObj.ToBitmap() }
        $p.Controls.Add($pic)

        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $Text
        $lbl.AutoSize = $true
        $lbl.Location = New-Object System.Drawing.Point(40, 8)
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $p.Controls.Add($lbl)
        
        $Parent.Controls.Add($p)
    }

    Add-StatusIndicator $statusGroup "Core Services: Operational" $Icon_Good 30
    Add-StatusIndicator $statusGroup "Network Link: Stable" $Icon_Good 70
    Add-StatusIndicator $statusGroup "Update Service: Idle" $Icon_NoStatus 110
    Add-StatusIndicator $statusGroup "Security Module: Active" $Icon_UAC 150

    # ---------------------------------------------------------
    # TAB 2 & 3: BROWSERS (LAZY LOADING)
    # ---------------------------------------------------------
    $browserModern = New-Object System.Windows.Forms.WebBrowser
    $browserModern.Dock = "Fill"
    $browserModern.ScriptErrorsSuppressed = $true
    $tabModern.Controls.Add($browserModern)

    $browserLegacy = New-Object System.Windows.Forms.WebBrowser
    $browserLegacy.Dock = "Fill"
    $browserLegacy.ScriptErrorsSuppressed = $false
    $tabLegacy.Controls.Add($browserLegacy)

    $tabControl.Add_SelectedIndexChanged({
            if ($tabControl.SelectedTab -eq $tabModern -and $browserModern.Url -eq $null) {
                $modernFile = Join-Path $HtmlDir "MODERN.HTML"
                if (Test-Path $modernFile) { $browserModern.Navigate($modernFile) }
            }
            if ($tabControl.SelectedTab -eq $tabLegacy -and $browserLegacy.Url -eq $null) {
                $legacyFile = Join-Path $HtmlDir "LEGACY.HTML"
                if (Test-Path $legacyFile) { $browserLegacy.Navigate($legacyFile) }
            }
        })

    # ---------------------------------------------------------
    # TAB 4: FILE EXPLORER (OVERHAULED)
    # ---------------------------------------------------------
    $expTopBar = New-Object System.Windows.Forms.Panel
    $expTopBar.Dock = "Top"
    $expTopBar.Height = 70 
    $expTopBar.Padding = New-Object System.Windows.Forms.Padding(5)
    $expTopBar.BackColor = [System.Drawing.Color]::WhiteSmoke
    $tabExplorer.Controls.Add($expTopBar)

    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Text = "Path:"
    $lblPath.AutoSize = $true
    $lblPath.Location = New-Object System.Drawing.Point(10, 14)
    $expTopBar.Controls.Add($lblPath)

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = New-Object System.Drawing.Point(50, 11)
    $txtPath.Width = 500
    $txtPath.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Top
    $txtPath.Text = "My Computer"
    $expTopBar.Controls.Add($txtPath)

    $btnGo = New-Object System.Windows.Forms.Button
    $btnGo.Text = "Go"
    $btnGo.UseVisualStyleBackColor = $true
    $btnGo.Size = New-Object System.Drawing.Size(40, 25)
    $btnGo.Location = New-Object System.Drawing.Point(555, 10)
    $expTopBar.Controls.Add($btnGo)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(620, 11)
    $txtSearch.Width = 200
    $expTopBar.Controls.Add($txtSearch)

    $btnSearch = New-Object System.Windows.Forms.Button
    $btnSearch.Text = "Search"
    $btnSearch.UseVisualStyleBackColor = $true
    $btnSearch.Size = New-Object System.Drawing.Size(60, 25)
    $btnSearch.Location = New-Object System.Drawing.Point(825, 10)
    $expTopBar.Controls.Add($btnSearch)

    $lblView = New-Object System.Windows.Forms.Label; $lblView.Text = "View:"; $lblView.AutoSize = $true; $lblView.Location = New-Object System.Drawing.Point(10, 45); $expTopBar.Controls.Add($lblView)
    $cmbView = New-Object System.Windows.Forms.ComboBox; $cmbView.DropDownStyle = "DropDownList"; $cmbView.Location = New-Object System.Drawing.Point(50, 42); $cmbView.Size = New-Object System.Drawing.Size(120, 25)
    $cmbView.Items.AddRange(@("Extra Large Icons", "Large Icons", "Medium Icons", "Small Icons", "List", "Details", "Tiles"))
    $cmbView.SelectedItem = "Details"
    $expTopBar.Controls.Add($cmbView)

    $lblSort = New-Object System.Windows.Forms.Label; $lblSort.Text = "Sort:"; $lblSort.AutoSize = $true; $lblSort.Location = New-Object System.Drawing.Point(190, 45); $expTopBar.Controls.Add($lblSort)
    $cmbSort = New-Object System.Windows.Forms.ComboBox; $cmbSort.DropDownStyle = "DropDownList"; $cmbSort.Location = New-Object System.Drawing.Point(230, 42); $cmbSort.Size = New-Object System.Drawing.Size(100, 25)
    $cmbSort.Items.AddRange(@("Name", "Size", "Type", "Date"))
    $cmbSort.SelectedItem = $Global:Settings.SortBy
    $expTopBar.Controls.Add($cmbSort)

    $lblGrp = New-Object System.Windows.Forms.Label; $lblGrp.Text = "Group:"; $lblGrp.AutoSize = $true; $lblGrp.Location = New-Object System.Drawing.Point(350, 45); $expTopBar.Controls.Add($lblGrp)
    $cmbGrp = New-Object System.Windows.Forms.ComboBox; $cmbGrp.DropDownStyle = "DropDownList"; $cmbGrp.Location = New-Object System.Drawing.Point(400, 42); $cmbGrp.Size = New-Object System.Drawing.Size(100, 25)
    $cmbGrp.Items.AddRange(@("None", "Type", "Date"))
    $cmbGrp.SelectedItem = $Global:Settings.GroupBy
    $expTopBar.Controls.Add($cmbGrp)


    # -- MAIN SPLIT --
    $splitMain = New-Object System.Windows.Forms.SplitContainer
    $splitMain.Dock = "Fill"
    $splitMain.Orientation = "Vertical"
    $splitMain.SplitterWidth = 5
    $tabExplorer.Controls.Add($splitMain)
    $splitMain.BringToFront()

    # -- RIGHT SPLIT --
    $splitRight = New-Object System.Windows.Forms.SplitContainer
    $splitRight.Dock = "Fill"
    if ($Global:Settings.InfoPanelPos -eq "Bottom") {
        $splitRight.Orientation = "Horizontal"
    }
    else {
        $splitRight.Orientation = "Vertical"
    }
    $splitRight.FixedPanel = "Panel2" 
    $splitMain.Panel2.Controls.Add($splitRight)

    # -- Controls --
    $tvFiles = New-Object System.Windows.Forms.TreeView
    $tvFiles.Dock = "Fill"
    $tvFiles.ShowLines = $true
    $tvFiles.ShowPlusMinus = $true
    $tvFiles.ImageList = $ilSmall
    $splitMain.Panel1.Controls.Add($tvFiles)

    $lvFiles = New-Object System.Windows.Forms.ListView
    $lvFiles.Dock = "Fill"
    $lvFiles.FullRowSelect = $true
    $lvFiles.GridLines = $false
    $lvFiles.SmallImageList = $ilSmall
    $lvFiles.LargeImageList = $ilLarge 
    $lvFiles.Columns.Add("Name", 250) | Out-Null
    $lvFiles.Columns.Add("Size", 100) | Out-Null
    $lvFiles.Columns.Add("Type", 120) | Out-Null
    $lvFiles.Columns.Add("Date Modified", 150) | Out-Null
    $splitRight.Panel1.Controls.Add($lvFiles)

    $grpMeta = New-Object System.Windows.Forms.GroupBox
    $grpMeta.Text = "Information"
    $grpMeta.Dock = "Fill"
    $splitRight.Panel2.Controls.Add($grpMeta)
    
    $lblMeta = New-Object System.Windows.Forms.Label
    $lblMeta.Dock = "Fill"
    $lblMeta.Text = "Select an item..."
    $lblMeta.Padding = New-Object System.Windows.Forms.Padding(10, 20, 10, 10) # Added Top Padding
    $grpMeta.Controls.Add($lblMeta)

    # Explorer Logic
    $rootNode = $tvFiles.Nodes.Add("My Computer")
    $rootNode.ImageKey = "Drive"
    $rootNode.SelectedImageKey = "Drive"
    $rootNode.Tag = "ROOT"
    $drives = [System.IO.DriveInfo]::GetDrives()
    foreach ($drive in $drives) {
        if ($drive.IsReady) {
            $node = $rootNode.Nodes.Add("$($drive.Name) ($($drive.VolumeLabel))")
            $node.Tag = $drive.RootDirectory.FullName
            if ($drive.Name -match "C") { 
                $node.ImageKey = "C-Drive"; $node.SelectedImageKey = "C-Drive"
            }
            else {
                $node.ImageKey = "Drive"; $node.SelectedImageKey = "Drive"
            }
            $node.Nodes.Add("Dummy") | Out-Null
        }
    }
    $rootNode.Expand()

    $tvFiles.Add_BeforeExpand({
            param($sender, $e)
            if ($e.Node.Nodes.Count -eq 1 -and $e.Node.Nodes[0].Text -eq "Dummy") {
                $e.Node.Nodes.Clear()
                $path = $e.Node.Tag
                try {
                    $dirs = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
                    foreach ($dir in $dirs) {
                        $newNode = $e.Node.Nodes.Add($dir.Name)
                        $newNode.Tag = $dir.FullName
                        $newNode.ImageKey = "Folder"; $newNode.SelectedImageKey = "Folder"
                        $newNode.Nodes.Add("Dummy") | Out-Null
                    }
                }
                catch {}
            }
        })

    $Script:CurrentPath = "ROOT"
    
    function Group-Items {
        $lvFiles.Groups.Clear()
        if ($cmbGrp.SelectedItem -eq "None") { $lvFiles.ShowGroups = $false; return }
        $lvFiles.ShowGroups = $true
        
        $groups = @{}
        foreach ($item in $lvFiles.Items) {
            $key = "Other"
            if ($cmbGrp.SelectedItem -eq "Type") { $key = $item.SubItems[2].Text }
            if ($cmbGrp.SelectedItem -eq "Date") { $key = $item.SubItems[3].Text.Split(' ')[0] } # Just date part
            
            if (-not $groups.ContainsKey($key)) {
                $groups[$key] = $lvFiles.Groups.Add($key, $key)
            }
            $item.Group = $groups[$key]
        }
    }

    function Load-ListView {
        param($path)
        $lvFiles.BeginUpdate()
        $lvFiles.Items.Clear()
        $txtPath.Text = $path
        $Script:CurrentPath = $path

        if ($path -eq "ROOT") {
            foreach ($d in $drives) {
                if ($d.IsReady) {
                    $iconKey = if ($d.Name -match "C") { "C-Drive" } else { "Drive" }
                    $item = $lvFiles.Items.Add($d.Name, $iconKey)
                    $item.SubItems.Add($d.TotalSize)
                    $item.SubItems.Add("Local Disk")
                    $item.Tag = $d.RootDirectory.FullName
                }
            }
        }
        else {
            try {
                $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                # Sort logic
                if ($cmbSort.SelectedItem -eq "Size") { $items = $items | Sort-Object Length -Descending }
                elseif ($cmbSort.SelectedItem -eq "Date") { $items = $items | Sort-Object LastWriteTime -Descending }
                elseif ($cmbSort.SelectedItem -eq "Type") { $items = $items | Sort-Object Extension }
                else { $items = $items | Sort-Object Name }

                foreach ($i in $items) {
                    $iconKey = "File"
                    $type = "File"
                    
                    if ($i.PSIsContainer) { 
                        $iconKey = "Folder"; $type = "Folder" 
                    }
                    elseif ($i.Extension -match "zip|rar|7z") { 
                        $iconKey = "Zip"; $type = "Archive" 
                    } 
                    else {
                        # EXTRACT ICON LOGIC
                        $ext = $i.Extension
                        if (-not $ilSmall.Images.ContainsKey($ext)) {
                            try {
                                $extracted = [System.Drawing.Icon]::ExtractAssociatedIcon($i.FullName)
                                if ($extracted) {
                                    $ilSmall.Images.Add($ext, $extracted)
                                    $ilMedium.Images.Add($ext, $extracted)
                                    $ilLarge.Images.Add($ext, $extracted)
                                    $ilExtra.Images.Add($ext, $extracted)
                                }
                            }
                            catch {}
                        }
                        if ($ilSmall.Images.ContainsKey($ext)) { $iconKey = $ext }
                    }
                    
                    $item = $lvFiles.Items.Add($i.Name, $iconKey)
                    $sizeStr = if ($i.PSIsContainer) { "" } else { "{0:N0} KB" -f ($i.Length / 1KB) }
                    $item.SubItems.Add($sizeStr)
                    $item.SubItems.Add($type)
                    $item.SubItems.Add($i.LastWriteTime.ToString())
                    $item.Tag = $i.FullName
                }
            }
            catch { $lvFiles.Items.Add("Error reading path") }
        }
        Group-Items
        $lvFiles.EndUpdate()
    }
    
    $txtPath.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq 'Enter') { $e.SuppressKeyPress = $true; if (Test-Path $txtPath.Text) { Load-ListView $txtPath.Text } }
        })

    $tvFiles.Add_AfterSelect({ param($sender, $e); Load-ListView $e.Node.Tag })
    $lvFiles.Add_DoubleClick({ 
            if ($lvFiles.SelectedItems.Count -gt 0) {
                $tag = $lvFiles.SelectedItems[0].Tag
                if ($tag -and (Test-Path $tag -PathType Container)) { Load-ListView $tag }
                elseif ($tag -and (Test-Path $tag -PathType Leaf)) { [System.Diagnostics.Process]::Start($tag) }
            }
        })
    $lvFiles.Add_SelectedIndexChanged({
            if ($lvFiles.SelectedItems.Count -gt 0) {
                $tag = $lvFiles.SelectedItems[0].Tag
                if ($tag -ne $null -and (Test-Path $tag)) {
                    $item = Get-Item $tag
                    $info = "Name: $($item.Name)`nType: $($item.GetType().Name)`n"
                    if ($item -is [System.IO.FileInfo]) { $info += "Size: {0:N2} MB`n" -f ($item.Length / 1MB) }
                    $info += "Modified: $($item.LastWriteTime)"
                    $lblMeta.Text = $info
                }
            }
        })

    $cmbView.Add_SelectedIndexChanged({
            $v = $cmbView.SelectedItem
            $Global:Settings.ViewMode = $v
            switch ($v) {
                "Extra Large Icons" { $lvFiles.LargeImageList = $ilExtra; $lvFiles.View = "LargeIcon" }
                "Large Icons" { $lvFiles.LargeImageList = $ilLarge; $lvFiles.View = "LargeIcon" }
                "Medium Icons" { $lvFiles.LargeImageList = $ilMedium; $lvFiles.View = "LargeIcon" }
                "Small Icons" { $lvFiles.View = "SmallIcon" }
                "List" { $lvFiles.View = "List" }
                "Details" { $lvFiles.View = "Details" }
                "Tiles" { $lvFiles.View = "Tile"; $lvFiles.TileSize = New-Object System.Drawing.Size(200, 50) }
            }
        })

    $cmbGrp.Add_SelectedIndexChanged({ Group-Items })
    $cmbSort.Add_SelectedIndexChanged({ Load-ListView $Script:CurrentPath })

    $btnGo.Add_Click({ if (Test-Path $txtPath.Text) { Load-ListView $txtPath.Text } })

    # ---------------------------------------------------------
    # TAB: GEMINI CHAT
    # ---------------------------------------------------------
    $gemPanel = New-Object System.Windows.Forms.Panel
    $gemPanel.Dock = "Fill"
    $gemPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    $gemPanel.BackColor = $Color_White
    $tabGemini.Controls.Add($gemPanel)

    # WebBrowser Setup - Direct attachment to main panel (Fixes Null Reference Crash)
    $wbChat = New-Object System.Windows.Forms.WebBrowser
    $wbChat.Dock = "Fill"
    $wbChat.ScriptErrorsSuppressed = $true
    $wbChat.ScrollBarsEnabled = $false # HTML handles scrolling
    $gemPanel.Controls.Add($wbChat)

    # Load the Local HTML Interface
    $htmlPath = "$ScriptBaseDir\Resources\HTML\GeminiApp.html"
    if (Test-Path $htmlPath) {
        $wbChat.Navigate($htmlPath)
    }
    else {
        $wbChat.DocumentText = "<h1>Error: Resources/HTML/GeminiApp.html not found!</h1>"
    }

    # ---------------------------------------------------------
    # HYBRID INTEROP LOGIC (The Bridge)
    # ---------------------------------------------------------
    $wbChat.Add_Navigating({
            param($source, $e)
        
            $url = $e.Url.ToString()
        
            # Check for our custom protocol 'gemini:'
            if ($url.StartsWith("gemini:")) {
                $e.Cancel = $true # Stop actual navigation
            
                # Parse Action
                if ($url -match "gemini:send\?model=(.*?)&msg=(.*)") {
                    # Decode Query Params (Use System.Net.WebUtility for PWSH Core compatibility)
                    $rawModel = [System.Net.WebUtility]::UrlDecode($matches[1])
                    $rawMsg = [System.Net.WebUtility]::UrlDecode($matches[2])
                
                    # Run API Call Asynchronously to keep UI responsive
                    # Note: WinForms requires UI updates on main thread
                
                    $response = Invoke-GeminiAPI -Prompt $rawMsg -Model $rawModel
                
                    # ESCAPE FOR JAVASCRIPT INJECTION
                    $cleanResponse = $response.Replace("\", "\\").Replace("'", "\'").Replace("`r", "").Replace("`n", "\n")
                
                    # Inject Response back into HTML
                    $wbChat.Document.InvokeScript("addMessage", @("gemini", $cleanResponse))
                    Write-Log "Chat turn completed." "INFO"
                }
                elseif ($url -eq "gemini:clear") {
                    $Global:ChatHistory = @()
                    Write-Log "Chat cleared via HTML." "INFO"
                }
                elseif ($url -eq "gemini:save") {
                    # Implement Save Logic here if needed or keep existing HTML redirection
                    Write-Log "Save requested." "INFO"
                }
            }
        })
    
    # System.Web is not needed for System.Net.WebUtility
    
    # Middle (Chat WebBrowser)
    # $wbChat = New-Object System.Windows.Forms.WebBrowser # This is now defined above
    # $wbChat.Dock = "Fill"
    # $wbChat.ScriptErrorsSuppressed = $true
    # $gemMid.Controls.Add($wbChat)

    # Legacy UI functions removed to prevent overwriting GeminiApp.html
    # Layout init logic follows...

    # Initial Layout
    $mainForm.Add_Load({
            try {
                if ($Global:Settings.SplitTree -gt 50) { $splitMain.SplitterDistance = $Global:Settings.SplitTree }
            
                $dim = if ($splitRight.Orientation -eq "Vertical") { $splitRight.Width } else { $splitRight.Height }
                $safeMeta = $dim - $Global:Settings.SplitMeta
                if ($safeMeta -gt 50 -and $safeMeta -lt ($dim - 50)) {
                    $splitRight.SplitterDistance = $safeMeta
                }
                $cmbView.SelectedItem = $Global:Settings.ViewMode
            }
            catch {}
        })
    
    $splitMain.Add_SplitterMoved({ $Global:Settings.SplitTree = $splitMain.SplitterDistance; Save-Config })
    $splitRight.Add_SplitterMoved({ 
            $dim = if ($splitRight.Orientation -eq "Vertical") { $splitRight.Width } else { $splitRight.Height }
            $Global:Settings.SplitMeta = $dim - $splitRight.SplitterDistance
            Save-Config 
        })

    # ---------------------------------------------------------
    # Display Form
    # ---------------------------------------------------------
    $mainForm.ShowDialog() | Out-Null

}
catch {
    Write-Host "CRITICAL ERROR OCCURRED:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Read-Host "Press Enter to exit..."
}