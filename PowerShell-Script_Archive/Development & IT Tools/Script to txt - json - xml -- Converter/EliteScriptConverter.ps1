<#
.SYNOPSIS
    Batch converts .ps1 and .py script files to JSON, TXT, or XML.

.DESCRIPTION
    EliteScriptConverter is a Windows Forms application that allows users to select a source directory
    containing PowerShell and Python scripts and convert them into structured text formats.
    Designed for data portability, documentation, and AI dataset preparation.
    
    Adheres to EliteSoftware standards and UI conventions.

.NOTES
    PROJECT NAME: EliteScriptConverter
    VERSION NUMBER (MUST ALWAYS BE 4 VALUES): 1.2.3.1
    AUTHOR: Zachary Whiteman / EliteSoftware Company / Google Gemini
    COPYRIGHT: © 2007 - 2025 - EliteSoftware Company - Zachary Whiteman - All rights reserved
#>

# ---------------------------------------------------------
# CONSOLE WINDOW MANAGEMENT
# ---------------------------------------------------------
try {
    $windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    $showWindow = Add-Type -MemberDefinition $windowcode -Name "Win32ShowWindow" -Namespace Win32Functions -PassThru
    $handle = (Get-Process -Id $PID).MainWindowHandle
    if ($handle -ne 0) {
        $showWindow::ShowWindow($handle, 6) # 6 = SW_MINIMIZE
    }
} catch {}

# ---------------------------------------------------------
# LOGGING STANDARDS FOR ALL PROJECTS
# ---------------------------------------------------------

# This line is the key: It finds the folder where the script itself is running.
$ScriptBaseDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# --- [!!] CUSTOMIZE THIS [!!] ---
$ConfigDirName = "EliteScriptConverter_Config"
# --- [!!] --------------------- ---

# Build all paths relative to the script's location
$ConfigDir = [System.IO.Path]::Combine($ScriptBaseDir, "Tool-Resources", $ConfigDirName)
$LogFilesDir = [System.IO.Path]::Combine($ConfigDir, "Log Files")
$ErrorLogDir = [System.IO.Path]::Combine($LogFilesDir, "Error Logs")
$HistoricalLogDir = [System.IO.Path]::Combine($LogFilesDir, "Historical Logs")
$HistoricalErrorLogDir = [System.IO.Path]::Combine($ErrorLogDir, "Historical Logs")
$Global:LiveLogFile = [System.IO.Path]::Combine($LogFilesDir, "LiveLog.json")

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
    Writes a standard message to the main "LiveLog.json" file.
#>
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
        Write-Log -Message "An error occurred. Details in ErrorLog-$fileNameTimestamp.json. Context: $ContextMessage" -Severity "ERROR"
    }
    catch {
        Write-Warning "Could not write to error log: $($_.Exception.Message)"
    }
}

# 4. --- RUN AT STARTUP ---
# Clean up old logs every time the script starts
Archive-OldLogs

# 5. --- LOGGING MODULE LOADED ---
Write-Log -Message "Script started. Logging system initialized."

# ---------------------------------------------------------
# GUI & APPLICATION SETUP
# ---------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create Main Form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "EliteScriptConverter - Script to TXT/JSON/XML"
$mainForm.Width = 700
$mainForm.Height = 730 # Increased height for larger banner
$mainForm.StartPosition = "CenterScreen"
# Removed custom BackColor
# Removed custom ForeColor

# --- ICON ---
$iconPath = Join-Path -Path $ScriptBaseDir -ChildPath "Tool-Resources\EliteSoftware-App-Website-ICON.ico"
if (Test-Path $iconPath) {
    try {
        $mainForm.Icon = New-Object System.Drawing.Icon($iconPath)
    } catch {
        Write-Warning "Could not load icon: $($_.Exception.Message)"
    }
}

# --- FONTS ---
$headerFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$labelFont = New-Object System.Drawing.Font("Segoe UI", 10)
$smallFont = New-Object System.Drawing.Font("Segoe UI", 8.5)
$sloganFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)

# --- BANNER IMAGE ---
$bannerPath = Join-Path -Path $ScriptBaseDir -ChildPath "Tool-Resources\EliteSoftware-Company-Banner.png"
if (Test-Path $bannerPath) {
    $pbBanner = New-Object System.Windows.Forms.PictureBox
    $pbBanner.Location = "0, 0"
    $pbBanner.Size = "700, 150"
    $pbBanner.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pbBanner.Image = [System.Drawing.Image]::FromFile($bannerPath)
    $mainForm.Controls.Add($pbBanner)
}

