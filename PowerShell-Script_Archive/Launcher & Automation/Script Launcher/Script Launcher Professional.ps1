<#
.SYNOPSIS
    An advanced PowerShell GUI to manage and launch script files (.ps1, .py, .bat, .cmd) from multiple folders, with metadata, custom icons, and multiple view modes.
.DESCRIPTION
    This script provides a professional-grade GUI for managing and executing various script files.
    It's an adaptation of the original HTML Project Launcher.

    New in this version:
    - **Alternate Views:** You can now switch between Details, Tiles, Large Icons, Small Icons, and List views via the "View" menu.
    - **Custom Icons:** Set a custom icon for any script via the "Edit Metadata" dialog. Supports icons from .ico, .exe, and .dll files.
    - **UI Enhancements:** The metadata editor has been redesigned for a better user experience.

    Features:
    - Scans specified folders for .ps1, .py, .bat, and .cmd files.
    - Allows for running or editing scripts directly from the interface.
    - Supports custom metadata (Author, Version, etc.) for each script via .meta.json files.
    - "Ignore File" system to hide specific scripts from the list.
    - "Manage Ignored Files" tool to review and un-ignore scripts.
    - UI state (window size, location, column widths, view mode) is saved between sessions.
.NOTES
    Last Modified: 2025-07-12
    Requires PowerShell with .NET Framework access. Python scripts require 'python.exe' to be in your system's PATH.
.AUTHOR
    Zachary Whiteman
    Written and edited by Gemini
#>

# 1.) Preamble and Configuration
# ---------------------------------
# Enable native Windows UI styling. This MUST be the first UI-related command.
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- C# Code for Console Window Control and ListView Sorter ---
Add-Type -ReferencedAssemblies 'System.Windows.Forms.dll' -TypeDefinition @"
using System;
using System.Collections;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class Win32
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;
    public const int SW_MINIMIZE = 6;
}

public class ListViewItemComparer : IComparer
{
    private int col;
    private SortOrder order;
    public ListViewItemComparer() { col = 0; order = SortOrder.Ascending; }
    public ListViewItemComparer(int column, SortOrder order) { this.col = column; this.order = order; }
    public int Compare(object x, object y)
    {
        int returnVal = -1;
        ListViewItem itemX = (ListViewItem)x;
        ListViewItem itemY = (ListViewItem)y;
        try {
            // Attempt to compare as dates for date columns
            DateTime firstDate = DateTime.Parse(itemX.SubItems[col].Text);
            DateTime secondDate = DateTime.Parse(itemY.SubItems[col].Text);
            returnVal = DateTime.Compare(firstDate, secondDate);
        } catch {
            // Otherwise, compare as strings
            returnVal = String.Compare(itemX.SubItems[col].Text, itemY.SubItems[col].Text);
        }
        if (order == SortOrder.Descending) { returnVal *= -1; }
        return returnVal;
    }
}
"@

# --- Helper Functions (Defined early to be available globally) ---
function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    try { return Split-Path -Parent $MyInvocation.MyCommand.Definition } catch { return $PWD }
}

# --- Global Configuration ---
$ScriptFileTypes = @("*.ps1", "*.py", "*.bat", "*.cmd")
$ScriptDir = Get-ScriptDirectory
$ConfigSourceFile = Join-Path -Path $ScriptDir -ChildPath "config.json"
$global:AppConfig = @{
    SourceFolders = @()
    Settings      = @{
        IsFirstRun        = $true
        AutoCleanOnExit   = $false
        CleanMetadata     = $false
        CleanConfig       = $false
        WindowSize        = New-Object System.Drawing.Size(950, 600)
        WindowLocation    = $null
        ColumnWidths      = @{}
        IgnoredFiles      = @()
        CurrentView       = "Details" # NEW: To store the last used view
        ApplicationPaths  = @{
            ".ps1" = "pwsh.exe"
            ".py"  = "python.exe"
            ".bat" = "cmd.exe"
            ".cmd" = "cmd.exe"
        }
    }
}

# 2.) GUI Element Creation
# ---------------------------------
# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Script Launcher Pro"
$form.MinimumSize = New-Object System.Drawing.Size(700, 400)
$form.StartPosition = "Manual"
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch {}

# --- Image Lists for Icons ---
$largeImageList = New-Object System.Windows.Forms.ImageList; $largeImageList.ImageSize = New-Object System.Drawing.Size(32, 32); $largeImageList.ColorDepth = "Depth32Bit"
$smallImageList = New-Object System.Windows.Forms.ImageList; $smallImageList.ImageSize = New-Object System.Drawing.Size(16, 16); $smallImageList.ColorDepth = "Depth32Bit"
$global:iconCache = @{} # To cache loaded icons and avoid duplicates

