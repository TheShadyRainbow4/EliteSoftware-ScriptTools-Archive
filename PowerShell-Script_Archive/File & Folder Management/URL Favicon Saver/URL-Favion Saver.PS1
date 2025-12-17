# -----------------------------------------------------------------------
# Ultimate Favicon Downloader (Enterprise Edition)
# Version: 1.0.1.0
# Fixes: Titlebar Exit Crash, SVG handling, Path Logic, Settings Persistence
# Enhancements: Enhanced Logging, DuckDuckGo Fallback, Google S2 Fallback, HTML parsing upgrade
# -----------------------------------------------------------------------

# -----------------------------------------------------------------------
# 1. --- PORTABLE PATH & CONFIGURATION (LOGGING MODULE) ---
# -----------------------------------------------------------------------

# This line is the key: It finds the folder where the script itself is running.
$ScriptBaseDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# --- [!!] CUSTOMIZE THIS [!!] ---
$ConfigDirName = "FaviconDownloader_Config"
# --- [!!] --------------------- ---

# Build all paths relative to the script's location
$ConfigDir = [System.IO.Path]::Combine($ScriptBaseDir, $ConfigDirName)
$LogFilesDir = [System.IO.Path]::Combine($ConfigDir, "Log Files")
$ErrorLogDir = [System.IO.Path]::Combine($LogFilesDir, "Error Logs")
$HistoricalLogDir = [System.IO.Path]::Combine($LogFilesDir, "Historical Logs")
$HistoricalErrorLogDir = [System.IO.Path]::Combine($ErrorLogDir, "Historical Logs")
$Global:LiveLogFile = [System.IO.Path]::Combine($LogFilesDir, "LiveLog.json")
$ConfigPath = [System.IO.Path]::Combine($ConfigDir, "FaviconDownloader.settings.xml")

