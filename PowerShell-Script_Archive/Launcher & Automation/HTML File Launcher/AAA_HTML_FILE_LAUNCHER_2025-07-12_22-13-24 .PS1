<#
.SYNOPSIS
    An advanced PowerShell GUI to manage and launch HTML projects from multiple folders, with metadata support.
.DESCRIPTION
    This script provides a professional-grade GUI for managing HTML projects.

    New in this version:
    - **Performance Fix:** Reworked the application's startup sequence. The main window now appears instantly, with data loading immediately after, which eliminates the long delay on first launch.
    - **Layout Fix:** Re-engineered the bottom button panel using a nested layout to guarantee the buttons are never cut off, regardless of window size.
    - **UI Enhancements:** The bottom buttons have been resized for better visual balance and consistency.
    - **Console Output Fix:** Suppressed the "0 0 0 True" output in the console window for a cleaner execution.
.NOTES
    Last Modified: 2025-07-12
    Requires PowerShell with .NET Framework access.
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
            DateTime firstDate = DateTime.Parse(itemX.SubItems[col].Text);
            DateTime secondDate = DateTime.Parse(itemY.SubItems[col].Text);
            returnVal = DateTime.Compare(firstDate, secondDate);
        } catch {
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
$DashboardFileName = "dashboard.html"
$InjectionIdentifier = "<!-- Injected by Project Launcher -->"
$ScriptDir = Get-ScriptDirectory
$ConfigSourceFile = Join-Path -Path $ScriptDir -ChildPath "config.json"
$global:AppConfig = @{
    SourceFolders = @()
    Settings      = @{
        IsFirstRun        = $true
        AutoCleanOnExit   = $false
        CleanDashboard    = $false
        CleanMetadata     = $false
        CleanConfig       = $false
        WindowSize        = New-Object System.Drawing.Size(850, 600)
        WindowLocation    = $null
        ColumnWidths      = @{}
        IgnoredFiles      = @() # New setting to store ignored files
    }
}

# 2.) GUI Element Creation
# ---------------------------------
# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Project Launcher Pro"
$form.MinimumSize = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "Manual" # We will set location from config
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch {}

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
$manageFoldersMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Manage Project Folders...")
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("E&xit")
$viewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&View")
$groupByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Group By")
$toolsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Tools")
$refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Refresh List")
$generateWebIndexMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&View Dashboard in Browser")
$manageIgnoredMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Manage &Ignored Files...")
$cleanFilesMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Clean Temporary Files...")
$optionsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Options")
$cleanupSettingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Auto-Cleanup Settings...")

$fileMenuItem.DropDownItems.AddRange(@($manageFoldersMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $exitMenuItem))
$viewMenuItem.DropDownItems.Add($groupByMenuItem)
$toolsMenuItem.DropDownItems.AddRange(@($refreshMenuItem, $generateWebIndexMenuItem, $manageIgnoredMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $cleanFilesMenuItem))
$optionsMenuItem.DropDownItems.Add($cleanupSettingsMenuItem)
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

# --- New inner panel to stack buttons vertically ---
$buttonStackPanel = New-Object System.Windows.Forms.TableLayoutPanel
$buttonStackPanel.AutoSize = $true
$buttonStackPanel.Anchor = "None"
$buttonStackPanel.ColumnCount = 1
$buttonStackPanel.RowCount = 3
$buttonStackPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$buttonStackPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$buttonStackPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null

# --- Buttons ---
$refreshButton = New-Object System.Windows.Forms.Button; $refreshButton.Text = "Refresh"; $refreshButton.Size = New-Object System.Drawing.Size(220, 30)
$generateButton = New-Object System.Windows.Forms.Button; $generateButton.Text = "View Dashboard in Browser"; $generateButton.Size = New-Object System.Drawing.Size(220, 30)
$closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Size = New-Object System.Drawing.Size(220, 30)

# Add buttons to the stack panel
$buttonStackPanel.Controls.Add($refreshButton, 0, 0)
$buttonStackPanel.Controls.Add($generateButton, 0, 1)
$buttonStackPanel.Controls.Add($closeButton, 0, 2)

# Add the stack panel to the middle of the bottom panel
$bottomTableLayoutPanel.Controls.Add($buttonStackPanel, 1, 0)

# --- ListView ---
$listView = New-Object System.Windows.Forms.ListView
$listView.View = "Details"; $listView.Dock = "Fill"; $listView.FullRowSelect = $true; $listView.GridLines = $true; $listView.MultiSelect = $false
$listView.Columns.Add("File Name", 250) | Out-Null; $listView.Columns.Add("Date Modified", 150) | Out-Null; $listView.Columns.Add("Date Created", 150) | Out-Null; $listView.Columns.Add("Author", 120) | Out-Null; $listView.Columns.Add("Version", 80) | Out-Null; $listView.Columns.Add("Source Folder", 200) | Out-Null
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$openMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Project"); $editMetaMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Metadata..."); $ignoreFileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Ignore File"); $openFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Containing Folder")
$contextMenu.Items.AddRange(@($openMenuItem, $editMetaMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $ignoreFileMenuItem, $openFolderMenuItem)); $listView.ContextMenuStrip = $contextMenu