# --- Main Layout Panel ---
$mainTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$mainTableLayoutPanel.Dock = "Fill"; $mainTableLayoutPanel.ColumnCount = 1; $mainTableLayoutPanel.RowCount = 4
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null

# --- Menu Strip ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip; $menuStrip.Dock = "Fill"
$fileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&File")
$manageFoldersMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Manage Script Folders...")
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("E&xit")
$viewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&View")
$viewByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Arrange By") # NEW
$groupByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Group By")
$toolsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Tools")
$refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Refresh List")
$manageIgnoredMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Manage &Ignored Files...")
$cleanFilesMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Clean Temporary Files...")
$optionsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Options")
$appPathMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Configure &Application Paths...")
$cleanupSettingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Auto-Cleanup Settings...")

$fileMenuItem.DropDownItems.AddRange(@($manageFoldersMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $exitMenuItem))
$viewMenuItem.DropDownItems.AddRange(@($viewByMenuItem, $groupByMenuItem))
$toolsMenuItem.DropDownItems.AddRange(@($refreshMenuItem, $manageIgnoredMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $cleanFilesMenuItem))
$optionsMenuItem.DropDownItems.AddRange(@($appPathMenuItem, $cleanupSettingsMenuItem))
$menuStrip.Items.AddRange(@($fileMenuItem, $viewMenuItem, $toolsMenuItem, $optionsMenuItem))

# --- Status Strip ---
$statusStrip = New-Object System.Windows.Forms.StatusStrip; $statusStrip.Dock = "Fill"
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $statusStrip.Items.Add($statusLabel)

# --- Bottom Button Panel ---
$bottomTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$bottomTableLayoutPanel.Dock = "Fill"; $bottomTableLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 10)
$bottomTableLayoutPanel.ColumnCount = 3
$bottomTableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null
$bottomTableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$bottomTableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null
$buttonStackPanel = New-Object System.Windows.Forms.TableLayoutPanel
$buttonStackPanel.AutoSize = $true; $buttonStackPanel.Anchor = "None"; $buttonStackPanel.ColumnCount = 1; $buttonStackPanel.RowCount = 2
$buttonStackPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$buttonStackPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$refreshButton = New-Object System.Windows.Forms.Button; $refreshButton.Text = "Refresh"; $refreshButton.Size = New-Object System.Drawing.Size(220, 30)
$closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Size = New-Object System.Drawing.Size(220, 30)
$buttonStackPanel.Controls.Add($refreshButton, 0, 0); $buttonStackPanel.Controls.Add($closeButton, 0, 1);
$bottomTableLayoutPanel.Controls.Add($buttonStackPanel, 1, 0)

# --- ListView ---
$listView = New-Object System.Windows.Forms.ListView
$listView.View = "Details"; $listView.Dock = "Fill"; $listView.FullRowSelect = $true; $listView.GridLines = $true; $listView.MultiSelect = $false
$listView.LargeImageList = $largeImageList; $listView.SmallImageList = $smallImageList # Assign image lists
$listView.Columns.Add("File Name", 250) | Out-Null
$listView.Columns.Add("File Type", 80) | Out-Null
$listView.Columns.Add("Date Modified", 150) | Out-Null
$listView.Columns.Add("Date Created", 150) | Out-Null
$listView.Columns.Add("Author", 120) | Out-Null
$listView.Columns.Add("Version", 80) | Out-Null
$listView.Columns.Add("Source Folder", 200) | Out-Null
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$runScriptMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Run Script"); $editScriptMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Script"); $editMetaMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Metadata..."); $ignoreFileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Ignore File"); $openFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Containing Folder")
$contextMenu.Items.AddRange(@($runScriptMenuItem, $editScriptMenuItem, $editMetaMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $ignoreFileMenuItem, $openFolderMenuItem)); $listView.ContextMenuStrip = $contextMenu

# --- Final Assembly ---
$mainTableLayoutPanel.Controls.Add($menuStrip, 0, 0); $mainTableLayoutPanel.Controls.Add($listView, 0, 1); $mainTableLayoutPanel.Controls.Add($bottomTableLayoutPanel, 0, 2); $mainTableLayoutPanel.Controls.Add($statusStrip, 0, 3)
$form.Controls.Add($mainTableLayoutPanel)