# 2. --- AUTOMATIC DIRECTORY CREATION ---
# Ensure all the folders we need actually exist, creating them if not.
@($ConfigDir, $LogFilesDir, $ErrorLogDir, $HistoricalLogDir, $HistoricalErrorLogDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# 3. --- LOGGING FUNCTIONS ---

<#
.SYNOPSIS
    Archives old logs to a historical folder on startup.
#>
function Archive-OldLogs {
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

<#
.SYNOPSIS
    Writes a standard message to the main "LiveLog.json" file and Console.
#>
function Write-Log {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [string]$Category = "INFO",
        [string]$Color = "Gray"
    )

    # Console Color Mapping
    switch ($Category) {
        "ERROR"   { $Color = "Red" }
        "WARN"    { $Color = "Yellow" }
        "SUCCESS" { $Color = "Green" }
        "ACTION"  { $Color = "Cyan" }
        "DEBUG"   { $Color = "DarkGray" }
        "UI"      { $Color = "Magenta" }
        Default   { $Color = "White" }
    }
    
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $ConsoleMessage = "[$Timestamp] [$Category]: $Message"
    Write-Host $ConsoleMessage -ForegroundColor $Color

    if ($Category -eq "WARN") { Write-Warning $Message }

    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Severity  = $Category
        Message   = $Message
    }

    try {
        # Append the JSON entry to the live log file
        $logEntry | ConvertTo-Json -Compress | Add-Content -Path $Global:LiveLogFile
    }
    catch {
        Write-Warning "Failed to write to LiveLog: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Writes a detailed error record to its own separate file for debugging.
#>
function Write-ErrorLog {
    param (
        [string]$ContextMessage,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    # Always write the error to the console
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
        
        # Also write a summary to the main LiveLog
        Write-Log -Message "An error occurred. Details in ErrorLog-$fileNameTimestamp.json. Context: $ContextMessage" -Category "ERROR"
    }
    catch {
        Write-Warning "Could not write to error log: $($_.Exception.Message)"
    }
}

# 4. --- RUN AT STARTUP ---
# Clean up old logs every time the script starts
Archive-OldLogs
Write-Log -Message "Script started. Logging system initialized." -Category "INFO"


# -----------------------------------------------------------------------
# CORE APPLICATION LOGIC
# -----------------------------------------------------------------------

# --- Global State Variables ---
$Global:CurrentFaviconImageObject = $null
$Global:CurrentMemoryStream = $null 
$Global:CurrentDefaultFileName = $null
$Global:Settings = @{
    HideConsole = $false
    OpenExplorer = $true
    LastSaveDir = [Environment]::GetFolderPath("Desktop")
}


# --- 2. Settings Functions (Enhanced) ---

function Load-Settings {
    Write-Log -Message "Attempting to load persistent settings from: $ConfigPath" -Category "DEBUG"
    
    if (Test-Path $ConfigPath) {
        try {
            [xml]$Config = Get-Content -Path $ConfigPath -Raw
            
            # Helper to safely get bool
            $Hide = $false
            if ($Config.Settings.HideConsole) { $Hide = [System.Convert]::ToBoolean($Config.Settings.HideConsole) }
            
            $OpenExp = $true
            if ($Config.Settings.OpenExplorer) { $OpenExp = [System.Convert]::ToBoolean($Config.Settings.OpenExplorer) }
            
            $SaveDir = [Environment]::GetFolderPath("Desktop")
            if ($Config.Settings.LastSaveDir -and (Test-Path $Config.Settings.LastSaveDir)) { 
                $SaveDir = $Config.Settings.LastSaveDir 
            }

            $Global:Settings.HideConsole = $Hide
            $Global:Settings.OpenExplorer = $OpenExp
            $Global:Settings.LastSaveDir = $SaveDir
            
            Write-Log -Message "Settings loaded successfully." -Category "SUCCESS"
        } catch {
            Write-Log -Message "Failed to parse settings file. Using defaults." -Category "WARN"
            Write-ErrorLog -ContextMessage "Load-Settings Failed" -ErrorRecord $_
        }
    } else {
        Write-Log -Message "No config found. Using defaults." -Category "INFO"
    }
}

function Save-Settings {
    Write-Log -Message "Saving settings to $ConfigPath" -Category "DEBUG"
    try {
        $ConfigXml = [xml]@"
<Settings>
    <HideConsole>$($Global:Settings.HideConsole)</HideConsole>
    <OpenExplorer>$($Global:Settings.OpenExplorer)</OpenExplorer>
    <LastSaveDir>$($Global:Settings.LastSaveDir)</LastSaveDir>
</Settings>
"@
        $ConfigXml.Save($ConfigPath)
        Write-Log -Message "Settings saved." -Category "SUCCESS"
    } catch {
        Write-Log -Message "Failed to save settings: $($_.Exception.Message)" -Category "ERROR"
    }
}


# --- 3. Self-Elevation and Console Logic ---

Load-Settings
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$CurrentHideConsoleState = $args -contains "-HideConsole"

if (-not $IsAdmin) {
    Write-Log -Message "Relaunch required: Not running as Administrator." -Category "WARN"
    
    $CurrentScript = $MyInvocation.MyCommand.Path
    $Arguments = "-File `"$CurrentScript`""
    
    if ($Global:Settings.HideConsole) {
        $Arguments = "-WindowStyle Hidden $Arguments -HideConsole"
        Write-Log -Message "Adding Hidden window style argument for relaunch." -Category "INFO"
    }

    $StartProcess = New-Object System.Diagnostics.ProcessStartInfo
    $StartProcess.FileName = $PSHOME + "\pwsh.exe"
    $StartProcess.Arguments = $Arguments
    $StartProcess.Verb = "RunAs"
    
    try {
        [System.Diagnostics.Process]::Start($StartProcess) | Out-Null
        Write-Log -Message "Original process exiting..." -Category "INFO"
        Exit
    } catch {
        Write-Log -Message "Failed to relaunch as admin." -Category "ERROR"
        Exit
    }
} elseif ($CurrentHideConsoleState) {
    Write-Log -Message "Running in hidden console mode." -Category "INFO"
} else {
    Write-Log -Message "Running as Administrator (Console visible)." -Category "INFO"
}


# --- Load Assemblies ---
Write-Log -Message "Loading .NET Assemblies..." -Category "DEBUG"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.WebClient
Add-Type -AssemblyName System.Xml 

[System.Windows.Forms.Application]::EnableVisualStyles()


# --- Global Helper: Convert to ICO ---

function Convert-ToICO {
    param(
        [Parameter(Mandatory=$true)][System.Drawing.Image]$ImageObject,
        [Parameter(Mandatory=$true)][string]$OutputFilePath
    )
    
    Write-Log -Message "Starting ICO conversion process..." -Category "DEBUG"
    try {
        $TargetSize = 128
        $Bitmap = New-Object System.Drawing.Bitmap($ImageObject, $TargetSize, $TargetSize)
        $Icon = [System.Drawing.Icon]::FromHandle($Bitmap.GetHicon())
        $FileStream = New-Object System.IO.FileStream($OutputFilePath, [System.IO.FileMode]::Create)
        $Icon.Save($FileStream)
        $FileStream.Close()
        
        $Bitmap.Dispose()
        $Icon.Dispose()
        Write-Log -Message "Image converted and saved to $OutputFilePath." -Category "SUCCESS"
        return $true
    } catch {
        Write-ErrorLog -ContextMessage "Convert-ToICO Failed" -ErrorRecord $_
        throw $_
    }
}


# --- Function: Load Image to Memory & Populate Previews ---

function Load-ImageToMemory {
    param(
        [Parameter(Mandatory=$true)][string]$URL,
        [Parameter(Mandatory=$true)][System.Windows.Forms.Label]$StatusControl,
        [Parameter(Mandatory=$true)][System.Windows.Forms.ProgressBar]$ProgressControl,
        [Parameter(Mandatory=$true)][System.Collections.ArrayList]$PreviewBoxes
    )
    
    Write-Log -Message "Fetching favicon for: $URL" -Category "ACTION"
    $ProgressControl.Visible = $true
    $StatusControl.Text = "Status: Initializing connection..."
    
    # Reset previews
    foreach ($pb in $PreviewBoxes) { 
        $pb.Image = $null 
        $pb.BackColor = "Control"
        $pb.BorderStyle = "Fixed3D"
    }
    [System.Windows.Forms.Application]::DoEvents()
    
    # CLEANUP PREVIOUS RESOURCES
    if ($Global:CurrentFaviconImageObject) { 
        $Global:CurrentFaviconImageObject.Dispose()
        $Global:CurrentFaviconImageObject = $null
    }
    if ($Global:CurrentMemoryStream) {
        $Global:CurrentMemoryStream.Dispose()
        $Global:CurrentMemoryStream = $null
    }

    $Global:CurrentDefaultFileName = $null

    $WebClient = New-Object System.Net.WebClient
    $EdgeUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 Edg/115.0.1901.200"
    $WebClient.Headers.Add("User-Agent", $EdgeUserAgent)

    $FaviconURL = ""
    $BaseURL = ""
    
    # 1. Normalize URL
    if (-not ($URL -match "^https?://")) { $URL = "http://" + $URL }
    try {
        $BaseURI = New-Object System.Uri($URL)
        $BaseURL = "$($BaseURI.Scheme)://$($BaseURI.Authority)"
        $HostName = $BaseURI.Host.Replace("www.", "").Split('.') | Select-Object -First 1
        $Global:CurrentDefaultFileName = "$HostName.ico"
        Write-Log -Message "Target Host: $($BaseURI.Host)" -Category "INFO"
    } catch {
        Write-Log -Message "Invalid URL format provided." -Category "ERROR"
        throw "Invalid URL format."
    }

    try {
        $FoundData = $null
        $FoundUrl = $null

        # --- Helper: Download Check ---
        function Try-DownloadImage {
            param($TargetUrl)
            try {
                Write-Log -Message "Checking: $TargetUrl" -Category "DEBUG"
                $Data = $WebClient.DownloadData($TargetUrl)
                # Basic validation: >100 bytes (avoids empty/error pages often)
                if ($Data.Count -gt 100) { return $Data }
            } catch {
                # Silent fail for distinct checks
            }
            return $null
        }

        # ----------------------------------------------------------------
        # STRATEGY 1: Intelligent HTML Parsing
        # ----------------------------------------------------------------
        $StatusControl.Text = "Status: Scanning HTML tags..."
        [System.Windows.Forms.Application]::DoEvents()
        
        try {
            Write-Log -Message "Strategy 1: HTML Parsing" -Category "INFO"
            $HTML = $WebClient.DownloadString($URL)
            
            # Improved Regex: Matches icon, shortcut icon, apple-touch-icon, fluid-icon
            $Pattern = '<link\s+[^>]*rel=["''](?:[\w-]+\s+)?((?:shortcut\s+)?icon|apple-touch-icon|fluid-icon)(?:\s+[\w-]+)?["''][^>]*>'
            $Matches = [regex]::Matches($HTML, $Pattern, "IgnoreCase")

            foreach ($Match in $Matches) {
                if ($Match.Value -match 'href=["'']([^"'']+)["'']') {
                    $RelPath = $matches[1]
                    
                    if ($RelPath -match "\.svg(\?.*)?$") {
                        Write-Log -Message "Skipping SVG: $RelPath" -Category "WARN"
                        continue
                    }

                    # URL Construction
                    $FullUrl = ""
                    if ($RelPath -match "^//") { 
                        $FullUrl = "https:" + $RelPath 
                    } elseif ($RelPath -match "^https?://") {
                        $FullUrl = $RelPath
                    } else {
                        # Resolve relative path
                        $FullUrl = (New-Object System.Uri($BaseURI, $RelPath)).AbsoluteUri
                    }

                    $StatusControl.Text = "Status: Testing tag found..."
                    $Data = Try-DownloadImage -TargetUrl $FullUrl
                    if ($Data) {
                        $FoundData = $Data
                        $FoundUrl = $FullUrl
                        Write-Log -Message "Success: Found via HTML ($FullUrl)" -Category "SUCCESS"
                        break 
                    }
                }
            }
        } catch {
            Write-Log -Message "HTML Parsing failed or returned no results." -Category "WARN"
        }

        # ----------------------------------------------------------------
        # STRATEGY 2: Standard Root Check
        # ----------------------------------------------------------------
        if (-not $FoundData) {
            $StatusControl.Text = "Status: Checking root /favicon.ico..."
            [System.Windows.Forms.Application]::DoEvents()
            Write-Log -Message "Strategy 2: Root Location Check" -Category "INFO"
            
            $RootUrl = "$BaseURL/favicon.ico"
            $Data = Try-DownloadImage -TargetUrl $RootUrl
            if ($Data) {
                $FoundData = $Data
                $FoundUrl = $RootUrl
                Write-Log -Message "Success: Found at root." -Category "SUCCESS"
            }
        }

        # ----------------------------------------------------------------
        # STRATEGY 3: DuckDuckGo API (New!)
        # ----------------------------------------------------------------
        if (-not $FoundData) {
            $StatusControl.Text = "Status: Checking DuckDuckGo..."
            [System.Windows.Forms.Application]::DoEvents()
            Write-Log -Message "Strategy 3: DuckDuckGo Service" -Category "INFO"
            
            $DDGUrl = "https://icons.duckduckgo.com/ip3/$($BaseURI.Host).ico"
            $Data = Try-DownloadImage -TargetUrl $DDGUrl
            
            if ($Data) {
                $FoundData = $Data
                $FoundUrl = $DDGUrl
                Write-Log -Message "Success: Found via DuckDuckGo." -Category "SUCCESS"
            }
        }

        # ----------------------------------------------------------------
        # STRATEGY 4: Google S2 API (Fallback)
        # ----------------------------------------------------------------
        if (-not $FoundData) {
            $StatusControl.Text = "Status: Fetching from Google API..."
            [System.Windows.Forms.Application]::DoEvents()
            Write-Log -Message "Strategy 4: Google S2 Service" -Category "WARN"
            
            $GoogleUrl = "https://www.google.com/s2/favicons?domain_url=$($BaseURI.AbsoluteUri)&sz=128"
            $Data = Try-DownloadImage -TargetUrl $GoogleUrl
            
            if ($Data) {
                $FoundData = $Data
                $FoundUrl = $GoogleUrl
                Write-Log -Message "Success: Retrieved via Google API." -Category "SUCCESS"
            }
        }

        if (-not $FoundData) {
            throw "Unable to locate any favicon via HTML, Root, DuckDuckGo, or Google API."
        }
        
        # ----------------------------------------------------------------
        # Process Image
        # ----------------------------------------------------------------
        $StatusControl.Text = "Status: Processing Image..."
        Write-Log -Message "Finalizing image data..." -Category "DEBUG"
        
        # --- ROBUST FIX: Unary Comma Operator ---
        $Global:CurrentMemoryStream = New-Object System.IO.MemoryStream(,$FoundData)
        
        try {
            $ImageObject = [System.Drawing.Image]::FromStream($Global:CurrentMemoryStream)
            $Global:CurrentFaviconImageObject = $ImageObject
        } catch {
            Write-Log -Message "Stream decoding failed." -Category "ERROR"
            throw "Downloaded data is not a valid image format."
        }
        
        # 4. Populate Multi-Size Previews
        Write-Log -Message "Generating previews..." -Category "DEBUG"
        
        function Set-Preview($Index, $Size) {
            try {
                $Bmp = New-Object System.Drawing.Bitmap($Size, $Size)
                $Graph = [System.Drawing.Graphics]::FromImage($Bmp)
                $Graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $Graph.DrawImage($ImageObject, 0, 0, $Size, $Size)
                $Graph.Dispose()
                $PreviewBoxes[$Index].Image = $Bmp
            } catch {
                Write-Log -Message "Preview generation error for size $Size" -Category "WARN"
            }
        }

        Set-Preview 0 16
        Set-Preview 1 32
        Set-Preview 2 64
        Set-Preview 3 128
        
        $StatusControl.Text = "Status: Success! Ready to Save."
        return $true
        
    } catch {
        $ErrorMessage = $_.Exception.Message
        $StatusControl.Text = "Status: ERROR (See logs)"
        Write-Log -Message "Load failed: $ErrorMessage" -Category "ERROR"
        Write-ErrorLog -ContextMessage "Load-ImageToMemory Failed" -ErrorRecord $_
        [System.Windows.Forms.MessageBox]::Show("Load Error:`n$ErrorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
        
    } finally {
        $ProgressControl.Visible = $false
        $WebClient.Dispose()
    }
}


# --- Function: Handle Saving ---

function Save-Favicon {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.Label]$StatusControl,
        [Parameter(Mandatory=$true)][System.Windows.Forms.CheckBox]$OpenExplorerCheckbox
    )

    Write-Log -Message "Initiating Save..." -Category "ACTION"
    
    if (-not $Global:CurrentFaviconImageObject) {
        return $null
    }
    
    try {
        $StatusControl.Text = "Status: Opening Save Dialog..."
        
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Filter = "Icon Files (*.ico)|*.ico"
        $SaveFileDialog.FileName = $Global:CurrentDefaultFileName
        $SaveFileDialog.Title = "Save Favicon As"
        
        # --- SMART DIRECTORY LOGIC ---
        if (Test-Path $Global:Settings.LastSaveDir) {
            $SaveFileDialog.InitialDirectory = $Global:Settings.LastSaveDir
        } else {
            $SaveFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
        }

        if ($SaveFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            $StatusControl.Text = "Status: Save cancelled."
            return $null
        }
        
        $SavedPath = $SaveFileDialog.FileName
        
        # UPDATE LAST SAVE DIR
        $Global:Settings.LastSaveDir = Split-Path -Path $SavedPath -Parent
        Save-Settings # Persist the new location immediately
        
        $StatusControl.Text = "Status: Saving..."
        [System.Windows.Forms.Application]::DoEvents()
        
        Convert-ToICO -ImageObject $Global:CurrentFaviconImageObject -OutputFilePath $SavedPath
        
        $StatusControl.Text = "Status: Saved to $SavedPath"
        Write-Log -Message "File saved to: $SavedPath" -Category "SUCCESS"
        return $SavedPath

    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Log -Message "Save failed: $ErrorMessage" -Category "ERROR"
        Write-ErrorLog -ContextMessage "Save-Favicon Failed" -ErrorRecord $_
        [System.Windows.Forms.MessageBox]::Show("Save Error:`n$ErrorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $null
    }
}


