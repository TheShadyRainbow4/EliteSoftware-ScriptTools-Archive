<#
    .SYNOPSIS
        EliteSoftware - MP3 Toolkit
        A comprehensive MP3 editor and previewer.
    
    .DESCRIPTION
        Allows browsing, metadata editing, album art management, and previewing of MP3 files.
        Features non-destructive saving and a distinct EliteSoftware UI.
    
    .AUTHOR
        EliteSoftware - Zachary Whiteman - Gemini Ai
    
    .COPYRIGHT
        Copyright 2025
#>

# -----------------------------------------------------------------------------
# 1. --- PORTABLE PATH & CONFIGURATION ---
# -----------------------------------------------------------------------------
$ScriptBaseDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ConfigDirName = "MP3Toolkit_Config"
$ConfigDir = [System.IO.Path]::Combine($ScriptBaseDir, $ConfigDirName)
$LogFilesDir = [System.IO.Path]::Combine($ConfigDir, "Log Files")
$ErrorLogDir = [System.IO.Path]::Combine($LogFilesDir, "Error Logs")
$HistoricalLogDir = [System.IO.Path]::Combine($LogFilesDir, "Historical Logs")
$HistoricalErrorLogDir = [System.IO.Path]::Combine($ErrorLogDir, "Historical Logs")
$Global:LiveLogFile = [System.IO.Path]::Combine($LogFilesDir, "LiveLog.json")
$ConfigFile = [System.IO.Path]::Combine($ConfigDir, "config.json")
$LibDir = [System.IO.Path]::Combine($ScriptBaseDir, "lib")
$IconsDir = [System.IO.Path]::Combine($ScriptBaseDir, "Icons for MP3-Editor-EliteSoftware")

# -----------------------------------------------------------------------------
# 2. --- AUTOMATIC DIRECTORY CREATION ---
# -----------------------------------------------------------------------------
@($ConfigDir, $LogFilesDir, $ErrorLogDir, $HistoricalLogDir, $HistoricalErrorLogDir, $LibDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# -----------------------------------------------------------------------------
# 3. --- LOGGING & CONFIG FUNCTIONS ---
# -----------------------------------------------------------------------------
function Archive-OldLogs {
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
        Message        = $ErrorRecord.Exception.Message
        StackTrace     = $ErrorRecord.Exception.StackTrace
    }
    $errorFile = [System.IO.Path]::Combine($ErrorLogDir, "Error-$fileNameTimestamp.json")
    try {
        $errorDetails | ConvertTo-Json | Set-Content -Path $errorFile
    }
    catch {
        Write-Warning "Failed to write ErrorLog: $($_.Exception.Message)"
    }
}

function Get-Config {
    if (Test-Path $ConfigFile) {
        return Get-Content $ConfigFile | ConvertFrom-Json
    }
    return @{ ShowStartupHints = $true }
}

function Set-Config {
    param($Settings)
    $Settings | ConvertTo-Json | Set-Content $ConfigFile
}

# Archive logs on startup
Archive-OldLogs
Write-Log "Application Started. EliteSoftware MP3 Toolkit v1.7.0.0"

# -----------------------------------------------------------------------------
# 4. --- DEPENDENCY CHECK (TagLib#) ---
# -----------------------------------------------------------------------------
$TagLibPath = [System.IO.Path]::Combine($LibDir, "TagLibSharp.dll")

if (-not (Test-Path $TagLibPath)) {
    Write-Log "TagLibSharp.dll not found in lib directory. Attempting download..." "WARN"
    try {
        $Url = "https://globalcdn.nuget.org/packages/taglibsharp.2.3.0.nupkg"
        $ZipPath = [System.IO.Path]::Combine($LibDir, "taglibsharp.zip")
        
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $LibDir -Force
        
        $ExtractedDll = Get-ChildItem -Path $LibDir -Recurse -Filter "TagLibSharp.dll" | Select-Object -First 1
        if ($ExtractedDll) {
            Copy-Item -Path $ExtractedDll.FullName -Destination $TagLibPath -Force
            Write-Log "TagLibSharp.dll downloaded and installed successfully."
        }
        else {
            throw "Could not locate TagLibSharp.dll in the downloaded package."
        }
        Remove-Item $ZipPath -Force
    }
    catch {
        Write-ErrorLog "Failed to download TagLibSharp." $_
        [System.Windows.Forms.MessageBox]::Show("Critical Error: TagLibSharp.dll could not be downloaded. Please manually place it in the 'lib' folder.", "Missing Dependency", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }
}

# Load Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    Add-Type -Path $TagLibPath
    Write-Log "TagLibSharp assembly loaded."
}
catch {
    Write-ErrorLog "Failed to load TagLibSharp assembly." $_
    exit
}

# -----------------------------------------------------------------------------
# 5. --- UI CONSTRUCTION ---
# -----------------------------------------------------------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()

# -- Colors & Styles --
$Color_TealDark = [System.Drawing.Color]::FromArgb(0, 128, 128)
$Color_TealLight = [System.Drawing.Color]::FromArgb(0, 160, 160)
$Color_GreyLight = [System.Drawing.Color]::FromArgb(240, 240, 240)
$Color_GreyDark = [System.Drawing.Color]::FromArgb(200, 200, 200)
$Color_White = [System.Drawing.Color]::White
$Color_Control = [System.Drawing.SystemColors]::Control
$Color_ControlLight = [System.Drawing.SystemColors]::ControlLight
$Color_Link = [System.Drawing.Color]::Blue