# 3.) Core Functions
# ------------------
function Initialize-Application {
    $statusLabel.Text = "Loading configuration..."
    $form.Refresh()
    Load-Configuration
    $statusLabel.Text = "Ready."
    $form.Refresh()
}

function Handle-FirstRunAndLoadData {
    if ($global:AppConfig.Settings.IsFirstRun) {
        $newSettings = Show-CleanupOptionsDialog -Title "First Time Setup" -ButtonText "Save & Continue"
        if ($newSettings) {
            $global:AppConfig.Settings.IsFirstRun = $false
            $global:AppConfig.Settings.AutoCleanOnExit = $newSettings.AutoCleanOnExit
            $global:AppConfig.Settings.CleanMetadata = $newSettings.CleanMetadata
            $global:AppConfig.Settings.CleanConfig = $newSettings.CleanConfig
            Save-Configuration
        }
    }
    Refresh-FileList
}

function Set-ListView-View {
    param([System.Windows.Forms.View]$view)
    $listView.View = $view
    $global:AppConfig.Settings.CurrentView = $view.ToString()
    # Enable/disable grid lines based on view
    $listView.GridLines = ($view -eq [System.Windows.Forms.View]::Details)
}

function Update-Grouping {
    param([int]$ColumnIndex)
    $listView.BeginUpdate()
    if ($ColumnIndex -lt 0) {
        $listView.ShowGroups = $false
    } else {
        $listView.ShowGroups = $true
        $listView.Groups.Clear()
        $groups = @{}
        foreach ($item in $listView.Items) {
            $groupName = $item.SubItems[$ColumnIndex].Text
            if ($ColumnIndex -eq 2 -or $ColumnIndex -eq 3) { # Date Modified or Date Created
                try { $date = [datetime]::Parse($groupName); $groupName = $date.ToString("yyyy-MM-dd HH:00") } catch { $groupName = "(Invalid Date)" }
            }
            if (-not $groupName) { $groupName = "(None)" }
            if (-not $groups.ContainsKey($groupName)) {
                $groups[$groupName] = New-Object System.Windows.Forms.ListViewGroup($groupName, $groupName)
                $listView.Groups.Add($groups[$groupName]) | Out-Null
            }
            $item.Group = $groups[$groupName]
        }
    }
    $listView.EndUpdate()
}

function Clean-TemporaryFiles {
    param([bool]$CleanMetadata, [bool]$CleanConfig)
    $statusLabel.Text = "Cleaning temporary files..."
    if ($CleanMetadata) { 
        $metaFilter = $ScriptFileTypes | ForEach-Object { "$_.meta.json" }
        $global:AppConfig.SourceFolders | ForEach-Object { 
            Get-ChildItem -Path $_ -Include $metaFilter -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue 
        } 
    }
    if ($CleanConfig) { Remove-Item -Path $ConfigSourceFile -Force -ErrorAction SilentlyContinue }
    $statusLabel.Text = "Cleanup complete."; Refresh-FileList
}

function Show-CleanupOptionsDialog {
    param([string]$Title, [string]$ButtonText)
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = $Title; $dialog.Size = New-Object System.Drawing.Size(450, 230); $dialog.FormBorderStyle = "FixedDialog"; $dialog.StartPosition = "CenterParent"
    $masterCheckbox = New-Object System.Windows.Forms.CheckBox; $masterCheckbox.Text = "Automatically clean selected files on exit"; $masterCheckbox.Location = New-Object System.Drawing.Point(20, 20); $masterCheckbox.AutoSize = $true; $masterCheckbox.Checked = $global:AppConfig.Settings.AutoCleanOnExit
    $groupbox = New-Object System.Windows.Forms.GroupBox; $groupbox.Text = "Files to Clean"; $groupbox.Location = New-Object System.Drawing.Point(20, 50); $groupbox.Size = New-Object System.Drawing.Size(400, 80)
    $metadataCheckbox = New-Object System.Windows.Forms.CheckBox; $metadataCheckbox.Text = "Script Metadata (*.meta.json)"; $metadataCheckbox.Location = New-Object System.Drawing.Point(15, 25); $metadataCheckbox.AutoSize = $true; $metadataCheckbox.Checked = $global:AppConfig.Settings.CleanMetadata
    $configCheckbox = New-Object System.Windows.Forms.CheckBox; $configCheckbox.Text = "App Configuration (config.json)"; $configCheckbox.Location = New-Object System.Drawing.Point(15, 50); $configCheckbox.AutoSize = $true; $configCheckbox.Checked = $global:AppConfig.Settings.CleanConfig
    $okButton = New-Object System.Windows.Forms.Button; $okButton.Text = $ButtonText; $okButton.DialogResult = "OK"; $okButton.Location = New-Object System.Drawing.Point(230, 150)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(320, 150)
    $groupbox.Controls.AddRange(@($metadataCheckbox, $configCheckbox)); $dialog.Controls.AddRange(@($masterCheckbox, $groupbox, $okButton, $cancelButton))
    if ($dialog.ShowDialog($form) -eq "OK") { return @{ AutoCleanOnExit = $masterCheckbox.Checked; CleanMetadata = $metadataCheckbox.Checked; CleanConfig = $configCheckbox.Checked } }
    return $null
}