# --- Main UI Function ---

function Show-FaviconDownloaderUI {
    Write-Log -Message "Constructing UI..." -Category "UI"

    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Ultimate Favicon Downloader (Enterprise Edition)"
    $Form.Size = New-Object System.Drawing.Size(500, 520)
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $Form.MaximizeBox = $false
    $Form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $Form.Add_FormClosed({
        Write-Log -Message "Form closing. Saving final settings..." -Category "DEBUG"
        # Ensure latest checkboxes are saved
        $Global:Settings.HideConsole = $HideConsoleCheckbox.Checked
        $Global:Settings.OpenExplorer = $OpenExplorerCheckbox.Checked
        Save-Settings
        
        if ($Global:CurrentFaviconImageObject) { $Global:CurrentFaviconImageObject.Dispose() }
        if ($Global:CurrentMemoryStream) { $Global:CurrentMemoryStream.Dispose() }
    })

    $YPos = 15
    
    # URL Input
    $URLLabel = New-Object System.Windows.Forms.Label; $URLLabel.Location = New-Object System.Drawing.Point(10, $YPos); $URLLabel.Size = New-Object System.Drawing.Size(90, 20); $URLLabel.Text = "Website URL:"; $Form.Controls.Add($URLLabel)
    $URLTextBox = New-Object System.Windows.Forms.TextBox; $URLTextBox.Location = New-Object System.Drawing.Point(100, $YPos); $URLTextBox.Size = New-Object System.Drawing.Size(350, 20); $URLTextBox.Text = "https://www.wikipedia.org/"; $Form.Controls.Add($URLTextBox)

    $YPos += 35
    
    # --- MULTI-SIZE PREVIEW SECTION ---
    $PreviewLabel = New-Object System.Windows.Forms.Label; $PreviewLabel.Location = New-Object System.Drawing.Point(10, $YPos); $PreviewLabel.Size = New-Object System.Drawing.Size(400, 20); $PreviewLabel.Text = "Previews (16px, 32px, 64px, 128px):"; $Form.Controls.Add($PreviewLabel)
    
    $YPos += 25
    
    $PreviewBoxes = New-Object System.Collections.ArrayList
    
    function Add-Box($X, $Size) {
        $PB = New-Object System.Windows.Forms.PictureBox
        $PB.Location = New-Object System.Drawing.Point($X, $YPos)
        $PB.Size = New-Object System.Drawing.Size($Size, $Size)
        $PB.BorderStyle = "Fixed3D"
        $PB.SizeMode = "StretchImage"
        $Form.Controls.Add($PB)
        [void]$PreviewBoxes.Add($PB)
    }

    Add-Box 10 16
    Add-Box 36 32
    Add-Box 78 64
    Add-Box 152 128
    
    $YPos += 140 
    
    # Options
    $OpenExplorerCheckbox = New-Object System.Windows.Forms.CheckBox; $OpenExplorerCheckbox.Location = New-Object System.Drawing.Point(10, $YPos); $OpenExplorerCheckbox.Size = New-Object System.Drawing.Size(400, 20); $OpenExplorerCheckbox.Text = "Open explorer after save"; 
    $OpenExplorerCheckbox.Checked = $Global:Settings.OpenExplorer; # LOADED FROM SETTINGS
    $Form.Controls.Add($OpenExplorerCheckbox)
    
    $YPos += 25
    $HideConsoleCheckbox = New-Object System.Windows.Forms.CheckBox; $HideConsoleCheckbox.Location = New-Object System.Drawing.Point(10, $YPos); $HideConsoleCheckbox.Size = New-Object System.Drawing.Size(400, 20); $HideConsoleCheckbox.Text = "Hide console on next launch (Requires relaunch)"; 
    $HideConsoleCheckbox.Checked = $Global:Settings.HideConsole; # LOADED FROM SETTINGS
    $Form.Controls.Add($HideConsoleCheckbox)

    # Event to update setting immediately on change
    $OpenExplorerCheckbox.Add_CheckedChanged({ $Global:Settings.OpenExplorer = $OpenExplorerCheckbox.Checked })
    $HideConsoleCheckbox.Add_CheckedChanged({ $Global:Settings.HideConsole = $HideConsoleCheckbox.Checked })

    $YPos += 35
    
    # Buttons
    $LoadButton = New-Object System.Windows.Forms.Button; $LoadButton.Location = New-Object System.Drawing.Point(14, $YPos); $LoadButton.Size = New-Object System.Drawing.Size(460, 40); $LoadButton.Text = "Fetch Icon Resources"; $Form.Controls.Add($LoadButton)
    
    $YPos += 50
    $SaveButton = New-Object System.Windows.Forms.Button; $SaveButton.Location = New-Object System.Drawing.Point(14, $YPos); $SaveButton.Size = New-Object System.Drawing.Size(460, 40); $SaveButton.Text = "Save Icon As"; $SaveButton.Enabled = $true; $Form.Controls.Add($SaveButton)
    
    $YPos += 50
    $ProgressBar = New-Object System.Windows.Forms.ProgressBar; $ProgressBar.Location = New-Object System.Drawing.Point(10, $YPos); $ProgressBar.Size = New-Object System.Drawing.Size(460, 20); $ProgressBar.Style = "Marquee"; $ProgressBar.Visible = $false; $Form.Controls.Add($ProgressBar)

    $YPos += 25
    $StatusLabel = New-Object System.Windows.Forms.Label; $StatusLabel.Location = New-Object System.Drawing.Point(10, $YPos); $StatusLabel.Size = New-Object System.Drawing.Size(460, 40); $StatusLabel.Text = "Ready."; $Form.Controls.Add($StatusLabel)


    # --- Logic: Unified Load Function Wrapper ---
    $PerformLoadAction = {
        Write-Log -Message "Button Click: Fetch" -Category "UI"
        $LoadButton.Enabled = $false; $SaveButton.Enabled = $false
        $InputURL = $URLTextBox.Text.Trim()
        
        $Success = Load-ImageToMemory -URL $InputURL -StatusControl $StatusLabel -ProgressControl $ProgressBar -PreviewBoxes $PreviewBoxes
        
        $LoadButton.Enabled = $true; $SaveButton.Enabled = $true
        return $Success
    }


    # --- Events ---

    # 1. Enter Key on TextBox
    $URLTextBox.Add_KeyDown({
        if ($_.KeyCode -eq 'Enter') {
            $_.SuppressKeyPress = $true
            & $PerformLoadAction
        }
    })

    # 2. Load Button Click
    $LoadButton.Add_Click({
        & $PerformLoadAction
    })

    # 3. Save Button Click
    $SaveButton.Add_Click({
        Write-Log -Message "Button Click: Save" -Category "UI"
        $LoadButton.Enabled = $false; $SaveButton.Enabled = $false
        
        # A. Relaunch Check (Console State Change)
        $NewHide = $HideConsoleCheckbox.Checked
        $CurHide = $args -contains "-HideConsole"
        
        if (($NewHide -ne $CurHide) -or (-not $IsAdmin)) {
            Write-Log -Message "Console visibility changed or not admin. Relaunching..." -Category "WARN"
            Save-Settings # Ensure settings are saved before restart
            
            $Self = $MyInvocation.MyCommand.Path
            $ArgsList = "-File `"$Self`""
            if ($NewHide) { $ArgsList = "-WindowStyle Hidden $ArgsList -HideConsole" }
            Start-Process -FilePath $PSHOME\pwsh.exe -ArgumentList $ArgsList -Verb RunAs
            $Form.Close(); return
        }

        # B. Check if Load Needed
        $LoadResult = $true
        if (-not $Global:CurrentFaviconImageObject) {
            $LoadResult = & $PerformLoadAction
        }

        # C. Perform Save
        if ($LoadResult -and $Global:CurrentFaviconImageObject) {
             $SavedPath = Save-Favicon -StatusControl $StatusLabel -OpenExplorerCheckbox $OpenExplorerCheckbox
             
             # The checkbox logic is now controlled by the setting, which is updated by the checkbox event
             if ($SavedPath -and $Global:Settings.OpenExplorer) {
                 Write-Log -Message "Opening Explorer to: $SavedPath" -Category "ACTION"
                 Start-Process "explorer.exe" -ArgumentList "/select,`"$SavedPath`""
             }
        }
        
        $LoadButton.Enabled = $true; $SaveButton.Enabled = $true
    })

    Write-Log -Message "Showing Main Form" -Category "UI"
    [void]$Form.ShowDialog()
}

# Run
try {
    Show-FaviconDownloaderUI
} finally {
    Write-Log -Message "Script execution finished." -Category "INFO"
}
