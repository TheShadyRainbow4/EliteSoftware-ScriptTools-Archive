<#
.SYNOPSIS
    Opti-Link Instant Messenger - v0.7.0.0
    Created by: EliteSoftware Enterprises / Zachary Whiteman / Google Gemini Ai
    Date: 11/15/2025
    Time: 09:08 AM

.DESCRIPTION
    A custom PowerShell chat client for LM Studio.
    
    v0.7.0.0:
    - MAJOR REFACTOR: Replaced RichTextBox with WebBrowser control for Chat Bubbles.
    - Rewrote Append-Text to inject HTML/CSS for bubble styling.
    - CRITICAL FIX: Expanded Save/Load-Config to handle ALL UI settings.
      This fixes the icon bug and all other settings persistence issues.
    - Restored all tabs: Chat, Connection, Model Parameters, Prompt Template, Downloaded Models.
    - Restored full custom "About" and "Changelog" windows from v0.4.0.0.
    - UI FIX: Fixed control overlap on "Prompt Template" tab.
    - UI FIX: Removed all custom button colors from dialogs.
    - THEME: Removed gradient. Set main window to solid Teal.
    - THEME: Added custom renderer to make MenuStrip items Blue on hover.
    - THEME: Placed TabControl in a Teal-backed Panel to create background effect.
    - GGUF: Added "Backend" tab to Settings to toggle LM Studio/Local GGUF.
    - GGUF: Added button to download and unzip llama.cpp into config subfolders.
#>

# 1. --- ASSEMBLY LOADING ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. --- GLOBAL VARIABLES & APP VERSION ---
$Global:AppVersion = "1.0.3.7"
$Global:ChatHistory = @()
$Global:TealThemeEnabled = $true
$Global:SelectedGGUFModelPath = ""

# 3. --- ENABLE VISUAL STYLES ---
[System.Windows.Forms.Application]::EnableVisualStyles()

# 4. --- CONFIGURATION & PERSISTENCE ---

# --- Define portable config paths ---
# Reverted to the most reliable method for finding the script's own directory.
$ScriptBaseDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ConfigDir = [System.IO.Path]::Combine($ScriptBaseDir, "OptiLink_Config")

$ConfigIconDir = [System.IO.Path]::Combine($ConfigDir, "Icons")
$GGUFDir = [System.IO.Path]::Combine($ConfigDir, "GGUF")
$InterfaceDir = [System.IO.Path]::Combine($ConfigDir, "Interface Framework")
$ConfigFile = [System.IO.Path]::Combine($ConfigDir, "settings.json")

# --- Define Log paths ---
$LogFilesDir = [System.IO.Path]::Combine($ConfigDir, "Log Files")
$ErrorLogDir = [System.IO.Path]::Combine($LogFilesDir, "Error Logs")
$HistoricalLogDir = [System.IO.Path]::Combine($LogFilesDir, "Historical Logs")
$HistoricalErrorLogDir = [System.IO.Path]::Combine($ErrorLogDir, "Historical Logs")
$Global:LiveLogFile = [System.IO.Path]::Combine($LogFilesDir, "LiveLog.json")

# --- Ensure ALL config directories exist ---
@($ConfigDir, $ConfigIconDir, $GGUFDir, $InterfaceDir, $LogFilesDir, $ErrorLogDir, $HistoricalLogDir, $HistoricalErrorLogDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -Path $_ -ItemType Directory -Force | Out-Null }
}

# --- LOGGING & ARCHIVING ---

function Archive-OldLogs {
    # Archive LiveLog.json if it exists
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
            # Assuming file names are already timestamped, just move them
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

    # If the severity is a warning, also write it to the console warning stream.
    if ($Severity -eq "WARN") {
        Write-Warning $Message
    }

    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Severity  = $Severity
        Message   = $Message
    }

    try {
        $logEntry | ConvertTo-Json | Add-Content -Path $Global:LiveLogFile
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

    # --- CONSOLE OUTPUT ---
    # Per user request, ensure errors are still written to the console.
    Write-Error -ErrorRecord $ErrorRecord

    # --- FILE LOGGING ---
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
        
        # Also write a summary to the main LiveLog
        Write-Log -Message "An error occurred. Details saved to ErrorLog-$fileNameTimestamp.json. Context: $ContextMessage" -Severity "ERROR"
    }
    catch {
        Write-Warning "Could not write to error log: $($_.Exception.Message)"
    }
}

# --- Run Archiving at Startup ---
Archive-OldLogs

# --- **REBUILT** Save-Config (Saves EVERYTHING) ---
function Save-Config {
    param (
        $SettingsObject
    )
    try {
        $SettingsObject | ConvertTo-Json -Depth 5 | Out-File -FilePath $Global:ConfigFile -Encoding UTF8
    }
    catch { Write-ErrorLog -ContextMessage "Failed to save settings to settings.json" -ErrorRecord $_ }
}

# --- **REBUILT** Load-Config (Returns one object) ---
function Load-Config {
    if (Test-Path $Global:ConfigFile) {
        try { return (Get-Content -Path $Global:ConfigFile -Raw | ConvertFrom-Json) }
        catch {
            Write-ErrorLog -ContextMessage "Failed to parse settings.json" -ErrorRecord $_
            return $null
        }
    }
    return $null
}

function Apply-Theme {
    param(
        $Form,
        $MenuBar,
        $TabBackgroundPanel,
        $MenuBarShadow
    )

    if ($Global:TealThemeEnabled) {
        $baseColor = [System.Drawing.Color]::FromArgb(255, 0, 108, 108) # Darker Teal
        $highlightColor = [System.Drawing.Color]::Blue
        $formColor = [System.Drawing.Color]::Teal
    }
    else {
        $baseColor = [System.Drawing.SystemColors]::ControlDark
        $highlightColor = [System.Drawing.SystemColors]::Highlight
        $formColor = [System.Drawing.SystemColors]::Control
    }

    $Form.BackColor = $formColor
    $TabBackgroundPanel.BackColor = $formColor
    $MenuBar.BackColor = $baseColor
    $MenuBarShadow.BackColor = if ($Global:TealThemeEnabled) { [System.Drawing.Color]::Black } else { [System.Drawing.SystemColors]::ControlDarkDark }
    $MenuBar.Renderer = [ThemedMenuRenderer]::new($baseColor, $highlightColor)
}

function Apply-AppIcon {
    param (
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.NotifyIcon]$TrayIcon,
        [System.Windows.Forms.PictureBox]$PicBox1,
        [System.Windows.Forms.PictureBox]$PicBox2,
        [string]$RelativeIconPath
    )
    if (-not ([string]::IsNullOrEmpty($RelativeIconPath))) {
        $FullIconPath = [System.IO.Path]::Combine($Global:ConfigDir, $RelativeIconPath)
        if (Test-Path $FullIconPath) {
            try {
                $icon = [System.Drawing.Icon]::new($FullIconPath)
                $Form.Icon = $icon
                $TrayIcon.Icon = $icon
                $PicBox1.Image = $icon.ToBitmap()
                $PicBox2.Image = $icon.ToBitmap()
            }
            catch { Write-ErrorLog -ContextMessage "Failed to load custom icon" -ErrorRecord $_ }
        }
    }
}

# --- **REBUILT** Append-Text (For Chat Bubbles) ---
function Append-Text {
    param (
        [System.Windows.Forms.WebBrowser]$Browser,
        [string]$Text,
        [string]$UserRole, # "user" or "ai"
        [switch]$StartStream # Indicates this is the start of a streaming AI message
    )
    
    if ($Browser.Document -eq $null) {
        Write-Log -Message "WebBrowser document not ready to append text." -Severity "WARN"
        return
    }
    
    try {
        $doc = $Browser.Document
        $body = $doc.Body
        
        $messageDiv = $doc.CreateElement("div")
        $messageDiv.SetAttribute("className", "message $UserRole")

        if ($UserRole -eq "ai" -and $StartStream) {
            $messageDiv.Id = "ai-streaming-message" # Assign a unique ID for streaming updates
            $messageDiv.InnerText = $Text
            $body.AppendChild($messageDiv)
        } elseif ($UserRole -eq "ai" -and (-not $StartStream)) {
            # This is a non-streaming AI message, just append
            $messageDiv.InnerText = $Text
            $body.AppendChild($messageDiv)
        } else { # User message
            $messageDiv.InnerText = $Text
            $body.AppendChild($messageDiv)
        }
        
        # Auto-scroll to bottom
        $body.SetAttribute("scrollTop", $body.GetAttribute("scrollHeight"))
    }
    catch {
        Write-ErrorLog -ContextMessage "Failed to append HTML text to chat browser" -ErrorRecord $_
    }
}

function Update-LastAIMessageThreadSafe {
    param (
        [System.Windows.Forms.WebBrowser]$Browser,
        [string]$TextToAppend
    )
    
    if ($Browser.InvokeRequired) {
        $Browser.Invoke([System.Action[System.Windows.Forms.WebBrowser, System.String]]{
            param($b, $t)
            Update-LastAIMessageThreadSafe -Browser $b -TextToAppend $t
        }, $Browser, $TextToAppend)
    } else {
        if ($Browser.Document -eq $null) {
            Write-Log -Message "WebBrowser document not ready for thread-safe update." -Severity "WARN"
            return
        }
        
        try {
            $doc = $Browser.Document
            $aiMessageDiv = $doc.GetElementById("ai-streaming-message")
            
            if ($aiMessageDiv) {
                # Append text to the existing AI message div
                $aiMessageDiv.InnerText += $TextToAppend
                # Auto-scroll to bottom
                $doc.Body.SetAttribute("scrollTop", $doc.Body.GetAttribute("scrollHeight"))
            } else {
                # If for some reason the div doesn't exist, create it and append
                Append-Text -Browser $Browser -Text $TextToAppend -UserRole "ai" -StartStream
                Write-Log -Message "Created new AI streaming div unexpectedly." -Severity "WARN"
            }
        }
        catch {
            Write-ErrorLog -ContextMessage "Failed to update thread-safe AI message in chat browser" -ErrorRecord $_
        }
    }
}

# --- Helper Function to pretty-print file size ---
function Format-Bytes {
    param ($bytes)
    $suffixes = @("B", "KB", "MB", "GB", "TB", "PB")
    $index = 0
    while ($bytes -ge 1024 -and $index -lt ($suffixes.Length - 1)) {
        $bytes /= 1024
        $index++
    }
    return [string]::Format("{0:N2} {1}", $bytes, $suffixes[$index])
}

function Update-ModelStatusLabel {
    if ($Global:BackendPreference -eq "Local GGUF (Experimental)") {
        if (-not [string]::IsNullOrWhiteSpace($Global:SelectedGGUFModelPath)) {
            $modelName = [System.IO.Path]::GetFileName($Global:SelectedGGUFModelPath)
            $ModelStatusLabel.Text = "Local: $modelName"
        } else {
            $ModelStatusLabel.Text = "Local: No model selected"
        }
    } else {
        $modelId = $null
        if ($ModelComboBox.SelectedItem) { $modelId = $ModelComboBox.SelectedItem.ToString() }
        else { $modelId = $ModelIdBox.Text }

        if (-not [string]::IsNullOrWhiteSpace($modelId)) {
            $ModelStatusLabel.Text = "LM Studio: $modelId"
        } else {
            $ModelStatusLabel.Text = "LM Studio: No model selected"
        }
    }
}