function Show-IgnoredFilesManager {
    $managerForm = New-Object System.Windows.Forms.Form
    $managerForm.Text = "Manage Ignored Files"; $managerForm.Size = New-Object System.Drawing.Size(600, 400); $managerForm.FormBorderStyle = "Sizable"; $managerForm.StartPosition = "CenterParent"
    $listBox = New-Object System.Windows.Forms.ListBox; $listBox.Dock = "Fill"; $listBox.Items.AddRange($global:AppConfig.Settings.IgnoredFiles)
    $buttonPanel = New-Object System.Windows.Forms.Panel; $buttonPanel.Dock = "Bottom"; $buttonPanel.Height = 40
    $unignoreButton = New-Object System.Windows.Forms.Button; $unignoreButton.Text = "Unignore Selected"; $unignoreButton.Location = New-Object System.Drawing.Point(10, 5); $unignoreButton.AutoSize = $true
    $closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Location = New-Object System.Drawing.Point(500, 5); $closeButton.Anchor = "Right"
    $unignoreButton.Add_Click({
        if ($listBox.SelectedItem) {
            $global:AppConfig.Settings.IgnoredFiles = $global:AppConfig.Settings.IgnoredFiles | Where-Object { $_ -ne $listBox.SelectedItem }
            $listBox.Items.Remove($listBox.SelectedItem)
        }
    })
    $closeButton.Add_Click({ $managerForm.Close() })
    $buttonPanel.Controls.AddRange(@($unignoreButton, $closeButton)); $managerForm.Controls.AddRange(@($listBox, $buttonPanel))
    $managerForm.ShowDialog($form)
    Save-Configuration; Refresh-FileList; $managerForm.Dispose()
}

function Load-Configuration {
    if (Test-Path $ConfigSourceFile) {
        try {
            $configOnDisk = Get-Content -Path $ConfigSourceFile | ConvertFrom-Json
            if ($configOnDisk.SourceFolders) { $global:AppConfig.SourceFolders = $configOnDisk.SourceFolders }
            if ($configOnDisk.Settings) { 
                foreach ($key in $configOnDisk.Settings.Keys) { 
                    if($global:AppConfig.Settings.ContainsKey($key) -and $key -ne 'ApplicationPaths') { 
                        $global:AppConfig.Settings[$key] = $configOnDisk.Settings[$key] 
                    } 
                }
                if ($configOnDisk.Settings.ApplicationPaths) {
                    foreach ($ext in $configOnDisk.Settings.ApplicationPaths.Keys) {
                        $global:AppConfig.Settings.ApplicationPaths[$ext] = $configOnDisk.Settings.ApplicationPaths[$ext]
                    }
                }
            }
        } catch { $statusLabel.Text = "Warning: Could not read config.json." }
    }
    if ($global:AppConfig.SourceFolders.Count -eq 0) { $global:AppConfig.SourceFolders = @($ScriptDir) }
    
    $form.Size = $global:AppConfig.Settings.WindowSize
    if ($global:AppConfig.Settings.WindowLocation) { $form.Location = $global:AppConfig.Settings.WindowLocation } else { $form.StartPosition = "CenterScreen" }
    foreach ($key in $global:AppConfig.Settings.ColumnWidths.Keys) { if ($key -lt $listView.Columns.Count) { $listView.Columns[$key].Width = $global:AppConfig.Settings.ColumnWidths[$key] } }
    
    # Set the view from config
    try {
        $viewEnum = [System.Windows.Forms.View]($global:AppConfig.Settings.CurrentView)
        Set-ListView-View -view $viewEnum
    } catch {
        Set-ListView-View -view "Details"
    }
}

function Save-Configuration {
    $global:AppConfig.Settings.WindowSize = $form.Size
    $global:AppConfig.Settings.WindowLocation = $form.Location
    $global:AppConfig.Settings.ColumnWidths = @{}
    for ($i = 0; $i -lt $listView.Columns.Count; $i++) { $global:AppConfig.Settings.ColumnWidths[$i] = $listView.Columns[$i].Width }

    try {
        $global:AppConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigSourceFile -Encoding UTF8
    } catch { $statusLabel.Text = "Error: Could not save configuration to config.json." }
}