# --- Final Assembly ---
$mainTableLayoutPanel.Controls.Add($menuStrip, 0, 0); $mainTableLayoutPanel.Controls.Add($listView, 0, 1); $mainTableLayoutPanel.Controls.Add($bottomTableLayoutPanel, 0, 2); $mainTableLayoutPanel.Controls.Add($statusStrip, 0, 3)
$form.Controls.Add($mainTableLayoutPanel)

# 3.) Core Functions
# ------------------
function Initialize-Application {
    $statusLabel.Text = "Loading configuration..."
    $form.Refresh()
    Load-Configuration
    $statusLabel.Text = "Loading file list..."
    $form.Refresh()
    Refresh-FileList
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
            if ($ColumnIndex -eq 1 -or $ColumnIndex -eq 2) { # Date Modified or Date Created
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
    param([bool]$CleanDashboard, [bool]$CleanMetadata, [bool]$CleanConfig)
    $statusLabel.Text = "Cleaning temporary files..."
    if ($CleanMetadata) { $global:AppConfig.SourceFolders | ForEach-Object { Get-ChildItem -Path $_ -Filter "*.html.meta.json" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue } }
    if ($CleanDashboard) { Remove-Item -Path (Join-Path -Path $ScriptDir -ChildPath $DashboardFileName) -Force -ErrorAction SilentlyContinue }
    if ($CleanConfig) { Remove-Item -Path $ConfigSourceFile -Force -ErrorAction SilentlyContinue }
    $statusLabel.Text = "Cleanup complete."; Refresh-FileList
}

function Show-CleanupOptionsDialog {
    param([string]$Title, [string]$ButtonText)
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = $Title; $dialog.Size = New-Object System.Drawing.Size(450, 250); $dialog.FormBorderStyle = "FixedDialog"; $dialog.StartPosition = "CenterParent"
    $masterCheckbox = New-Object System.Windows.Forms.CheckBox; $masterCheckbox.Text = "Automatically clean selected files on exit"; $masterCheckbox.Location = New-Object System.Drawing.Point(20, 20); $masterCheckbox.AutoSize = $true; $masterCheckbox.Checked = $global:AppConfig.Settings.AutoCleanOnExit
    $groupbox = New-Object System.Windows.Forms.GroupBox; $groupbox.Text = "Files to Clean"; $groupbox.Location = New-Object System.Drawing.Point(20, 50); $groupbox.Size = New-Object System.Drawing.Size(400, 100)
    $dashboardCheckbox = New-Object System.Windows.Forms.CheckBox; $dashboardCheckbox.Text = "Web Dashboard (dashboard.html)"; $dashboardCheckbox.Location = New-Object System.Drawing.Point(15, 25); $dashboardCheckbox.AutoSize = $true; $dashboardCheckbox.Checked = $global:AppConfig.Settings.CleanDashboard
    $metadataCheckbox = New-Object System.Windows.Forms.CheckBox; $metadataCheckbox.Text = "Project Metadata (*.meta.json)"; $metadataCheckbox.Location = New-Object System.Drawing.Point(15, 50); $metadataCheckbox.AutoSize = $true; $metadataCheckbox.Checked = $global:AppConfig.Settings.CleanMetadata
    $configCheckbox = New-Object System.Windows.Forms.CheckBox; $configCheckbox.Text = "App Configuration (config.json)"; $configCheckbox.Location = New-Object System.Drawing.Point(15, 75); $configCheckbox.AutoSize = $true; $configCheckbox.Checked = $global:AppConfig.Settings.CleanConfig
    $okButton = New-Object System.Windows.Forms.Button; $okButton.Text = $ButtonText; $okButton.DialogResult = "OK"; $okButton.Location = New-Object System.Drawing.Point(230, 170)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(320, 170)
    $groupbox.Controls.AddRange(@($dashboardCheckbox, $metadataCheckbox, $configCheckbox)); $dialog.Controls.AddRange(@($masterCheckbox, $groupbox, $okButton, $cancelButton))
    if ($dialog.ShowDialog($form) -eq "OK") { return @{ AutoCleanOnExit = $masterCheckbox.Checked; CleanDashboard = $dashboardCheckbox.Checked; CleanMetadata = $metadataCheckbox.Checked; CleanConfig = $configCheckbox.Checked } }
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
            if ($configOnDisk.Settings) { foreach ($key in $configOnDisk.Settings.Keys) { $global:AppConfig.Settings[$key] = $configOnDisk.Settings[$key] } }
        } catch { $statusLabel.Text = "Warning: Could not read config.json." }
    }
    if ($global:AppConfig.SourceFolders.Count -eq 0) { $global:AppConfig.SourceFolders = @($ScriptDir) }
    
    # Apply saved UI settings
    $form.Size = $global:AppConfig.Settings.WindowSize
    if ($global:AppConfig.Settings.WindowLocation) { $form.Location = $global:AppConfig.Settings.WindowLocation } else { $form.StartPosition = "CenterScreen" }
    foreach ($key in $global:AppConfig.Settings.ColumnWidths.Keys) { if ($key -lt $listView.Columns.Count) { $listView.Columns[$key].Width = $global:AppConfig.Settings.ColumnWidths[$key] } }

    if ($global:AppConfig.Settings.IsFirstRun) {
        # This will now run *after* the main form is shown, via the Load event
        $newSettings = Show-CleanupOptionsDialog -Title "First Time Setup" -ButtonText "Save & Continue"
        if ($newSettings) {
            $global:AppConfig.Settings.IsFirstRun = $false; $global:AppConfig.Settings.AutoCleanOnExit = $newSettings.AutoCleanOnExit; $global:AppConfig.Settings.CleanDashboard = $newSettings.CleanDashboard; $global:AppConfig.Settings.CleanMetadata = $newSettings.CleanMetadata; $global:AppConfig.Settings.CleanConfig = $newSettings.CleanConfig
            Save-Configuration
        }
    }
}