# -- Icons (High Quality Loading) --
function Load-Icon {
    param($Name)
    $Path = Join-Path $IconsDir $Name
    if (Test-Path $Path) {
        try {
            # Use constructor to load full resolution icon
            return New-Object System.Drawing.Icon($Path)
        }
        catch {
            Write-Warning "Failed to load icon $Name : $($_.Exception.Message)"
        }
    }
    return $null
}

$Icon_App = Load-Icon "App-Icon.ico"
$Icon_Help = Load-Icon "HELP.ico"
$Icon_Alert = Load-Icon "ALERT-IMPORTANT.ico"
$Icon_Info = Load-Icon "INFORMATION-WARNING.ico"
$Icon_MP3 = Load-Icon "MP3-File.ico"
$Icon_WhatsNew = Load-Icon "WHATS NEW.ico"
$Icon_Welcome = Load-Icon "WELCOME BACK.ico"
$Icon_Save = Load-Icon "SAVE ICON.ico"
$Icon_Spin = Load-Icon "SPIN THE DISK.ico"
$Icon_Folder = Load-Icon "FOLDER ICON.ico"

# Fallback Icon
if ($null -eq $Icon_App) {
    $IconPath = Join-Path $PSHOME "pwsh.exe"
    if (-not (Test-Path $IconPath)) { $IconPath = Join-Path $PSHOME "powershell.exe" }
    if (Test-Path $IconPath) { try { $Icon_App = [System.Drawing.Icon]::ExtractAssociatedIcon($IconPath) } catch {} }
}

# -- Helper: Custom Message Box --
function Show-MessageBox {
    param(
        [string]$Message,
        [string]$Title,
        [string]$ButtonText = "OK",
        [string]$Type = "Info"
    )
    
    $MsgForm = New-Object System.Windows.Forms.Form
    $MsgForm.Text = $Title
    $MsgForm.Size = New-Object System.Drawing.Size(450, 220)
    $MsgForm.StartPosition = "CenterParent"
    $MsgForm.BackColor = $Color_Control
    $MsgForm.FormBorderStyle = "FixedDialog"
    $MsgForm.MaximizeBox = $false
    $MsgForm.MinimizeBox = $false
    if ($Icon_App) { $MsgForm.Icon = $Icon_App }

    # Icon
    $IconBox = New-Object System.Windows.Forms.PictureBox
    $IconBox.Size = New-Object System.Drawing.Size(48, 48)
    $IconBox.Location = New-Object System.Drawing.Point(20, 20)
    $IconBox.SizeMode = "Zoom"
    
    if ($Type -eq "Error" -and $Icon_Alert) { $IconBox.Image = $Icon_Alert.ToBitmap() }
    elseif ($Type -eq "Info" -and $Icon_Info) { $IconBox.Image = $Icon_Info.ToBitmap() }
    else { $IconBox.Image = [System.Drawing.SystemIcons]::Information.ToBitmap() }
    
    $MsgForm.Controls.Add($IconBox)

    # Message
    $lblMsg = New-Object System.Windows.Forms.Label
    $lblMsg.Text = $Message
    $lblMsg.Location = New-Object System.Drawing.Point(80, 20)
    $lblMsg.Size = New-Object System.Drawing.Size(330, 90)
    $lblMsg.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $MsgForm.Controls.Add($lblMsg)

    # Bottom Panel
    $BotPanel = New-Object System.Windows.Forms.Panel
    $BotPanel.Dock = "Bottom"
    $BotPanel.Height = 50
    $BotPanel.BackColor = $Color_ControlLight
    $MsgForm.Controls.Add($BotPanel)

    # Button
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $ButtonText
    $btn.Location = New-Object System.Drawing.Point(330, 10)
    $btn.Size = New-Object System.Drawing.Size(90, 30)
    $btn.UseVisualStyleBackColor = $true
    $btn.Add_Click({ $MsgForm.Close() })
    $BotPanel.Controls.Add($btn)

    $MsgForm.ShowDialog() | Out-Null
}

# -- Helper: Create Gradient Header (Robust Version) --
function Create-GradientHeader {
    param($ParentForm, $TitleText, $IconToUse)
    
    $HeaderPanel = New-Object System.Windows.Forms.Panel
    $HeaderPanel.Dock = "Top"
    $HeaderPanel.Height = 70
    $HeaderPanel.BackColor = $Color_TealDark
    
    # Gradient Paint
    $HeaderPanel.Add_Paint({
            param($sender, $e)
            $rect = $sender.ClientRectangle
            $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $Color_TealLight, $Color_TealDark, 90)
            $e.Graphics.FillRectangle($brush, $rect)
        })
    
    $ParentForm.Controls.Add($HeaderPanel)

    # Icon (PictureBox)
    if ($IconToUse) {
        $Pic = New-Object System.Windows.Forms.PictureBox
        $Pic.Size = New-Object System.Drawing.Size(48, 48)
        $Pic.Location = New-Object System.Drawing.Point(10, 10)
        $Pic.SizeMode = "Zoom"
        $Pic.BackColor = [System.Drawing.Color]::Transparent
        $Pic.Image = $IconToUse.ToBitmap()
        $HeaderPanel.Controls.Add($Pic)
    }

    # Title (Label with Shadow Effect)
    $lblShadow = New-Object System.Windows.Forms.Label
    $lblShadow.Text = $TitleText
    $lblShadow.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblShadow.ForeColor = [System.Drawing.Color]::Black
    $lblShadow.BackColor = [System.Drawing.Color]::Transparent
    $lblShadow.AutoSize = $true
    $lblShadow.Location = New-Object System.Drawing.Point(72, 17)
    $HeaderPanel.Controls.Add($lblShadow)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $TitleText
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(70, 15)
    $HeaderPanel.Controls.Add($lblTitle)
    
    $lblTitle.BringToFront()
}