function Refresh-FileList {
    $listView.BeginUpdate(); $listView.Items.Clear(); $statusLabel.Text = "Searching for scripts..."; $form.Cursor = "WaitCursor"; $form.Refresh()
    
    # Clear image lists and cache for a full refresh
    $largeImageList.Images.Clear(); $smallImageList.Images.Clear(); $global:iconCache.Clear()

    foreach ($folder in $global:AppConfig.SourceFolders) {
        if (-not (Test-Path $folder)) { Write-Warning "Source folder not found: $folder"; continue }
        Get-ChildItem -Path $folder -Include $ScriptFileTypes -File -Recurse | Where-Object { $_.FullName -notin $global:AppConfig.Settings.IgnoredFiles } | ForEach-Object {
            $file = $_
            $metaFilePath = "$($file.FullName).meta.json"
            $author = ""; $version = ""; $customIconPath = $null
            if (Test-Path $metaFilePath) { 
                try { 
                    $meta = Get-Content -Path $metaFilePath | ConvertFrom-Json
                    $author = $meta.Author
                    $version = $meta.Version
                    $customIconPath = $meta.CustomIconPath
                } catch {} 
            }

            # --- Icon Loading Logic ---
            $iconKey = $customIconPath
            if (-not $iconKey) { $iconKey = $file.Extension } # Use extension as key for default icons
            
            if (-not $global:iconCache.ContainsKey($iconKey)) {
                $icon = $null
                try {
                    if ($customIconPath -and (Test-Path $customIconPath)) {
                        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($customIconPath)
                    } else {
                        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($file.FullName)
                    }
                } catch {
                    # Fallback to a generic system icon if extraction fails
                    $icon = [System.Drawing.SystemIcons]::Application
                }
                
                if ($icon) {
                    $largeImageList.Images.Add($icon)
                    $smallImageList.Images.Add($icon)
                    $global:iconCache[$iconKey] = $largeImageList.Images.Count - 1
                    $icon.Dispose()
                }
            }
            
            $imageIndex = $global:iconCache.Get_Item($iconKey)
            
            # --- Create ListView Item ---
            $item = New-Object System.Windows.Forms.ListViewItem($file.Name, $imageIndex)
            $item.SubItems.Add($file.Extension) | Out-Null
            $item.SubItems.Add($file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
            $item.SubItems.Add($file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
            $item.SubItems.Add($author) | Out-Null; $item.SubItems.Add($version) | Out-Null; $item.SubItems.Add($file.DirectoryName) | Out-Null
            $item.Tag = $file.FullName; $listView.Items.Add($item) | Out-Null
        }
    }
    $statusLabel.Text = "Found $($listView.Items.Count) scripts. Ready."; $form.Cursor = "Default"; $listView.EndUpdate()
}

function Run-SelectedScript {
    if ($listView.SelectedItems.Count -eq 0) { return }
    $fullPath = $listView.SelectedItems[0].Tag
    $extension = [System.IO.Path]::GetExtension($fullPath).ToLower()
    $statusLabel.Text = "Executing $($listView.SelectedItems[0].Text)..."
    
    $appPath = $global:AppConfig.Settings.ApplicationPaths[$extension]
    if (-not $appPath) {
        [System.Windows.Forms.MessageBox]::Show("No application path configured for '$extension' files. Please configure it under Options.", "Error", "OK", "Error")
        $statusLabel.Text = "Execution failed: No application configured."
        return
    }

    try {
        $argumentList = ""
        switch ($extension) {
            ".ps1" { $argumentList = "-NoProfile -File `"$fullPath`"" }
            ".py"  { $argumentList = "`"$fullPath`"" }
            ".bat" { $argumentList = "/c `"$fullPath`"" }
            ".cmd" { $argumentList = "/c `"$fullPath`"" }
        }
        
        Start-Process -FilePath $appPath -ArgumentList $argumentList -ErrorAction Stop
        $statusLabel.Text = "Execution started for $($listView.SelectedItems[0].Text)."
    }
    catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Failed to run script with '$appPath':`n$errorMessage`n`nEnsure the application path is correct and it's in your system's PATH if not fully qualified.", "Execution Error", "OK", "Error")
        $statusLabel.Text = "Execution failed."
    }
}

function Edit-SelectedScript {
    if ($listView.SelectedItems.Count -eq 0) { return }
    $fullPath = $listView.SelectedItems[0].Tag
    try {
        Invoke-Item -Path $fullPath
    }
    catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Failed to open script for editing:`n$errorMessage", "Error", "OK", "Error")
    }
}

function Show-MetadataEditor {
    if ($listView.SelectedItems.Count -eq 0) { return }
    $item = $listView.SelectedItems[0]; $fullPath = $item.Tag; $metaFilePath = "$fullPath.meta.json"
    $metadata = [ordered]@{}
    if (Test-Path $metaFilePath) { try { $metadata = Get-Content -Path $metaFilePath | ConvertFrom-Json -AsHashtable } catch { $metadata = [ordered]@{} } }
    
    $editorForm = New-Object System.Windows.Forms.Form
    $editorForm.Text = "Edit Metadata for $($item.Text)"; $editorForm.Size = New-Object System.Drawing.Size(550, 250); $editorForm.FormBorderStyle = "FixedDialog"; $editorForm.StartPosition = "CenterParent"

    $authorLabel = New-Object System.Windows.Forms.Label; $authorLabel.Text = "Author:"; $authorLabel.Location = New-Object System.Drawing.Point(20, 23); $authorLabel.AutoSize = $true
    $authorTextBox = New-Object System.Windows.Forms.TextBox; $authorTextBox.Text = $metadata['Author']; $authorTextBox.Location = New-Object System.Drawing.Point(120, 20); $authorTextBox.Size = New-Object System.Drawing.Size(400, 20)

    $versionLabel = New-Object System.Windows.Forms.Label; $versionLabel.Text = "Version:"; $versionLabel.Location = New-Object System.Drawing.Point(20, 53); $versionLabel.AutoSize = $true
    $versionTextBox = New-Object System.Windows.Forms.TextBox; $versionTextBox.Text = $metadata['Version']; $versionTextBox.Location = New-Object System.Drawing.Point(120, 50); $versionTextBox.Size = New-Object System.Drawing.Size(400, 20)

    $iconLabel = New-Object System.Windows.Forms.Label; $iconLabel.Text = "Custom Icon:"; $iconLabel.Location = New-Object System.Drawing.Point(20, 83); $iconLabel.AutoSize = $true
    $iconTextBox = New-Object System.Windows.Forms.TextBox; $iconTextBox.Text = $metadata['CustomIconPath']; $iconTextBox.Location = New-Object System.Drawing.Point(120, 80); $iconTextBox.Size = New-Object System.Drawing.Size(315, 20)
    $iconBrowseButton = New-Object System.Windows.Forms.Button; $iconBrowseButton.Text = "..."; $iconBrowseButton.Location = New-Object System.Drawing.Point(440, 79); $iconBrowseButton.Size = New-Object System.Drawing.Size(80, 23)
    $iconBrowseButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "Icon Files (*.ico, *.exe, *.dll)|*.ico;*.exe;*.dll|All files (*.*)|*.*"
        $openFileDialog.Title = "Select Custom Icon"
        if ($openFileDialog.ShowDialog($editorForm) -eq "OK") {
            $iconTextBox.Text = $openFileDialog.FileName
        }
        $openFileDialog.Dispose()
    })

    $saveButton = New-Object System.Windows.Forms.Button; $saveButton.Text = "Save"; $saveButton.DialogResult = "OK"; $saveButton.Location = New-Object System.Drawing.Point(350, 150)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(435, 150)
    
    $editorForm.Controls.AddRange(@($authorLabel, $authorTextBox, $versionLabel, $versionTextBox, $iconLabel, $iconTextBox, $iconBrowseButton, $saveButton, $cancelButton))
    
    if ($editorForm.ShowDialog($form) -eq "OK") {
        $newMeta = [ordered]@{};
        $newMeta['Author'] = $authorTextBox.Text
        $newMeta['Version'] = $versionTextBox.Text
        $newMeta['CustomIconPath'] = $iconTextBox.Text
        # Add any other existing metadata back in
        foreach($key in $metadata.Keys) {
            if (-not $newMeta.ContainsKey($key)) {
                $newMeta[$key] = $metadata[$key]
            }
        }

        $newMeta | ConvertTo-Json | Set-Content -Path $metaFilePath -Encoding UTF8
        Refresh-FileList; $statusLabel.Text = "Metadata saved for $($item.Text)."
    }
    $editorForm.Dispose()
}

function Show-SourceManager {
    $managerForm = New-Object System.Windows.Forms.Form
    $managerForm.Text = "Manage Script Folders"; $managerForm.Size = New-Object System.Drawing.Size(500, 300); $managerForm.FormBorderStyle = "FixedDialog"; $managerForm.StartPosition = "CenterParent"
    $listBox = New-Object System.Windows.Forms.ListBox; $listBox.Dock = "Fill"; $listBox.Items.AddRange($global:AppConfig.SourceFolders)
    $buttonPanel = New-Object System.Windows.Forms.Panel; $buttonPanel.Dock = "Bottom"; $buttonPanel.Height = 40
    $addButton = New-Object System.Windows.Forms.Button; $addButton.Text = "Add..."; $addButton.Location = New-Object System.Drawing.Point(10, 5)
    $removeButton = New-Object System.Windows.Forms.Button; $removeButton.Text = "Remove"; $removeButton.Location = New-Object System.Drawing.Point(95, 5)
    $closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Location = New-Object System.Drawing.Point(400, 5); $closeButton.Anchor = "Right"
    $addButton.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog($managerForm) -eq "OK") { if (-not ($listBox.Items -contains $folderBrowser.SelectedPath)) { $listBox.Items.Add($folderBrowser.SelectedPath) } }; $folderBrowser.Dispose() })
    $removeButton.Add_Click({ if ($listBox.SelectedItem) { $listBox.Items.Remove($listBox.SelectedItem) } }); $closeButton.Add_Click({ $managerForm.Close() })
    $buttonPanel.Controls.AddRange(@($addButton, $removeButton, $closeButton)); $managerForm.Controls.AddRange(@($listBox, $buttonPanel))
    $managerForm.ShowDialog($form)
    $global:AppConfig.SourceFolders = $listBox.Items; Save-Configuration; Refresh-FileList; $managerForm.Dispose()
}