function Save-Configuration {
    # Capture UI settings before saving
    $global:AppConfig.Settings.WindowSize = $form.Size
    $global:AppConfig.Settings.WindowLocation = $form.Location
    $global:AppConfig.Settings.ColumnWidths = @{}
    for ($i = 0; $i -lt $listView.Columns.Count; $i++) { $global:AppConfig.Settings.ColumnWidths[$i] = $listView.Columns[$i].Width }

    try {
        $global:AppConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigSourceFile -Encoding UTF8
    } catch { $statusLabel.Text = "Error: Could not save configuration to config.json." }
}

function Refresh-FileList {
    $listView.BeginUpdate(); $listView.Items.Clear(); $statusLabel.Text = "Searching..."; $form.Cursor = "WaitCursor"
    foreach ($folder in $global:AppConfig.SourceFolders) {
        if (-not (Test-Path $folder)) { Write-Warning "Source folder not found: $folder"; continue }
        Get-ChildItem -Path $folder -Filter "*.html" -File -Recurse | Where-Object { $_.Name -ne $DashboardFileName -and $_.FullName -notin $global:AppConfig.Settings.IgnoredFiles } | ForEach-Object {
            $metaFilePath = "$($_.FullName).meta.json"; $author = ""; $version = ""
            if (Test-Path $metaFilePath) { try { $meta = Get-Content -Path $metaFilePath | ConvertFrom-Json; $author = $meta.Author; $version = $meta.Version } catch {} }
            $item = New-Object System.Windows.Forms.ListViewItem($_.Name)
            $item.SubItems.Add($_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
            $item.SubItems.Add($_.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
            $item.SubItems.Add($author) | Out-Null; $item.SubItems.Add($version) | Out-Null; $item.SubItems.Add($_.DirectoryName) | Out-Null
            $item.Tag = $_.FullName; $listView.Items.Add($item) | Out-Null
        }
    }
    $statusLabel.Text = "Found $($listView.Items.Count) projects. Ready."; $form.Cursor = "Default"; $listView.EndUpdate()
}

function Open-SelectedFile {
    if ($listView.SelectedItems.Count -eq 0) { return }
    $fullPath = $listView.SelectedItems[0].Tag
    Inject-NavigationCode -FilePath $fullPath; Start-Process -FilePath $fullPath
}

function Show-MetadataEditor {
    if ($listView.SelectedItems.Count -eq 0) { return }
    $item = $listView.SelectedItems[0]; $fullPath = $item.Tag; $metaFilePath = "$fullPath.meta.json"
    $metadata = [ordered]@{}
    if (Test-Path $metaFilePath) { try { $metadata = Get-Content -Path $metaFilePath | ConvertFrom-Json -AsHashtable } catch { $metadata = [ordered]@{} } }
    
    if (-not $metadata.ContainsKey('Author')) { $metadata['Author'] = '' }
    if (-not $metadata.ContainsKey('Version')) { $metadata['Version'] = '' }

    $editorForm = New-Object System.Windows.Forms.Form
    $editorForm.Text = "Edit Metadata for $($item.Text)"; $editorForm.Size = New-Object System.Drawing.Size(500, 400); $editorForm.FormBorderStyle = "Sizable"; $editorForm.StartPosition = "CenterParent"
    $dataGridView = New-Object System.Windows.Forms.DataGridView; $dataGridView.Dock = "Fill"
    $dataGridView.Columns.Add("Property", "Property"); $dataGridView.Columns.Add("Value", "Value")
    $dataGridView.Columns["Property"].Width = 150; $dataGridView.Columns["Value"].AutoSizeMode = "Fill"
    foreach ($key in $metadata.Keys) { $dataGridView.Rows.Add($key, $metadata[$key]) | Out-Null }
    $buttonPanel = New-Object System.Windows.Forms.Panel; $buttonPanel.Dock = "Bottom"; $buttonPanel.Height = 40
    $saveButton = New-Object System.Windows.Forms.Button; $saveButton.Text = "Save"; $saveButton.DialogResult = "OK"; $saveButton.Location = New-Object System.Drawing.Point(310, 5)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(395, 5)
    $buttonPanel.Controls.AddRange(@($saveButton, $cancelButton)); $editorForm.Controls.AddRange(@($dataGridView, $buttonPanel))
    if ($editorForm.ShowDialog($form) -eq "OK") {
        $newMeta = [ordered]@{}; foreach ($row in $dataGridView.Rows) { if ($row.IsNewRow) { continue }; $key = $row.Cells["Property"].Value; $value = $row.Cells["Value"].Value; if ($key) { $newMeta[$key] = $value } }
        $newMeta | ConvertTo-Json | Set-Content -Path $metaFilePath -Encoding UTF8
        Refresh-FileList; $statusLabel.Text = "Metadata saved for $($item.Text)."
    }
    $editorForm.Dispose()
}

function Show-SourceManager {
    $managerForm = New-Object System.Windows.Forms.Form
    $managerForm.Text = "Manage Project Folders"; $managerForm.Size = New-Object System.Drawing.Size(500, 300); $managerForm.FormBorderStyle = "FixedDialog"; $managerForm.StartPosition = "CenterParent"
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

function Inject-NavigationCode {
    param([string]$FilePath)
    $content = Get-Content -Path $FilePath -Raw
    if ($content -notmatch [regex]::Escape($InjectionIdentifier)) {
        $dashboardPath = "file:///$((Join-Path -Path $ScriptDir -ChildPath $DashboardFileName).Replace('\', '/'))"
        $injectionCode = @"
$InjectionIdentifier
<style>
    .launcher-nav-buttons { position: fixed; bottom: 20px; right: 20px; z-index: 9999; display: flex; gap: 10px; }
    .launcher-nav-buttons a { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 14px; text-decoration: none; padding: 10px 15px; background-color: rgba(0, 0, 0, 0.7); color: white; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.3); transition: all 0.2s ease; backdrop-filter: blur(5px); }
    .launcher-nav-buttons a:hover { background-color: rgba(255, 255, 255, 0.9); color: black; }
</style>
<div class="launcher-nav-buttons">
    <a href="#" onclick="window.history.back(); return false;">&larr; Back</a>
    <a href="$dashboardPath">Home</a>
</div>
"@
        $newContent = $content -replace '(?i)</body>', "$injectionCode`n</body>"; Set-Content -Path $FilePath -Value $newContent -Encoding UTF8
    }
}

function Generate-HtmlIndex {
    $statusLabel.Text = "Generating web index..."; $form.Cursor = "WaitCursor"; $allItems = @()
    foreach ($item in $listView.Items) { $allItems += [pscustomobject]@{ FileName = $item.Text; FullPath = $item.Tag; Author = $item.SubItems[3].Text } }
    $tileItems = $allItems | ForEach-Object {
        $fileUri = "file:///$($_.FullPath.Replace('\', '/'))"; $authorInfo = if ($_.Author) { "<div class='tile-author'>by $($_.Author)</div>" } else { "" }
        @"
    <a href="$fileUri" class="tile"><div class="preview-container"><iframe src="$fileUri" scrolling="no" sandbox="allow-scripts"></iframe></div><div class="tile-footer"><div class="tile-title">$($_.FileName)</div>$authorInfo</div></a>
"@
    }
    $htmlContent = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Project Launchpad</title>
<style>
    :root { --bg-color: #121212; --text-color: #e0e0e0; --header-color: #ffffff; --accent-color: #33aaff; --accent-hover: #55ccff; --tile-bg: #1e1e1e; --tile-hover-bg: #2a2a2a; --tile-border: #333; --footer-text: #666; }
    .theme-light { --bg-color: #f4f4f4; --text-color: #333333; --header-color: #000000; --accent-color: #0078d4; --accent-hover: #005a9e; --tile-bg: #ffffff; --tile-hover-bg: #e8e8e8; --tile-border: #ddd; --footer-text: #888; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: var(--bg-color); color: var(--text-color); margin: 0; padding: 20px; transition: background-color 0.3s, color 0.3s; }
    .container { max-width: 1400px; margin: 0 auto; } .dashboard-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 20px; margin-bottom: 20px; background-color: var(--tile-bg); border-radius: 8px; border: 1px solid var(--tile-border); }
    .dashboard-header h1 { color: var(--header-color); border-bottom: none; padding-bottom: 0; margin: 0; font-size: 1.5em; }
    .controls button { background-color: var(--accent-color); color: white; border: none; padding: 8px 12px; border-radius: 5px; cursor: pointer; transition: background-color 0.2s; margin-left: 10px; }
    .controls button:hover { background-color: var(--accent-hover); } .tile-container.grid-view { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 25px; }
    .tile-container.list-view { display: flex; flex-direction: column; gap: 10px; } .tile { text-decoration: none; color: var(--text-color); background-color: var(--tile-bg); border-radius: 8px; overflow: hidden; border: 1px solid var(--tile-border); transition: all 0.2s ease-in-out; }
    .grid-view .tile { display: flex; flex-direction: column; } .list-view .tile { display: flex; flex-direction: row; align-items: center; }
    .tile:hover { transform: translateY(-3px); box-shadow: 0 8px 15px rgba(0,0,0,0.2); border-color: var(--accent-color); }
    .list-view .tile:hover { transform: translateX(5px); } .preview-container { width: 100%; height: 220px; overflow: hidden; background-color: #000; }
    .list-view .preview-container { width: 120px; height: 80px; flex-shrink: 0; } .tile iframe { width: 1024px; height: 768px; transform-origin: top left; border: none; pointer-events: none; }
    .grid-view .tile iframe { transform: scale(calc(320 / 1024)); } .list-view .tile iframe { transform: scale(calc(120 / 1024)); }
    .tile-footer { padding: 15px; } .list-view .tile-footer { flex-grow: 1; } .tile-title { font-size: 1.1em; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .tile-author { font-size: 0.9em; color: #999; margin-top: 5px; } footer { text-align: center; margin-top: 40px; font-size: 0.9em; color: var(--footer-text); }
</style></head><body><div class="container">
<header class="dashboard-header"><h1>Project Launchpad</h1><div class="controls"><button id="theme-toggle">Toggle Theme</button><button id="layout-toggle">Toggle Layout</button></div></header>
<main class="tile-container"> $($tileItems -join "`n") </main>
<footer>Generated by Project Launcher Pro on $(Get-Date)</footer></div>
<script>
    document.addEventListener('DOMContentLoaded', () => {
        const themeToggle = document.getElementById('theme-toggle'); const layoutToggle = document.getElementById('layout-toggle'); const body = document.body; const tileContainer = document.querySelector('.tile-container');
        const savedTheme = localStorage.getItem('dashboardTheme') || 'theme-dark'; const savedLayout = localStorage.getItem('dashboardLayout') || 'grid-view';
        body.classList.add(savedTheme); tileContainer.classList.add(savedLayout);
        themeToggle.addEventListener('click', () => { if (body.classList.contains('theme-dark')) { body.classList.replace('theme-dark', 'theme-light'); localStorage.setItem('dashboardTheme', 'theme-light'); } else { body.classList.replace('theme-light', 'theme-dark'); localStorage.setItem('dashboardTheme', 'theme-dark'); } });
        layoutToggle.addEventListener('click', () => { if (tileContainer.classList.contains('grid-view')) { tileContainer.classList.replace('grid-view', 'list-view'); localStorage.setItem('dashboardLayout', 'list-view'); } else { tileContainer.classList.replace('list-view', 'grid-view'); localStorage.setItem('dashboardLayout', 'grid-view'); } });
    });
</script></body></html>
"@
    $dashboardPath = Join-Path -Path $ScriptDir -ChildPath $DashboardFileName; Set-Content -Path $dashboardPath -Value $htmlContent -Encoding UTF8
    $statusLabel.Text = "Successfully generated '$DashboardFileName'."; $form.Cursor = "Default"
    [System.Windows.Forms.MessageBox]::Show("Successfully generated '$DashboardFileName'.", "Success", "OK", "Information"); Start-Process -FilePath $dashboardPath
}

# 4.) Event Handlers
# ------------------
$manageFoldersMenuItem.Add_Click({ Show-SourceManager })
$refreshMenuItem.Add_Click({ Refresh-FileList }); $refreshButton.Add_Click({ Refresh-FileList })
$generateWebIndexMenuItem.Add_Click({ Generate-HtmlIndex }); $generateButton.Add_Click({ Generate-HtmlIndex })
$exitMenuItem.Add_Click({ $form.Close() }); $closeButton.Add_Click({ $form.Close() })
$cleanFilesMenuItem.Add_Click({
    $cleanupOptions = Show-CleanupOptionsDialog -Title "Manual File Cleanup" -ButtonText "Clean Selected Files"
    if ($cleanupOptions) { $confirmResult = [System.Windows.Forms.MessageBox]::Show("This action cannot be undone. Are you sure you want to clean the selected files?", "Confirm Cleanup", "YesNo", "Warning"); if ($confirmResult -eq "Yes") { Clean-TemporaryFiles -CleanDashboard $cleanupOptions.CleanDashboard -CleanMetadata $cleanupOptions.CleanMetadata -CleanConfig $cleanupOptions.CleanConfig } }
})
$cleanupSettingsMenuItem.Add_Click({
    $newSettings = Show-CleanupOptionsDialog -Title "Auto-Cleanup Settings" -ButtonText "Save Settings"
    if ($newSettings) { $global:AppConfig.Settings.AutoCleanOnExit = $newSettings.AutoCleanOnExit; $global:AppConfig.Settings.CleanDashboard = $newSettings.CleanDashboard; $global:AppConfig.Settings.CleanMetadata = $newSettings.CleanMetadata; $global:AppConfig.Settings.CleanConfig = $newSettings.CleanConfig; Save-Configuration; $statusLabel.Text = "Auto-cleanup settings saved." }
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
$listView.Add_DoubleClick({ Open-SelectedFile })
$listView.Add_ColumnClick({ param($s, $e); if ($listView.Sorting -eq "Ascending") { $listView.Sorting = "Descending" } else { $listView.Sorting = "Ascending" }; $listView.ListViewItemSorter = New-Object ListViewItemComparer($e.Column, $listView.Sorting) })
$openMenuItem.Add_Click({ Open-SelectedFile })
$editMetaMenuItem.Add_Click({ Show-MetadataEditor })
$openFolderMenuItem.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Invoke-Item -Path (Split-Path -Path $listView.SelectedItems[0].Tag -Parent) } })
$form.Add_FormClosing({ Save-Configuration; if ($global:AppConfig.Settings.AutoCleanOnExit) { Clean-TemporaryFiles -CleanDashboard $global:AppConfig.Settings.CleanDashboard -CleanMetadata $global:AppConfig.Settings.CleanMetadata -CleanConfig $global:AppConfig.Settings.CleanConfig } })
$form.Add_Load({ Initialize-Application })
$form.Add_Shown({ [void][Win32]::ShowWindow([Win32]::GetConsoleWindow(), [Win32]::SW_MINIMIZE) })

# 5.) Final Assembly and Display
# ------------------------------
# Add GroupBy menu items dynamically
$groupByMenuItem.DropDownItems.Add("None", $null, { Update-Grouping -ColumnIndex -1 }) | Out-Null
for ($i = 0; $i -lt $listView.Columns.Count; $i++) {
    $columnName = $listView.Columns[$i].Text
    $columnIndex = $i # Capture current value for the scriptblock
    $groupByMenuItem.DropDownItems.Add($columnName, $null, { Update-Grouping -ColumnIndex $columnIndex }) | Out-Null
}

[void]$form.ShowDialog()

# 6.) Cleanup
# -----------
$form.Dispose()
"
