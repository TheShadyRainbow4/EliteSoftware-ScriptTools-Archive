# --- Script Information ---
# Author: Gemini
# Version: 6.2 (Custom Default Path)
# Description: A stable GUI tool that now defaults to a user-specified output path (G:\Extracted Resources).

function Show-ResourceExtractorGUI {
    # --- Error Handling ---
    try {
        # --- Assembly Loading ---
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # --- Initial Setup ---
        [System.Windows.Forms.Application]::EnableVisualStyles()
        # --- CHANGE: Hardcoded the default path as requested ---
        $defaultOutputDirectory = "G:\Extracted Resources"

        # =====================================================================
        # GUI Element Creation
        # =====================================================================
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Batch Resource Extractor v6.2 (Final)"
        $form.Size = New-Object System.Drawing.Size(600, 670)
        $form.StartPosition = "CenterScreen"
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false

        $groupFiles = New-Object System.Windows.Forms.GroupBox; $groupFiles.Text = "DLL Files"; $groupFiles.Location = "10, 10"; $groupFiles.Size = "565, 170"; $form.Controls.Add($groupFiles)
        $listBoxFiles = New-Object System.Windows.Forms.ListBox; $listBoxFiles.Location = "15, 25"; $listBoxFiles.Size = "420, 130"; $listBoxFiles.SelectionMode = "MultiExtended"; $groupFiles.Controls.Add($listBoxFiles)
        $buttonAddFiles = New-Object System.Windows.Forms.Button; $buttonAddFiles.Text = "Add Files..."; $buttonAddFiles.Location = "445, 25"; $buttonAddFiles.Size = "110, 30"; $groupFiles.Controls.Add($buttonAddFiles)
        $buttonRemoveFile = New-Object System.Windows.Forms.Button; $buttonRemoveFile.Text = "Remove Selected"; $buttonRemoveFile.Location = "445, 60"; $buttonRemoveFile.Size = "110, 30"; $groupFiles.Controls.Add($buttonRemoveFile)
        $buttonClearList = New-Object System.Windows.Forms.Button; $buttonClearList.Text = "Clear List"; $buttonClearList.Location = "445, 95"; $buttonClearList.Size = "110, 30"; $groupFiles.Controls.Add($buttonClearList)
        
        $groupTypes = New-Object System.Windows.Forms.GroupBox; $groupTypes.Text = "Resource Types to Extract"; $groupTypes.Location = "10, 190"; $groupTypes.Size = "565, 60"; $form.Controls.Add($groupTypes)
        $checkBoxIcons = New-Object System.Windows.Forms.CheckBox; $checkBoxIcons.Text = "Icons"; $checkBoxIcons.Location = "20, 25"; $checkBoxIcons.Checked = $true; $checkBoxIcons.AutoSize = $true; $groupTypes.Controls.Add($checkBoxIcons)
        $checkBoxBitmaps = New-Object System.Windows.Forms.CheckBox; $checkBoxBitmaps.Text = "BMP"; $checkBoxBitmaps.Location = "120, 25"; $checkBoxBitmaps.AutoSize = $true; $groupTypes.Controls.Add($checkBoxBitmaps)
        $checkBoxCursors = New-Object System.Windows.Forms.CheckBox; $checkBoxCursors.Text = "Cursors"; $checkBoxCursors.Location = "220, 25"; $checkBoxCursors.AutoSize = $true; $groupTypes.Controls.Add($checkBoxCursors)
        $checkBoxPngs = New-Object System.Windows.Forms.CheckBox; $checkBoxPngs.Text = "PNG"; $checkBoxPngs.Location = "320, 25"; $checkBoxPngs.AutoSize = $true; $groupTypes.Controls.Add($checkBoxPngs)
        
        $groupAdvanced = New-Object System.Windows.Forms.GroupBox; $groupAdvanced.Text = "Advanced Options"; $groupAdvanced.Location = "10, 260"; $groupAdvanced.Size = "565, 90"; $form.Controls.Add($groupAdvanced)
        $labelOutputDir = New-Object System.Windows.Forms.Label; $labelOutputDir.Text = "Output Directory:"; $labelOutputDir.Location = "15, 28"; $labelOutputDir.AutoSize = $true; $groupAdvanced.Controls.Add($labelOutputDir)
        $textBoxOutputDir = New-Object System.Windows.Forms.TextBox; $textBoxOutputDir.Text = $defaultOutputDirectory; $textBoxOutputDir.Location = "125, 25"; $textBoxOutputDir.Size = "340, 20"; $groupAdvanced.Controls.Add($textBoxOutputDir)
        $buttonBrowse = New-Object System.Windows.Forms.Button; $buttonBrowse.Text = "Browse..."; $buttonBrowse.Location = "470, 24"; $buttonBrowse.Size = "85, 23"; $groupAdvanced.Controls.Add($buttonBrowse)
        $checkBoxClearFolder = New-Object System.Windows.Forms.CheckBox; $checkBoxClearFolder.Text = "Clear existing output sub-folder before extraction"; $checkBoxClearFolder.Location = "15, 55"; $checkBoxClearFolder.AutoSize = $true; $groupAdvanced.Controls.Add($checkBoxClearFolder)

        $buttonExtract = New-Object System.Windows.Forms.Button; $buttonExtract.Text = "Start Extraction"; $buttonExtract.Location = "10, 360"; $buttonExtract.Size = "565, 30"; $form.Controls.Add($buttonExtract)
        
        $buttonArchive = New-Object System.Windows.Forms.Button; $buttonArchive.Text = "Archive Previous Extractions"; $buttonArchive.Location = "10, 400"; $buttonArchive.Size = "415, 30"; $form.Controls.Add($buttonArchive)
        $buttonOpenOutput = New-Object System.Windows.Forms.Button; $buttonOpenOutput.Text = "Open Output Folder"; $buttonOpenOutput.Location = "435, 400"; $buttonOpenOutput.Size = "140, 30"; $form.Controls.Add($buttonOpenOutput)

        $textBoxLog = New-Object System.Windows.Forms.TextBox; $textBoxLog.Location = "10, 440"; $textBoxLog.Size = "565, 170"; $textBoxLog.Multiline = $true; $textBoxLog.ScrollBars = "Vertical"; $textBoxLog.ReadOnly = $true; $textBoxLog.Font = "Consolas, 8"; $form.Controls.Add($textBoxLog)

        # =====================================================================
        # ToolTips
        # =====================================================================
        $toolTip = New-Object System.Windows.Forms.ToolTip
        $toolTip.SetToolTip($listBoxFiles, "This list contains all the DLL files queued for resource extraction.")
        $toolTip.SetToolTip($buttonAddFiles, "Opens a dialog to select one or more DLL files to add to the list.")
        $toolTip.SetToolTip($buttonRemoveFile, "Removes the currently selected file(s) from the list.")
        $toolTip.SetToolTip($buttonClearList, "Removes all files from the list.")
        $toolTip.SetToolTip($checkBoxIcons, "Check to extract all icon resources (.ico files).")
        $toolTip.SetToolTip($checkBoxBitmaps, "Check to extract all bitmap image resources (.bmp files).")
        $toolTip.SetToolTip($checkBoxCursors, "Check to extract all cursor resources (.cur, .ani files).")
        $toolTip.SetToolTip($checkBoxPngs, "Check to extract all PNG image resources (.png files).")
        $toolTip.SetToolTip($textBoxOutputDir, "The main folder where subfolders for each DLL will be created.")
        $toolTip.SetToolTip($buttonBrowse, "Opens a dialog to select a new main output directory.")
        $toolTip.SetToolTip($checkBoxClearFolder, "If checked, any existing folder for a DLL will be deleted before extraction begins. Use with caution.")
        $toolTip.SetToolTip($buttonExtract, "Starts the batch extraction process. Will create nested subfolders for each resource type.")
        $toolTip.SetToolTip($buttonArchive, "Moves all current contents of the output folder into a new, timestamped 'Previously Extracted' folder.")
        $toolTip.SetToolTip($buttonOpenOutput, "Opens the specified output directory in Windows Explorer.")
        $toolTip.SetToolTip($textBoxLog, "Displays progress, status messages, and any errors.")

        # =====================================================================
        # Functions and Event Handlers
        # =====================================================================
        function Write-Log($message) { if (-not [string]::IsNullOrEmpty($message)) { $timestamp = Get-Date -Format "HH:mm:ss"; $logEntry = "[$timestamp] $message"; $textBoxLog.AppendText("$logEntry`r`n"); $textBoxLog.SelectionStart = $textBoxLog.Text.Length; $textBoxLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() } }
        function Set-UIEnabledState($enabled) { $groupFiles.Enabled = $enabled; $groupTypes.Enabled = $enabled; $groupAdvanced.Enabled = $enabled; $buttonExtract.Enabled = $enabled; $buttonArchive.Enabled = $enabled }

        $buttonAddFiles.Add_Click({ $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Title = "Select DLL Files"; $openFileDialog.Filter = "DLL Files (*.dll)|*.dll|All Files (*.*)|*.*"; $openFileDialog.MultiSelect = $true; if ($openFileDialog.ShowDialog() -eq "OK") { foreach ($file in $openFileDialog.FileNames) { if (-not $listBoxFiles.Items.Contains($file)) { $listBoxFiles.Items.Add($file) | Out-Null } } } })
        $buttonRemoveFile.Add_Click({ for ($i = $listBoxFiles.SelectedItems.Count - 1; $i -ge 0; $i--) { $listBoxFiles.Items.Remove($listBoxFiles.SelectedItems[$i]) } })
        $buttonClearList.Add_Click({ $listBoxFiles.Items.Clear(); Write-Log "File list cleared." })
        $buttonBrowse.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog() -eq "OK") { $textBoxOutputDir.Text = $folderBrowser.SelectedPath } })
        $buttonOpenOutput.Add_Click({ $outputDir = $textBoxOutputDir.Text; if (Test-Path -Path $outputDir) { Write-Log "Opening output directory: $outputDir"; Invoke-Item -Path $outputDir } else { [System.Windows.Forms.MessageBox]::Show("The output directory does not exist yet.", "Directory Not Found", "OK", "Information") } })

        $buttonArchive.Add_Click({
            $baseOutputDirectory = $textBoxOutputDir.Text
            if (-not (Test-Path -Path $baseOutputDirectory)) { [System.Windows.Forms.MessageBox]::Show("The output directory does not exist. Nothing to archive.", "Directory Not Found", "OK", "Information"); return }
            $itemsToArchive = Get-ChildItem -Path $baseOutputDirectory | Where-Object { $_.Name -notlike "Previously Extracted*" }
            if ($itemsToArchive.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("The output directory is already empty or only contains archives.", "Nothing to Archive", "OK", "Information"); return }
            Write-Log "Archiving previous extractions..."
            $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Set-UIEnabledState($false)
            try {
                $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                $archiveFolderName = "Previously Extracted ($timestamp)"
                $archiveFolderPath = Join-Path -Path $baseOutputDirectory -ChildPath $archiveFolderName
                New-Item -Path $archiveFolderPath -ItemType Directory -Force | Out-Null
                foreach ($item in $itemsToArchive) { Write-Log "  -> Moving $($item.Name)..."; Move-Item -Path $item.FullName -Destination $archiveFolderPath -Force }
                Write-Log "Archiving complete. All items moved to '$archiveFolderName'."
                [System.Windows.Forms.MessageBox]::Show("All previous items have been archived successfully.", "Archive Complete", "OK", "Information")
            }
            catch { $errorMessage = "An error occurred during archiving: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $errorMessage"; [System.Windows.Forms.MessageBox]::Show($errorMessage, "Archive Failed", "OK", "Error") }
            finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default; Set-UIEnabledState($true) }
        })
        
        $buttonExtract.Add_Click({
            if ($listBoxFiles.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please add at least one DLL file.", "No Files", "OK", "Warning"); return }
            $resourceTypes = @{ "Icons" = $checkBoxIcons.Checked; "BMP" = $checkBoxBitmaps.Checked; "Cursors" = $checkBoxCursors.Checked; "PNG" = $checkBoxPngs.Checked }
            if (-not ($resourceTypes.ContainsValue($true))) { [System.Windows.Forms.MessageBox]::Show("Please select at least one resource type.", "No Resource Types", "OK", "Warning"); return }
            if (-not (Get-Command ResourceHacker.exe -ErrorAction SilentlyContinue)) { Write-Log "ERROR: ResourceHacker.exe not found in PATH."; [System.Windows.Forms.MessageBox]::Show("ResourceHacker.exe could not be found.", "Dependency Missing", "OK", "Error"); return }

            Set-UIEnabledState($false); $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; $textBoxLog.Text = ""; Write-Log "Starting extraction process..."
            
            try {
                $baseOutputDirectory = $textBoxOutputDir.Text
                if (-not (Test-Path -Path $baseOutputDirectory)) { Write-Log "Base directory not found. Creating it..."; New-Item -Path $baseOutputDirectory -ItemType Directory -Force | Out-Null }
                
                foreach ($dllPath in $listBoxFiles.Items) {
                    $dllName = [System.IO.Path]::GetFileName($dllPath)
                    $dllSubfolderName = ([System.IO.Path]::GetFileNameWithoutExtension($dllName)) -replace "[^a-zA-Z0-9_.-]", '_'
                    $dllTargetDir = Join-Path -Path $baseOutputDirectory -ChildPath $dllSubfolderName
                    Write-Log "------------------------------------------------------------"; Write-Log "Processing: $dllName"
                    if ($checkBoxClearFolder.Checked -and (Test-Path -Path $dllTargetDir)) { Write-Log "Clearing existing target directory..."; Remove-Item -Path $dllTargetDir -Recurse -Force }
                    New-Item -Path $dllTargetDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    
                    $masks = @{"Icons" = "ICONGROUP,,"; "BMP" = "BITMAP,,"; "Cursors" = "CURSORGROUP,,"; "PNG" = "PNG,,"}
                    foreach ($type in $resourceTypes.Keys) {
                        if ($resourceTypes[$type]) {
                            $resourceSubfolderPath = Join-Path -Path $dllTargetDir -ChildPath $type
                            New-Item -Path $resourceSubfolderPath -ItemType Directory -Force | Out-Null
                            Write-Log "  -> Attempting to extract $type..."
                            $arguments = "-open `"$dllPath`" -save `"$resourceSubfolderPath`" -action extract -mask $($masks[$type])"
                            $pinfo = New-Object System.Diagnostics.ProcessStartInfo; $pinfo.FileName = "ResourceHacker.exe"; $pinfo.Arguments = $arguments; $pinfo.UseShellExecute = $false; $pinfo.CreateNoWindow = $true
                            $process = New-Object System.Diagnostics.Process; $process.StartInfo = $pinfo; $process.Start() | Out-Null; $process.WaitForExit()
                            if ((Get-ChildItem -Path $resourceSubfolderPath).Count -eq 0) { Write-Log "     - No resources of type '$type' found. Removing empty folder."; Remove-Item -Path $resourceSubfolderPath -Recurse -Force } else { Write-Log "     - Success. Resources saved to '$type' subfolder." }
                        }
                    }
                    
                    if ((Get-ChildItem -Path $dllTargetDir).Count -eq 0) {
                        Write-Log "  -> No resources of any selected type found for $dllName. Removing main folder."
                        Remove-Item -Path $dllTargetDir -Recurse -Force
                    }
                }
                Write-Log "------------------------------------------------------------"; Write-Log "All operations completed!"
                [System.Windows.Forms.MessageBox]::Show("Extraction process has finished.", "Complete", "OK", "Information")
            }
            catch { $errorMessage = "A critical error occurred: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $errorMessage"; [System.Windows.Forms.MessageBox]::Show($errorMessage, "Extraction Failed", "OK", "Error") }
            finally { Set-UIEnabledState($true); $form.Cursor = [System.Windows.Forms.Cursors]::Default }
        })
        
        $form.Add_Load({ Write-Log "Application Ready." })
        $form.ShowDialog() | Out-Null
        $form.Dispose()
    }
    catch { $errorMessage = "A critical, unhandled error occurred.`n`nMessage: $($_.Exception.Message)`nLine: $($_.InvocationInfo.ScriptLineNumber)`n`nFull Error Details:`n$($_ | Out-String)"; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($errorMessage, "Script Failed Critically", "OK", "Error") }
}

Show-ResourceExtractorGUI