# --- **NEW** Function to run llama-cli in a dedicated, stable Runspace ---
function Invoke-LlamaInRunspace {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LlamaCliPath,
        [Parameter(Mandatory=$true)]
        [System.Collections.Generic.List[string]]$ArgumentList
    )

    $runspace = $null
    $powershell = $null

    try {
        # Create a new runspace to isolate the process
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $runspace.Open()

        # Create a PowerShell object within the new runspace
        $powershell = [System.Management.Automation.PowerShell]::Create()
        $powershell.Runspace = $runspace

        # Add the command and its arguments
        $powershell.AddCommand($LlamaCliPath)
        foreach ($arg in $ArgumentList) {
            $powershell.AddArgument($arg)
        }
        
        # Add a command to merge the error stream into the output stream
        # This ensures we capture both stdout and stderr from llama-cli.exe
        $powershell.AddCommand("Out-String").AddParameter("Stream")

        # Invoke the command and return the results as a stream
        return $powershell.Invoke()
    }
    catch {
        # Log any exceptions that occur during the setup or invocation
        Write-ErrorLog -ContextMessage "A critical error occurred while trying to invoke llama-cli in a new runspace." -ErrorRecord $_
        return $null # Return null to indicate failure
    }
    finally {
        # Clean up the PowerShell object and the runspace
        if ($powershell -ne $null) {
            $powershell.Dispose()
        }
        if ($runspace -ne $null) {
            $runspace.Dispose()
        }
    }
}


# Defer parsing of the ThemedMenuRenderer class by defining it as a string
# and invoking it after the required assemblies are loaded. This prevents a
# ParserError in both pwsh.exe and powershell.exe.
$ThemedMenuRendererClassDefinition = @'
class ThemedMenuRenderer : System.Windows.Forms.ToolStripProfessionalRenderer {
    [System.Drawing.Brush]$baseBrush
    [System.Drawing.Brush]$highlightBrush

    ThemedMenuRenderer([System.Drawing.Color]$baseColor, [System.Drawing.Color]$highlightColor) {
        $this.baseBrush = [System.Drawing.SolidBrush]::new($baseColor)
        $this.highlightBrush = [System.Drawing.SolidBrush]::new($highlightColor)
    }
    
    # Override menu item background
    [void] OnRenderMenuItemBackground($e) {
        if ($e.Item.Selected -or $e.Item.Pressed) {
            [void]$e.Graphics.FillRectangle($this.highlightBrush, $e.Item.ContentRectangle)
        }
        else {
            [void]$e.Graphics.FillRectangle($this.baseBrush, $e.Item.ContentRectangle)
        }
        
        # Draw the text
        $textColor = [System.Drawing.Color]::White
        $textFormat = [System.Windows.Forms.TextFormatFlags]::Default
        [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics, $e.Item.Text, $e.Item.Font, $e.Item.ContentRectangle, $textColor, $textFormat)
    }
    
    # Override menu background
    [void] OnRenderImageMargin($e) {
        [void]$e.Graphics.FillRectangle($this.baseBrush, $e.AffectedBounds)
    }
    [void] OnRenderDropDownBackground($e) {
        [void]$e.Graphics.FillRectangle($this.baseBrush, $e.AffectedBounds)
    }
}
'@
Invoke-Expression -Command $ThemedMenuRendererClassDefinition


# 5. --- FORM INITIALIZATION ---
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "OptiLink Instant Messenger"
$MainForm.Size = New-Object System.Drawing.Size(480, 700) 
$MainForm.MinimumSize = New-Object System.Drawing.Size(400, 500)
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
# Form background color is now set by Apply-Theme
$Global:CurrentIconPath = $null
$Global:SendKeyPreference = "Ctrl+Enter" 
$Global:BackendPreference = "LM Studio (Network)"
$Global:LlamaCppPath = ""
$Global:LlamaProcess = $null


# 6. --- CONTROLS ---

# --- ToolTip Component ---
$ToolTip = New-Object System.Windows.Forms.ToolTip
$ToolTip.AutoPopDelay = 10000 
$ToolTip.InitialDelay = 500

# --- Menu Bar ---
$MenuBar = New-Object System.Windows.Forms.MenuStrip
$MenuBar.Dock = [System.Windows.Forms.DockStyle]::Top
$MenuBar.ForeColor = [System.Drawing.Color]::White 
# MenuBar.BackColor and .Renderer are now set by Apply-Theme

$FileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&File")
$FileLaunchLMStudioMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Launch LM Studio")
$FileImportGGUFMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Import GGUF Model...")
$FileImportGGUFMenuItem.Enabled = $false 
$FileExportChatMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Export Chat As...")
$FileExportChatMenuItem.Enabled = $false 
$FileSettingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Settings...")
$FileExitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Exit")
$FileMenuItem.DropDownItems.AddRange(@(
    $FileLaunchLMStudioMenuItem,
    $FileImportGGUFMenuItem,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $FileExportChatMenuItem,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $FileSettingsMenuItem,
    $FileExitMenuItem
))

$HelpMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Help")
$HelpChangelogMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Changelog...")
$HelpAboutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&About...")
$HelpMenuItem.DropDownItems.AddRange(@($HelpChangelogMenuItem, $HelpAboutMenuItem))

$MenuBar.Items.AddRange(@($FileMenuItem, $HelpMenuItem))
$MainForm.Controls.Add($MenuBar)

# --- Menu Bar Shadow ---
$MenuBarShadow = New-Object System.Windows.Forms.Panel
$MenuBarShadow.Height = 1
$MenuBarShadow.Dock = [System.Windows.Forms.DockStyle]::Top
$MenuBarShadow.BackColor = [System.Drawing.Color]::Black
$MainForm.Controls.Add($MenuBarShadow)

# --- Status Bar ---
$StatusBar = New-Object System.Windows.Forms.StatusStrip
$StatusBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
$StatusBar.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLabel.Text = "Ready."
$StatusLabel.BackColor = [System.Drawing.Color]::Transparent
$VersionLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$VersionLabel.Text = "v$Global:AppVersion"
$VersionLabel.Alignment = [System.Windows.Forms.ToolStripItemAlignment]::Right
$VersionLabel.BackColor = [System.Drawing.Color]::Transparent
$StatusBar.Items.AddRange(@($StatusLabel, $VersionLabel))
$MainForm.Controls.Add($StatusBar)

# --- System Tray Icon ---
$TrayIcon = New-Object System.Windows.Forms.NotifyIcon
$TrayIcon.Text = "OptiLink Instant Messenger"
$TrayIcon.Visible = $true
$TrayContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$TrayMenuShow = New-Object System.Windows.Forms.ToolStripMenuItem("&Show")
$TrayMenuExit = New-Object System.Windows.Forms.ToolStripMenuItem("&Exit")
$TrayContextMenu.Items.AddRange(@($TrayMenuShow, $TrayMenuExit))
$TrayIcon.ContextMenuStrip = $TrayContextMenu

# --- **NEW** Tab Background Panel ---
$TabBackgroundPanel = New-Object System.Windows.Forms.Panel
$TabBackgroundPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
# TabBackgroundPanel.BackColor is now set by Apply-Theme
$TabBackgroundPanel.Padding = New-Object System.Windows.Forms.Padding(5, 35, 5, 25) # Creates space at top and bottom
$MainForm.Controls.Add($TabBackgroundPanel)

# --- Tab Control ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Dock = [System.Windows.Forms.DockStyle]::Fill # Docks inside the panel
$TabControl.Multiline = $true
# Removed custom drawing

# ---TAB 1: Chat Interface ---
$TabPageChat = New-Object System.Windows.Forms.TabPage
$TabPageChat.Text = "Chat"

$TopChatPanel = New-Object System.Windows.Forms.Panel
$TopChatPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$TopChatPanel.Height = 26
$ChatIconPreview = New-Object System.Windows.Forms.PictureBox
$ChatIconPreview.Size = New-Object System.Drawing.Size(16, 16)
$ChatIconPreview.Location = New-Object System.Drawing.Point(5, 5)
$ChatIconPreview.SizeMode = "StretchImage"

$ModelStatusLabel = New-Object System.Windows.Forms.Label
$ModelStatusLabel.Text = "No model loaded"
$ModelStatusLabel.Location = New-Object System.Drawing.Point(25, 5)
$ModelStatusLabel.Size = New-Object System.Drawing.Size(400, 20)
$ModelStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$ModelStatusLabel.ForeColor = [System.Drawing.SystemColors]::GrayText

$TopChatPanel.Controls.AddRange(@($ChatIconPreview, $ModelStatusLabel))

$InputPanel = New-Object System.Windows.Forms.Panel
$InputPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$InputPanel.Height = 60 
$InputPanel.Padding = New-Object System.Windows.Forms.Padding(5)

$ButtonsPanel = New-Object System.Windows.Forms.Panel
$ButtonsPanel.Dock = [System.Windows.Forms.DockStyle]::Right
$ButtonsPanel.Width = 75

$StopButton = New-Object System.Windows.Forms.Button
$StopButton.Text = "Stop"
$StopButton.Dock = [System.Windows.Forms.DockStyle]::Top
$StopButton.Height = 25 # Half of the panel's client area height
$StopButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$StopButton.Enabled = $false # Initially disabled

$SendButton = New-Object System.Windows.Forms.Button
$SendButton.Text = "Send"
$SendButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
$SendButton.Height = 25 # Half of the panel's client area height
$SendButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) 

$ButtonsPanel.Controls.AddRange(@($StopButton, $SendButton))

$UserInputBox = New-Object System.Windows.Forms.TextBox
$UserInputBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$UserInputBox.Multiline = $true
$UserInputBox.ScrollBars = "Vertical"
$InputPanel.Controls.AddRange(@($UserInputBox, $ButtonsPanel))

# --- **NEW** WebBrowser Control for Chat ---
$ChatBrowser = New-Object System.Windows.Forms.WebBrowser
$ChatBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
$ChatBrowser.AllowNavigation = $false
$ChatBrowser.AllowWebBrowserDrop = $false
$ChatBrowser.IsWebBrowserContextMenuEnabled = $false
$ChatBrowser.ScriptErrorsSuppressed = $true
$ChatBrowser.ScrollBarsEnabled = $true

# Initialize with styles
$ChatHtml = @"
<html>
<head>
    <meta http-equiv='X-UA-Compatible' content='IE=edge'>
    <style>
        body { 
            font-family: 'Segoe UI', sans-serif; 
            font-size: 10pt; 
            margin: 0; 
            padding: 10px; 
            background-color: #FFFFFF;
        }
        .message {
            max-width: 80%;
            padding: 8px 12px;
            margin-bottom: 8px;
            border-radius: 12px;
            line-height: 1.4;
            word-wrap: break-word;
        }
        .user {
            background-color: #0078D7;
            color: white;
            margin-left: auto;
            border-bottom-right-radius: 0;
        }
        .ai {
            background-color: #F1F1F1;
            color: black;
            margin-right: auto;
            border-bottom-left-radius: 0;
        }
    </style>