# Offset variable for shifting controls down
$yOffset = 160

# --- LOGO IMAGE ---
$logoPath = Join-Path -Path $ScriptBaseDir -ChildPath "Tool-Resources\EliteSoftware Logo-2.png"
if (Test-Path $logoPath) {
    $pbLogo = New-Object System.Windows.Forms.PictureBox
    $pbLogo.Location = "20, $yOffset"
    $pbLogo.Size = "64, 64"
    $pbLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pbLogo.Image = [System.Drawing.Image]::FromFile($logoPath)
    $mainForm.Controls.Add($pbLogo)
}

# --- HEADER / SLOGAN ---
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "EliteScriptConverter"
$lblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblHeader.Location = "95, $($yOffset + 10)" # Shifted Right for Logo
$lblHeader.Size = "400, 30"
# Removed custom ForeColor
$mainForm.Controls.Add($lblHeader)

$lblSlogan = New-Object System.Windows.Forms.Label
$lblSlogan.Text = "EliteSoftware is where robust architecture meets inspired visual design."
$lblSlogan.Font = $sloganFont
$lblSlogan.Location = "95, $($yOffset + 45)" # Shifted Right for Logo
$lblSlogan.Size = "580, 20"
# Removed custom ForeColor
$mainForm.Controls.Add($lblSlogan)

# Adjust offset for rest of controls
$yOffset = $yOffset + 80

# --- SOURCE DIRECTORY ---
$lblSource = New-Object System.Windows.Forms.Label
$lblSource.Text = "Source Directory (Scripts):"
$lblSource.Font = $labelFont
$lblSource.Location = "20, $($yOffset)"
$lblSource.Size = "200, 20"
$mainForm.Controls.Add($lblSource)

$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.Location = "20, $($yOffset + 25)"
$txtSource.Size = "440, 25" # Reduced for buttons
$txtSource.Font = $labelFont
$txtSource.Text = Join-Path -Path $ScriptBaseDir -ChildPath "Source"
$txtSource.ReadOnly = $true
$mainForm.Controls.Add($txtSource)

$btnImport = New-Object System.Windows.Forms.Button
$btnImport.Text = "Import..."
$btnImport.Location = "470, $($yOffset + 23)"
$btnImport.Size = "80, 28"
$btnImport.Font = $smallFont
$mainForm.Controls.Add($btnImport)

$btnClearSource = New-Object System.Windows.Forms.Button
$btnClearSource.Text = "Clear"
$btnClearSource.Location = "560, $($yOffset + 23)"
$btnClearSource.Size = "80, 28"
$btnClearSource.Font = $smallFont
$mainForm.Controls.Add($btnClearSource)

# --- OUTPUT DIRECTORY ---
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = "Output Directory:"
$lblOutput.Font = $labelFont
$lblOutput.Location = "20, $($yOffset + 60)"
$lblOutput.Size = "200, 20"
$mainForm.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = "20, $($yOffset + 85)"
$txtOutput.Size = "440, 25" # Reduced for buttons
$txtOutput.Font = $labelFont
$txtOutput.Text = Join-Path -Path $ScriptBaseDir -ChildPath "Output"
$txtOutput.ReadOnly = $true
$mainForm.Controls.Add($txtOutput)

$btnOpenOutput = New-Object System.Windows.Forms.Button
$btnOpenOutput.Text = "Open"
$btnOpenOutput.Location = "470, $($yOffset + 83)"
$btnOpenOutput.Size = "80, 28"
$btnOpenOutput.Font = $smallFont
$btnOpenOutput.Add_Click({
    if (Test-Path $txtOutput.Text) {
        Invoke-Item $txtOutput.Text
    } else {
        [System.Windows.Forms.MessageBox]::Show("Output directory does not exist.", "Error", "OK", "Error")
    }
})
$mainForm.Controls.Add($btnOpenOutput)

$btnClearOutput = New-Object System.Windows.Forms.Button
$btnClearOutput.Text = "Clear"
$btnClearOutput.Location = "560, $($yOffset + 83)"
$btnClearOutput.Size = "80, 28"
$btnClearOutput.Font = $smallFont
$mainForm.Controls.Add($btnClearOutput)