# -- Main Form --
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "EliteSoftware - MP3 Toolkit"
$Form.Size = New-Object System.Drawing.Size(1200, 900)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Color_Control
if ($Icon_App) { $Form.Icon = $Icon_App }

# -- Menu Bar --
$MenuStrip = New-Object System.Windows.Forms.MenuStrip
$MenuStrip.BackgroundImageLayout = "Stretch"
# Create simple gradient image for MenuStrip
$bmp = New-Object System.Drawing.Bitmap(1, 50)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(0, 0, 1, 50)), $Color_GreyLight, $Color_GreyDark, 90)
$g.FillRectangle($brush, 0, 0, 1, 50)
$g.Dispose()
$MenuStrip.BackgroundImage = $bmp
$Form.Controls.Add($MenuStrip)

$FileMenu = $MenuStrip.Items.Add("File")
$FileMenu.DropDownItems.Add("Open Folder...", $null, { Open-Folder })
$FileMenu.DropDownItems.Add("Save Copy to Safe House...", $null, { Save-File })
$FileMenu.DropDownItems.Add("-")
$FileMenu.DropDownItems.Add("Exit", $null, { $Form.Close() })

$HelpMenu = $MenuStrip.Items.Add("Help")
$HelpMenu.DropDownItems.Add("Guidance System", $null, { Show-Help })
$HelpMenu.DropDownItems.Add("What's New?", $null, { Show-WhatsNew })
$HelpMenu.DropDownItems.Add("About", $null, { Show-About })

# -- Header Panel --
Create-GradientHeader $Form "EliteSoftware - MP3 Toolkit" $Icon_App

# -- Status Bar --
$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$StatusStrip.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLabel.Text = "Ready"
$StatusStrip.Items.Add($StatusLabel)
$Form.Controls.Add($StatusStrip)

# -- Main Layout (Split Container) --
$SplitContainer = New-Object System.Windows.Forms.SplitContainer
$SplitContainer.Dock = "Fill"
$SplitContainer.FixedPanel = "None" # Allow resizing freely
$SplitContainer.SplitterDistance = 300 
$SplitContainer.SplitterWidth = 8 # Wider splitter
$SplitContainer.BackColor = [System.Drawing.Color]::Silver # Visible splitter color
$Form.Controls.Add($SplitContainer)
$SplitContainer.BringToFront()

# -- Left Panel (File Browser) --
$TreePanel = New-Object System.Windows.Forms.Panel
$TreePanel.Dock = "Fill"
$TreePanel.Padding = New-Object System.Windows.Forms.Padding(0) # Remove padding to fix cutoff
$TreePanel.BackColor = $Color_Control
$SplitContainer.Panel1.Controls.Add($TreePanel)

$lblBrowser = New-Object System.Windows.Forms.Label
$lblBrowser.Text = "File Browser:"
$lblBrowser.Dock = "Top"
$lblBrowser.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblBrowser.Padding = New-Object System.Windows.Forms.Padding(5)
$TreePanel.Controls.Add($lblBrowser)

# Container for TreeView to show border
$TreeContainer = New-Object System.Windows.Forms.Panel
$TreeContainer.Dock = "Fill"
$TreeContainer.BorderStyle = "Fixed3D" 
$TreeContainer.Padding = New-Object System.Windows.Forms.Padding(2)
$TreePanel.Controls.Add($TreeContainer)

$TreeView = New-Object System.Windows.Forms.TreeView
$TreeView.Dock = "Fill"
$TreeView.BorderStyle = "None" 
$TreeView.Scrollable = $true
$TreeView.Add_AfterSelect({ $global:SelectedFile = $TreeView.SelectedNode.Tag; Load-Metadata })

# -- TreeView Icons --
$ImageList = New-Object System.Windows.Forms.ImageList
$ImageList.ColorDepth = "Depth32Bit"
$ImageList.ImageSize = New-Object System.Drawing.Size(24, 24) # Standard tree size, high quality

if ($Icon_MP3) { $ImageList.Images.Add("mp3", $Icon_MP3) }
if ($Icon_Folder) { $ImageList.Images.Add("folder", $Icon_Folder) }

$TreeView.ImageList = $ImageList
$TreeContainer.Controls.Add($TreeView)

$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = "Browse for Tunes"
$btnOpenFolder.Dock = "Bottom"
$btnOpenFolder.Height = 40
$btnOpenFolder.UseVisualStyleBackColor = $true
$btnOpenFolder.Add_Click({ Open-Folder })
$TreePanel.Controls.Add($btnOpenFolder)

# -- Right Panel (Editor) --
$EditorPanel = New-Object System.Windows.Forms.Panel
$EditorPanel.Dock = "Fill"
$EditorPanel.Padding = New-Object System.Windows.Forms.Padding(20)
$EditorPanel.AutoScroll = $true 
$EditorPanel.BackColor = $Color_Control
$SplitContainer.Panel2.Controls.Add($EditorPanel)

# -- Album Art Section --
$ArtGroup = New-Object System.Windows.Forms.GroupBox
$ArtGroup.Text = "Visual Stimulation (Album Art)"
$ArtGroup.Size = New-Object System.Drawing.Size(300, 350)
$ArtGroup.Location = New-Object System.Drawing.Point(600, 20)
$EditorPanel.Controls.Add($ArtGroup)

$PictureBox = New-Object System.Windows.Forms.PictureBox
$PictureBox.Size = New-Object System.Drawing.Size(280, 280)
$PictureBox.Location = New-Object System.Drawing.Point(10, 20)
$PictureBox.BorderStyle = "FixedSingle"
$PictureBox.SizeMode = "Zoom"
$ArtGroup.Controls.Add($PictureBox)