</head>
<body>
    <div class='message ai'>Welcome! Configure your connection and model settings first.</div>
</body>
</html>
"@
$ChatBrowser.DocumentText = $ChatHtml

$TabPageChat.Controls.AddRange(@($ChatBrowser, $InputPanel, $TopChatPanel))


# --- TAB 2: Connection Settings ---
$TabPageSettings = New-Object System.Windows.Forms.TabPage
$TabPageSettings.Text = "Connection"
$TabPageSettings.Padding = New-Object System.Windows.Forms.Padding(10)

$TopSettingsPanel = New-Object System.Windows.Forms.Panel
$TopSettingsPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$TopSettingsPanel.Height = 26
$SettingsIconPreview = New-Object System.Windows.Forms.PictureBox
$SettingsIconPreview.Size = New-Object System.Drawing.Size(16, 16)
$SettingsIconPreview.Location = New-Object System.Drawing.Point(10, 5) 
$SettingsIconPreview.SizeMode = "StretchImage"
$TopSettingsPanel.Controls.Add($SettingsIconPreview)

$SettingsPanel = New-Object System.Windows.Forms.Panel
$SettingsPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$ServerGroupBox = New-Object System.Windows.Forms.GroupBox
$ServerGroupBox.Text = "Server Connection"
$ServerGroupBox.Anchor = "Top, Left, Right"
$ServerGroupBox.Size = New-Object System.Drawing.Size(400, 90)
$ServerGroupBox.Location = New-Object System.Drawing.Point(10, 10) 
$UrlLabel = New-Object System.Windows.Forms.Label
$UrlLabel.Text = "URL / IP:"
$UrlLabel.Location = New-Object System.Drawing.Point(10, 25)
$UrlLabel.Size = New-Object System.Drawing.Size(60, 20)
$UrlLabel.BackColor = [System.Drawing.Color]::Transparent
$UrlBox = New-Object System.Windows.Forms.TextBox
$UrlBox.Text = "http://localhost"
$UrlBox.Location = New-Object System.Drawing.Point(75, 22)
$UrlBox.Size = New-Object System.Drawing.Size(310, 20)
$PortLabel = New-Object System.Windows.Forms.Label
$PortLabel.Text = "Port:"
$PortLabel.Location = New-Object System.Drawing.Point(10, 55)
$PortLabel.Size = New-Object System.Drawing.Size(60, 20)
$PortLabel.BackColor = [System.Drawing.Color]::Transparent
$PortBox = New-Object System.Windows.Forms.TextBox
$PortBox.Text = "1234"
$PortBox.Location = New-Object System.Drawing.Point(75, 52)
$PortBox.Size = New-Object System.Drawing.Size(100, 20)
$ServerGroupBox.Controls.AddRange(@($UrlLabel, $UrlBox, $PortLabel, $PortBox))
$ModelGroupBox = New-Object System.Windows.Forms.GroupBox
$ModelGroupBox.Text = "Loaded Model Selection"
$ModelGroupBox.Anchor = "Top, Left, Right"
$ModelGroupBox.Size = New-Object System.Drawing.Size(400, 200)
$ModelGroupBox.Location = New-Object System.Drawing.Point(10, 110) 
$FetchModelsButton = New-Object System.Windows.Forms.Button
$FetchModelsButton.Text = "Fetch Loaded Models"
$FetchModelsButton.Location = New-Object System.Drawing.Point(10, 25)
$FetchModelsButton.Size = New-Object System.Drawing.Size(375, 30)
$ModelComboBox = New-Object System.Windows.Forms.ComboBox
$ModelComboBox.Text = "Select a model..."
$ModelComboBox.Location = New-Object System.Drawing.Point(10, 65)
$ModelComboBox.Size = New-Object System.Drawing.Size(375, 20)
$ModelComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$OrLabel = New-Object System.Windows.Forms.Label
$OrLabel.Text = "--- OR ---"
$OrLabel.Location = New-Object System.Drawing.Point(10, 105)
$OrLabel.Size = New-Object System.Drawing.Size(375, 20)
$OrLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$OrLabel.BackColor = [System.Drawing.Color]::Transparent
$ModelIdLabel = New-Object System.Windows.Forms.Label
$ModelIdLabel.Text = "Manual Model ID:"
$ModelIdLabel.Location = New-Object System.Drawing.Point(10, 140)
$ModelIdLabel.Size = New-Object System.Drawing.Size(110, 20)
$ModelIdLabel.BackColor = [System.Drawing.Color]::Transparent
$ModelIdBox = New-Object System.Windows.Forms.TextBox
$ModelIdBox.Text = ""
$ModelIdBox.Location = New-Object System.Drawing.Point(125, 137)
$ModelIdBox.Size = New-Object System.Drawing.Size(260, 20)
$ModelIdBox.PlaceholderText = "e.g. gpt-3.5-turbo"
$ModelComboBox.Add_SelectedIndexChanged({ Update-ModelStatusLabel })
$ModelIdBox.Add_TextChanged({ Update-ModelStatusLabel })
$ModelGroupBox.Controls.AddRange(@($FetchModelsButton, $ModelComboBox, $OrLabel, $ModelIdLabel, $ModelIdBox))
$SettingsPanel.Controls.AddRange(@($ServerGroupBox, $ModelGroupBox))
$TabPageSettings.Controls.AddRange(@($SettingsPanel, $TopSettingsPanel))

# --- TAB 3: Model Parameters ---
$TabPageModelParams = New-Object System.Windows.Forms.TabPage
$TabPageModelParams.Text = "Model Parameters"
$TabPageModelParams.Padding = New-Object System.Windows.Forms.Padding(10)
$PersonaLabel = New-Object System.Windows.Forms.Label
$PersonaLabel.Text = "Pre-defined Personas:"
$PersonaLabel.Location = New-Object System.Drawing.Point(10, 10)
$PersonaLabel.Size = New-Object System.Drawing.Size(130, 20)
$PersonaLabel.BackColor = [System.Drawing.Color]::Transparent
$PersonaComboBox = New-Object System.Windows.Forms.ComboBox
$PersonaComboBox.Location = New-Object System.Drawing.Point(150, 7)
$PersonaComboBox.Size = New-Object System.Drawing.Size(260, 20)
$PersonaComboBox.DropDownStyle = "DropDownList"
$PersonaComboBox.Items.AddRange(@("None (Default)", "Helpful Assistant", "Retro AI (1980s)", "Sarcastic Butler", "Pirate Captain"))
$PersonaComboBox.SelectedIndex = 0
$ToolTip.SetToolTip($PersonaComboBox, "Select a pre-defined persona to set the System Prompt.")
$SysPromptLabel = New-Object System.Windows.Forms.Label
$SysPromptLabel.Text = "System Prompt:"
$SysPromptLabel.Location = New-Object System.Drawing.Point(10, 40)
$SysPromptLabel.BackColor = [System.Drawing.Color]::Transparent
$SysPromptBox = New-Object System.Windows.Forms.TextBox
$SysPromptBox.Location = New-Object System.Drawing.Point(10, 70) # Moved down
$SysPromptBox.Size = New-Object System.Drawing.Size(400, 150)
$SysPromptBox.Multiline = $true
$SysPromptBox.ScrollBars = "Vertical"
$ToolTip.SetToolTip($SysPromptBox, "Set the model's personality or instructions. (e.g., 'You are a helpful assistant.')")
$TempLabel = New-Object System.Windows.Forms.Label
$TempLabel.Text = "Temperature (0.0 - 2.0):"
$TempLabel.Location = New-Object System.Drawing.Point(10, 260) # New Y
$TempLabel.Size = New-Object System.Drawing.Size(160, 20) # Wider
$TempLabel.BackColor = [System.Drawing.Color]::Transparent
$TempNumeric = New-Object System.Windows.Forms.NumericUpDown
$TempNumeric.Location = New-Object System.Drawing.Point(180, 258) # New X, Y
$TempNumeric.Size = New-Object System.Drawing.Size(60, 20)
$TempNumeric.DecimalPlaces = 1
$TempNumeric.Increment = 0.1
$TempNumeric.Minimum = 0.0
$TempNumeric.Maximum = 2.0
$TempNumeric.Value = 0.7
$ToolTip.SetToolTip($TempNumeric, "Controls randomness. Lower is more predictable, higher is more creative.")
$GpuLabel = New-Object System.Windows.Forms.Label
$GpuLabel.Text = "GPU Offload (-1 for max):"
$GpuLabel.Location = New-Object System.Drawing.Point(10, 325) # New Y
$GpuLabel.Size = New-Object System.Drawing.Size(160, 20) # Wider
$GpuLabel.BackColor = [System.Drawing.Color]::Transparent
$GpuNumeric = New-Object System.Windows.Forms.NumericUpDown
$GpuNumeric.Location = New-Object System.Drawing.Point(180, 323) # New X, Y
$GpuNumeric.Size = New-Object System.Drawing.Size(60, 20)
$GpuNumeric.Minimum = -1
$GpuNumeric.Maximum = 100
$GpuNumeric.Value = -1
$ToolTip.SetToolTip($GpuNumeric, "Number of layers to offload to GPU. -1 means offload all possible.")
$ContextLabel = New-Object System.Windows.Forms.Label
$ContextLabel.Text = "Context Length (0=auto):"
$ContextLabel.Location = New-Object System.Drawing.Point(10, 390) # New Y
$ContextLabel.Size = New-Object System.Drawing.Size(160, 20) # Wider
$ContextLabel.BackColor = [System.Drawing.Color]::Transparent
$ContextNumeric = New-Object System.Windows.Forms.NumericUpDown
$ContextNumeric.Location = New-Object System.Drawing.Point(180, 388) # New X, Y
$ContextNumeric.Size = New-Object System.Drawing.Size(60, 20)
$ContextNumeric.Minimum = 0
$ContextNumeric.Maximum = 32768
$ContextNumeric.Increment = 1024
$ContextNumeric.Value = 0
$ToolTip.SetToolTip($ContextNumeric, "Max context size. 0 lets LM Studio decide.")
$TabPageModelParams.Controls.AddRange(@($PersonaLabel, $PersonaComboBox, $SysPromptLabel, $SysPromptBox, $TempLabel, $TempNumeric, $GpuLabel, $GpuNumeric, $ContextLabel, $ContextNumeric))