function Show-ApplicationPathEditor {
    $editorForm = New-Object System.Windows.Forms.Form
    $editorForm.Text = "Configure Application Paths"; $editorForm.Size = New-Object System.Drawing.Size(600, 350); $editorForm.FormBorderStyle = "Sizable"; $editorForm.StartPosition = "CenterParent"
    
    $dataGridView = New-Object System.Windows.Forms.DataGridView; $dataGridView.Dock = "Fill"
    $dataGridView.Columns.Add("Extension", "File Type"); $dataGridView.Columns.Add("Path", "Executable Path")
    $dataGridView.Columns["Extension"].ReadOnly = $true; $dataGridView.Columns["Extension"].Width = 100
    $dataGridView.Columns["Path"].AutoSizeMode = "Fill"
    
    $browseColumn = New-Object System.Windows.Forms.DataGridViewButtonColumn
    $browseColumn.Name = "Browse"; $browseColumn.Text = "..."; $browseColumn.UseColumnTextForButtonValue = $true
    $browseColumn.Width = 40; $dataGridView.Columns.Add($browseColumn) | Out-Null
    
    foreach ($ext in $global:AppConfig.Settings.ApplicationPaths.Keys) {
        $dataGridView.Rows.Add($ext, $global:AppConfig.Settings.ApplicationPaths[$ext]) | Out-Null
    }
    
    $dataGridView.Add_CellContentClick({
        param($sender, $e)
        if ($e.ColumnIndex -eq $dataGridView.Columns["Browse"].Index -and $e.RowIndex -ge 0) {
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Filter = "Executables (*.exe)|*.exe|All files (*.*)|*.*"
            if ($openFileDialog.ShowDialog($editorForm) -eq "OK") {
                $dataGridView.Rows[$e.RowIndex].Cells["Path"].Value = $openFileDialog.FileName
            }
            $openFileDialog.Dispose()
        }
    })

    $buttonPanel = New-Object System.Windows.Forms.Panel; $buttonPanel.Dock = "Bottom"; $buttonPanel.Height = 40
    $saveButton = New-Object System.Windows.Forms.Button; $saveButton.Text = "Save"; $saveButton.DialogResult = "OK"; $saveButton.Location = New-Object System.Drawing.Point(410, 5)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(495, 5)
    $buttonPanel.Controls.AddRange(@($saveButton, $cancelButton)); $editorForm.Controls.AddRange(@($dataGridView, $buttonPanel))
    
    if ($editorForm.ShowDialog($form) -eq "OK") {
        foreach ($row in $dataGridView.Rows) {
            if ($row.IsNewRow) { continue }
            $ext = $row.Cells["Extension"].Value
            $path = $row.Cells["Path"].Value
            if ($ext -and $path) {
                $global:AppConfig.Settings.ApplicationPaths[$ext] = $path
            }
        }
        Save-Configuration
        $statusLabel.Text = "Application paths saved."
    }
    $editorForm.Dispose()
}