# --- FORMAT SELECTION ---
$grpFormat = New-Object System.Windows.Forms.GroupBox
$grpFormat.Text = "Output Format"
$grpFormat.Location = "20, $($yOffset + 130)"
$grpFormat.Size = "620, 70"
# Removed custom ForeColor
$grpFormat.Font = $labelFont
$mainForm.Controls.Add($grpFormat)

$chkTXT = New-Object System.Windows.Forms.CheckBox
$chkTXT.Text = "TXT (Plain Text)"
$chkTXT.Location = "30, 30"
$chkTXT.Checked = $true
$chkTXT.AutoSize = $true
$grpFormat.Controls.Add($chkTXT)

$chkJSON = New-Object System.Windows.Forms.CheckBox
$chkJSON.Text = "JSON"
$chkJSON.Location = "180, 30"
$chkJSON.AutoSize = $true
$grpFormat.Controls.Add($chkJSON)

$chkXML = New-Object System.Windows.Forms.CheckBox
$chkXML.Text = "XML"
$chkXML.Location = "280, 30"
$chkXML.AutoSize = $true
$grpFormat.Controls.Add($chkXML)

# --- ACTION BUTTONS ---
$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "Convert Scripts"
$btnConvert.Location = "20, $($yOffset + 220)"
$btnConvert.Size = "200, 40"
$btnConvert.Font = $headerFont
# Removed custom BackColor
# Removed custom ForeColor
# Removed FlatStyle
$mainForm.Controls.Add($btnConvert)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Close"
$btnClose.Location = "520, $($yOffset + 220)"
$btnClose.Size = "120, 40"
$btnClose.Font = $labelFont
# Removed custom BackColor
# Removed custom ForeColor
# Removed FlatStyle
$mainForm.Controls.Add($btnClose)

$btnChangelog = New-Object System.Windows.Forms.Button
$btnChangelog.Text = "View Changelog"
$btnChangelog.Location = "390, $($yOffset + 220)"
$btnChangelog.Size = "120, 40"
$btnChangelog.Font = $labelFont
# Removed custom BackColor
# Removed custom ForeColor
# Removed FlatStyle
$mainForm.Controls.Add($btnChangelog)

# --- LOG WINDOW ---
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Activity Log:"
$lblLog.Location = "20, $($yOffset + 270)"
$lblLog.Size = "200, 20"
$lblLog.Font = $labelFont
$mainForm.Controls.Add($lblLog)

$rtbLog = New-Object System.Windows.Forms.RichTextBox
$rtbLog.Location = "20, $($yOffset + 295)"
$rtbLog.Size = "620, 110"
# Removed custom BackColor
# Removed custom ForeColor
$rtbLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$rtbLog.ReadOnly = $true
$mainForm.Controls.Add($rtbLog)

# --- HELPER FUNCTION: GUI LOGGING ---
function Log-Gui {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $rtbLog.AppendText("[$timestamp] $Message`r`n")
    $rtbLog.ScrollToCaret()
    Write-Log -Message $Message # Also write to file
}

# --- EVENT HANDLERS ---

$btnClose.Add_Click({
    $mainForm.Close()
})

$btnImport.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Import Scripts"
    $openFileDialog.Filter = "Scripts (*.ps1;*.py)|*.ps1;*.py|All Files (*.*)|*.*"
    $openFileDialog.Multiselect = $true
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $destPath = $txtSource.Text
        if (-not (Test-Path $destPath)) { New-Item -Path $destPath -ItemType Directory -Force | Out-Null }
        
        foreach ($file in $openFileDialog.FileNames) {
            Copy-Item -Path $file -Destination $destPath -Force
            Log-Gui "Imported: $(Split-Path $file -Leaf)"
        }
        [System.Windows.Forms.MessageBox]::Show("Files imported successfully!", "Done", "OK", "Information")
    }
})

$btnClearSource.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete all files in the Source directory?", "Confirm Clear Source", "YesNo", "Warning")
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $path = $txtSource.Text
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse | Remove-Item -Recurse -Force
            Log-Gui "Cleared Source directory."
            [System.Windows.Forms.MessageBox]::Show("Source directory cleared.", "Done", "OK", "Information")
        }
    }
})