# --- TAB 4: Prompt Template ---
$TabPagePromptTemplate = New-Object System.Windows.Forms.TabPage
$TabPagePromptTemplate.Text = "Templates"
$TabPagePromptTemplate.Padding = New-Object System.Windows.Forms.Padding(10)
$StopStringsLabel = New-Object System.Windows.Forms.Label
$StopStringsLabel.Text = "Additional Stop Strings (one per line):"
$StopStringsLabel.Location = New-Object System.Drawing.Point(10, 10)
$StopStringsLabel.Size = New-Object System.Drawing.Size(400, 20) # Wider
$StopStringsLabel.BackColor = [System.Drawing.Color]::Transparent
$StopStringsBox = New-Object System.Windows.Forms.TextBox
$StopStringsBox.Location = New-Object System.Drawing.Point(10, 30)
$StopStringsBox.Size = New-Object System.Drawing.Size(400, 100)
$StopStringsBox.Multiline = $true
$StopStringsBox.ScrollBars = "Vertical"
$ToolTip.SetToolTip($StopStringsBox, "Force the AI to stop generating text if it encounters one of these strings.")

# **REVISED** UI Layout
$LimitResponseCheckBox = New-Object System.Windows.Forms.CheckBox
$LimitResponseCheckBox.Location = New-Object System.Drawing.Point(13, 172) # Moved to the left
$LimitResponseCheckBox.Size = New-Object System.Drawing.Size(20, 20)
$LimitResponseCheckBox.Checked = $false
$ToolTip.SetToolTip($LimitResponseCheckBox, "Enable to limit the maximum number of tokens the AI can generate.")

$LimitResponseLabel = New-Object System.Windows.Forms.Label
$LimitResponseLabel.Text = "Limit Response Length:"
$LimitResponseLabel.Location = New-Object System.Drawing.Point(35, 170) # Moved next to checkbox
$LimitResponseLabel.Size = New-Object System.Drawing.Size(140, 20)
$LimitResponseLabel.BackColor = [System.Drawing.Color]::Transparent

$LimitResponseNumeric = New-Object System.Windows.Forms.NumericUpDown
$LimitResponseNumeric.Location = New-Object System.Drawing.Point(180, 168) # Moved closer to label
$LimitResponseNumeric.Size = New-Object System.Drawing.Size(70, 20)
$LimitResponseNumeric.Minimum = -1
$LimitResponseNumeric.Maximum = 8192
$LimitResponseNumeric.Increment = 128
$LimitResponseNumeric.Value = 1024
$LimitResponseNumeric.Enabled = $false
$ToolTip.SetToolTip($LimitResponseNumeric, "Max tokens to generate. -1 means no limit.")
$LimitResponseCheckBox.Add_CheckedChanged({
    $LimitResponseNumeric.Enabled = $LimitResponseCheckBox.Checked
})
$TabPagePromptTemplate.Controls.AddRange(@($StopStringsLabel, $StopStringsBox, $LimitResponseCheckBox, $LimitResponseLabel, $LimitResponseNumeric))


# --- TAB 5: Downloaded Models ---
$TabPageDownloadedModels = New-Object System.Windows.Forms.TabPage
$TabPageDownloadedModels.Text = "Models"
$TabPageDownloadedModels.Padding = New-Object System.Windows.Forms.Padding(10)
$RefreshModelsButton = New-Object System.Windows.Forms.Button
$RefreshModelsButton.Text = "Refresh Downloaded Model List"
$RefreshModelsButton.Dock = [System.Windows.Forms.DockStyle]::Top
$RefreshModelsButton.Height = 30
$ToolTip.SetToolTip($RefreshModelsButton, "Queries the LM Studio server to find all models in your library.")
$DownloadedModelsListView = New-Object System.Windows.Forms.ListView
$DownloadedModelsListView.Dock = [System.Windows.Forms.DockStyle]::Fill
$DownloadedModelsListView.View = "Details"
$DownloadedModelsListView.FullRowSelect = $true
$DownloadedModelsListView.GridLines = $true
$DownloadedModelsListView.Columns.Clear()
$DownloadedModelsListView.Columns.Add("File Name", 200)
$DownloadedModelsListView.Columns.Add("Size", 80)
$DownloadedModelsListView.Columns.Add("Full Path", 0) # Hidden column for full path
$DownloadedModelsListView.Add_SelectedIndexChanged({
    if ($DownloadedModelsListView.SelectedItems.Count -gt 0) {
        $Global:SelectedGGUFModelPath = $DownloadedModelsListView.SelectedItems[0].SubItems[2].Text # Get from hidden Full Path column (index 2)
        Write-Log -Message "Selected GGUF Model: $($Global:SelectedGGUFModelPath)"
        Update-ModelStatusLabel
    }
})
$DownloadedModelsListView.Add_DoubleClick({
    if ($DownloadedModelsListView.SelectedItems.Count -gt 0) {
        $Global:SelectedGGUFModelPath = $DownloadedModelsListView.SelectedItems[0].SubItems[2].Text # Get from hidden Full Path column (index 2)
        Write-Log -Message "Double-clicked and selected GGUF Model: $($Global:SelectedGGUFModelPath)"
        $TabControl.SelectedTab = $TabPageChat
        Update-ModelStatusLabel
    }
})
$DownloadedModelsPanel = New-Object System.Windows.Forms.Panel
$DownloadedModelsPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$DownloadedModelsPanel.Padding = New-Object System.Windows.Forms.Padding(0, 40, 0, 0) 
$DownloadedModelsPanel.Controls.Add($DownloadedModelsListView)
$TabPageDownloadedModels.Controls.AddRange(@($DownloadedModelsPanel, $RefreshModelsButton)) 


# Add tabs in order
$TabControl.TabPages.AddRange(@($TabPageChat, $TabPageSettings, $TabPageModelParams, $TabPagePromptTemplate, $TabPageDownloadedModels))
$TabBackgroundPanel.Controls.Add($TabControl) # Add TabControl to the background panel
$TabControl.BringToFront()


# --- (PROCESS POLLING TIMER REMOVED) ---


# 7. --- EVENT HANDLERS ---

# --- Form Load/Close ---
$MainForm.Add_Load({
    $loadedSettings = Load-Config
    if ($loadedSettings) {
        $UrlBox.Text = $loadedSettings.LastUrl
        $PortBox.Text = $loadedSettings.LastPort
        $Global:CurrentIconPath = $loadedSettings.IconPath
        $Global:SendKeyPreference = $loadedSettings.SendKeyPref
        $Global:BackendPreference = $loadedSettings.BackendPref
        if ($loadedSettings.PSObject.Properties.Match('TealThemeEnabled').Count -gt 0) {
            $Global:TealThemeEnabled = $loadedSettings.TealThemeEnabled
        }
        
        $SysPromptBox.Text = $loadedSettings.SystemPrompt
        $TempNumeric.Value = $loadedSettings.Temperature
        $GpuNumeric.Value = $loadedSettings.GpuOffload
        $ContextNumeric.Value = $loadedSettings.ContextLength
        $StopStringsBox.Lines = $loadedSettings.StopStrings
        $LimitResponse = $loadedSettings.LimitResponse
        $LimitResponseValue = $loadedSettings.LimitResponseValue
        $Global:SelectedGGUFModelPath = $loadedSettings.SelectedGGUFModelPath
        
        $StatusLabel.Text = "Loaded previous settings."
    }

    # Default Icon Logic
    if ([string]::IsNullOrEmpty($Global:CurrentIconPath)) {
        $defaultIconRelativePath = "Icons\OptiLink.ico"
        $defaultIconFullPath = [System.IO.Path]::Combine($ConfigDir, $defaultIconRelativePath)
        if (Test-Path $defaultIconFullPath) {
            $Global:CurrentIconPath = $defaultIconRelativePath
        }
    }
    
    # Apply whatever icon was decided upon
    Apply-AppIcon -Form $MainForm -TrayIcon $TrayIcon -PicBox1 $ChatIconPreview -PicBox2 $SettingsIconPreview -RelativeIconPath $Global:CurrentIconPath
    
    # Apply the current theme
    Apply-Theme -Form $MainForm -MenuBar $MenuBar -TabBackgroundPanel $TabBackgroundPanel -MenuBarShadow $MenuBarShadow

    # Update the model status label
    Update-ModelStatusLabel
})

$MainForm.Add_FormClosing({
    Write-Log -Message "Form closing. Saving settings. TealThemeEnabled is: $($Global:TealThemeEnabled)"
    # **NEW** Create a settings object to save EVERYTHING
    $AllSettings = @{
        LastUrl = $UrlBox.Text
        LastPort = $PortBox.Text
        IconPath = $Global:CurrentIconPath
        SendKeyPref = $Global:SendKeyPreference
        BackendPref = $Global:BackendPreference
        TealThemeEnabled = $Global:TealThemeEnabled
        SystemPrompt = $SysPromptBox.Text
        Temperature = $TempNumeric.Value
        GpuOffload = $GpuNumeric.Value
        ContextLength = $ContextNumeric.Value
        StopStrings = $StopStringsBox.Lines
        LimitResponse = $LimitResponseCheckBox.Checked
        LimitResponseValue = $LimitResponseNumeric.Value
        SelectedGGUFModelPath = $Global:SelectedGGUFModelPath
    }
    Save-Config -SettingsObject $AllSettings
    $TrayIcon.Dispose()
})

# --- Form Resize (Minimize to Tray) ---
$MainForm.Add_Resize({
    if ($MainForm.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        $MainForm.Hide()
        $MainForm.ShowInTaskbar = $false
    }
})

# --- Tray Icon Events ---
$TrayIcon.Add_DoubleClick({
    $MainForm.Show()
    $MainForm.ShowInTaskbar = $true
    $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $MainForm.Activate()
})
$TrayMenuShow.Add_Click({ $TrayIcon.Raise_DoubleClick($null, $null) })
$TrayMenuExit.Add_Click({ $MainForm.Close() })


# --- Menu Items ---
$FileExitMenuItem.Add_Click({ $MainForm.Close() })
$FileLaunchLMStudioMenuItem.Add_Click({
    try {
        Start-Process "LM Studio.exe"
        $StatusLabel.Text = "Launching LM Studio..."
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Could not find 'LM Studio.exe' in your system's PATH.", "Launch Error")
        $StatusLabel.Text = "Error: Could not launch LM Studio."
    }
})

