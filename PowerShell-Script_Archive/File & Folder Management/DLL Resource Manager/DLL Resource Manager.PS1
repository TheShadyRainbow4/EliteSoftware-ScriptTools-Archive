# -----------------------------------------------------------------------------
# --- Script Information ---
# Author: Gemini (Modified by Zachary Whiteman/Scripy)
# Version: 6.8.4 (Automated VS Environment Setup)
# Description: This version adds a helper function to automatically find and
#              invoke the Visual Studio `vcvarsall.bat` script. This correctly
#              sets up the required environment (PATH, LIB, INCLUDE) for the
#              SDK tools (rc.exe, link.exe) to function properly from any shell.
# -----------------------------------------------------------------------------

# region Initialization and Setup

function Show-ResourceExtractorGUI {
    # Self-Elevation Check
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Administrator privileges required. Attempting to self-elevate..."
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-File `"$($MyInvocation.MyCommand.Path)`""
        exit
    }

    # --- Full Error Handling for Initialization ---
    try {
        # --- Assembly Loading ---
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop

        # --- Initial Setup ---
        [System.Windows.Forms.Application]::EnableVisualStyles()

        # --- App Data Configuration Management ---
        $projectName = "DLLResourceManager"
        $defaultOutputDirectory = 'G:\Extracted Resources'
        $configPath = Join-Path $env:APPDATA "EliteSoftware\$projectName\$projectName.config.json"
        $config = @{
            ExtractionOutputDirectory = $defaultOutputDirectory
            CreationOutputDirectory   = $defaultOutputDirectory
            ConfigVersion             = "6.8.4"
        }
        if (Test-Path $configPath) {
            try {
                $loadedConfig = Get-Content -Path $configPath | ConvertFrom-Json
                if (-not [string]::IsNullOrEmpty($loadedConfig.ExtractionOutputDirectory)) { $config.ExtractionOutputDirectory = $loadedConfig.ExtractionOutputDirectory }
                if (-not [string]::IsNullOrEmpty($loadedConfig.CreationOutputDirectory)) { $config.CreationOutputDirectory = $loadedConfig.CreationOutputDirectory }
            } catch { Write-Warning "Configuration file corrupted. Resetting to defaults." }
        }
        $appDataDir = Split-Path $configPath -Parent
        if (-not (Test-Path $appDataDir)) { New-Item -Path $appDataDir -ItemType Directory -Force | Out-Null }
        function Save-Config { try { $config | ConvertTo-Json | Set-Content -Path $configPath -Force } catch { Write-Error "Failed to save configuration: $($_.Exception.Message)" } }

# endregion

# region GUI Element Creation

        $form = New-Object System.Windows.Forms.Form
        $form.Text = "EliteSoftware - Batch Resource Extractor/Creator v6.8.4"
        $form.Size = New-Object System.Drawing.Size(600, 700)
        $form.MinimumSize = New-Object System.Drawing.Size(600, 550)
        $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "Sizable"; $form.MaximizeBox = $true; $form.MinimizeBox = $true

        $tabControl = New-Object System.Windows.Forms.TabControl
        $tabControl.Location = "10, 10"; $tabControl.Size = "565, 505"; $tabControl.Anchor = 'Top', 'Bottom', 'Left', 'Right'; $form.Controls.Add($tabControl)
        
        $tabPageDLL = New-Object System.Windows.Forms.TabPage; $tabPageDLL.Text = "DLL Resource Extraction"; $tabControl.Controls.Add($tabPageDLL)
        $tabPageMUI = New-Object System.Windows.Forms.TabPage; $tabPageMUI.Text = "MUI Resource Extraction"; $tabControl.Controls.Add($tabPageMUI)
        $tabPageEXE = New-Object System.Windows.Forms.TabPage; $tabPageEXE.Text = "EXE Resource Extraction"; $tabControl.Controls.Add($tabPageEXE)
        $tabPageCreation = New-Object System.Windows.Forms.TabPage; $tabPageCreation.Text = "Icon DLL Creation"; $tabControl.Controls.Add($tabPageCreation)

        $textBoxLog = New-Object System.Windows.Forms.TextBox
        $textBoxLog.Location = "10, 525"; $textBoxLog.Size = "565, 100"; $textBoxLog.Anchor = 'Bottom', 'Left', 'Right'; $textBoxLog.Multiline = $true; $textBoxLog.ScrollBars = "Vertical"; $textBoxLog.ReadOnly = $true; $textBoxLog.Font = "Consolas, 8"; $form.Controls.Add($textBoxLog)
        $statusBar = New-Object System.Windows.Forms.Label
        $statusBar.Location = "10, 630"; $statusBar.Size = "460, 20"; $statusBar.Text = "Ready"; $statusBar.Anchor = 'Bottom', 'Left'; $form.Controls.Add($statusBar)
        $versionLabel = New-Object System.Windows.Forms.Label
        $versionLabel.Location = "470, 630"; $versionLabel.Size = "100, 20"; $versionLabel.Text = "v6.8.4"; $versionLabel.TextAlign = "MiddleRight"; $versionLabel.Anchor = 'Bottom', 'Right'; $form.Controls.Add($versionLabel)

# endregion

# region Tab Controls Definition
        # Tab 1: DLL Extraction Controls
        $groupFiles_DLL = New-Object System.Windows.Forms.GroupBox; $groupFiles_DLL.Text = "DLL Files"; $groupFiles_DLL.Location = "10, 10"; $groupFiles_DLL.Size = "545, 160"; $tabPageDLL.Controls.Add($groupFiles_DLL)
        $listBoxFiles_DLL = New-Object System.Windows.Forms.ListBox; $listBoxFiles_DLL.Location = "15, 25"; $listBoxFiles_DLL.Size = "380, 120"; $listBoxFiles_DLL.SelectionMode = "MultiExtended"; $groupFiles_DLL.Controls.Add($listBoxFiles_DLL)
        $buttonAddFiles_DLL = New-Object System.Windows.Forms.Button; $buttonAddFiles_DLL.Text = "Add Files..."; $buttonAddFiles_DLL.Location = "405, 25"; $buttonAddFiles_DLL.Size = "125, 30"; $groupFiles_DLL.Controls.Add($buttonAddFiles_DLL)
        $buttonRemoveFile_DLL = New-Object System.Windows.Forms.Button; $buttonRemoveFile_DLL.Text = "Remove Selected"; $buttonRemoveFile_DLL.Location = "405, 60"; $buttonRemoveFile_DLL.Size = "125, 30"; $groupFiles_DLL.Controls.Add($buttonRemoveFile_DLL)
        $buttonClearList_DLL = New-Object System.Windows.Forms.Button; $buttonClearList_DLL.Text = "Clear List"; $buttonClearList_DLL.Location = "405, 95"; $buttonClearList_DLL.Size = "125, 30"; $groupFiles_DLL.Controls.Add($buttonClearList_DLL)
        $groupTypes_DLL = New-Object System.Windows.Forms.GroupBox; $groupTypes_DLL.Text = "Resource Types to Extract"; $groupTypes_DLL.Location = "10, 180"; $groupTypes_DLL.Size = "545, 60"; $tabPageDLL.Controls.Add($groupTypes_DLL)
        $checkBoxIcons_DLL = New-Object System.Windows.Forms.CheckBox; $checkBoxIcons_DLL.Text = "Icons"; $checkBoxIcons_DLL.Location = "20, 25"; $checkBoxIcons_DLL.Checked = $true; $checkBoxIcons_DLL.AutoSize = $true; $groupTypes_DLL.Controls.Add($checkBoxIcons_DLL)
        $checkBoxBitmaps_DLL = New-Object System.Windows.Forms.CheckBox; $checkBoxBitmaps_DLL.Text = "BMP"; $checkBoxBitmaps_DLL.Location = "120, 25"; $checkBoxBitmaps_DLL.AutoSize = $true; $groupTypes_DLL.Controls.Add($checkBoxBitmaps_DLL)
        $checkBoxCursors_DLL = New-Object System.Windows.Forms.CheckBox; $checkBoxCursors_DLL.Text = "Cursors"; $checkBoxCursors_DLL.Location = "220, 25"; $checkBoxCursors_DLL.AutoSize = $true; $groupTypes_DLL.Controls.Add($checkBoxCursors_DLL)
        $checkBoxPngs_DLL = New-Object System.Windows.Forms.CheckBox; $checkBoxPngs_DLL.Text = "PNG"; $checkBoxPngs_DLL.Location = "320, 25"; $checkBoxPngs_DLL.AutoSize = $true; $groupTypes_DLL.Controls.Add($checkBoxPngs_DLL)
        $groupAdvanced_DLL = New-Object System.Windows.Forms.GroupBox; $groupAdvanced_DLL.Text = "Advanced Options"; $groupAdvanced_DLL.Location = "10, 250"; $groupAdvanced_DLL.Size = "545, 90"; $tabPageDLL.Controls.Add($groupAdvanced_DLL)
        $textBoxOutputDir_DLL = New-Object System.Windows.Forms.TextBox; $textBoxOutputDir_DLL.Text = $config.ExtractionOutputDirectory; $textBoxOutputDir_DLL.Location = "125, 25"; $textBoxOutputDir_DLL.Size = "295, 20"; $groupAdvanced_DLL.Controls.Add($textBoxOutputDir_DLL)
        $buttonBrowse_DLL = New-Object System.Windows.Forms.Button; $buttonBrowse_DLL.Text = "Browse..."; $buttonBrowse_DLL.Location = "430, 24"; $buttonBrowse_DLL.Size = "100, 23"; $groupAdvanced_DLL.Controls.Add($buttonBrowse_DLL)
        $checkBoxClearFolder_DLL = New-Object System.Windows.Forms.CheckBox; $checkBoxClearFolder_DLL.Text = "Clear existing output sub-folder before extraction"; $checkBoxClearFolder_DLL.Location = "15, 55"; $checkBoxClearFolder_DLL.AutoSize = $true; $groupAdvanced_DLL.Controls.Add($checkBoxClearFolder_DLL)
        $buttonExtract_DLL = New-Object System.Windows.Forms.Button; $buttonExtract_DLL.Text = "Start Extraction"; $buttonExtract_DLL.Location = "142, 350"; $buttonExtract_DLL.Size = "280, 30"; $buttonExtract_DLL.Anchor = 'Top', 'Left'; $tabPageDLL.Controls.Add($buttonExtract_DLL)
        $buttonArchive_DLL = New-Object System.Windows.Forms.Button; $buttonArchive_DLL.Text = "Archive Previous Extractions"; $buttonArchive_DLL.Location = "10, 385"; $buttonArchive_DLL.Size = "267, 30"; $buttonArchive_DLL.Anchor = 'Top', 'Left'; $tabPageDLL.Controls.Add($buttonArchive_DLL)
        $buttonOpenOutput_DLL = New-Object System.Windows.Forms.Button; $buttonOpenOutput_DLL.Text = "Open Output Folder"; $buttonOpenOutput_DLL.Location = "287, 385"; $buttonOpenOutput_DLL.Size = "268, 30"; $buttonOpenOutput_DLL.Anchor = 'Top', 'Left'; $tabPageDLL.Controls.Add($buttonOpenOutput_DLL)

        # Tab 2: MUI Extraction Controls
        $groupFiles_MUI = New-Object System.Windows.Forms.GroupBox; $groupFiles_MUI.Text = "MUI Files"; $groupFiles_MUI.Location = "10, 10"; $groupFiles_MUI.Size = "545, 160"; $tabPageMUI.Controls.Add($groupFiles_MUI)
        $listBoxFiles_MUI = New-Object System.Windows.Forms.ListBox; $listBoxFiles_MUI.Location = "15, 25"; $listBoxFiles_MUI.Size = "380, 120"; $listBoxFiles_MUI.SelectionMode = "MultiExtended"; $groupFiles_MUI.Controls.Add($listBoxFiles_MUI)
        $buttonAddFiles_MUI = New-Object System.Windows.Forms.Button; $buttonAddFiles_MUI.Text = "Add Files..."; $buttonAddFiles_MUI.Location = "405, 25"; $buttonAddFiles_MUI.Size = "125, 30"; $groupFiles_MUI.Controls.Add($buttonAddFiles_MUI)
        $buttonRemoveFile_MUI = New-Object System.Windows.Forms.Button; $buttonRemoveFile_MUI.Text = "Remove Selected"; $buttonRemoveFile_MUI.Location = "405, 60"; $buttonRemoveFile_MUI.Size = "125, 30"; $groupFiles_MUI.Controls.Add($buttonRemoveFile_MUI)
        $buttonClearList_MUI = New-Object System.Windows.Forms.Button; $buttonClearList_MUI.Text = "Clear List"; $buttonClearList_MUI.Location = "405, 95"; $buttonClearList_MUI.Size = "125, 30"; $groupFiles_MUI.Controls.Add($buttonClearList_MUI)
        $groupTypes_MUI = New-Object System.Windows.Forms.GroupBox; $groupTypes_MUI.Text = "Resource Types to Extract"; $groupTypes_MUI.Location = "10, 180"; $groupTypes_MUI.Size = "545, 60"; $tabPageMUI.Controls.Add($groupTypes_MUI)
        $checkBoxIcons_MUI = New-Object System.Windows.Forms.CheckBox; $checkBoxIcons_MUI.Text = "Icons"; $checkBoxIcons_MUI.Location = "20, 25"; $checkBoxIcons_MUI.Checked = $true; $checkBoxIcons_MUI.AutoSize = $true; $groupTypes_MUI.Controls.Add($checkBoxIcons_MUI)
        $checkBoxBitmaps_MUI = New-Object System.Windows.Forms.CheckBox; $checkBoxBitmaps_MUI.Text = "BMP"; $checkBoxBitmaps_MUI.Location = "120, 25"; $checkBoxBitmaps_MUI.AutoSize = $true; $groupTypes_MUI.Controls.Add($checkBoxBitmaps_MUI)
        $checkBoxCursors_MUI = New-Object System.Windows.Forms.CheckBox; $checkBoxCursors_MUI.Text = "Cursors"; $checkBoxCursors_MUI.Location = "220, 25"; $checkBoxCursors_MUI.AutoSize = $true; $groupTypes_MUI.Controls.Add($checkBoxCursors_MUI)
        $checkBoxPngs_MUI = New-Object System.Windows.Forms.CheckBox; $checkBoxPngs_MUI.Text = "PNG"; $checkBoxPngs_MUI.Location = "320, 25"; $checkBoxPngs_MUI.AutoSize = $true; $groupTypes_MUI.Controls.Add($checkBoxPngs_MUI)
        $groupAdvanced_MUI = New-Object System.Windows.Forms.GroupBox; $groupAdvanced_MUI.Text = "Advanced Options"; $groupAdvanced_MUI.Location = "10, 250"; $groupAdvanced_MUI.Size = "545, 90"; $tabPageMUI.Controls.Add($groupAdvanced_MUI)
        $textBoxOutputDir_MUI = New-Object System.Windows.Forms.TextBox; $textBoxOutputDir_MUI.Text = $config.ExtractionOutputDirectory; $textBoxOutputDir_MUI.Location = "125, 25"; $textBoxOutputDir_MUI.Size = "295, 20"; $groupAdvanced_MUI.Controls.Add($textBoxOutputDir_MUI)
        $buttonBrowse_MUI = New-Object System.Windows.Forms.Button; $buttonBrowse_MUI.Text = "Browse..."; $buttonBrowse_MUI.Location = "430, 24"; $buttonBrowse_MUI.Size = "100, 23"; $groupAdvanced_MUI.Controls.Add($buttonBrowse_MUI)
        $checkBoxClearFolder_MUI = New-Object System.Windows.Forms.CheckBox; $checkBoxClearFolder_MUI.Text = "Clear existing output sub-folder before extraction"; $checkBoxClearFolder_MUI.Location = "15, 55"; $checkBoxClearFolder_MUI.AutoSize = $true; $groupAdvanced_MUI.Controls.Add($checkBoxClearFolder_MUI)
        $buttonExtract_MUI = New-Object System.Windows.Forms.Button; $buttonExtract_MUI.Text = "Start Extraction"; $buttonExtract_MUI.Location = "142, 350"; $buttonExtract_MUI.Size = "280, 30"; $buttonExtract_MUI.Anchor = 'Top', 'Left'; $tabPageMUI.Controls.Add($buttonExtract_MUI)
        $buttonArchive_MUI = New-Object System.Windows.Forms.Button; $buttonArchive_MUI.Text = "Archive Previous Extractions"; $buttonArchive_MUI.Location = "10, 385"; $buttonArchive_MUI.Size = "267, 30"; $buttonArchive_MUI.Anchor = 'Top', 'Left'; $tabPageMUI.Controls.Add($buttonArchive_MUI)
        $buttonOpenOutput_MUI = New-Object System.Windows.Forms.Button; $buttonOpenOutput_MUI.Text = "Open Output Folder"; $buttonOpenOutput_MUI.Location = "287, 385"; $buttonOpenOutput_MUI.Size = "268, 30"; $buttonOpenOutput_MUI.Anchor = 'Top', 'Left'; $tabPageMUI.Controls.Add($buttonOpenOutput_MUI)

        # Tab 3: EXE Extraction Controls
        $groupFiles_EXE = New-Object System.Windows.Forms.GroupBox; $groupFiles_EXE.Text = "EXE Files"; $groupFiles_EXE.Location = "10, 10"; $groupFiles_EXE.Size = "545, 160"; $tabPageEXE.Controls.Add($groupFiles_EXE)
        $listBoxFiles_EXE = New-Object System.Windows.Forms.ListBox; $listBoxFiles_EXE.Location = "15, 25"; $listBoxFiles_EXE.Size = "380, 120"; $listBoxFiles_EXE.SelectionMode = "MultiExtended"; $groupFiles_EXE.Controls.Add($listBoxFiles_EXE)
        $buttonAddFiles_EXE = New-Object System.Windows.Forms.Button; $buttonAddFiles_EXE.Text = "Add Files..."; $buttonAddFiles_EXE.Location = "405, 25"; $buttonAddFiles_EXE.Size = "125, 30"; $groupFiles_EXE.Controls.Add($buttonAddFiles_EXE)
        $buttonRemoveFile_EXE = New-Object System.Windows.Forms.Button; $buttonRemoveFile_EXE.Text = "Remove Selected"; $buttonRemoveFile_EXE.Location = "405, 60"; $buttonRemoveFile_EXE.Size = "125, 30"; $groupFiles_EXE.Controls.Add($buttonRemoveFile_EXE)
        $buttonClearList_EXE = New-Object System.Windows.Forms.Button; $buttonClearList_EXE.Text = "Clear List"; $buttonClearList_EXE.Location = "405, 95"; $buttonClearList_EXE.Size = "125, 30"; $groupFiles_EXE.Controls.Add($buttonClearList_EXE)
        $groupTypes_EXE = New-Object System.Windows.Forms.GroupBox; $groupTypes_EXE.Text = "Resource Types to Extract"; $groupTypes_EXE.Location = "10, 180"; $groupTypes_EXE.Size = "545, 60"; $tabPageEXE.Controls.Add($groupTypes_EXE)
        $checkBoxIcons_EXE = New-Object System.Windows.Forms.CheckBox; $checkBoxIcons_EXE.Text = "Icons"; $checkBoxIcons_EXE.Location = "20, 25"; $checkBoxIcons_EXE.Checked = $true; $checkBoxIcons_EXE.AutoSize = $true; $groupTypes_EXE.Controls.Add($checkBoxIcons_EXE)
        $checkBoxBitmaps_EXE = New-Object System.Windows.Forms.CheckBox; $checkBoxBitmaps_EXE.Text = "BMP"; $checkBoxBitmaps_EXE.Location = "120, 25"; $checkBoxBitmaps_EXE.AutoSize = $true; $groupTypes_EXE.Controls.Add($checkBoxBitmaps_EXE)
        $checkBoxCursors_EXE = New-Object System.Windows.Forms.CheckBox; $checkBoxCursors_EXE.Text = "Cursors"; $checkBoxCursors_EXE.Location = "220, 25"; $checkBoxCursors_EXE.AutoSize = $true; $groupTypes_EXE.Controls.Add($checkBoxCursors_EXE)
        $checkBoxPngs_EXE = New-Object System.Windows.Forms.CheckBox; $checkBoxPngs_EXE.Text = "PNG"; $checkBoxPngs_EXE.Location = "320, 25"; $checkBoxPngs_EXE.AutoSize = $true; $groupTypes_EXE.Controls.Add($checkBoxPngs_EXE)
        $groupAdvanced_EXE = New-Object System.Windows.Forms.GroupBox; $groupAdvanced_EXE.Text = "Advanced Options"; $groupAdvanced_EXE.Location = "10, 250"; $groupAdvanced_EXE.Size = "545, 90"; $tabPageEXE.Controls.Add($groupAdvanced_EXE)
        $textBoxOutputDir_EXE = New-Object System.Windows.Forms.TextBox; $textBoxOutputDir_EXE.Text = $config.ExtractionOutputDirectory; $textBoxOutputDir_EXE.Location = "125, 25"; $textBoxOutputDir_EXE.Size = "295, 20"; $groupAdvanced_EXE.Controls.Add($textBoxOutputDir_EXE)
        $buttonBrowse_EXE = New-Object System.Windows.Forms.Button; $buttonBrowse_EXE.Text = "Browse..."; $buttonBrowse_EXE.Location = "430, 24"; $buttonBrowse_EXE.Size = "100, 23"; $groupAdvanced_EXE.Controls.Add($buttonBrowse_EXE)
        $checkBoxClearFolder_EXE = New-Object System.Windows.Forms.CheckBox; $checkBoxClearFolder_EXE.Text = "Clear existing output sub-folder before extraction"; $checkBoxClearFolder_EXE.Location = "15, 55"; $checkBoxClearFolder_EXE.AutoSize = $true; $groupAdvanced_EXE.Controls.Add($checkBoxClearFolder_EXE)
        $buttonExtract_EXE = New-Object System.Windows.Forms.Button; $buttonExtract_EXE.Text = "Start Extraction"; $buttonExtract_EXE.Location = "142, 350"; $buttonExtract_EXE.Size = "280, 30"; $buttonExtract_EXE.Anchor = 'Top', 'Left'; $tabPageEXE.Controls.Add($buttonExtract_EXE)
        $buttonArchive_EXE = New-Object System.Windows.Forms.Button; $buttonArchive_EXE.Text = "Archive Previous Extractions"; $buttonArchive_EXE.Location = "10, 385"; $buttonArchive_EXE.Size = "267, 30"; $buttonArchive_EXE.Anchor = 'Top', 'Left'; $tabPageEXE.Controls.Add($buttonArchive_EXE)
        $buttonOpenOutput_EXE = New-Object System.Windows.Forms.Button; $buttonOpenOutput_EXE.Text = "Open Output Folder"; $buttonOpenOutput_EXE.Location = "287, 385"; $buttonOpenOutput_EXE.Size = "268, 30"; $buttonOpenOutput_EXE.Anchor = 'Top', 'Left'; $tabPageEXE.Controls.Add($buttonOpenOutput_EXE)

        # Tab 4: Icon DLL Creation Controls
        $groupIconList = New-Object System.Windows.Forms.GroupBox; $groupIconList.Text = "Source Icon Files (*.ico)"; $groupIconList.Location = "10, 10"; $groupIconList.Size = "545, 170"; $tabPageCreation.Controls.Add($groupIconList)
        $listBoxIcons = New-Object System.Windows.Forms.ListBox; $listBoxIcons.Location = "15, 25"; $listBoxIcons.Size = "380, 130"; $listBoxIcons.SelectionMode = "MultiExtended"; $groupIconList.Controls.Add($listBoxIcons)
        $buttonAddIcons = New-Object System.Windows.Forms.Button; $buttonAddIcons.Text = "Add Icons..."; $buttonAddIcons.Location = "405, 25"; $buttonAddIcons.Size = "125, 30"; $groupIconList.Controls.Add($buttonAddIcons)
        $buttonRemoveIcons = New-Object System.Windows.Forms.Button; $buttonRemoveIcons.Text = "Remove Selected"; $buttonRemoveIcons.Location = "405, 60"; $buttonRemoveIcons.Size = "125, 30"; $groupIconList.Controls.Add($buttonRemoveIcons)
        $buttonClearIcons = New-Object System.Windows.Forms.Button; $buttonClearIcons.Text = "Clear List"; $buttonClearIcons.Location = "405, 95"; $buttonClearIcons.Size = "125, 30"; $groupIconList.Controls.Add($buttonClearIcons)
        $groupCreationOutput = New-Object System.Windows.Forms.GroupBox; $groupCreationOutput.Text = "Output Settings"; $groupCreationOutput.Location = "10, 190"; $groupCreationOutput.Size = "545, 130"; $tabPageCreation.Controls.Add($groupCreationOutput)
        $textBoxDllName = New-Object System.Windows.Forms.TextBox; $textBoxDllName.Text = "MyCustomIcons.dll"; $textBoxDllName.Location = "125, 25"; $textBoxDllName.Size = "405, 20"; $groupCreationOutput.Controls.Add($textBoxDllName)
        $textBoxCreationDir = New-Object System.Windows.Forms.TextBox; $textBoxCreationDir.Text = $config.CreationOutputDirectory; $textBoxCreationDir.Location = "125, 60"; $textBoxCreationDir.Size = "295, 20"; $groupCreationOutput.Controls.Add($textBoxCreationDir)
        $buttonBrowseCreation = New-Object System.Windows.Forms.Button; $buttonBrowseCreation.Text = "Browse..."; $buttonBrowseCreation.Location = "430, 59"; $buttonBrowseCreation.Size = "100, 23"; $groupCreationOutput.Controls.Add($buttonBrowseCreation)
        $checkBoxAutoOpen = New-Object System.Windows.Forms.CheckBox; $checkBoxAutoOpen.Text = "Open output folder upon successful creation"; $checkBoxAutoOpen.Location = "15, 95"; $checkBoxAutoOpen.Checked = $true; $checkBoxAutoOpen.AutoSize = $true; $groupCreationOutput.Controls.Add($checkBoxAutoOpen)
        $buttonCreateDll = New-Object System.Windows.Forms.Button; $buttonCreateDll.Text = "Create Icon DLL"; $buttonCreateDll.Location = "142, 330"; $buttonCreateDll.Size = "280, 30"; $buttonCreateDll.Anchor = 'Top', 'Left'; $tabPageCreation.Controls.Add($buttonCreateDll)
# endregion

# region Functions and Event Handlers
        # --- Global Helper Functions ---
        $script:vsEnvInitialized = $false
        function Write-Log($message, [string]$status = "Ready") { if (-not [string]::IsNullOrEmpty($message)) { $timestamp = Get-Date -Format "HH:mm:ss"; $logEntry = "[$timestamp] $message"; $textBoxLog.AppendText("$logEntry`r`n"); $textBoxLog.SelectionStart = $textBoxLog.Text.Length; $textBoxLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }; $statusBar.Text = $status }
        function Set-UIEnabledState($enabled) { $tabControl.Enabled = $enabled }

        function Import-VisualStudioEnvironment {
            if ($script:vsEnvInitialized) { return $true }
            
            Write-Log "Initializing Visual Studio build environment..." -status "Initializing..."
            try {
                # Find vswhere.exe, which is the official way to locate VS installations
                $vsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
                if (-not (Test-Path $vsWherePath)) {
                    throw "vswhere.exe not found. Cannot locate Visual Studio."
                }

                # Use vswhere to get the installation path
                $vsInstallPath = & $vsWherePath -latest -property installationPath
                if ([string]::IsNullOrEmpty($vsInstallPath)) {
                    throw "Could not determine Visual Studio installation path."
                }

                $vcvarsPath = Join-Path $vsInstallPath "VC\Auxiliary\Build\vcvarsall.bat"
                if (-not (Test-Path $vcvarsPath)) {
                    throw "vcvarsall.bat not found at expected path: $vcvarsPath"
                }
                
                Write-Log "  -> Found vcvarsall.bat. Importing environment..."
                # This is the magic part: run the batch file and capture the environment variables it sets
                $cmd = "`"`"$vcvarsPath`"`" x64 & set"
                $envVars = cmd /c $cmd
                
                foreach ($line in ($envVars -split "`r`n")) {
                    if ($line -match '^([^=]+)=(.*)$') {
                        $name = $matches[1]
                        $value = $matches[2]
                        # Set the environment variable in the current PowerShell process
                        [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
                    }
                }
                Write-Log "  -> Build environment imported successfully."
                $script:vsEnvInitialized = $true
                return $true
            } catch {
                Write-Log "FATAL: Failed to initialize VS Build Environment: $($_.Exception.Message)" -status "Job Failed"
                return $false
            }
        }


        # --- Tab 1: DLL Event Handlers (Extraction) ---
        $buttonAddFiles_DLL.Add_Click({ try { $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Title = "Select DLL Files"; $ofd.Filter = "DLL Files (*.dll)|*.dll|All Files (*.*)|*.*"; $ofd.MultiSelect = $true; if ($ofd.ShowDialog() -eq "OK") { foreach ($file in $ofd.FileNames) { if (-not $listBoxFiles_DLL.Items.Contains($file)) { $listBoxFiles_DLL.Items.Add($file) | Out-Null } } } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonRemoveFile_DLL.Add_Click({ try { for ($i = $listBoxFiles_DLL.SelectedItems.Count - 1; $i -ge 0; $i--) { $listBoxFiles_DLL.Items.Remove($listBoxFiles_DLL.SelectedItems[$i]) } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonClearList_DLL.Add_Click({ try { $listBoxFiles_DLL.Items.Clear(); Write-Log "DLL file list cleared." } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonBrowse_DLL.Add_Click({ try { $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; $fbd.Description = "Select Output Directory"; $fbd.SelectedPath = $textBoxOutputDir_DLL.Text; if ($fbd.ShowDialog() -eq "OK") { $textBoxOutputDir_DLL.Text = $fbd.SelectedPath; $config.ExtractionOutputDirectory = $fbd.SelectedPath; Save-Config } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonOpenOutput_DLL.Add_Click({ try { if (Test-Path -Path $textBoxOutputDir_DLL.Text) { Invoke-Item -Path $textBoxOutputDir_DLL.Text } else { [System.Windows.Forms.MessageBox]::Show("Directory does not exist.", "Not Found", "OK", "Information") } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonArchive_DLL.Add_Click({ try { $baseDir = $textBoxOutputDir_DLL.Text; if (-not (Test-Path -Path $baseDir)) { [System.Windows.Forms.MessageBox]::Show("Directory does not exist.", "Not Found", "OK", "Information"); return }; $items = Get-ChildItem -Path $baseDir | Where-Object { $_.Name -notlike "Previously Extracted*" }; if ($items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nothing to archive.", "Empty", "OK", "Information"); return }; Write-Log "Archiving..." -status "Archiving..."; $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Set-UIEnabledState($false); $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"; $archiveFolder = "Previously Extracted ($ts)"; $archivePath = Join-Path -Path $baseDir -ChildPath $archiveFolder; New-Item -Path $archivePath -ItemType Directory -Force | Out-Null; foreach ($item in $items) { Move-Item -Path $item.FullName -Destination $archivePath -Force }; Write-Log "Archive complete." -status "Ready"; [System.Windows.Forms.MessageBox]::Show("Archive complete.", "Complete", "OK", "Information") } catch { $err = "Archive error: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $err" -status "Job Failed"; [System.Windows.Forms.MessageBox]::Show($err, "Archive Failed", "OK", "Error") } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default; Set-UIEnabledState($true) } })
        $buttonExtract_DLL.Add_Click({
            if ($listBoxFiles_DLL.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please add at least one DLL file.", "No Files", "OK", "Warning"); return }
            $resourceTypes = @{ "Icons" = $checkBoxIcons_DLL.Checked; "BMP" = $checkBoxBitmaps_DLL.Checked; "Cursors" = $checkBoxCursors_DLL.Checked; "PNG" = $checkBoxPngs_DLL.Checked }
            if (-not ($resourceTypes.ContainsValue($true))) { [System.Windows.Forms.MessageBox]::Show("Please select at least one resource type.", "No Types", "OK", "Warning"); return }
            if (-not (Get-Command ResourceHacker.exe -ErrorAction SilentlyContinue)) { Write-Log "ERROR: ResourceHacker.exe not found." -status "Critical Error"; [System.Windows.Forms.MessageBox]::Show("ResourceHacker.exe not found.", "Dependency Missing", "OK", "Error"); return }
            Set-UIEnabledState($false); $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Write-Log "Starting extraction..." -status "Extracting..."
            try {
                $baseOutputDir = $textBoxOutputDir_DLL.Text
                if (-not (Test-Path -Path $baseOutputDir)) { Write-Log "Base directory not found. Creating..."; New-Item -Path $baseOutputDir -ItemType Directory -Force | Out-Null }
                foreach ($filePath in $listBoxFiles_DLL.Items) {
                    $fileName = [System.IO.Path]::GetFileName($filePath); $subfolderName = ([System.IO.Path]::GetFileNameWithoutExtension($fileName)) -replace "[^a-zA-Z0-9_.-]", '_'; $targetDir = Join-Path -Path $baseOutputDir -ChildPath $subfolderName
                    Write-Log "Processing: $fileName"
                    if ($checkBoxClearFolder_DLL.Checked -and (Test-Path -Path $targetDir)) { Write-Log "  -> Clearing existing folder..."; Remove-Item -Path $targetDir -Recurse -Force }
                    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    $masks = @{"Icons" = "ICONGROUP,,"; "BMP" = "BITMAP,,"; "Cursors" = "CURSORGROUP,,"; "PNG" = "PNG,,"}
                    foreach ($type in $resourceTypes.Keys) {
                        if ($resourceTypes[$type]) {
                            $resPath = Join-Path -Path $targetDir -ChildPath $type; New-Item -Path $resPath -ItemType Directory -Force | Out-Null
                            Write-Log "  -> Extracting $type..."
                            $args = "-open `"$filePath`" -save `"$resPath`" -action extract -mask $($masks[$type])"
                            $pinfo = New-Object System.Diagnostics.ProcessStartInfo; $pinfo.FileName = "ResourceHacker.exe"; $pinfo.Arguments = $args; $pinfo.UseShellExecute = $false; $pinfo.CreateNoWindow = $true
                            $process = New-Object System.Diagnostics.Process; $process.StartInfo = $pinfo; $process.Start() | Out-Null; $process.WaitForExit()
                            if ((Get-ChildItem -Path $resPath).Count -eq 0) { Write-Log "     - No '$type' resources found. Removing folder."; Remove-Item -Path $resPath -Recurse -Force } else { Write-Log "     - Success." }
                        }
                    }
                    if ((Get-ChildItem -Path $targetDir).Count -eq 0) { Write-Log "  -> No resources found. Removing main folder."; Remove-Item -Path $targetDir -Recurse -Force }
                }
                Write-Log "All operations completed!"; [System.Windows.Forms.MessageBox]::Show("Extraction complete.", "Complete", "OK", "Information")
            } catch { $err = "Extraction error: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $err" -status "Job Failed"; [System.Windows.Forms.MessageBox]::Show($err, "Extraction Failed", "OK", "Error") }
            finally { Set-UIEnabledState($true); $form.Cursor = [System.Windows.Forms.Cursors]::Default; $statusBar.Text = "Ready" }
        })

        # --- Tab 2: MUI Event Handlers (Extraction) ---
        $buttonAddFiles_MUI.Add_Click({ try { $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Title = "Select MUI Files"; $ofd.Filter = "MUI Files (*.mui)|*.mui|All Files (*.*)|*.*"; $ofd.MultiSelect = $true; if ($ofd.ShowDialog() -eq "OK") { foreach ($file in $ofd.FileNames) { if (-not $listBoxFiles_MUI.Items.Contains($file)) { $listBoxFiles_MUI.Items.Add($file) | Out-Null } } } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonRemoveFile_MUI.Add_Click({ try { for ($i = $listBoxFiles_MUI.SelectedItems.Count - 1; $i -ge 0; $i--) { $listBoxFiles_MUI.Items.Remove($listBoxFiles_MUI.SelectedItems[$i]) } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonClearList_MUI.Add_Click({ try { $listBoxFiles_MUI.Items.Clear(); Write-Log "MUI file list cleared." } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonBrowse_MUI.Add_Click({ try { $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; $fbd.Description = "Select Output Directory"; $fbd.SelectedPath = $textBoxOutputDir_MUI.Text; if ($fbd.ShowDialog() -eq "OK") { $textBoxOutputDir_MUI.Text = $fbd.SelectedPath; $config.ExtractionOutputDirectory = $fbd.SelectedPath; Save-Config } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonOpenOutput_MUI.Add_Click({ try { if (Test-Path -Path $textBoxOutputDir_MUI.Text) { Invoke-Item -Path $textBoxOutputDir_MUI.Text } else { [System.Windows.Forms.MessageBox]::Show("Directory does not exist.", "Not Found", "OK", "Information") } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonArchive_MUI.Add_Click({ try { $baseDir = $textBoxOutputDir_MUI.Text; if (-not (Test-Path -Path $baseDir)) { [System.Windows.Forms.MessageBox]::Show("Directory does not exist.", "Not Found", "OK", "Information"); return }; $items = Get-ChildItem -Path $baseDir | Where-Object { $_.Name -notlike "Previously Extracted*" }; if ($items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nothing to archive.", "Empty", "OK", "Information"); return }; Write-Log "Archiving..." -status "Archiving..."; $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Set-UIEnabledState($false); $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"; $archiveFolder = "Previously Extracted ($ts)"; $archivePath = Join-Path -Path $baseDir -ChildPath $archiveFolder; New-Item -Path $archivePath -ItemType Directory -Force | Out-Null; foreach ($item in $items) { Move-Item -Path $item.FullName -Destination $archivePath -Force }; Write-Log "Archive complete." -status "Ready"; [System.Windows.Forms.MessageBox]::Show("Archive complete.", "Complete", "OK", "Information") } catch { $err = "Archive error: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $err" -status "Job Failed"; [System.Windows.Forms.MessageBox]::Show($err, "Archive Failed", "OK", "Error") } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default; Set-UIEnabledState($true) } })
        $buttonExtract_MUI.Add_Click({
            if ($listBoxFiles_MUI.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please add at least one MUI file.", "No Files", "OK", "Warning"); return }
            $resourceTypes = @{ "Icons" = $checkBoxIcons_MUI.Checked; "BMP" = $checkBoxBitmaps_MUI.Checked; "Cursors" = $checkBoxCursors_MUI.Checked; "PNG" = $checkBoxPngs_MUI.Checked }
            if (-not ($resourceTypes.ContainsValue($true))) { [System.Windows.Forms.MessageBox]::Show("Please select at least one resource type.", "No Types", "OK", "Warning"); return }
            if (-not (Get-Command ResourceHacker.exe -ErrorAction SilentlyContinue)) { Write-Log "ERROR: ResourceHacker.exe not found." -status "Critical Error"; [System.Windows.Forms.MessageBox]::Show("ResourceHacker.exe not found.", "Dependency Missing", "OK", "Error"); return }
            Set-UIEnabledState($false); $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Write-Log "Starting extraction..." -status "Extracting..."
            try {
                $baseOutputDir = $textBoxOutputDir_MUI.Text
                if (-not (Test-Path -Path $baseOutputDir)) { Write-Log "Base directory not found. Creating..."; New-Item -Path $baseOutputDir -ItemType Directory -Force | Out-Null }
                foreach ($filePath in $listBoxFiles_MUI.Items) {
                    $fileName = [System.IO.Path]::GetFileName($filePath); $subfolderName = ([System.IO.Path]::GetFileNameWithoutExtension($fileName)) -replace "[^a-zA-Z0-9_.-]", '_'; $targetDir = Join-Path -Path $baseOutputDir -ChildPath $subfolderName
                    Write-Log "Processing: $fileName"
                    if ($checkBoxClearFolder_MUI.Checked -and (Test-Path -Path $targetDir)) { Write-Log "  -> Clearing existing folder..."; Remove-Item -Path $targetDir -Recurse -Force }
                    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    $masks = @{"Icons" = "ICONGROUP,,"; "BMP" = "BITMAP,,"; "Cursors" = "CURSORGROUP,,"; "PNG" = "PNG,,"}
                    foreach ($type in $resourceTypes.Keys) {
                        if ($resourceTypes[$type]) {
                            $resPath = Join-Path -Path $targetDir -ChildPath $type; New-Item -Path $resPath -ItemType Directory -Force | Out-Null
                            Write-Log "  -> Extracting $type..."
                            $args = "-open `"$filePath`" -save `"$resPath`" -action extract -mask $($masks[$type])"
                            $pinfo = New-Object System.Diagnostics.ProcessStartInfo; $pinfo.FileName = "ResourceHacker.exe"; $pinfo.Arguments = $args; $pinfo.UseShellExecute = $false; $pinfo.CreateNoWindow = $true
                            $process = New-Object System.Diagnostics.Process; $process.StartInfo = $pinfo; $process.Start() | Out-Null; $process.WaitForExit()
                            if ((Get-ChildItem -Path $resPath).Count -eq 0) { Write-Log "     - No '$type' resources found. Removing folder."; Remove-Item -Path $resPath -Recurse -Force } else { Write-Log "     - Success." }
                        }
                    }
                    if ((Get-ChildItem -Path $targetDir).Count -eq 0) { Write-Log "  -> No resources found. Removing main folder."; Remove-Item -Path $targetDir -Recurse -Force }
                }
                Write-Log "All operations completed!"; [System.Windows.Forms.MessageBox]::Show("Extraction complete.", "Complete", "OK", "Information")
            } catch { $err = "Extraction error: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $err" -status "Job Failed"; [System.Windows.Forms.MessageBox]::Show($err, "Extraction Failed", "OK", "Error") }
            finally { Set-UIEnabledState($true); $form.Cursor = [System.Windows.Forms.Cursors]::Default; $statusBar.Text = "Ready" }
        })

        # --- Tab 3: EXE Event Handlers (Extraction) ---
        $buttonAddFiles_EXE.Add_Click({ try { $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Title = "Select EXE Files"; $ofd.Filter = "EXE Files (*.exe)|*.exe|All Files (*.*)|*.*"; $ofd.MultiSelect = $true; if ($ofd.ShowDialog() -eq "OK") { foreach ($file in $ofd.FileNames) { if (-not $listBoxFiles_EXE.Items.Contains($file)) { $listBoxFiles_EXE.Items.Add($file) | Out-Null } } } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonRemoveFile_EXE.Add_Click({ try { for ($i = $listBoxFiles_EXE.SelectedItems.Count - 1; $i -ge 0; $i--) { $listBoxFiles_EXE.Items.Remove($listBoxFiles_EXE.SelectedItems[$i]) } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonClearList_EXE.Add_Click({ try { $listBoxFiles_EXE.Items.Clear(); Write-Log "EXE file list cleared." } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonBrowse_EXE.Add_Click({ try { $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; $fbd.Description = "Select Output Directory"; $fbd.SelectedPath = $textBoxOutputDir_EXE.Text; if ($fbd.ShowDialog() -eq "OK") { $textBoxOutputDir_EXE.Text = $fbd.SelectedPath; $config.ExtractionOutputDirectory = $fbd.SelectedPath; Save-Config } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonOpenOutput_EXE.Add_Click({ try { if (Test-Path -Path $textBoxOutputDir_EXE.Text) { Invoke-Item -Path $textBoxOutputDir_EXE.Text } else { [System.Windows.Forms.MessageBox]::Show("Directory does not exist.", "Not Found", "OK", "Information") } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonArchive_EXE.Add_Click({ try { $baseDir = $textBoxOutputDir_EXE.Text; if (-not (Test-Path -Path $baseDir)) { [System.Windows.Forms.MessageBox]::Show("Directory does not exist.", "Not Found", "OK", "Information"); return }; $items = Get-ChildItem -Path $baseDir | Where-Object { $_.Name -notlike "Previously Extracted*" }; if ($items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nothing to archive.", "Empty", "OK", "Information"); return }; Write-Log "Archiving..." -status "Archiving..."; $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Set-UIEnabledState($false); $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"; $archiveFolder = "Previously Extracted ($ts)"; $archivePath = Join-Path -Path $baseDir -ChildPath $archiveFolder; New-Item -Path $archivePath -ItemType Directory -Force | Out-Null; foreach ($item in $items) { Move-Item -Path $item.FullName -Destination $archivePath -Force }; Write-Log "Archive complete." -status "Ready"; [System.Windows.Forms.MessageBox]::Show("Archive complete.", "Complete", "OK", "Information") } catch { $err = "Archive error: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $err" -status "Job Failed"; [System.Windows.Forms.MessageBox]::Show($err, "Archive Failed", "OK", "Error") } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default; Set-UIEnabledState($true) } })
        $buttonExtract_EXE.Add_Click({
            if ($listBoxFiles_EXE.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please add at least one EXE file.", "No Files", "OK", "Warning"); return }
            $resourceTypes = @{ "Icons" = $checkBoxIcons_EXE.Checked; "BMP" = $checkBoxBitmaps_EXE.Checked; "Cursors" = $checkBoxCursors_EXE.Checked; "PNG" = $checkBoxPngs_EXE.Checked }
            if (-not ($resourceTypes.ContainsValue($true))) { [System.Windows.Forms.MessageBox]::Show("Please select at least one resource type.", "No Types", "OK", "Warning"); return }
            if (-not (Get-Command ResourceHacker.exe -ErrorAction SilentlyContinue)) { Write-Log "ERROR: ResourceHacker.exe not found." -status "Critical Error"; [System.Windows.Forms.MessageBox]::Show("ResourceHacker.exe not found.", "Dependency Missing", "OK", "Error"); return }
            Set-UIEnabledState($false); $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Write-Log "Starting extraction..." -status "Extracting..."
            try {
                $baseOutputDir = $textBoxOutputDir_EXE.Text
                if (-not (Test-Path -Path $baseOutputDir)) { Write-Log "Base directory not found. Creating..."; New-Item -Path $baseOutputDir -ItemType Directory -Force | Out-Null }
                foreach ($filePath in $listBoxFiles_EXE.Items) {
                    $fileName = [System.IO.Path]::GetFileName($filePath); $subfolderName = ([System.IO.Path]::GetFileNameWithoutExtension($fileName)) -replace "[^a-zA-Z0-9_.-]", '_'; $targetDir = Join-Path -Path $baseOutputDir -ChildPath $subfolderName
                    Write-Log "Processing: $fileName"
                    if ($checkBoxClearFolder_EXE.Checked -and (Test-Path -Path $targetDir)) { Write-Log "  -> Clearing existing folder..."; Remove-Item -Path $targetDir -Recurse -Force }
                    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    $masks = @{"Icons" = "ICONGROUP,,"; "BMP" = "BITMAP,,"; "Cursors" = "CURSORGROUP,,"; "PNG" = "PNG,,"}
                    foreach ($type in $resourceTypes.Keys) {
                        if ($resourceTypes[$type]) {
                            $resPath = Join-Path -Path $targetDir -ChildPath $type; New-Item -Path $resPath -ItemType Directory -Force | Out-Null
                            Write-Log "  -> Extracting $type..."
                            $args = "-open `"$filePath`" -save `"$resPath`" -action extract -mask $($masks[$type])"
                            $pinfo = New-Object System.Diagnostics.ProcessStartInfo; $pinfo.FileName = "ResourceHacker.exe"; $pinfo.Arguments = $args; $pinfo.UseShellExecute = $false; $pinfo.CreateNoWindow = $true
                            $process = New-Object System.Diagnostics.Process; $process.StartInfo = $pinfo; $process.Start() | Out-Null; $process.WaitForExit()
                            if ((Get-ChildItem -Path $resPath).Count -eq 0) { Write-Log "     - No '$type' resources found. Removing folder."; Remove-Item -Path $resPath -Recurse -Force } else { Write-Log "     - Success." }
                        }
                    }
                    if ((Get-ChildItem -Path $targetDir).Count -eq 0) { Write-Log "  -> No resources found. Removing main folder."; Remove-Item -Path $targetDir -Recurse -Force }
                }
                Write-Log "All operations completed!"; [System.Windows.Forms.MessageBox]::Show("Extraction complete.", "Complete", "OK", "Information")
            } catch { $err = "Extraction error: $($_.Exception.Message)"; Write-Log "FATAL ERROR: $err" -status "Job Failed"; [System.Windows.Forms.MessageBox]::Show($err, "Extraction Failed", "OK", "Error") }
            finally { Set-UIEnabledState($true); $form.Cursor = [System.Windows.Forms.Cursors]::Default; $statusBar.Text = "Ready" }
        })
        
        # --- Tab 4: Creation Event Handlers ---
        $buttonAddIcons.Add_Click({
            try {
                $ofd = New-Object System.Windows.Forms.OpenFileDialog
                $ofd.Title = "Select Icon Files"
                $ofd.Filter = "Icon Files (*.ico)|*.ico"
                $ofd.MultiSelect = $true 
                if ($ofd.ShowDialog() -eq "OK") {
                    foreach ($file in $ofd.FileNames) {
                        if (-not $listBoxIcons.Items.Contains($file)) {
                            $listBoxIcons.Items.Add($file) | Out-Null
                        }
                    }
                }
            } catch {
                Write-Log "ERROR: $($_.Exception.Message)" -status "Error"
            }
        })
        $buttonRemoveIcons.Add_Click({ try { for ($i = $listBoxIcons.SelectedItems.Count - 1; $i -ge 0; $i--) { $listBoxIcons.Items.Remove($listBoxIcons.SelectedItems[$i]) } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonClearIcons.Add_Click({ try { $listBoxIcons.Items.Clear(); Write-Log "Icon file list cleared." } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonBrowseCreation.Add_Click({ try { $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; $fbd.Description = "Select Output Directory"; $fbd.SelectedPath = $textBoxCreationDir.Text; if ($fbd.ShowDialog() -eq "OK") { $textBoxCreationDir.Text = $fbd.SelectedPath; $config.CreationOutputDirectory = $fbd.SelectedPath; Save-Config } } catch { Write-Log "ERROR: $($_.Exception.Message)" -status "Error" } })
        $buttonCreateDll.Add_Click({
            if ($listBoxIcons.Items.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Add at least one .ico file.", "No Icons", "OK", "Warning"); return }
            $dllName = $textBoxDllName.Text.Trim()
            if ([string]::IsNullOrEmpty($dllName) -or -not ($dllName -like "*.dll")) { [System.Windows.Forms.MessageBox]::Show("Specify a valid DLL file name, ending with .dll", "Invalid Filename", "OK", "Warning"); return }
            
            # --- Initialize Build Environment ---
            if (-not (Import-VisualStudioEnvironment)) {
                 [System.Windows.Forms.MessageBox]::Show("Could not initialize the Visual Studio Build Environment. Please ensure Visual Studio or the Build Tools are installed correctly. See log for details.", "Environment Error", "OK", "Error")
                return
            }

            Set-UIEnabledState($false); $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; Write-Log "Starting DLL creation using Windows SDK..." -status "Creating DLL..."
            $tempBaseName = "temp_icons_$(Get-Random)"
            $rcFilePath = Join-Path ([System.IO.Path]::GetTempPath()) "$($tempBaseName).rc"
            $resFilePath = Join-Path ([System.IO.Path]::GetTempPath()) "$($tempBaseName).res"
            $outputDir = $textBoxCreationDir.Text
            if (-not (Test-Path -Path $outputDir)) { New-Item -Path $outputDir -ItemType Directory -Force | Out-Null }
            $dllOutputPath = Join-Path $outputDir $dllName
            
            try {
                # Step 1: Generate a single .rc file with all icons
                Write-Log "-> Generating resource script..."
                $rcContent = [System.Collections.Generic.List[string]]::new()
                $rcContent.Add("// Generated by EliteSoftware v6.8.4")
                $rcContent.Add("")
                for ($i = 0; $i -lt $listBoxIcons.Items.Count; $i++) {
                    $currentIconPath = $listBoxIcons.Items[$i]
                    $resID = $i 
                    $escapedPath = $currentIconPath.Replace('\', '\\') 
                    $rcContent.Add("$resID ICON `"$escapedPath`"")
                    Write-Log "  -> Adding icon '$((Get-Item $currentIconPath).Name)' with ID $resID"
                }
                [System.IO.File]::WriteAllLines($rcFilePath, $rcContent, [System.Text.Encoding]::ASCII)

                # Step 2: Compile the .rc script to a .res file using rc.exe
                Write-Log "-> Compiling resources with rc.exe..."
                $process = Start-Process -FilePath "rc.exe" -ArgumentList "/nologo", "/fo `"$resFilePath`"", "`"$rcFilePath`"" -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -ne 0 -or -not(Test-Path $resFilePath)) {
                    throw "Resource Compiler (rc.exe) failed. Could not create .res file."
                }
                Write-Log "  -> .res file created successfully."

                # Step 3: Link the .res file into a resource-only DLL using link.exe
                Write-Log "-> Linking resource file with link.exe..."
                $linkArgs = "/DLL", "/NOENTRY", "/MACHINE:X64", "/OUT:`"$dllOutputPath`"", "`"$resFilePath`""
                $process = Start-Process -FilePath "link.exe" -ArgumentList $linkArgs -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -ne 0 -or -not(Test-Path $dllOutputPath)) {
                    throw "Linker (link.exe) failed. Could not create .dll file."
                }

                # Step 4: Success
                Write-Log "DLL created successfully at '$dllOutputPath'"
                [System.Windows.Forms.MessageBox]::Show("Icon DLL creation complete.", "Complete", "OK", "Information")
                if ($checkBoxAutoOpen.Checked) { Invoke-Item -Path $outputDir }

            } catch { 
                $err = "Creation error: $($_.Exception.Message)"
                Write-Log "FATAL ERROR: $err" -status "Job Failed"
                [System.Windows.Forms.MessageBox]::Show($err, "Creation Failed", "OK", "Error")
            }
            finally {
                if (Test-Path $rcFilePath) { Remove-Item $rcFilePath -Force -ErrorAction SilentlyContinue }
                if (Test-Path $resFilePath) { Remove-Item $resFilePath -Force -ErrorAction SilentlyContinue }
                Set-UIEnabledState($true)
                $form.Cursor = [System.Windows.Forms.Cursors]::Default
                $statusBar.Text = "Ready"
            }
        })
        
        $form.Add_Shown({ Write-Log "Application Ready." }); $form.ShowDialog() | Out-Null; $form.Dispose()

# endregion

    } catch { $errorMessage = "A critical, unhandled error occurred.`n`nError: $($_.Exception.Message)`nLine: $($_.InvocationInfo.ScriptLineNumber)"; Write-Error $errorMessage; Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue; [System.Windows.Forms.MessageBox]::Show($errorMessage, "Script Failed Critically", "OK", "Error") }
}

Show-ResourceExtractorGUI