$btnAddArt = New-Object System.Windows.Forms.Button
$btnAddArt.Text = "Slap a sticker on it"
$btnAddArt.Location = New-Object System.Drawing.Point(10, 310)
$btnAddArt.Size = New-Object System.Drawing.Size(135, 30)
$btnAddArt.UseVisualStyleBackColor = $true
$btnAddArt.Add_Click({ Add-Art })
$ArtGroup.Controls.Add($btnAddArt)

$btnRemoveArt = New-Object System.Windows.Forms.Button
$btnRemoveArt.Text = "Nuke the art"
$btnRemoveArt.Location = New-Object System.Drawing.Point(155, 310)
$btnRemoveArt.Size = New-Object System.Drawing.Size(135, 30)
$btnRemoveArt.UseVisualStyleBackColor = $true
$btnRemoveArt.Add_Click({ Remove-Art })
$ArtGroup.Controls.Add($btnRemoveArt)

# -- Metadata Section --
$MetaGroup = New-Object System.Windows.Forms.GroupBox
$MetaGroup.Text = "The Nitty Gritty (Metadata)"
$MetaGroup.Size = New-Object System.Drawing.Size(550, 700) # Increased height + padding
$MetaGroup.Location = New-Object System.Drawing.Point(20, 20)
$EditorPanel.Controls.Add($MetaGroup)

# Global Control Map to ensure access
$global:MetaControls = @{}

function Create-MetaField {
    param($Label, $Y, $Key)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Label
    $lbl.Location = New-Object System.Drawing.Point(20, $Y)
    $lbl.AutoSize = $true
    $MetaGroup.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $YInt = [int]$Y
    $txt.Location = New-Object System.Drawing.Point(140, ($YInt - 3))
    $txt.Size = New-Object System.Drawing.Size(300, 25) # Shrunk by ~20%
    $MetaGroup.Controls.Add($txt)
    
    $global:MetaControls[$Key] = $txt
}

# Filename (Special)
$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = "Filename:"
$lblFile.Location = New-Object System.Drawing.Point(20, 30)
$lblFile.AutoSize = $true
$MetaGroup.Controls.Add($lblFile)

$txtFilename = New-Object System.Windows.Forms.TextBox
$txtFilename.Location = New-Object System.Drawing.Point(140, 27)
$txtFilename.Size = New-Object System.Drawing.Size(300, 25)
$MetaGroup.Controls.Add($txtFilename)
$global:MetaControls["Filename"] = $txtFilename

# Standard Fields (Shifted down)
Create-MetaField "Title:" 70 "Title"
Create-MetaField "Artist:" 110 "Artist"
Create-MetaField "Album:" 150 "Album"
Create-MetaField "Album Artist:" 190 "AlbumArtist"
Create-MetaField "Year:" 230 "Year"
Create-MetaField "Genre:" 270 "Genre"
Create-MetaField "Track #:" 310 "Track"
Create-MetaField "BPM:" 350 "BPM"
Create-MetaField "Subtitle:" 390 "Subtitle"
Create-MetaField "Publisher:" 430 "Publisher"
Create-MetaField "Composer(s):" 470 "Composers"
Create-MetaField "Conductor(s):" 510 "Conductors"
Create-MetaField "Copyright:" 550 "Copyright"
Create-MetaField "Comment:" 590 "Comment"

# Rating Field
$lblRating = New-Object System.Windows.Forms.Label
$lblRating.Text = "Rating (0-5):"
$lblRating.Location = New-Object System.Drawing.Point(20, 630)
$lblRating.AutoSize = $true
$MetaGroup.Controls.Add($lblRating)

$cmbRating = New-Object System.Windows.Forms.ComboBox
$cmbRating.Location = New-Object System.Drawing.Point(140, 627)
$cmbRating.Size = New-Object System.Drawing.Size(100, 25)
$cmbRating.DropDownStyle = "DropDownList"
0..5 | ForEach-Object { $cmbRating.Items.Add($_) }
$MetaGroup.Controls.Add($cmbRating)
$global:MetaControls["Rating"] = $cmbRating

# -- Playback Controls --
$PlayerGroup = New-Object System.Windows.Forms.GroupBox
$PlayerGroup.Text = "Noise Maker"
$PlayerGroup.Size = New-Object System.Drawing.Size(300, 100)
$PlayerGroup.Location = New-Object System.Drawing.Point(600, 400)
$EditorPanel.Controls.Add($PlayerGroup)

# Spin Icon
if ($Icon_Spin) {
    $picSpin = New-Object System.Windows.Forms.PictureBox
    $picSpin.Size = New-Object System.Drawing.Size(32, 32)
    $picSpin.Location = New-Object System.Drawing.Point(240, 30)
    $picSpin.SizeMode = "Zoom"
    $picSpin.Image = $Icon_Spin.ToBitmap()
    $PlayerGroup.Controls.Add($picSpin)
}

$btnPlay = New-Object System.Windows.Forms.Button
$btnPlay.Text = "Spin the disk"
$btnPlay.Location = New-Object System.Drawing.Point(20, 30)
$btnPlay.Size = New-Object System.Drawing.Size(100, 40)
$btnPlay.UseVisualStyleBackColor = $true
$btnPlay.Add_Click({ Play-Audio })
$PlayerGroup.Controls.Add($btnPlay)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Silence!"
$btnStop.Location = New-Object System.Drawing.Point(130, 30)
$btnStop.Size = New-Object System.Drawing.Size(100, 40)
$btnStop.UseVisualStyleBackColor = $true
$btnStop.Add_Click({ Stop-Audio })
$PlayerGroup.Controls.Add($btnStop)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready to rock."
$lblStatus.Location = New-Object System.Drawing.Point(20, 80)
$lblStatus.AutoSize = $true
$PlayerGroup.Controls.Add($lblStatus)