$FileSettingsMenuItem.Add_Click({
    $SettingsForm = New-Object System.Windows.Forms.Form
    $SettingsForm.Text = "Settings"
    $SettingsForm.Size = New-Object System.Drawing.Size(350, 520) # Made taller for theme option
    $SettingsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $SettingsForm.ControlBox = $false
    $SettingsForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    
    $TempIconPath = $null 
    $IconGroupBox = New-Object System.Windows.Forms.GroupBox
    $IconGroupBox.Text = "Application Icon"
    $IconGroupBox.Size = New-Object System.Drawing.Size(310, 150)
    $IconGroupBox.Location = New-Object System.Drawing.Point(10, 10)
    $IconLabel = New-Object System.Windows.Forms.Label
    $IconLabel.Text = "Select a custom .ico file:"
    $IconLabel.Location = New-Object System.Drawing.Point(15, 30)
    $IconLabel.Size = New-Object System.Drawing.Size(150, 20)
    $IconLabel.BackColor = [System.Drawing.Color]::Transparent
    $IconBrowseButton = New-Object System.Windows.Forms.Button
    $IconBrowseButton.Text = "Browse..."
    $IconBrowseButton.Location = New-Object System.Drawing.Point(170, 27)
    $IconBrowseButton.Size = New-Object System.Drawing.Size(120, 25)
    $IconPreview = New-Object System.Windows.Forms.PictureBox
    $IconPreview.Location = New-Object System.Drawing.Point(20, 60)
    $IconPreview.Size = New-Object System.Drawing.Size(64, 64)
    $IconPreview.SizeMode = "StretchImage"
    $IconPreview.BorderStyle = "FixedSingle"
    if ($MainForm.Icon) { $IconPreview.Image = $MainForm.Icon.ToBitmap() }
    $IconClearButton = New-Object System.Windows.Forms.Button
    $IconClearButton.Text = "Clear Icon"
    $IconClearButton.Location = New-Object System.Drawing.Point(170, 60)
    $IconClearButton.Size = New-Object System.Drawing.Size(120, 25)
    $IconGroupBox.Controls.AddRange(@($IconLabel, $IconBrowseButton, $IconPreview, $IconClearButton))
    
    $SendKeyGroupBox = New-Object System.Windows.Forms.GroupBox
    $SendKeyGroupBox.Text = "Send Message Hotkey"
    $SendKeyGroupBox.Size = New-Object System.Drawing.Size(310, 60)
    $SendKeyGroupBox.Location = New-Object System.Drawing.Point(10, 170)
    $SendKeyComboBox = New-Object System.Windows.Forms.ComboBox
    $SendKeyComboBox.Location = New-Object System.Drawing.Point(15, 25)
    $SendKeyComboBox.Size = New-Object System.Drawing.Size(275, 20)
    $SendKeyComboBox.DropDownStyle = "DropDownList"
    $SendKeyComboBox.Items.AddRange(@("Enter", "Ctrl+Enter", "Shift+Enter"))
    $SendKeyComboBox.SelectedItem = $Global:SendKeyPreference
    $SendKeyGroupBox.Controls.Add($SendKeyComboBox)

    # --- **NEW** Backend Settings ---
    $BackendGroupBox = New-Object System.Windows.Forms.GroupBox
    $BackendGroupBox.Text = "Model Backend"
    $BackendGroupBox.Size = New-Object System.Drawing.Size(310, 120) # Made shorter
    $BackendGroupBox.Location = New-Object System.Drawing.Point(10, 240)
    
    $LmStudioRadio = New-Object System.Windows.Forms.RadioButton
    $LmStudioRadio.Text = "LM Studio"
    $LmStudioRadio.Location = New-Object System.Drawing.Point(15, 25)
    $LmStudioRadio.Size = New-Object System.Drawing.Size(120, 20)
    $LmStudioRadio.Checked = ($Global:BackendPreference -eq "LM Studio (Network)")
    $ToolTip.SetToolTip($LmStudioRadio, "Use the LM Studio server API.")
    
    $GgufRadio = New-Object System.Windows.Forms.RadioButton
    $GgufRadio.Text = "Local GGUF"
    $GgufRadio.Location = New-Object System.Drawing.Point(165, 25) # Side-by-side
    $GgufRadio.Size = New-Object System.Drawing.Size(120, 20)
    $GgufRadio.Checked = ($Global:BackendPreference -eq "Local GGUF (Experimental)")
    $ToolTip.SetToolTip($GgufRadio, "Run GGUF models directly using llama.cpp (Requires download).")
    $GgufRadio.Add_CheckedChanged({
        if ($GgufRadio.Checked -and $ContextNumeric.Value -eq 0) {
            $ContextNumeric.Value = 2048
        }
    })
    
    $DownloadLlamaCppButton = New-Object System.Windows.Forms.Button
    $DownloadLlamaCppButton.Text = "Download llama.cpp"
    $DownloadLlamaCppButton.Location = New-Object System.Drawing.Point(15, 55) # Moved up
    $DownloadLlamaCppButton.Size = New-Object System.Drawing.Size(275, 30)
    $ToolTip.SetToolTip($DownloadLlamaCppButton, "Downloads the llama.cpp binaries to your config folder.")
    
    $DownloadStatusLabel = New-Object System.Windows.Forms.Label
    $DownloadStatusLabel.Text = "Ready to download."
    $DownloadStatusLabel.Location = New-Object System.Drawing.Point(15, 90) # Moved up and closer
    $DownloadStatusLabel.Size = New-Object System.Drawing.Size(275, 20)
    $DownloadStatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $DownloadStatusLabel.BackColor = [System.Drawing.Color]::Transparent
    
    $BackendGroupBox.Controls.AddRange(@($LmStudioRadio, $GgufRadio, $DownloadLlamaCppButton, $DownloadStatusLabel))
    
    # --- Theme Settings ---
    $ThemeGroupBox = New-Object System.Windows.Forms.GroupBox
    $ThemeGroupBox.Text = "Theme"
    $ThemeGroupBox.Size = New-Object System.Drawing.Size(310, 60)
    $ThemeGroupBox.Location = New-Object System.Drawing.Point(10, 370)
    $ThemeToggleCheckBox = New-Object System.Windows.Forms.CheckBox
    $ThemeToggleCheckBox.Text = "Enable Teal Theme"
    $ThemeToggleCheckBox.Location = New-Object System.Drawing.Point(15, 25)
    $ThemeToggleCheckBox.Size = New-Object System.Drawing.Size(280, 20) # Made wider to prevent text wrapping
    $ThemeToggleCheckBox.Checked = $Global:TealThemeEnabled
    $ThemeGroupBox.Controls.Add($ThemeToggleCheckBox)

    # --- OK/Cancel Buttons ---
    $OkButton = New-Object System.Windows.Forms.Button
    $OkButton.Text = "Okay"
    $OkButton.Location = New-Object System.Drawing.Point(87, 440) # Moved down
    $OkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Text = "Cancel"
    $CancelButton.Location = New-Object System.Drawing.Point(172, 440) # Moved down
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    
    $SettingsForm.Controls.AddRange(@($IconGroupBox, $SendKeyGroupBox, $BackendGroupBox, $ThemeGroupBox, $OkButton, $CancelButton))
    $SettingsForm.AcceptButton = $OkButton
    $SettingsForm.CancelButton = $CancelButton
    
    $IconBrowseButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "Icon Files (*.ico)|*.ico"
        $OpenFileDialog.Title = "Select an Icon"
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $TempIconPath = $OpenFileDialog.FileName
            try { $IconPreview.Image = [System.Drawing.Icon]::new($TempIconPath).ToBitmap() }
            catch { $TempIconPath = $null }
        }
    })
    $IconClearButton.Add_Click({
        $TempIconPath = "CLEAR"
        $IconPreview.Image = $null
    })

    # --- Llama.cpp Download (DISABLED - Llama.cpp is manually installed) ---
    # $DownloadLlamaCppButton.Add_Click({
    #     $DownloadLlamaCppButton.Enabled = $false
    #     $DownloadStatusLabel.Text = "Downloading llama.cpp zip..."
    #     $SettingsForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
    #     $llamaUrl = "https://sourceforge.net/projects/llama-cpp.mirror/files/b7021/llama-b7021-bin-win-cpu-x64.zip/download"
    #     $zipPath = [System.IO.Path]::Combine($InterfaceDir, "llama.cpp.zip")
    #     $exePath = [System.IO.Path]::Combine($InterfaceDir, "llama-cli.exe") # Guessing exe name
        
    #     Write-Log -Message "Attempting to download llama.cpp from $llamaUrl"
    #     try {
    #         Invoke-WebRequest -Uri $llamaUrl -OutFile $zipPath -UseBasicParsing
    #         $DownloadStatusLabel.Text = "Download complete. Extracting..."
    #         Write-Log -Message "llama.cpp download successful. Extracting..."
            
    #         # Extract
    #         Expand-Archive -Path $zipPath -DestinationPath $InterfaceDir -Force
            
    #         # Clean up zip
    #         Remove-Item $zipPath
            
    #         Write-Log -Message "llama.cpp extracted and zip file removed."
            
    #         # Check for common exe names
    #         if (Test-Path $exePath) {
    #             $Global:LlamaCppPath = $exePath
    #         } elseif (Test-Path (Join-Path $InterfaceDir "main.exe")) {
    #             $Global:LlamaCppPath = (Join-Path $InterfaceDir "main.exe")
    #         }
            
    #         $DownloadStatusLabel.Text = "llama.cpp is installed!"
    #         Write-Log -Message "llama.cpp installation complete."
    #     }
    #     catch {
    #         Write-ErrorLog -ContextMessage "Failed to download or extract llama.cpp" -ErrorRecord $_
    #         $DownloadStatusLabel.Text = "Error: Download failed."
    #         [System.Windows.Forms.MessageBox]::Show("Failed to download or extract llama.cpp.`n$($_.Exception.Message)", "Download Error")
    #     }
    #     finally {
    #         $SettingsForm.Cursor = [System.Windows.Forms.Cursors]::Default
    #     }
    # })
    
    # Pre-set status to indicate llama.cpp is installed
    $DownloadLlamaCppButton.Enabled = $false
    $DownloadStatusLabel.Text = "llama.cpp is installed!"

    if ($SettingsForm.ShowDialog($MainForm) -eq [System.Windows.Forms.DialogResult]::OK) {
        # --- Apply and Save Settings ---
        $Global:TealThemeEnabled = $ThemeToggleCheckBox.Checked
        $Global:SendKeyPreference = $SendKeyComboBox.SelectedItem
        if ($LmStudioRadio.Checked) { $Global:BackendPreference = "LM Studio (Network)" }
        else { $Global:BackendPreference = "Local GGUF (Experimental)" }

        # Apply the theme immediately
        Apply-Theme -Form $MainForm -MenuBar $MenuBar -TabBackgroundPanel $TabBackgroundPanel -MenuBarShadow $MenuBarShadow
        
        # Update the model status label
        Update-ModelStatusLabel

        if ($TempIconPath -eq "CLEAR") {
            $Global:CurrentIconPath = $null
            $MainForm.Icon = $null
            $TrayIcon.Icon = $null
            $ChatIconPreview.Image = $null
            $SettingsIconPreview.Image = $null
        }
        elseif ($TempIconPath) {
            try {
                $iconFileName = [System.IO.Path]::GetFileName($TempIconPath)
                $DestinationPath = [System.IO.Path]::Combine($Global:ConfigIconDir, $iconFileName)
                Copy-Item -Path $TempIconPath -Destination $DestinationPath -Force
                $Global:CurrentIconPath = "Icons\$iconFileName"
                Apply-AppIcon -Form $MainForm -TrayIcon $TrayIcon -PicBox1 $ChatIconPreview -PicBox2 $SettingsIconPreview -RelativeIconPath $Global:CurrentIconPath
            }
            catch { [System.Windows.Forms.MessageBox]::Show("Failed to copy or apply the new icon.`n$($_.Exception.Message)", "Icon Error") }
        }
    }
    $SettingsForm.Dispose()
})