$btnClearOutput.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete all files in the Output directory?", "Confirm Clear Output", "YesNo", "Warning")
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $path = $txtOutput.Text
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse | Remove-Item -Recurse -Force
            Log-Gui "Cleared Output directory."
            [System.Windows.Forms.MessageBox]::Show("Output directory cleared.", "Done", "OK", "Information")
        }
    }
})

$btnChangelog.Add_Click({
    $changelogPath = Join-Path -Path $ScriptBaseDir -ChildPath "Tool-Resources\EliteScriptConverter_Changelog.json"
    
    # Create Changelog Form
    $clForm = New-Object System.Windows.Forms.Form
    $clForm.Text = "Changelog - EliteScriptConverter"
    $clForm.Width = 700
    $clForm.Height = 600
    $clForm.StartPosition = "CenterScreen"
    if ($mainForm.Icon) { $clForm.Icon = $mainForm.Icon }
    $clForm.BackColor = "White"

    # Title Label (Replacing Banner Image)
    $lblChangelogTitle = New-Object System.Windows.Forms.Label
    $lblChangelogTitle.Text = "Changelog"
    $lblChangelogTitle.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $lblChangelogTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215) # Windows Blue
    $lblChangelogTitle.Dock = "Top"
    $lblChangelogTitle.Height = 60
    $lblChangelogTitle.TextAlign = "MiddleCenter"
    $clForm.Controls.Add($lblChangelogTitle)

    # Bottom Panel
    $pnlBottom = New-Object System.Windows.Forms.Panel
    $pnlBottom.Dock = "Bottom"
    $pnlBottom.Height = 60
    $pnlBottom.BackColor = [System.Drawing.SystemColors]::ControlLight # Lighter Grey
    $clForm.Controls.Add($pnlBottom)

    # Done Button
    $btnDone = New-Object System.Windows.Forms.Button
    $btnDone.Text = "Done"
    $btnDone.Size = "100, 35"
    # Center the button
    $btnX = [int](($pnlBottom.Width - $btnDone.Width) / 2)
    $btnY = [int](($pnlBottom.Height - $btnDone.Height) / 2)
    $btnDone.Location = New-Object System.Drawing.Point($btnX, $btnY)
    $btnDone.Anchor = [System.Windows.Forms.AnchorStyles]::None 
    $btnDone.UseVisualStyleBackColor = $true
    $btnDone.Add_Click({ $clForm.Close() })
    $pnlBottom.Controls.Add($btnDone)
    
    # Handle resize to keep button centered
    $pnlBottom.Add_Resize({
        $btnDone.Left = [int](($pnlBottom.Width - $btnDone.Width) / 2)
        $btnDone.Top = [int](($pnlBottom.Height - $btnDone.Height) / 2)
    })

    # WebBrowser for Markdown/HTML Display
    $wbChangelog = New-Object System.Windows.Forms.WebBrowser
    $wbChangelog.Dock = "Fill"
    $wbChangelog.ScrollBarsEnabled = $true
    
    # Correct Control Addition Order
    $clForm.Controls.Add($pnlBottom)
    $clForm.Controls.Add($lblChangelogTitle)
    $clForm.Controls.Add($wbChangelog)

    if (Test-Path $changelogPath) {
        try {
            $jsonContent = Get-Content -Path $changelogPath -Raw | ConvertFrom-Json
            
            # Start HTML Builder
            $sb = New-Object System.Text.StringBuilder
            
            $style = @"
            <style>
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #ffffff; color: #333; padding: 20px; margin: 0; }
                .changelog-entry { background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px; margin-bottom: 25px; }
                .version-header { display: flex; justify-content: space-between; align-items: baseline; border-bottom: 2px solid #0078D7; padding-bottom: 10px; margin-bottom: 15px; }
                .version-title { font-size: 24px; font-weight: bold; color: #0078D7; margin: 0; }
                .version-date { font-size: 14px; color: #777; }
                .author { font-size: 12px; color: #999; margin-bottom: 10px; font-style: italic; }
                ul { padding-left: 20px; margin-top: 10px; }
                li { margin-bottom: 8px; line-height: 1.5; }
                li::marker { color: #0078D7; }
            </style>
"@
            $sb.AppendLine("<html><head><meta charset='UTF-8'>$style</head><body>")
            
            foreach ($entry in $jsonContent) {
                $sb.AppendLine("<div class='changelog-entry'>")
                
                # Header
                $sb.AppendLine("  <div class='version-header'>")
                $sb.AppendLine("    <h1 class='version-title'>Version $($entry.Version)</h1>")
                $sb.AppendLine("    <span class='version-date'>$($entry.Date)</span>")
                $sb.AppendLine("  </div>")
                
                # Author
                $sb.AppendLine("  <div class='author'>Author: $($entry.Author)</div>")
                
                # Changes
                $sb.AppendLine("  <ul>")
                foreach ($change in $entry.Changes) {
                    $sb.AppendLine("    <li>$change</li>")
                }
                $sb.AppendLine("  </ul>")
                
                $sb.AppendLine("</div>")
            }
            
            $sb.AppendLine("</body></html>")
            
            $wbChangelog.DocumentText = $sb.ToString()
        } catch {
             $wbChangelog.DocumentText = "<html><body style='font-family: Segoe UI;'><h1>Error</h1><p>Error reading changelog: $($_.Exception.Message)</p></body></html>"
        }
    } else {
        $wbChangelog.DocumentText = "<html><body style='font-family: Segoe UI;'><h1>File Not Found</h1><p>Changelog file not found.</p></body></html>"
    }
    
    $clForm.ShowDialog()
})

$btnConvert.Add_Click({
    $sourcePath = $txtSource.Text
    $outputPath = $txtOutput.Text

    if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path $sourcePath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid Source Directory.", "Error", "OK", "Error")
        return
    }
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid Output Directory.", "Error", "OK", "Error")
        return
    }
    if (-not (Test-Path $outputPath)) {
        try {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
            Log-Gui "Created output directory: $outputPath"
        } catch {
            Log-Gui "Error creating output directory: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Could not create output directory.", "Error", "OK", "Error")
            return
        }
    }

    $scripts = Get-ChildItem -Path $sourcePath -Include *.ps1, *.py -Recurse -File
    if ($scripts.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No .ps1 or .py files found in source directory.", "Info", "OK", "Information")
        Log-Gui "No scripts found to convert."
        return
    }

    Log-Gui "Found $($scripts.Count) scripts. Starting conversion..."
    $btnConvert.Enabled = $false
    $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    foreach ($script in $scripts) {
        try {
            $content = Get-Content -Path $script.FullName -Raw
            $baseName = $script.BaseName
            
            $dataObject = @{
                FileName = $script.Name
                Extension = $script.Extension
                FullPath = $script.FullName
                Content = $content
                ConvertedAt = Get-Date
            }

            # JSON Conversion
            if ($chkJSON.Checked) {
                $jsonFile = Join-Path -Path $outputPath -ChildPath "$baseName.json"
                $dataObject | ConvertTo-Json -Depth 2 | Set-Content -Path $jsonFile
                Log-Gui "Converted to JSON: $baseName"
            }

            # XML Conversion
            if ($chkXML.Checked) {
                $xmlFile = Join-Path -Path $outputPath -ChildPath "$baseName.xml"
                $xmlContent = $dataObject | ConvertTo-Xml -NoTypeInformation -Depth 2 -As "String"
                $xmlContent | Set-Content -Path $xmlFile
                Log-Gui "Converted to XML: $baseName"
            }

            # TXT Conversion
            if ($chkTXT.Checked) {
                $txtFile = Join-Path -Path $outputPath -ChildPath "$baseName.txt"
                $txtHeader = "### SOURCE: $($script.Name) ###`r`n### PATH: $($script.FullName) ###`r`n--------------------------------------------------`r`n"
                $finalTxt = $txtHeader + $content
                $finalTxt | Set-Content -Path $txtFile
                Log-Gui "Converted to TXT: $baseName"
            }

        } catch {
            Log-Gui "Error converting $($script.Name): $($_.Exception.Message)"
            Write-ErrorLog -ContextMessage "Failed to convert script: $($script.FullName)" -ErrorRecord $_
        }
    }

    $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnConvert.Enabled = $true
    Log-Gui "Conversion process completed."
    [System.Windows.Forms.MessageBox]::Show("Conversion Completed!", "Done", "OK", "Information")
})

# --- SHOW FORM ---
Log-Gui "Application ready."
$mainForm.Add_Shown({ $mainForm.Activate() })
[void]$mainForm.ShowDialog()