# -- Save Button --
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Copy to Safe House"
$btnSave.Location = New-Object System.Drawing.Point(600, 520)
$btnSave.Size = New-Object System.Drawing.Size(300, 80)
$btnSave.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnSave.UseVisualStyleBackColor = $true
if ($Icon_Save) {
    $btnSave.ImageAlign = "MiddleLeft"
    $btnSave.TextImageRelation = "ImageBeforeText"
    $btnSave.Image = $Icon_Save.ToBitmap()
}
$btnSave.Add_Click({ Save-File })
$EditorPanel.Controls.Add($btnSave)

# -----------------------------------------------------------------------------
# 6. --- LOGIC FUNCTIONS ---
# -----------------------------------------------------------------------------
$global:MediaPlayer = New-Object System.Media.SoundPlayer
$global:WMP = New-Object -ComObject WMPlayer.OCX.7
$global:SelectedFile = $null
$global:CurrentArtBytes = $null
$global:PendingChanges = @{} # Key: FilePath, Value: Hashtable of changes

function Open-Folder {
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FolderBrowser.ShowDialog() -eq "OK") {
        $TreeView.Nodes.Clear()
        $RootNode = $TreeView.Nodes.Add($FolderBrowser.SelectedPath)
        $RootNode.ImageKey = "folder"
        $RootNode.SelectedImageKey = "folder"
        
        $Files = Get-ChildItem -Path $FolderBrowser.SelectedPath -Filter "*.mp3"
        foreach ($File in $Files) {
            $Node = $RootNode.Nodes.Add($File.Name)
            $Node.Tag = $File.FullName
            $Node.ImageKey = "mp3"
            $Node.SelectedImageKey = "mp3"
        }
        $RootNode.Expand()
        $StatusLabel.Text = "Opened folder: $($FolderBrowser.SelectedPath)"
        Write-Log "Opened folder: $($FolderBrowser.SelectedPath)"
    }
}

function Save-Current-State {
    if (-not $global:SelectedFile) { return }
    
    $state = @{
        Filename    = $global:MetaControls["Filename"].Text
        Title       = $global:MetaControls["Title"].Text
        Artist      = $global:MetaControls["Artist"].Text
        Album       = $global:MetaControls["Album"].Text
        AlbumArtist = $global:MetaControls["AlbumArtist"].Text
        Year        = $global:MetaControls["Year"].Text
        Genre       = $global:MetaControls["Genre"].Text
        Track       = $global:MetaControls["Track"].Text
        BPM         = $global:MetaControls["BPM"].Text
        Subtitle    = $global:MetaControls["Subtitle"].Text
        Publisher   = $global:MetaControls["Publisher"].Text
        Composers   = $global:MetaControls["Composers"].Text
        Conductors  = $global:MetaControls["Conductors"].Text
        Copyright   = $global:MetaControls["Copyright"].Text
        Comment     = $global:MetaControls["Comment"].Text
        Rating      = $global:MetaControls["Rating"].SelectedItem
        Art         = $global:CurrentArtBytes
        HasArt      = ($null -ne $PictureBox.Image)
    }
    
    $global:PendingChanges[$global:SelectedFile] = $state
}

function Load-Metadata {
    Write-Log "Load-Metadata triggered."
    
    if ($global:SelectedFile) { Save-Current-State }

    $global:SelectedFile = $TreeView.SelectedNode.Tag
    Write-Log "Selected File: $global:SelectedFile"

    if (-not $global:SelectedFile) { 
        Write-Log "No file selected or tag is empty." "WARN"
        return 
    }
    
    # Fallback: Always show filename first
    $global:MetaControls["Filename"].Text = Split-Path $global:SelectedFile -Leaf

    if ($global:PendingChanges.ContainsKey($global:SelectedFile)) {
        Write-Log "Loading from pending changes."
        $state = $global:PendingChanges[$global:SelectedFile]
        $global:MetaControls["Filename"].Text = $state.Filename
        $global:MetaControls["Title"].Text = $state.Title
        $global:MetaControls["Artist"].Text = $state.Artist
        $global:MetaControls["Album"].Text = $state.Album
        $global:MetaControls["AlbumArtist"].Text = $state.AlbumArtist
        $global:MetaControls["Year"].Text = $state.Year
        $global:MetaControls["Genre"].Text = $state.Genre
        $global:MetaControls["Track"].Text = $state.Track
        $global:MetaControls["BPM"].Text = $state.BPM
        $global:MetaControls["Subtitle"].Text = $state.Subtitle
        $global:MetaControls["Publisher"].Text = $state.Publisher
        $global:MetaControls["Composers"].Text = $state.Composers
        $global:MetaControls["Conductors"].Text = $state.Conductors
        $global:MetaControls["Copyright"].Text = $state.Copyright
        $global:MetaControls["Comment"].Text = $state.Comment
        $global:MetaControls["Rating"].SelectedItem = $state.Rating
        
        $global:CurrentArtBytes = $state.Art
        if ($state.HasArt -and $global:CurrentArtBytes) {
            $ms = New-Object System.IO.MemoryStream(, $global:CurrentArtBytes)
            $PictureBox.Image = [System.Drawing.Image]::FromStream($ms)
        }
        else {
            $PictureBox.Image = $null
        }
    }
    else {
        Write-Log "Loading from disk via TagLib."
        try {
            $tfile = [TagLib.File]::Create($global:SelectedFile)
            if ($null -eq $tfile) { throw "TagLib returned null for file." }
            
            $tag = $tfile.Tag
            if ($null -eq $tag) { throw "Tag object is null." }
            
            $global:MetaControls["Title"].Text = $tag.Title
            $global:MetaControls["Artist"].Text = $tag.FirstPerformer
            $global:MetaControls["Album"].Text = $tag.Album
            $global:MetaControls["AlbumArtist"].Text = $tag.FirstAlbumArtist
            $global:MetaControls["Year"].Text = $tag.Year
            $global:MetaControls["Genre"].Text = $tag.FirstGenre
            $global:MetaControls["Track"].Text = $tag.Track
            $global:MetaControls["BPM"].Text = $tag.BeatsPerMinute
            $global:MetaControls["Subtitle"].Text = $tag.Subtitle
            $global:MetaControls["Publisher"].Text = $tag.Publisher
            $global:MetaControls["Composers"].Text = [string]::Join(", ", $tag.Composers)
            $global:MetaControls["Conductors"].Text = [string]::Join(", ", $tag.Conductors)
            $global:MetaControls["Copyright"].Text = $tag.Copyright
            $global:MetaControls["Comment"].Text = $tag.Comment
            $global:MetaControls["Rating"].SelectedItem = 0 
            
            if ($tag.Pictures.Count -gt 0) {
                $pic = $tag.Pictures[0]
                $ms = New-Object System.IO.MemoryStream(, $pic.Data.Data)
                $PictureBox.Image = [System.Drawing.Image]::FromStream($ms)
                $global:CurrentArtBytes = $pic.Data.Data
            }
            else {
                $PictureBox.Image = $null
                $global:CurrentArtBytes = $null
            }
            $tfile.Dispose()
            Write-Log "Metadata loaded successfully."
        }
        catch {
            Write-ErrorLog "Error loading metadata" $_
            $StatusLabel.Text = "Error loading metadata."
            # Do not show message box for every error to avoid spam, just log it.
        }
    }
    $StatusLabel.Text = "Loaded: $(Split-Path $global:SelectedFile -Leaf)"
}