# --- **RESTORED** Changelog Window ---
$HelpChangelogMenuItem.Add_Click({
    $ChangelogForm = New-Object System.Windows.Forms.Form
    $ChangelogForm.Text = "Changelog"
    $ChangelogForm.Size = New-Object System.Drawing.Size(450, 500)
    $ChangelogForm.StartPosition = "CenterParent"
    $ChangelogForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ChangelogForm.ControlBox = $false
    
    $HeaderPanel = New-Object System.Windows.Forms.Panel
    $HeaderPanel.Dock = [System.Windows.Forms.DockStyle]::Top
    $HeaderPanel.Height = 50
    $HeaderPanel.add_Paint({param($sender, $e) 
        $graphics = $e.Graphics
        $rect = $sender.ClientRectangle
        $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, [System.Drawing.Color]::Teal, [System.Drawing.Color]::Blue, [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal)
        $graphics.FillRectangle($brush, $rect)
        $brush.Dispose()
    })
    $HeaderLabel = New-Object System.Windows.Forms.Label
    $HeaderLabel.Text = "Opti-Link Changelog"
    $HeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $HeaderLabel.ForeColor = [System.Drawing.Color]::White
    $HeaderLabel.BackColor = [System.Drawing.Color]::Transparent
    $HeaderLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $HeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $HeaderPanel.Controls.Add($HeaderLabel)

    $FooterPanel = New-Object System.Windows.Forms.Panel
    $FooterPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $FooterPanel.Height = 50
    $FooterPanel.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    
    $DoneButton = New-Object System.Windows.Forms.Button
    $DoneButton.Text = "Done"
    $DoneButton.Size = New-Object System.Drawing.Size(80, 25)
    $DoneButton.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $buttonX = ($FooterPanel.Width - $DoneButton.Width) / 2
    $DoneButton.Location = New-Object System.Drawing.Point($buttonX, 12)
    $DoneButton.Anchor = "Top"
    $DoneButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $FooterPanel.Controls.Add($DoneButton)
    
    $TextPanel = New-Object System.Windows.Forms.Panel
    $TextPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $TextPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    $ChangelogBox = New-Object System.Windows.Forms.RichTextBox
    $ChangelogBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $ChangelogBox.ReadOnly = $true
    $ChangelogBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $TextPanel.Controls.Add($ChangelogBox)
    
$ChangelogBox.Text = @"
v1.0.3.7 (11/17/2025)
- CRITICAL FIX: Replaced the asynchronous Process-based GGUF backend with a robust, dedicated PowerShell Runspace. This resolves the "No Runspace available" crash and ensures llama-cli executes in a stable, isolated environment.
- REFACTOR: Created a new reusable function `Invoke-LlamaInRunspace` to manage the entire lifecycle of the llama-cli process, improving stability and simplifying the main chat logic.
- IMPROVEMENT: The new Runspace implementation correctly streams output back to the chat window in real-time.

v0.9.3.5 (11/17/2025)
- CRITICAL FIX: Overhauled the local GGUF backend to use a proper, fully asynchronous event-driven model instead of a faulty timer. This resolves the UI freeze and ensures that AI responses are streamed back to the chat window correctly.
- BUGFIX: Fixed a regression where the LM Studio backend would cause a crash after receiving a message.
- BUGFIX: Hardened all UI state-resetting logic to prevent crashes related to PowerShell's handling of boolean values in obscure error states.
- CHANGE: Updated the path to the local `llama-cli.exe` to a new, more reliable location.
- FEATURE: The "Context Length" in settings now intelligently updates to a recommended value of 2048 when the "Local GGUF" backend is selected, preventing an error with the `llama-cli` executable.

v0.9.3.4 (11/17/2025)
- BUGFIX: Added `-no-cnv` flag to `llama-cli.exe` arguments to disable interactive mode and ensure the process exits correctly.
- BUGFIX: Re-enabled asynchronous streaming for local GGUF models.
- BUGFIX: Corrected argument quoting for paths and prompts with spaces.
- BUGFIX: Fixed a crash related to PowerShell runspaces on background threads by implementing a timer-based polling mechanism for `llama-cli.exe` output.

v0.9.3.3 (11/17/2025)
- BUGFIX: Fixed the argument parsing for `llama-cli.exe` by adding quotes around paths and prompts. This resolves the "invalid argument" error.
- REVERT: Re-enabled asynchronous streaming of AI responses.

v0.9.3.2 (11/17/2025)
- DEBUG: Temporarily switched to synchronous process handling for `llama-cli.exe` to ensure all error output is captured for debugging. This will temporarily disable streaming.

v0.9.3.1 (11/17/2025)
- BUGFIX: Fixed the `ErrorDataReceived` event handler to correctly log and display errors from `llama-cli.exe`.

v0.9.3.0 (11/17/2025)
- BUGFIX: Fixed a critical crash when sending a message with the local backend. The crash was caused by an incorrect exception type being passed to the error logging function.
- FEATURE: Double-clicking a model in the "Models" tab now selects it and switches to the "Chat" tab.
- FEATURE: The currently loaded model and backend are now displayed on the "Chat" tab.
- IMPROVEMENT: The model status label is updated whenever the backend or model selection changes.

v0.9.2.9 (11/17/2025)
- BUGFIX: Added extensive debugging `MessageBox`es to trace and diagnose the crash when sending a message with the local backend.
- FEATURE: Double-clicking a model in the "Models" tab now selects it and switches to the "Chat" tab.
- FEATURE: The currently loaded model and backend are now displayed on the "Chat" tab.
- IMPROVEMENT: The model status label is updated whenever the backend or model selection changes.

v0.9.2.8 (11/17/2025)
- FIX: Corrected the physical path to `llama-cli.exe` to resolve the "file not found" error, clarifying that the junction point was for user convenience only.

v0.9.2.7 (11/17/2025)
- FIX: Corrected the path to `llama-cli.exe` to account for the junction point.
- UI: Simplified the 'Models' tab by removing the 'Model Identifier', 'Quant', and 'Vision' columns.

v0.9.2.6 (11/17/2025)
- UI: Stacked the Stop and Send buttons vertically in the chat input panel for a more compact layout.

v0.9.2.5 (11/17/2025)
- FEATURE: Implemented Local GGUF Backend.
  - The application can now run GGUF models directly using `llama.cpp`.
  - Local GGUF models can be selected from the "Models" tab.
  - Model path, parameters, and stop strings are passed to `llama.cpp`.
- FEATURE: Implemented Streaming AI Responses.
  - AI responses are now displayed word-by-word (or line-by-line) as they are generated by `llama.cpp`.
- FEATURE: Added "Stop Generation" button.
  - Users can now interrupt ongoing AI generation from the local GGUF backend.
  - UI elements are correctly enabled/disabled during generation and on stop.
- REFACTOR: `Append-Text` function updated to support streaming with a unique ID for AI messages.
- NEW: Introduced `Update-LastAIMessageThreadSafe` for thread-safe incremental UI updates.
- REFACTOR: `llama.cpp` arguments are now constructed more robustly using an ArrayList.
- IMPROVEMENT: "Download llama.cpp" button in settings is now disabled and indicates `llama.cpp` is installed.
- IMPROVEMENT: `Save-Config` and `Load-Config` now persist the `SelectedGGUFModelPath`.

v0.9.2.4 (11/17/2025)
- CRITICAL FIX: After extensive debugging, the persistent issue with settings and logs not saving has been resolved. The script's path detection was failing under certain launch conditions (e.g., from a shortcut). The logic has been reverted to the most standard and reliable method (`$MyInvocation.MyCommand.Definition`), which is now working correctly. All logs and settings should now save properly to the correct 'OptiLink_Config' directory.
- CLEANUP: Removed all temporary debugging code.

v0.9.2.3 (11/17/2025)
- DEBUG: Added hardcore debugging to the central 'Write-Log' function to determine if it is being called and what path it is using.

v0.9.2.2 (11/17/2025)
- DEBUG: Added hardcore, absolute-path logging at startup to a file in C:\temp\ to definitively diagnose the persistent pathing issue when launched from a shortcut.
- REVERT: Reverted pathing logic to use the standard `$MyInvocation.MyCommand.Definition` method, pending results from the new debug log.

v0.9.2.1 (11/17/2025)
- CRITICAL FIX: Resolved issue where settings were not being saved. The script was using an unreliable method to find its path, causing it to look for the config file in the wrong directory. It now correctly builds the path from the project root.
- BUGFIX: Removed a redundant cleanup call for the system tray icon that could cause a crash on exit.
- DEBUG: Removed intrusive file logging now that the pathing issue is solved.

v0.9.1.9 (11/16/2025)
- DEBUG: Added intrusive file logging to diagnose why settings are not being saved upon closing the application.

v0.9.1.8 (11/16/2025)
- DEBUG: Added logging to the application's closing event to diagnose an issue with the theme setting not being saved correctly.

v0.9.1.7 (11/16/2025)
- UI FIX: Adjusted the layout of controls on the 'Templates' tab to be more compact and logical. The 'Limit Response Length' checkbox is now on the left of the label.

v0.9.1.6 (11/16/2025)
- CRITICAL FIX: Corrected a pathing issue that caused the app to create a new 'OptiLink_Config' folder in the wrong directory. The script now correctly locates its own directory.
- UI FIX: Widened the 'Enable Teal Theme' checkbox in Settings to prevent the text from wrapping and being cut off.

v0.9.2.0 (11/16/2025)
- CRITICAL FIX: Fixed a parser error in the ThemedMenuRenderer class that caused an instant crash on launch. Renamed internal variables to remove leading underscores, which were causing conflicts with PowerShell's parser.

v0.9.1.0 (11/16/2025)
- CRITICAL FIX: Corrected custom menu renderer methods to prevent a startup crash when applying themes. The methods were incorrectly returning values, causing the application to terminate.

v0.9.0.0 (11/16/2025)
- FEATURE: Added optional, persistent Theme setting.
  - Users can now toggle between the default Teal theme and a standard off-white/system color theme.
  - Theme choice is saved in settings.json and applied immediately and on startup.
- REFACTOR: The custom menu renderer was refactored to be theme-aware.

v0.8.9.0 (11/16/2025)
- UI: Re-laid out 'Model Backend' controls in Settings to be side-by-side, improving spacing.
- UI: Centered 'Okay' and 'Cancel' buttons in the Settings dialog and renamed 'OK' to 'Okay'.
- UI: Renamed 'About' dialog button to 'Okay' for consistency.

v0.8.8.0 (11/16/2025)
- UI OVERHAUL: Aggressively re-spaced and resized controls on 'Model Parameters' and 'Templates' tabs to fix all wrapping and clipping issues.
- UI: Increased spacing for 'Model Backend' radio buttons in the Settings dialog for better readability.

v0.8.7.0 (11/16/2025)
- CRITICAL FIX: Reordered script sections to fix function scope issue causing startup crash.
- CRITICAL FIX: Corrected invalid method calls in custom menu renderer to prevent crash.
- CRITICAL FIX: Corrected button centering logic to prevent 'op_Division' crash on dialogs.
- FEATURE: Implemented comprehensive logging system.
  - Logs now stored in 'OptiLink_Config\Log Files'.
  - Added automatic archiving of old logs to 'Historical Logs' on startup.
  - Added 'Write-Log' for general event logging to 'LiveLog.json'.
  - Added 'Write-ErrorLog' for detailed, structured error reports in 'Error Logs'.
  - Integrated logging into all major functions and web requests.
  - Errors and warnings are now also written to the console for immediate visibility.
- REFACTOR: Pointed app to 'OptiLink_Config' and removed legacy 'LMChat_Config'.
- FEATURE: App now automatically loads 'OptiLink.ico' as the default icon.
- UI: Adjusted MenuBar to be a darker teal and added a shadow effect for depth.
- UI: Renamed 'Downloaded Models' tab to 'Models'.
- UI: Renamed 'Prompt Template' tab to 'Templates'.
- UI: Made all text labels have transparent backgrounds to fix visual clipping issues.
- UI: Set button styles on dialogs to 'System' to fix appearance.
- UI: Adjusted main form padding to create space and prevent status bar overlap.
- UI: Aggressively re-spaced controls on all tabs and dialogs to fix all clipping issues.
- BEHAVIOR: The app no longer automatically switches to the 'Chat' tab after fetching models.

v0.7.0.0 (11/15/2025)
- MAJOR REFACTOR: Replaced RichTextBox with WebBrowser for Chat Bubbles.
- CRITICAL FIX: Expanded Save/Load-Config to handle ALL UI settings.
- Restored all tabs and custom About/Changelog windows.
- UI FIX: Fixed control overlap on "Prompt Template" tab.
- UI FIX: Removed all custom button colors from dialogs.
- THEME: Set main window to solid Teal with Blue menu highlights.
- THEME: Placed TabControl in a Teal-backed Panel.
- GGUF: Added "Backend" tab to Settings.
- GGUF: Added button to download and unzip llama.cpp.

v0.6.5.0 (11/15/2025)
- (Version skipped/reverted due to UI issues)

v0.5.0.0 (11/15/2025)
- Added "Model Parameters" & "Prompt Template" tabs.
- Added "Downloaded Models" tab.
- Added "Launch LM Studio" & "Send Key" preference.
- Added Tooltips for all new settings.

v0.4.0.0 (11/15/2025)
- Renamed application to "Opti-Link Instant Messenger"
- Swapped Chat and Connection tabs
- Added System Tray icon with minimize-to-tray
- Added "Settings" window (File -> Settings)
- Implemented custom icon management (portable)
- Added version number to the StatusStrip
- Created a custom "fancy" About box

v0.3.0.0 (11/15/2025)
- Fixed multiple critical startup errors
- Replaced deprecated StatusBar with modern StatusStrip

v0.2.0.0 (11/15/2025)
- Changed config location to be portable

v0.1.0.0 (11/15/2025)
- Initial release
"@
    
    $ChangelogForm.Controls.AddRange(@($TextPanel, $FooterPanel, $HeaderPanel))
    $ChangelogForm.AcceptButton = $DoneButton
    
    $ChangelogForm.ShowDialog($MainForm)
    $ChangelogForm.Dispose()
})