# 4.) Event Handlers
# ------------------
$manageFoldersMenuItem.Add_Click({ Show-SourceManager })
$refreshMenuItem.Add_Click({ Refresh-FileList }); $refreshButton.Add_Click({ Refresh-FileList })
$exitMenuItem.Add_Click({ $form.Close() }); $closeButton.Add_Click({ $form.Close() })
$appPathMenuItem.Add_Click({ Show-ApplicationPathEditor })
$cleanFilesMenuItem.Add_Click({
    $cleanupOptions = Show-CleanupOptionsDialog -Title "Manual File Cleanup" -ButtonText "Clean Selected Files"
    if ($cleanupOptions) { $confirmResult = [System.Windows.Forms.MessageBox]::Show("This action cannot be undone. Are you sure you want to clean the selected files?", "Confirm Cleanup", "YesNo", "Warning"); if ($confirmResult -eq "Yes") { Clean-TemporaryFiles -CleanMetadata $cleanupOptions.CleanMetadata -CleanConfig $cleanupOptions.CleanConfig } }
})
$cleanupSettingsMenuItem.Add_Click({
    $newSettings = Show-CleanupOptionsDialog -Title "Auto-Cleanup Settings" -ButtonText "Save Settings"
    if ($newSettings) { $global:AppConfig.Settings.AutoCleanOnExit = $newSettings.AutoCleanOnExit; $global:AppConfig.Settings.CleanMetadata = $newSettings.CleanMetadata; $global:AppConfig.Settings.CleanConfig = $newSettings.CleanConfig; Save-Configuration; $statusLabel.Text = "Auto-cleanup settings saved." }
})
$ignoreFileMenuItem.Add_Click({
    if ($listView.SelectedItems.Count -eq 0) { return }
    $fullPath = $listView.SelectedItems[0].Tag
    if (-not ($global:AppConfig.Settings.IgnoredFiles -contains $fullPath)) {
        $global:AppConfig.Settings.IgnoredFiles += $fullPath
        Save-Configuration
        Refresh-FileList
    }
})
$manageIgnoredMenuItem.Add_Click({ Show-IgnoredFilesManager })
$listView.Add_DoubleClick({ Run-SelectedScript })
$listView.Add_ColumnClick({ param($s, $e); if ($listView.Sorting -eq "Ascending") { $listView.Sorting = "Descending" } else { $listView.Sorting = "Ascending" }; $listView.ListViewItemSorter = New-Object ListViewItemComparer($e.Column, $listView.Sorting) })
$runScriptMenuItem.Add_Click({ Run-SelectedScript })
$editScriptMenuItem.Add_Click({ Edit-SelectedScript })
$editMetaMenuItem.Add_Click({ Show-MetadataEditor })
$openFolderMenuItem.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Invoke-Item -Path (Split-Path -Path $listView.SelectedItems[0].Tag -Parent) } })
$form.Add_FormClosing({ Save-Configuration; if ($global:AppConfig.Settings.AutoCleanOnExit) { Clean-TemporaryFiles -CleanMetadata $global:AppConfig.Settings.CleanMetadata -CleanConfig $global:AppConfig.Settings.CleanConfig } })
$form.Add_Load({ Initialize-Application })
$form.Add_Shown({ Handle-FirstRunAndLoadData; [void][Win32]::ShowWindow([Win32]::GetConsoleWindow(), [Win32]::SW_MINIMIZE) })

# 5.) Final Assembly and Display
# ------------------------------
# Add "Arrange By" menu items dynamically
$viewByMenuItem.DropDownItems.Add("Details", $null, { Set-ListView-View -view "Details" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("Tiles", $null, { Set-ListView-View -view "Tile" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("Large Icons", $null, { Set-ListView-View -view "LargeIcon" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("Small Icons", $null, { Set-ListView-View -view "SmallIcon" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("List", $null, { Set-ListView-View -view "List" }) | Out-Null

# Add "Group By" menu items dynamically
$groupByMenuItem.DropDownItems.Add("None", $null, { Update-Grouping -ColumnIndex -1 }) | Out-Null
for ($i = 0; $i -lt $listView.Columns.Count; $i++) {
    $columnName = $listView.Columns[$i].Text
    $columnIndex = $i
    $groupByMenuItem.DropDownItems.Add($columnName, $null, { Update-Grouping -ColumnIndex $columnIndex }) | Out-Null
}

[void]$form.ShowDialog()

# 6.) Cleanup
# -----------
$form.Dispose()