function Add-Art {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "Image Files|*.jpg;*.jpeg;*.png;*.bmp"
    if ($OpenFileDialog.ShowDialog() -eq "OK") {
        $PictureBox.Image = [System.Drawing.Image]::FromFile($OpenFileDialog.FileName)
        $global:CurrentArtBytes = [System.IO.File]::ReadAllBytes($OpenFileDialog.FileName)
        Write-Log "Staged new album art."
    }
}

function Remove-Art {
    $PictureBox.Image = $null
    $global:CurrentArtBytes = $null
    Write-Log "Cleared album art."
}

function Play-Audio {
    if (-not $global:SelectedFile) { return }
    try {
        $global:WMP.URL = $global:SelectedFile
        $global:WMP.Controls.play()
        $lblStatus.Text = "Playing: $(Split-Path $global:SelectedFile -Leaf)"
        $StatusLabel.Text = "Playing..."
        Write-Log "Started playback."
    }
    catch {
        Write-ErrorLog "Playback error" $_
    }
}

function Stop-Audio {
    $global:WMP.Controls.stop()
    $lblStatus.Text = "Silence."
    $StatusLabel.Text = "Stopped."
    Write-Log "Stopped playback."
}

function Save-File {
    Save-Current-State
    
    if ($global:PendingChanges.Count -eq 0) {
        Show-MessageBox "You haven't changed anything yet!" "Nothing to do" "OK" "Info"
        return
    }
    
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = "Select the Safe House (Output Folder)"
    if ($FolderBrowser.ShowDialog() -eq "OK") {
        $DestDir = $FolderBrowser.SelectedPath
        
        $count = 0
        foreach ($file in $global:PendingChanges.Keys) {
            $state = $global:PendingChanges[$file]
            $FileName = $state.Filename
            if (-not $FileName) { $FileName = Split-Path $file -Leaf }
            
            $DestPath = [System.IO.Path]::Combine($DestDir, $FileName)
            
            try {
                Copy-Item -Path $file -Destination $DestPath -Force
                
                $tfile = [TagLib.File]::Create($DestPath)
                $tag = $tfile.Tag
                
                $tag.Title = $state.Title
                $tag.Performers = @($state.Artist)
                $tag.Album = $state.Album
                $tag.AlbumArtists = @($state.AlbumArtist)
                $tag.Year = [uint32]$state.Year
                $tag.Genres = @($state.Genre)
                $tag.Track = [uint32]$state.Track
                $tag.BeatsPerMinute = [uint32]$state.BPM
                $tag.Subtitle = $state.Subtitle
                $tag.Publisher = $state.Publisher
                $tag.Composers = @($state.Composers)
                $tag.Conductors = @($state.Conductors)
                $tag.Copyright = $state.Copyright
                $tag.Comment = $state.Comment
                
                if ($state.HasArt -and $state.Art) {
                    $vect = New-Object TagLib.ByteVector($state.Art)
                    $pic = New-Object TagLib.Picture($vect)
                    $tag.Pictures = @($pic)
                }
                else {
                    $tag.Pictures = @()
                }
                
                $tfile.Save()
                $tfile.Dispose()
                $count++
            }
            catch {
                Write-ErrorLog "Failed to save file: $file" $_
            }
        }
        
        Show-MessageBox "Successfully saved $count files to the Safe House!" "Mission Accomplished" "OK" "Info"
        Write-Log "Batch save completed. Processed $count files."
        $StatusLabel.Text = "Saved $count files."
        $global:PendingChanges.Clear()
    }
}