# --- **RESTORED** About Window ---
$HelpAboutMenuItem.Add_Click({
    $AboutForm = New-Object System.Windows.Forms.Form
    $AboutForm.Text = "About OptiLink Instant Messenger"
    $AboutForm.Size = New-Object System.Drawing.Size(400, 250)
    $AboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $AboutForm.ControlBox = $false
    $AboutForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    
    $HeaderPanel = New-Object System.Windows.Forms.Panel
    $HeaderPanel.Dock = [System.Windows.Forms.DockStyle]::Top
    $HeaderPanel.Height = 50
    $HeaderPanel.add_Paint({param($sender, $e) 
        $graphics = $e.Graphics
        $rect = $sender.ClientRectangle
        $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, [System.Drawing.Color]::Teal, [System.Drawing.Color]::Blue, [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal)
        $graphics.FillRectangle($brush, $rect)
        $brush.Dispose()
    })
    $HeaderLabel = New-Object System.Windows.Forms.Label
    $HeaderLabel.Text = "OptiLink Instant Messenger - v$Global:AppVersion"
    $HeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $HeaderLabel.ForeColor = [System.Drawing.Color]::White
    $HeaderLabel.BackColor = [System.Drawing.Color]::Transparent
    $HeaderLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $HeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $HeaderPanel.Controls.Add($HeaderLabel)
    
    $FooterPanel = New-Object System.Windows.Forms.Panel
    $FooterPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $FooterPanel.Height = 50
    $FooterPanel.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    
    $AboutOkButton = New-Object System.Windows.Forms.Button
    $AboutOkButton.Text = "Okay"
    $AboutOkButton.Size = New-Object System.Drawing.Size(80, 25) 
    $AboutOkButton.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $buttonX = ($FooterPanel.Width - $AboutOkButton.Width) / 2
    $AboutOkButton.Location = New-Object System.Drawing.Point($buttonX, 12)
    $AboutOkButton.Anchor = "Top"
    $AboutOkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $FooterPanel.Controls.Add($AboutOkButton)

    $BodyLabel = New-Object System.Windows.Forms.Label
    $BodyLabel.Text = "Created by:`nEliteSoftware Enterprises`nZachary Whiteman`nGoogle Gemini Ai`n`n© 2025"
    $BodyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $BodyLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $BodyLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $BodyLabel.BackColor = [System.Drawing.Color]::Transparent
    
    $AboutForm.Controls.AddRange(@($BodyLabel, $FooterPanel, $HeaderPanel))
    $AboutForm.AcceptButton = $AboutOkButton
    
    $AboutForm.ShowDialog($MainForm)
    $AboutForm.Dispose()
})


# --- Connection Tab ---
$FetchModelsButton.Add_Click({
    $StatusLabel.Text = "Fetching models..."
    $MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Write-Log -Message "Attempting to fetch models from $($UrlBox.Text):$($PortBox.Text)."
    $uri = "$($UrlBox.Text):$($PortBox.Text)/v1/models"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec 5
        $ModelComboBox.Items.Clear()
        if ($response.data) {
            Write-Log -Message "Found $($response.data.Count) models."
            foreach ($model in $response.data) {
                $ModelComboBox.Items.Add($model.id)
            }
            if ($ModelComboBox.Items.Count -gt 0) { $ModelComboBox.SelectedIndex = 0 }
            $StatusLabel.Text = "Loaded models successfully. Ready to chat."
            Update-ModelStatusLabel
        }
        else { 
            $StatusLabel.Text = "Server responded, but no models found."
            Write-Log -Message "Server responded, but no models found." -Severity "WARN"
        }
    }
    catch {
        Write-ErrorLog -ContextMessage "Failed to fetch models from LM Studio" -ErrorRecord $_
        [System.Windows.Forms.MessageBox]::Show("Failed to fetch models.`n`nError: $($_.Exception.Message)`n`nEnsure LM Studio is running and the server is on.", "Connection Error")
        $StatusLabel.Text = "Error: Failed to connect."
    }
    finally { $MainForm.Cursor = [System.Windows.Forms.Cursors]::Default }
})

# --- Model Parameters Tab ---
$PersonaComboBox.Add_SelectedIndexChanged({
    switch ($PersonaComboBox.SelectedItem) {
        "None (Default)" { $SysPromptBox.Text = "" }
        "Helpful Assistant" { $SysPromptBox.Text = "You are a helpful, respectful, and honest assistant." }
        "Retro AI (1980s)" { $SysPromptBox.Text = "GREETINGS, USER. I AM A CYBERNETIC ENTITY. PROCESSING... PLEASE STATE YOUR QUERY." }
        "Sarcastic Butler" { $SysPromptBox.Text = "You are a witty and sarcastic butler. You perform all requests, but with a dry, judgmental wit and a begrudging tone." }
        "Pirate Captain" { $SysPromptBox.Text = "Yarrr! Ye be talkin' to Captain Blackheart. Speak yer mind, matey, but be quick about it!" }
    }
})

# --- Downloaded Models Tab ---
$RefreshModelsButton.Add_Click({
    $StatusLabel.Text = "Scanning local GGUF models..."
    $MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $DownloadedModelsListView.Items.Clear()
    Write-Log -Message "Attempting to list local GGUF models from $GGUFDir."
    try {
        $ggufFiles = Get-ChildItem -Path $GGUFDir -Filter "*.gguf" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -ne $true }

        if ($ggufFiles) {
            Write-Log -Message "Found $($ggufFiles.Count) local GGUF models."
            foreach ($file in $ggufFiles) {
                $item = New-Object System.Windows.Forms.ListViewItem($file.Name) # File Name (first column)
                $item.SubItems.Add((Format-Bytes -bytes $file.Length)) # Size (second column)
                $item.SubItems.Add($file.FullName) # Full Path (hidden third column)
                $DownloadedModelsListView.Items.Add($item)
            }
            $StatusLabel.Text = "Successfully listed local GGUF models."
        }
        else { 
            $StatusLabel.Text = "No local GGUF models found in $GGUFDir."
            Write-Log -Message "No local GGUF models found in $GGUFDir." -Severity "WARN"
        }
    }
    catch {
        Write-ErrorLog -ContextMessage "Failed to list local GGUF models" -ErrorRecord $_
        [System.Windows.Forms.MessageBox]::Show("Failed to list local GGUF models.`n`nError: $($_.Exception.Message)", "File System Error")
        $StatusLabel.Text = "Error: Failed to list local GGUF models."
    }
    finally { $MainForm.Cursor = [System.Windows.Forms.Cursors]::Default }
})

# --- Chat Tab ---
$StopButton.Add_Click({
    # This button is currently disabled during Runspace execution.
    # A more complex solution (e.g., jobs with IPC) would be needed to signal cancellation.
    Write-Log -Message "Stop button clicked, but cancellation is not yet implemented for Runspace jobs." -Severity "WARN"
})