# -- Dialog Functions --
function Show-About {
    $config = Get-Config
    $AboutForm = New-Object System.Windows.Forms.Form
    $AboutForm.Text = "About EliteSoftware - MP3 Toolkit"
    $AboutForm.Size = New-Object System.Drawing.Size(600, 500)
    $AboutForm.StartPosition = "CenterParent"
    $AboutForm.BackColor = $Color_Control
    $AboutForm.FormBorderStyle = "FixedDialog"
    $AboutForm.MaximizeBox = $false
    $AboutForm.MinimizeBox = $false
    if ($Icon_Info) { $AboutForm.Icon = $Icon_Info }

    Create-GradientHeader $AboutForm "EliteSoftware - MP3 Toolkit" $Icon_Info

    $ContentBox = New-Object System.Windows.Forms.RichTextBox
    $ContentBox.Location = New-Object System.Drawing.Point(20, 80)
    $ContentBox.Size = New-Object System.Drawing.Size(540, 250)
    $ContentBox.ReadOnly = $true
    $ContentBox.BorderStyle = "None"
    $ContentBox.BackColor = $Color_Control
    $ContentBox.Text = "EliteSoftware - MP3 Toolkit`nVersion: v1.7.0.0`n(c) 2025 EliteSoftware - Zachary Whiteman - Gemini AI.`n`nAn application for discovering and extracting joy from MP3 files.`n`nWarning: This is ALPHA software. Use at your own risk."
    $AboutForm.Controls.Add($ContentBox)
    
    $LinkLabel = New-Object System.Windows.Forms.LinkLabel
    $LinkLabel.Text = "Visit EliteSoftware Company Site"
    $LinkLabel.Location = New-Object System.Drawing.Point(20, 340)
    $LinkLabel.AutoSize = $true
    $LinkLabel.LinkColor = $Color_Link
    $LinkLabel.Add_LinkClicked({ 
            try {
                Start-Process -FilePath ([System.IO.Path]::Combine($ScriptBaseDir, "about_template.html")) 
            }
            catch {
                Show-MessageBox "Could not open the website. The internet is probably broken." "Error" "OK" "Error"
            }
        })
    $AboutForm.Controls.Add($LinkLabel)

    # Bottom Panel
    $BotPanel = New-Object System.Windows.Forms.Panel
    $BotPanel.Dock = "Bottom"
    $BotPanel.Height = 50
    $BotPanel.BackColor = $Color_ControlLight
    $AboutForm.Controls.Add($BotPanel)

    $chkShow = New-Object System.Windows.Forms.CheckBox
    $chkShow.Text = "Show startup hints"
    $chkShow.Checked = $config.ShowStartupHints
    $chkShow.Location = New-Object System.Drawing.Point(20, 15)
    $chkShow.AutoSize = $true
    $BotPanel.Controls.Add($chkShow)

    $btnDebug = New-Object System.Windows.Forms.Button
    $btnDebug.Text = "Copy Debug Info"
    $btnDebug.Location = New-Object System.Drawing.Point(150, 10)
    $btnDebug.Size = New-Object System.Drawing.Size(120, 30)
    $btnDebug.UseVisualStyleBackColor = $true
    $btnDebug.Add_Click({ [System.Windows.Forms.Clipboard]::SetText("Debug Info: EliteSoftware MP3 Toolkit v1.7.0.0") })
    $BotPanel.Controls.Add($btnDebug)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "OK"
    $btnOk.Location = New-Object System.Drawing.Point(480, 10)
    $btnOk.Size = New-Object System.Drawing.Size(90, 30)
    $btnOk.UseVisualStyleBackColor = $true
    $btnOk.Add_Click({ 
            $config.ShowStartupHints = $chkShow.Checked
            Set-Config $config
            $AboutForm.Close() 
        })
    $BotPanel.Controls.Add($btnOk)

    $AboutForm.ShowDialog() | Out-Null
}

function Show-WhatsNew {
    $NewsForm = New-Object System.Windows.Forms.Form
    $NewsForm.Text = "What's New in EliteSoftware - MP3 Toolkit"
    $NewsForm.Size = New-Object System.Drawing.Size(600, 500)
    $NewsForm.StartPosition = "CenterParent"
    $NewsForm.BackColor = $Color_Control
    $NewsForm.FormBorderStyle = "FixedDialog"
    $NewsForm.MaximizeBox = $false
    $NewsForm.MinimizeBox = $false
    if ($Icon_WhatsNew) { $NewsForm.Icon = $Icon_WhatsNew } 
    
    Create-GradientHeader $NewsForm "Fresh Features in v1.7.0.0!" $Icon_WhatsNew
    
    $ContentBox = New-Object System.Windows.Forms.RichTextBox
    $ContentBox.Location = New-Object System.Drawing.Point(20, 80)
    $ContentBox.Size = New-Object System.Drawing.Size(540, 320)
    $ContentBox.ReadOnly = $true
    $ContentBox.BorderStyle = "FixedSingle"
    $ContentBox.BackColor = $Color_Control
    $ContentBox.Text = "--- What's New in v1.7.0.0 ---`n- High-Res Icons: No more blurriness.`n- Metadata Fallback: Filename always shows up.`n- Tree View Fixes: Better layout and resizing.`n`n--- v1.6.0.0 ---`n- New Icons & Metadata Fix.`n`n--- v1.5.0.0 ---`n- Robust Banners & Debugging.`n`n--- v1.4.0.0 ---`n- Gradient Banners & Shadows.`n`n--- v1.3.0.0 ---`n- Layout Polish.`n`n--- v1.2.0.0 ---`n- Strict UI Refinement.`n`n--- v1.1.0.0 ---`n- UI Overhaul & Metadata Expansion.`n`n--- v1.0.0.0 ---`n- Initial Release."
    $NewsForm.Controls.Add($ContentBox)
    
    $BotPanel = New-Object System.Windows.Forms.Panel
    $BotPanel.Dock = "Bottom"
    $BotPanel.Height = 50
    $BotPanel.BackColor = $Color_ControlLight
    $NewsForm.Controls.Add($BotPanel)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Awesome!"
    $btnOk.Location = New-Object System.Drawing.Point(480, 10)
    $btnOk.Size = New-Object System.Drawing.Size(90, 30)
    $btnOk.UseVisualStyleBackColor = $true
    $btnOk.Add_Click({ $NewsForm.Close() })
    $BotPanel.Controls.Add($btnOk)
    
    $NewsForm.ShowDialog() | Out-Null
}

function Show-Help {
    $HelpForm = New-Object System.Windows.Forms.Form
    $HelpForm.Text = "EliteSoftware - Guidance System"
    $HelpForm.Size = New-Object System.Drawing.Size(600, 500)
    $HelpForm.StartPosition = "CenterParent"
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
        $Page.Controls.Add($Txt)
        
        $TabControl.TabPages.Add($Page)
    }

    Add-Tab "General Usage" "How to drive this thing:`r`n`r`n1. Click 'Browse for Tunes' to find your MP3 stash.`r`n2. Click a file in the tree view.`r`n3. Edit the metadata fields.`r`n4. Slap some new art on it if you want.`r`n5. Click 'Save Copy to Safe House' to export."
    Add-Tab "Version History" "v1.7.0.0 (2025-11-20)`r`n- High-Res Icons & Tree Fixes.`r`n`r`nv1.6.0.0`r`n- New Icons & Metadata Fix.`r`n`r`nv1.5.0.0`r`n- Robust Banners & Debugging.`r`n`r`nv1.4.0.0`r`n- Gradient Banners & Shadows.`r`n`r`nv1.3.0.0`r`n- Layout Polish.`r`n`r`nv1.2.0.0`r`n- Strict UI Refinement.`r`n`r`nv1.1.0.0`r`n- UI Overhaul & Metadata Expansion.`r`n`r`nv1.0.0.0`r`n- Initial Release."
    Add-Tab "Known Bugs" "- If you try to play a non-MP3 file, it might cry.`r`n- Sarcasm levels are critically high."
    Add-Tab "Future Updates" "- Telepathic metadata editing.`r`n- Coffee brewing integration."

    $BotPanel = New-Object System.Windows.Forms.Panel
    $BotPanel.Dock = "Bottom"
    $BotPanel.Height = 50
    $BotPanel.BackColor = $Color_ControlLight
    $HelpForm.Controls.Add($BotPanel)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Close"
    $btnOk.Location = New-Object System.Drawing.Point(480, 10)
    $btnOk.Size = New-Object System.Drawing.Size(90, 30)
    $btnOk.UseVisualStyleBackColor = $true
    $btnOk.Add_Click({ $HelpForm.Close() })
    $BotPanel.Controls.Add($btnOk)

    $HelpForm.ShowDialog() | Out-Null
}

function Show-StartupHints {
    $config = Get-Config
    if (-not $config.ShowStartupHints) { return }

    $HintForm = New-Object System.Windows.Forms.Form
    $HintForm.Text = "Welcome to EliteSoftware MP3 Toolkit"
    $HintForm.Size = New-Object System.Drawing.Size(500, 300)
    $HintForm.StartPosition = "CenterScreen"
    $HintForm.BackColor = $Color_Control
    $HintForm.FormBorderStyle = "FixedDialog"
    $HintForm.MaximizeBox = $false
    $HintForm.MinimizeBox = $false
    if ($Icon_Welcome) { $HintForm.Icon = $Icon_Welcome }

    Create-GradientHeader $HintForm "Welcome Back!" $Icon_Welcome

    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Text = "Did you know?`n`nYou can batch edit files by selecting them one by one and editing them. The app remembers your changes until you click 'Save Copy to Safe House'."
    $lblHint.Location = New-Object System.Drawing.Point(20, 80)
    $lblHint.Size = New-Object System.Drawing.Size(440, 100)
    $lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $HintForm.Controls.Add($lblHint)

    $BotPanel = New-Object System.Windows.Forms.Panel
    $BotPanel.Dock = "Bottom"
    $BotPanel.Height = 50
    $BotPanel.BackColor = $Color_ControlLight
    $HintForm.Controls.Add($BotPanel)

    $chkShow = New-Object System.Windows.Forms.CheckBox
    $chkShow.Text = "Show this on startup"
    $chkShow.Checked = $true
    $chkShow.Location = New-Object System.Drawing.Point(20, 15)
    $chkShow.AutoSize = $true
    $BotPanel.Controls.Add($chkShow)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Let's Go"
    $btnOk.Location = New-Object System.Drawing.Point(380, 10)
    $btnOk.Size = New-Object System.Drawing.Size(90, 30)
    $btnOk.UseVisualStyleBackColor = $true
    $btnOk.Add_Click({ 
            $config.ShowStartupHints = $chkShow.Checked
            Set-Config $config
            $HintForm.Close() 
        })
    $BotPanel.Controls.Add($btnOk)

    $HintForm.ShowDialog() | Out-Null
}

# -----------------------------------------------------------------------------
# 7. --- STARTUP ---
# -----------------------------------------------------------------------------
$Form.Add_Load({
        Write-Log "UI Loaded."
        Show-StartupHints
    })

$Form.ShowDialog() | Out-Null

# Cleanup WMP
$global:WMP.close()