$SendButton.Add_Click({
    try {
        $prompt = $UserInputBox.Text
        if ([string]::IsNullOrWhiteSpace($prompt)) { return }

        $SendButton.Enabled = $false
        $StopButton.Enabled = $false # Disabled for now with Runspace
        $UserInputBox.Enabled = $false
        $StatusLabel.Text = "AI is thinking..."
        $MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        if ($Global:BackendPreference -eq "Local GGUF (Experimental)") {
            #region **NEW** Local GGUF Backend Logic (Runspace Implementation)
            
            # --- 1. Validation ---
            if ([string]::IsNullOrWhiteSpace($Global:SelectedGGUFModelPath)) {
                [System.Windows.Forms.MessageBox]::Show("Please select a GGUF model from the 'Models' tab first.", "No GGUF Model Selected")
                throw "No GGUF model selected."
            }
            $llamaCliPath = "S:\Projects\OptiLink Instant Messenger\OptiLink Instant Messenger Installation\OptiLink_Config\Interface Framework\llama.cpp\llama-cli.exe"
            if (-not (Test-Path $llamaCliPath)) {
                [System.Windows.Forms.MessageBox]::Show("llama-cli.exe not found at the specified path: `n$llamaCliPath", "Error")
                throw "llama-cli.exe not found."
            }

            # --- 2. Build Arguments ---
            $arguments = New-Object System.Collections.Generic.List[string]
            $arguments.Add("-m"); $arguments.Add($Global:SelectedGGUFModelPath)
            $arguments.Add("-ngl"); $arguments.Add("$($GpuNumeric.Value)")
            $contextSize = if ($ContextNumeric.Value -eq 0) { 2048 } else { $ContextNumeric.Value }
            if ($ContextNumeric.Value -eq 0) { Write-Log -Message "Context size was 0, defaulting to $contextSize for local GGUF execution." -Severity "WARN" }
            $arguments.Add("-c"); $arguments.Add("$contextSize")
            $arguments.Add("--temp"); $arguments.Add("$($TempNumeric.Value)")
            if ($LimitResponseCheckBox.Checked) { $arguments.Add("-n"); $arguments.Add("$($LimitResponseNumeric.Value)") } else { $arguments.Add("-n"); $arguments.Add("-1") }
            $StopStringsBox.Lines | ForEach-Object { if (-not [string]::IsNullOrWhiteSpace($_)) { $arguments.Add("-r"); $arguments.Add($_) } }
            # Add crucial arguments for non-interactive streaming
            $arguments.Add("--no-display-prompt")
            $arguments.Add("--silent-prompt") # Use this for cleaner output
            $arguments.Add("-p"); $arguments.Add($prompt)

            Write-Log -Message "Executing llama-cli in Runspace: $llamaCliPath $($arguments -join ' ')"
            
            # --- 3. Prepare UI and History ---
            Append-Text -Browser $ChatBrowser -Text $prompt -UserRole "user"
            $UserInputBox.Clear()
            Append-Text -Browser $ChatBrowser -Text "" -UserRole "ai" -StartStream
            $Global:ChatHistory += @{ role = "user"; content = $prompt }
            $script:aiFullResponse = ""

            # --- 4. Invoke in Background Job for Responsiveness ---
            $scriptBlock = {
                # This block runs in a separate process
                param($LlamaCliPath, $ArgumentList, $InitialHost)
                
                # We need to re-import the class definition inside the job's scope
                $ThemedMenuRendererClassDefinition = @'
                class ThemedMenuRenderer : System.Windows.Forms.ToolStripProfessionalRenderer {
                    [System.Drawing.Brush]$baseBrush; [System.Drawing.Brush]$highlightBrush
                    ThemedMenuRenderer([System.Drawing.Color]$baseColor, [System.Drawing.Color]$highlightColor) { $this.baseBrush = [System.Drawing.SolidBrush]::new($baseColor); $this.highlightBrush = [System.Drawing.SolidBrush]::new($highlightColor) }
                    [void] OnRenderMenuItemBackground($e) { if ($e.Item.Selected -or $e.Item.Pressed) { [void]$e.Graphics.FillRectangle($this.highlightBrush, $e.Item.ContentRectangle) } else { [void]$e.Graphics.FillRectangle($this.baseBrush, $e.Item.ContentRectangle) }; $textColor = [System.Drawing.Color]::White; $textFormat = [System.Windows.Forms.TextFormatFlags]::Default; [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics, $e.Item.Text, $e.Item.Font, $e.Item.ContentRectangle, $textColor, $textFormat) }
                    [void] OnRenderImageMargin($e) { [void]$e.Graphics.FillRectangle($this.baseBrush, $e.AffectedBounds) }
                    [void] OnRenderDropDownBackground($e) { [void]$e.Graphics.FillRectangle($this.baseBrush, $e.AffectedBounds) }
                }
'@
                Invoke-Expression -Command $ThemedMenuRendererClassDefinition

                # Redefine the function inside the job's scope
                function Invoke-LlamaInRunspace {
                    param([string]$LlamaCliPath, [System.Collections.Generic.List[string]]$ArgumentList)
                    $runspace = $null; $powershell = $null
                    try {
                        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($InitialHost)
                        $runspace.Open()
                        $powershell = [System.Management.Automation.PowerShell]::Create()
                        $powershell.Runspace = $runspace
                        $powershell.AddCommand($LlamaCliPath)
                        foreach ($arg in $ArgumentList) { $powershell.AddArgument($arg) }
                        # Merge error stream 2>&1
                        $powershell.Commands.Commands[0].MergeMyResults([System.Management.Automation.Runspaces.PipelineResultTypes]::Error, [System.Management.Automation.Runspaces.PipelineResultTypes]::Output)
                        return $powershell.Invoke()
                    }
                    finally {
                        if ($powershell -ne $null) { $powershell.Dispose() }
                        if ($runspace -ne $null) { $runspace.Dispose() }
                    }
                }

                # Execute the function
                Invoke-LlamaInRunspace -LlamaCliPath $LlamaCliPath -ArgumentList $ArgumentList
            }

            $Global:LlamaJob = Start-Job -ScriptBlock $scriptBlock -ArgumentList @($llamaCliPath, $arguments, $Host)
            
            # --- 5. Monitor Job and Stream Results ---
            while ($Global:LlamaJob.State -eq 'Running') {
                $output = Receive-Job -Job $Global:LlamaJob -Keep
                if ($output) {
                    foreach($line in $output) {
                        $token = $line.ToString()
                        # The output from llama-cli often includes the prompt text at the start. We will ignore it.
                        # This is a simple way to filter; more robust parsing might be needed.
                        if (-not $token.StartsWith($prompt)) {
                            $MainForm.Invoke([System.Action]{ Update-LastAIMessageThreadSafe -Browser $ChatBrowser -TextToAppend $token })
                            $script:aiFullResponse += $token
                        }
                    }
                }
                Start-Sleep -Milliseconds 100 # Brief pause to prevent high CPU usage
            }

            # Receive any final output after the job completes
            $finalOutput = Receive-Job -Job $Global:LlamaJob
            if ($finalOutput) {
                foreach($line in $finalOutput) {
                    $token = $line.ToString()
                    if (-not $token.StartsWith($prompt)) {
                        $MainForm.Invoke([System.Action]{ Update-LastAIMessageThreadSafe -Browser $ChatBrowser -TextToAppend $token })
                        $script:aiFullResponse += $token
                    }
                }
            }

            # Handle job errors
            if ($Global:LlamaJob.State -eq 'Failed') {
                $errorMessage = $Global:LlamaJob.ChildJobs[0].JobStateInfo.Reason.Message
                Write-ErrorLog -ContextMessage "Llama.cpp job failed." -ErrorRecord $Global:LlamaJob.ChildJobs[0].JobStateInfo.Reason
                $MainForm.Invoke([System.Action]{ Update-LastAIMessageThreadSafe -Browser $ChatBrowser -TextToAppend "`n`n[ERROR] The AI model failed to run. Reason: $errorMessage" })
            }

            # Finalize history
            $Global:ChatHistory += @{ role = "assistant"; content = $script:aiFullResponse }
            
            # Cleanup job
            Remove-Job -Job $Global:LlamaJob
            $Global:LlamaJob = $null
            
            #endregion
        }
        else { # The existing LM Studio logic
            #region LM Studio Backend Logic
            $modelId = $null
            if ($ModelComboBox.SelectedItem) { $modelId = $ModelComboBox.SelectedItem.ToString() } else { $modelId = $ModelIdBox.Text }
            if ([string]::IsNullOrWhiteSpace($modelId)) {
                [System.Windows.Forms.MessageBox]::Show("Please select or manually enter a model ID in the 'Connection' tab first.", "No Model Selected")
                throw "No model selected for LM Studio."
            }
            
            Append-Text -Browser $ChatBrowser -Text $prompt -UserRole "user"
            $UserInputBox.Clear()
            
            try {
                Write-Log -Message "Sending chat completion request to $modelId."
                $uri = "$($UrlBox.Text):$($PortBox.Text)/v1/chat/completions"
                $messages = @(); if (-not [string]::IsNullOrWhiteSpace($SysPromptBox.Text)) { $messages += @{ role = "system"; content = $SysPromptBox.Text } }; $messages += @{ role = "user"; content = $prompt }
                $body = @{ model = $modelId; messages = $messages; temperature = $TempNumeric.Value; stream = $false }
                if ($LimitResponseCheckBox.Checked) { $body.Add("max_tokens", $LimitResponseNumeric.Value) }
                $stopStrings = $StopStringsBox.Text.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries); if ($stopStrings.Count -gt 0) { $body.Add("stop", $stopStrings) }
                
                $response = Invoke-RestMethod -Method Post -Uri $uri -Body ($body | ConvertTo-Json) -ContentType "application/json"
                $aiResponse = $response.choices[0].message.content
                Append-Text -Browser $ChatBrowser -Text $aiResponse -UserRole "ai"
                $Global:ChatHistory += @{ role = "user"; content = $prompt }; $Global:ChatHistory += @{ role = "assistant"; content = $aiResponse }
            }
            catch { Write-ErrorLog -ContextMessage "Failed to get chat completion response" -ErrorRecord $_; Append-Text -Browser $ChatBrowser -Text "Error: $($_.Exception.Message)" -UserRole "ai" }
            #endregion
        }
    }
    catch {
        Write-ErrorLog -ContextMessage "An unexpected error occurred in the SendButton click handler." -ErrorRecord $_
        # Don't show a message box for simple validation errors we threw ourselves.
        if ($_.Exception.Message -notin ("No GGUF model selected.", "llama-cli.exe not found.", "No model selected for LM Studio.")) {
             [System.Windows.Forms.MessageBox]::Show("A critical error occurred: $($_.Exception.Message)", "Critical Error")
        }
    }
    finally {
        # This block now runs after both backends complete or fail
        $StatusLabel.Text = "Ready."
        $MainForm.Cursor = [System.Windows.Forms.Cursors]::Default
        $SendButton.Enabled = $true
        $StopButton.Enabled = $false # Always false for now
        $UserInputBox.Enabled = $true
        [void]$UserInputBox.Focus()
    }
})

$UserInputBox.Add_KeyDown({
    param ($sender, $e)
    $send = $false
    switch ($Global:SendKeyPreference) {
        "Enter" { if (-not $e.Shift -and -not $e.Control -and $e.KeyCode -eq 'Enter') { $send = $true } }
        "Ctrl+Enter" { if ($e.Control -and $e.KeyCode -eq 'Enter') { $send = $true } }
        "Shift+Enter" { if ($e.Shift -and $e.KeyCode -eq 'Enter') { $send = $true } }
    }
    if ($send) {
        $e.Handled = $true
        $e.SuppressKeyPress = $true
        $SendButton.PerformClick()
    }
})

# 8. --- SHOW THE FORM ---
$MainForm.ShowDialog()

# 9. --- CLEANUP ---
$MainForm.Dispose()
