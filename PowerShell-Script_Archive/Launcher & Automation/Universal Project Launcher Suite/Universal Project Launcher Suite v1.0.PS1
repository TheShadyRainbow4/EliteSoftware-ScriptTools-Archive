<#
.SYNOPSIS
    A unified, professional PowerShell GUI with a tabbed interface to manage and launch both scripts and HTML projects.
.DESCRIPTION
    Universal Project Launcher Suite v1.4 - Created by: Zachary Whiteman & Google Gemini Ai. 2025-07-13 - 03:00 AM

    This script combines the "Script Launcher Professional" and "HTML Project Launcher Professional" into a single, powerful application.

    New Features in v1.4:
    - **Synced Source Folders:** Both tabs now share a single, unified list of source folders for maximum convenience.
    - **Backup & Restore:** You can now backup your entire application configuration to a file and restore it later via the "File" menu. This is great for saving different layout presets.
    - **Smarter Defaults:** On first launch, the app now automatically adds the script's directory and your Desktop as default source folders.
    - **Renamed Config File:** All settings are now saved to "Configuration.json".

    Core Features:
    - **Tabbed Interface:** Separate tabs for Scripts (.ps1, .py, .bat) and HTML Projects (.html).
    - **Full Feature Parity:** All advanced view modes (Details, Tiles, Icons) and grouping options are available for both tabs.
    - **Custom Icons & Metadata:** Supports custom icons for scripts and metadata for all files.
    - **Horizontal Button Layout:** A clean, centered row of primary action buttons.
.NOTES
    Requires PowerShell with .NET Framework access.
.AUTHOR
    Zachary Whiteman & Google Gemini
#>

# 1.) Preamble and Configuration
#---------------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- C# Helper Code (Console Control & ListView Sorter) ---
Add-Type -ReferencedAssemblies 'System.Windows.Forms.dll' -TypeDefinition @"
using System;
using System.Collections;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class Win32 {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    public const int SW_HIDE = 0, SW_SHOW = 5, SW_MINIMIZE = 6;
}

public class ListViewItemComparer : IComparer {
    private int col;
    private SortOrder order;
    public ListViewItemComparer() { col = 0; order = SortOrder.Ascending; }
    public ListViewItemComparer(int column, SortOrder order) { this.col = column; this.order = order; }
    public int Compare(object x, object y) {
        int returnVal;
        ListViewItem itemX = (ListViewItem)x;
        ListViewItem itemY = (ListViewItem)y;
        try {
            returnVal = DateTime.Compare(DateTime.Parse(itemX.SubItems[col].Text), DateTime.Parse(itemY.SubItems[col].Text));
        } catch {
            returnVal = String.Compare(itemX.SubItems[col].Text, itemY.SubItems[col].Text);
        }
        if (order == SortOrder.Descending) { returnVal *= -1; }
        return returnVal;
    }
}
"@

# --- Helper Functions ---
function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    try { return Split-Path -Parent $MyInvocation.MyCommand.Definition } catch { return $PWD }
}

# --- Global Configuration ---
$AppVersion = "1.4"
$ScriptDir = Get-ScriptDirectory
$ConfigSourceFile = Join-Path -Path $ScriptDir -ChildPath "Configuration.json"
$global:iconCache = @{}

# Define the default structure for the application's configuration
$global:AppConfig = @{
    ScriptLauncher = @{
        IgnoredFiles     = @()
        ColumnWidths     = @{}
        CurrentView      = "Details"
        ApplicationPaths = @{
            ".ps1" = "pwsh.exe"
            ".py"  = "python.exe"
            ".bat" = "cmd.exe"
            ".cmd" = "cmd.exe"
        }
    }
    HtmlLauncher = @{
        IgnoredFiles   = @()
        ColumnWidths   = @{}
        CurrentView    = "Details"
        DashboardFile  = "dashboard.html"
        InjectNavBar   = $true
    }
    GlobalSettings = @{
        SourceFolders      = @() # Folders are now shared
        ShowSetupOnStartup = $true
        AutoCleanOnExit    = $false
        CleanDashboard     = $false
        CleanMetadata      = $false
        CleanConfig        = $false
        WindowSize         = New-Object System.Drawing.Size(1000, 700)
        WindowLocation     = $null
        LastActiveTab      = 0
    }
}

# 2.) GUI Element Creation
#---------------------------------

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Universal Project Launcher Suite v$AppVersion"
$form.MinimumSize = New-Object System.Drawing.Size(800, 500)
$form.StartPosition = "Manual"
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch {}

# --- Main Layout & Tab Control ---
$mainTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$mainTableLayoutPanel.Dock = "Fill"; $mainTableLayoutPanel.ColumnCount = 1; $mainTableLayoutPanel.RowCount = 4
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null
$mainTableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null

$tabControl = New-Object System.Windows.Forms.TabControl; $tabControl.Dock = "Fill"
$scriptTabPage = New-Object System.Windows.Forms.TabPage; $scriptTabPage.Text = "Script Launcher"
$htmlTabPage = New-Object System.Windows.Forms.TabPage; $htmlTabPage.Text = "HTML Project Launcher"
$tabControl.TabPages.AddRange(@($scriptTabPage, $htmlTabPage))

# --- Image Lists for Icons (One set for each tab) ---
$scriptLargeImageList = New-Object System.Windows.Forms.ImageList; $scriptLargeImageList.ImageSize = New-Object System.Drawing.Size(32, 32); $scriptLargeImageList.ColorDepth = "Depth32Bit"
$scriptSmallImageList = New-Object System.Windows.Forms.ImageList; $scriptSmallImageList.ImageSize = New-Object System.Drawing.Size(16, 16); $scriptSmallImageList.ColorDepth = "Depth32Bit"
$htmlLargeImageList = New-Object System.Windows.Forms.ImageList; $htmlLargeImageList.ImageSize = New-Object System.Drawing.Size(32, 32); $htmlLargeImageList.ColorDepth = "Depth32Bit"
$htmlSmallImageList = New-Object System.Windows.Forms.ImageList; $htmlSmallImageList.ImageSize = New-Object System.Drawing.Size(16, 16); $htmlSmallImageList.ColorDepth = "Depth32Bit"

# --- Script Launcher Tab Controls ---
$scriptListView = New-Object System.Windows.Forms.ListView
$scriptListView.View = "Details"; $scriptListView.Dock = "Fill"; $scriptListView.FullRowSelect = $true; $scriptListView.GridLines = $true
$scriptListView.LargeImageList = $scriptLargeImageList; $scriptListView.SmallImageList = $scriptSmallImageList
$scriptListView.Columns.Add("File Name", 250); $scriptListView.Columns.Add("File Type", 80); $scriptListView.Columns.Add("Date Modified", 150); $scriptListView.Columns.Add("Date Created", 150); $scriptListView.Columns.Add("Author", 120); $scriptListView.Columns.Add("Version", 80); $scriptListView.Columns.Add("Source Folder", 200)
$scriptContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$runScriptMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Run Script"); $editScriptMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Script"); $editScriptMetaMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Metadata..."); $ignoreScriptFileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Ignore File"); $openScriptFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Containing Folder")
$scriptContextMenu.Items.AddRange(@($runScriptMenuItem, $editScriptMenuItem, $editScriptMetaMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $ignoreScriptFileMenuItem, $openScriptFolderMenuItem))
$scriptListView.ContextMenuStrip = $scriptContextMenu
$scriptTabPage.Controls.Add($scriptListView)

# --- HTML Launcher Tab Controls ---
$htmlListView = New-Object System.Windows.Forms.ListView
$htmlListView.View = "Details"; $htmlListView.Dock = "Fill"; $htmlListView.FullRowSelect = $true; $htmlListView.GridLines = $true
$htmlListView.LargeImageList = $htmlLargeImageList; $htmlListView.SmallImageList = $htmlSmallImageList
$htmlListView.Columns.Add("File Name", 250); $htmlListView.Columns.Add("Date Modified", 150); $htmlListView.Columns.Add("Date Created", 150); $htmlListView.Columns.Add("Author", 120); $htmlListView.Columns.Add("Version", 80); $htmlListView.Columns.Add("Source Folder", 200)
$htmlContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$openHtmlMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Project"); $editHtmlMetaMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Metadata..."); $ignoreHtmlFileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Ignore File"); $openHtmlFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open Containing Folder")
$htmlContextMenu.Items.AddRange(@($openHtmlMenuItem, $editHtmlMetaMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $ignoreHtmlFileMenuItem, $openHtmlFolderMenuItem))
$htmlListView.ContextMenuStrip = $htmlContextMenu
$htmlTabPage.Controls.Add($htmlListView)

# --- Menu Strip (Shared) ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip; $menuStrip.Dock = "Fill"
$fileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&File")
$manageFoldersMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Manage Source Folders...")
$backupSettingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Backup Settings...")
$restoreSettingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Restore Settings...")
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("E&xit")
$viewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&View")
$viewByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Arrange By")
$groupByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Group By")
$toolsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Tools")
$refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Refresh All Lists")
$manageIgnoredMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Manage &Ignored Files...")
$cleanFilesMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Clean Temporary Files...")
$optionsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Options")
$appPathMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Configure &Script App Paths...")
$cleanupSettingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Auto-Cleanup Settings...")

$fileMenuItem.DropDownItems.AddRange(@($manageFoldersMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $backupSettingsMenuItem, $restoreSettingsMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $exitMenuItem))
$viewMenuItem.DropDownItems.AddRange(@($viewByMenuItem, $groupByMenuItem))
$toolsMenuItem.DropDownItems.AddRange(@($refreshMenuItem, $manageIgnoredMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $cleanFilesMenuItem))
$optionsMenuItem.DropDownItems.AddRange(@($appPathMenuItem, $cleanupSettingsMenuItem))
$menuStrip.Items.AddRange(@($fileMenuItem, $viewMenuItem, $toolsMenuItem, $optionsMenuItem))

# --- Status Strip (Shared) ---
$statusStrip = New-Object System.Windows.Forms.StatusStrip; $statusStrip.Dock = "Fill"
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $statusStrip.Items.Add($statusLabel)

# --- Bottom Button Panel (Horizontal Layout) ---
$bottomFlowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$bottomFlowLayoutPanel.Dock = "Fill"; $bottomFlowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 10)
$bottomFlowLayoutPanel.FlowDirection = "LeftToRight"; $bottomFlowLayoutPanel.AutoSize = $true
$bottomTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$bottomTableLayoutPanel.Dock = "Fill"; $bottomTableLayoutPanel.AutoSize = $true
$bottomTableLayoutPanel.ColumnCount = 1
$bottomTableLayoutPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$bottomTableLayoutPanel.Controls.Add($bottomFlowLayoutPanel, 0, 0)
$bottomFlowLayoutPanel.Anchor = "None"

$refreshButton = New-Object System.Windows.Forms.Button; $refreshButton.Text = "Refresh"; $refreshButton.Size = New-Object System.Drawing.Size(150, 30); $refreshButton.Margin = New-Object System.Windows.Forms.Padding(5, 0, 5, 0)
$dashboardButton = New-Object System.Windows.Forms.Button; $dashboardButton.Text = "View Dashboard"; $dashboardButton.Size = New-Object System.Drawing.Size(150, 30); $dashboardButton.Margin = New-Object System.Windows.Forms.Padding(5, 0, 5, 0)
$closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Size = New-Object System.Drawing.Size(150, 30); $closeButton.Margin = New-Object System.Windows.Forms.Padding(5, 0, 5, 0)
$bottomFlowLayoutPanel.Controls.AddRange(@($refreshButton, $dashboardButton, $closeButton))


# --- Final Assembly ---
$mainTableLayoutPanel.Controls.Add($menuStrip, 0, 0)
$mainTableLayoutPanel.Controls.Add($tabControl, 0, 1)
$mainTableLayoutPanel.Controls.Add($bottomTableLayoutPanel, 0, 2)
$mainTableLayoutPanel.Controls.Add($statusStrip, 0, 3)
$form.Controls.Add($mainTableLayoutPanel)

# 3.) Core Functions
#------------------

function Get-ActiveLauncherContext {
    param([string]$Type)
    if ($Type -eq 'Script' -or (!$Type -and $tabControl.SelectedTab -eq $scriptTabPage)) {
        return [pscustomobject]@{
            Type           = "Script"
            ListView       = $scriptListView
            Config         = $global:AppConfig.ScriptLauncher
            FileTypes      = @("*.ps1", "*.py", "*.bat", "*.cmd")
            LargeImageList = $scriptLargeImageList
            SmallImageList = $scriptSmallImageList
        }
    }
    elseif ($Type -eq 'Html' -or (!$Type -and $tabControl.SelectedTab -eq $htmlTabPage)) {
        return [pscustomobject]@{
            Type           = "Html"
            ListView       = $htmlListView
            Config         = $global:AppConfig.HtmlLauncher
            FileTypes      = @("*.html")
            LargeImageList = $htmlLargeImageList
            SmallImageList = $htmlSmallImageList
        }
    }
}

function Initialize-Application {
    $statusLabel.Text = "Loading configuration..."
    $form.Refresh()
    Load-Configuration
    $statusLabel.Text = "Ready."
    $form.Refresh()
}

function Handle-FirstRunAndLoadData {
    if ($global:AppConfig.GlobalSettings.ShowSetupOnStartup) {
        $newSettings = Show-CleanupOptionsDialog -Title "Initial Setup" -ButtonText "Save"
        if ($newSettings) {
            $global:AppConfig.GlobalSettings.AutoCleanOnExit = $newSettings.AutoCleanOnExit
            $global:AppConfig.GlobalSettings.CleanDashboard = $newSettings.CleanDashboard
            $global:AppConfig.GlobalSettings.CleanMetadata = $newSettings.CleanMetadata
            $global:AppConfig.GlobalSettings.CleanConfig = $newSettings.CleanConfig
            $global:AppConfig.GlobalSettings.ShowSetupOnStartup = $newSettings.ShowSetupOnStartup
            Save-Configuration
        }
    }
    Refresh-List -AllTabs
}

function Set-ListView-View {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.View]$View
    )
    $ListView.View = $View
    $ListView.GridLines = ($View -eq [System.Windows.Forms.View]::Details)
    $context = Get-ActiveLauncherContext
    $context.Config.CurrentView = $View.ToString()
}

function Update-Grouping {
    param([int]$ColumnIndex)
    $context = Get-ActiveLauncherContext
    $lv = $context.ListView
    $lv.BeginUpdate()
    if ($ColumnIndex -lt 0) {
        $lv.ShowGroups = $false
    } else {
        $lv.ShowGroups = $true
        $lv.Groups.Clear()
        $groups = @{}
        foreach ($item in $lv.Items) {
            if ($ColumnIndex -ge $item.SubItems.Count) { continue } # Safety check
            $groupName = $item.SubItems[$ColumnIndex].Text
            # Date grouping logic
            if ($lv.Columns[$ColumnIndex].Text -match "Date") {
                try { $groupName = ([datetime]::Parse($groupName)).ToString("yyyy-MM-dd") } catch { $groupName = "(Invalid Date)" }
            }
            if (-not $groupName) { $groupName = "(None)" }
            if (-not $groups.ContainsKey($groupName)) {
                $groups[$groupName] = New-Object System.Windows.Forms.ListViewGroup($groupName, $groupName)
                $lv.Groups.Add($groups[$groupName]) | Out-Null
            }
            $item.Group = $groups[$groupName]
        }
    }
    $lv.EndUpdate()
}

function Refresh-List {
    param([switch]$AllTabs)
    
    $contexts = if ($AllTabs) { @((Get-ActiveLauncherContext -Type "Script"), (Get-ActiveLauncherContext -Type "Html")) } else { @(Get-ActiveLauncherContext) }

    foreach ($context in $contexts) {
        $lv = $context.ListView
        $lv.BeginUpdate(); $lv.Items.Clear(); $statusLabel.Text = "Searching for $($context.Type) files..."; $form.Cursor = "WaitCursor"; $form.Refresh()
        
        $context.LargeImageList.Images.Clear(); $context.SmallImageList.Images.Clear(); $global:iconCache.Clear()

        # Pre-load generic HTML icon if needed
        if ($context.Type -eq "Html" -and -not $global:iconCache.ContainsKey(".html")) {
            try {
                $tempFile = [System.IO.Path]::GetTempFileName() + ".html"
                New-Item -Path $tempFile -ItemType File -Force | Out-Null
                $htmlIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($tempFile)
                if ($htmlIcon) {
                    $context.LargeImageList.Images.Add($htmlIcon)
                    $context.SmallImageList.Images.Add($htmlIcon)
                    $global:iconCache[".html"] = $context.LargeImageList.Images.Count - 1
                    $htmlIcon.Dispose()
                }
                Remove-Item $tempFile -Force
            } catch {
                # Fallback to a generic system icon
                $genericIcon = [System.Drawing.SystemIcons]::Application
                $context.LargeImageList.Images.Add($genericIcon)
                $context.SmallImageList.Images.Add($genericIcon)
                $global:iconCache[".html"] = $context.LargeImageList.Images.Count - 1
            }
        }

        foreach ($folder in $global:AppConfig.GlobalSettings.SourceFolders) { # Use shared folders
            if (-not (Test-Path $folder)) { Write-Warning "Source folder not found: $folder"; continue }
            Get-ChildItem -Path $folder -Include $context.FileTypes -File -Recurse | Where-Object { $_.FullName -notin $context.Config.IgnoredFiles -and $_.Name -ne $global:AppConfig.HtmlLauncher.DashboardFile } | ForEach-Object {
                $file = $_
                $metaFilePath = "$($file.FullName).meta.json"
                $author = ""; $version = ""; $customIconPath = $null
                if (Test-Path $metaFilePath) { 
                    try { 
                        $meta = Get-Content -Path $metaFilePath | ConvertFrom-Json
                        $author = $meta.Author; $version = $meta.Version
                        if ($meta.PSObject.Properties.Name -contains 'CustomIconPath') { $customIconPath = $meta.CustomIconPath }
                    } catch {} 
                }

                # --- Icon Loading Logic ---
                $iconKey = if ($context.Type -eq "Script") { if ($customIconPath -and (Test-Path $customIconPath)) { $customIconPath } else { $file.Extension } } else { ".html" }
                
                if (-not $global:iconCache.ContainsKey($iconKey)) {
                    $icon = $null
                    try {
                        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconKey)
                    } catch {
                        try { $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($file.FullName) } catch { $icon = [System.Drawing.SystemIcons]::Application }
                    }
                    
                    if ($icon) {
                        $context.LargeImageList.Images.Add($icon)
                        $context.SmallImageList.Images.Add($icon)
                        $global:iconCache[$iconKey] = $context.LargeImageList.Images.Count - 1
                        $icon.Dispose()
                    }
                }
                $imageIndex = if ($global:iconCache.ContainsKey($iconKey)) { $global:iconCache[$iconKey] } else { -1 }

                # --- Create ListView Item ---
                $item = New-Object System.Windows.Forms.ListViewItem($file.Name, $imageIndex)
                $subItems = New-Object System.Collections.ArrayList
                if ($context.Type -eq "Script") { $subItems.Add($file.Extension) | Out-Null }
                else { $subItems.Add("") | Out-Null } # Placeholder for File Type
                $subItems.Add($file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
                $subItems.Add($file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
                $subItems.Add($author) | Out-Null; $subItems.Add($version) | Out-Null; $subItems.Add($file.DirectoryName) | Out-Null
                
                foreach($sub in $subItems){ $item.SubItems.Add($sub) | Out-Null }
                if($context.Type -eq 'Html'){ $item.SubItems.RemoveAt(1) } # Remove placeholder for HTML view
                
                $item.Tag = $file.FullName; $lv.Items.Add($item) | Out-Null
            }
        }
        $lv.EndUpdate()
    }
    $statusLabel.Text = "Ready."; $form.Cursor = "Default"
}

function Load-Configuration {
    $configExists = Test-Path $ConfigSourceFile
    if ($configExists) {
        try {
            $configOnDisk = Get-Content -Path $ConfigSourceFile | ConvertFrom-Json
            # Merge settings recursively to avoid overwriting entire objects
            function Merge-Hashtables($base, $overlay) {
                foreach ($key in $overlay.Keys) {
                    if ($base.ContainsKey($key) -and $base[$key] -is [hashtable] -and $overlay[$key] -is [hashtable]) {
                        Merge-Hashtables $base[$key] $overlay[$key]
                    } else {
                        $base[$key] = $overlay[$key]
                    }
                }
            }
            Merge-Hashtables $global:AppConfig $configOnDisk
        } catch { $statusLabel.Text = "Warning: Could not read or parse '$ConfigSourceFile'." }
    }
    
    # Add default folders if none are configured
    if (-not $configExists -or $global:AppConfig.GlobalSettings.SourceFolders.Count -eq 0) { 
        $DesktopPath = [System.Environment]::GetFolderPath('Desktop')
        $global:AppConfig.GlobalSettings.SourceFolders = @($ScriptDir, $DesktopPath) | Select-Object -Unique
    }
    
    $form.Size = $global:AppConfig.GlobalSettings.WindowSize
    if ($global:AppConfig.GlobalSettings.WindowLocation) { $form.Location = $global:AppConfig.GlobalSettings.WindowLocation } else { $form.StartPosition = "CenterScreen" }
    
    # Restore column widths and view for both listviews
    foreach ($key in $global:AppConfig.ScriptLauncher.ColumnWidths.Keys) { if ($key -lt $scriptListView.Columns.Count) { $scriptListView.Columns[$key].Width = $global:AppConfig.ScriptLauncher.ColumnWidths[$key] } }
    try { Set-ListView-View -ListView $scriptListView -View ([System.Windows.Forms.View]$global:AppConfig.ScriptLauncher.CurrentView) } catch {}
    
    foreach ($key in $global:AppConfig.HtmlLauncher.ColumnWidths.Keys) { if ($key -lt $htmlListView.Columns.Count) { $htmlListView.Columns[$key].Width = $global:AppConfig.HtmlLauncher.ColumnWidths[$key] } }
    try { Set-ListView-View -ListView $htmlListView -View ([System.Windows.Forms.View]$global:AppConfig.HtmlLauncher.CurrentView) } catch {}

    $tabControl.SelectedIndex = $global:AppConfig.GlobalSettings.LastActiveTab
}

function Save-Configuration {
    $global:AppConfig.GlobalSettings.WindowSize = $form.Size
    $global:AppConfig.GlobalSettings.WindowLocation = $form.Location
    $global:AppConfig.GlobalSettings.LastActiveTab = $tabControl.SelectedIndex
    
    $global:AppConfig.ScriptLauncher.ColumnWidths = @{}; for ($i = 0; $i -lt $scriptListView.Columns.Count; $i++) { $global:AppConfig.ScriptLauncher.ColumnWidths[$i] = $scriptListView.Columns[$i].Width }
    $global:AppConfig.HtmlLauncher.ColumnWidths = @{}; for ($i = 0; $i -lt $htmlListView.Columns.Count; $i++) { $global:AppConfig.HtmlLauncher.ColumnWidths[$i] = $htmlListView.Columns[$i].Width }

    try {
        $global:AppConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigSourceFile -Encoding UTF8
    } catch { $statusLabel.Text = "Error: Could not save configuration to '$ConfigSourceFile'." }
}

function Show-SourceManager {
    $managerForm = New-Object System.Windows.Forms.Form
    $managerForm.Text = "Manage Source Folders (Shared)"; $managerForm.Size = New-Object System.Drawing.Size(500, 300); $managerForm.FormBorderStyle = "FixedDialog"; $managerForm.StartPosition = "CenterParent"
    $listBox = New-Object System.Windows.Forms.ListBox; $listBox.Dock = "Fill"; $listBox.Items.AddRange($global:AppConfig.GlobalSettings.SourceFolders)
    $buttonPanel = New-Object System.Windows.Forms.Panel; $buttonPanel.Dock = "Bottom"; $buttonPanel.Height = 40
    $addButton = New-Object System.Windows.Forms.Button; $addButton.Text = "Add..."; $addButton.Location = New-Object System.Drawing.Point(10, 5)
    $removeButton = New-Object System.Windows.Forms.Button; $removeButton.Text = "Remove"; $removeButton.Location = New-Object System.Drawing.Point(95, 5)
    $closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Location = New-Object System.Drawing.Point(400, 5); $closeButton.Anchor = "Right"
    $addButton.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog($managerForm) -eq "OK") { if (-not ($listBox.Items -contains $folderBrowser.SelectedPath)) { $listBox.Items.Add($folderBrowser.SelectedPath) } }; $folderBrowser.Dispose() })
    $removeButton.Add_Click({ if ($listBox.SelectedItem) { $listBox.Items.Remove($listBox.SelectedItem) } }); $closeButton.Add_Click({ $managerForm.Close() })
    $buttonPanel.Controls.AddRange(@($addButton, $removeButton, $closeButton)); $managerForm.Controls.AddRange(@($listBox, $buttonPanel))
    $managerForm.ShowDialog($form)
    $global:AppConfig.GlobalSettings.SourceFolders = $listBox.Items; Save-Configuration; Refresh-List -AllTabs; $managerForm.Dispose()
}

function Show-MetadataEditor {
    $context = Get-ActiveLauncherContext
    $lv = $context.ListView
    if ($lv.SelectedItems.Count -eq 0) { return }
    $item = $lv.SelectedItems[0]; $fullPath = $item.Tag; $metaFilePath = "$fullPath.meta.json"
    $metadata = [ordered]@{}
    if (Test-Path $metaFilePath) { try { $metadata = Get-Content -Path $metaFilePath | ConvertFrom-Json -AsHashtable } catch { $metadata = [ordered]@{} } }
    
    $editorForm = New-Object System.Windows.Forms.Form
    $editorForm.Text = "Edit Metadata for $($item.Text)"; $editorForm.Size = New-Object System.Drawing.Size(550, 250); $editorForm.FormBorderStyle = "FixedDialog"; $editorForm.StartPosition = "CenterParent"

    $authorLabel = New-Object System.Windows.Forms.Label; $authorLabel.Text = "Author:"; $authorLabel.Location = New-Object System.Drawing.Point(20, 23); $authorLabel.AutoSize = $true
    $authorTextBox = New-Object System.Windows.Forms.TextBox; $authorTextBox.Text = $metadata['Author']; $authorTextBox.Location = New-Object System.Drawing.Point(120, 20); $authorTextBox.Size = New-Object System.Drawing.Size(400, 20)

    $versionLabel = New-Object System.Windows.Forms.Label; $versionLabel.Text = "Version:"; $versionLabel.Location = New-Object System.Drawing.Point(20, 53); $versionLabel.AutoSize = $true
    $versionTextBox = New-Object System.Windows.Forms.TextBox; $versionTextBox.Text = $metadata['Version']; $versionTextBox.Location = New-Object System.Drawing.Point(120, 50); $versionTextBox.Size = New-Object System.Drawing.Size(400, 20)
    
    $editorForm.Controls.AddRange(@($authorLabel, $authorTextBox, $versionLabel, $versionTextBox))

    if ($context.Type -eq "Script") {
        $iconLabel = New-Object System.Windows.Forms.Label; $iconLabel.Text = "Custom Icon:"; $iconLabel.Location = New-Object System.Drawing.Point(20, 83); $iconLabel.AutoSize = $true
        $iconTextBox = New-Object System.Windows.Forms.TextBox; $iconTextBox.Text = $metadata['CustomIconPath']; $iconTextBox.Location = New-Object System.Drawing.Point(120, 80); $iconTextBox.Size = New-Object System.Drawing.Size(315, 20)
        $iconBrowseButton = New-Object System.Windows.Forms.Button; $iconBrowseButton.Text = "..."; $iconBrowseButton.Location = New-Object System.Drawing.Point(440, 79); $iconBrowseButton.Size = New-Object System.Drawing.Size(80, 23)
        $iconBrowseButton.Add_Click({
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Filter = "Icon Files (*.ico, *.exe, *.dll)|*.ico;*.exe;*.dll|All files (*.*)|*.*"; $openFileDialog.Title = "Select Custom Icon"
            if ($openFileDialog.ShowDialog($editorForm) -eq "OK") { $iconTextBox.Text = $openFileDialog.FileName }
            $openFileDialog.Dispose()
        })
        $editorForm.Controls.AddRange(@($iconLabel, $iconTextBox, $iconBrowseButton))
    }

    $saveButton = New-Object System.Windows.Forms.Button; $saveButton.Text = "Save"; $saveButton.DialogResult = "OK"; $saveButton.Location = New-Object System.Drawing.Point(350, 150)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(435, 150)
    $editorForm.Controls.AddRange(@($saveButton, $cancelButton))
    
    if ($editorForm.ShowDialog($form) -eq "OK") {
        $newMeta = [ordered]@{}; $newMeta['Author'] = $authorTextBox.Text; $newMeta['Version'] = $versionTextBox.Text
        if ($context.Type -eq "Script") { $newMeta['CustomIconPath'] = $iconTextBox.Text }
        foreach($key in $metadata.Keys) { if (-not $newMeta.ContainsKey($key)) { $newMeta[$key] = $metadata[$key] } }
        $newMeta | ConvertTo-Json | Set-Content -Path $metaFilePath -Encoding UTF8
        Refresh-List -AllTabs; $statusLabel.Text = "Metadata saved for $($item.Text)."
    }
    $editorForm.Dispose()
}

function Show-CleanupOptionsDialog {
    param([string]$Title, [string]$ButtonText)
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = $Title; $dialog.Size = New-Object System.Drawing.Size(450, 280); $dialog.FormBorderStyle = "FixedDialog"; $dialog.StartPosition = "CenterParent"
    
    $masterCheckbox = New-Object System.Windows.Forms.CheckBox; $masterCheckbox.Text = "Automatically clean selected files on exit"; $masterCheckbox.Location = New-Object System.Drawing.Point(20, 20); $masterCheckbox.AutoSize = $true; $masterCheckbox.Checked = $global:AppConfig.GlobalSettings.AutoCleanOnExit
    
    $groupbox = New-Object System.Windows.Forms.GroupBox; $groupbox.Text = "Files to Clean"; $groupbox.Location = New-Object System.Drawing.Point(20, 50); $groupbox.Size = New-Object System.Drawing.Size(400, 100)
    $dashboardCheckbox = New-Object System.Windows.Forms.CheckBox; $dashboardCheckbox.Text = "Web Dashboard (dashboard.html)"; $dashboardCheckbox.Location = New-Object System.Drawing.Point(15, 25); $dashboardCheckbox.AutoSize = $true; $dashboardCheckbox.Checked = $global:AppConfig.GlobalSettings.CleanDashboard
    $metadataCheckbox = New-Object System.Windows.Forms.CheckBox; $metadataCheckbox.Text = "All Metadata (*.meta.json)"; $metadataCheckbox.Location = New-Object System.Drawing.Point(15, 50); $metadataCheckbox.AutoSize = $true; $metadataCheckbox.Checked = $global:AppConfig.GlobalSettings.CleanMetadata
    $configCheckbox = New-Object System.Windows.Forms.CheckBox; $configCheckbox.Text = "App Configuration (Configuration.json)"; $configCheckbox.Location = New-Object System.Drawing.Point(15, 75); $configCheckbox.AutoSize = $true; $configCheckbox.Checked = $global:AppConfig.GlobalSettings.CleanConfig
    
    $showOnStartupCheckbox = New-Object System.Windows.Forms.CheckBox; $showOnStartupCheckbox.Text = "Show this window on next startup"; $showOnStartupCheckbox.Location = New-Object System.Drawing.Point(20, 160); $showOnStartupCheckbox.AutoSize = $true; $showOnStartupCheckbox.Checked = $global:AppConfig.GlobalSettings.ShowSetupOnStartup
    if ($Title -ne "Initial Setup") { $showOnStartupCheckbox.Visible = $false }

    $okButton = New-Object System.Windows.Forms.Button; $okButton.Text = $ButtonText; $okButton.DialogResult = "OK"; $okButton.Location = New-Object System.Drawing.Point(230, 200)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Text = "Cancel"; $cancelButton.DialogResult = "Cancel"; $cancelButton.Location = New-Object System.Drawing.Point(320, 200)
    
    $groupbox.Controls.AddRange(@($dashboardCheckbox, $metadataCheckbox, $configCheckbox)); $dialog.Controls.AddRange(@($masterCheckbox, $groupbox, $showOnStartupCheckbox, $okButton, $cancelButton))
    
    if ($dialog.ShowDialog($form) -eq "OK") { 
        return @{ 
            AutoCleanOnExit = $masterCheckbox.Checked; 
            CleanDashboard = $dashboardCheckbox.Checked; 
            CleanMetadata = $metadataCheckbox.Checked; 
            CleanConfig = $configCheckbox.Checked;
            ShowSetupOnStartup = $showOnStartupCheckbox.Checked
        } 
    }
    return $null
}

function Show-IgnoredFilesManager {
    $context = Get-ActiveLauncherContext
    $managerForm = New-Object System.Windows.Forms.Form
    $managerForm.Text = "Manage Ignored Files for $($context.Type)s"; $managerForm.Size = New-Object System.Drawing.Size(600, 400); $managerForm.FormBorderStyle = "Sizable"; $managerForm.StartPosition = "CenterParent"
    $listBox = New-Object System.Windows.Forms.ListBox; $listBox.Dock = "Fill"; $listBox.Items.AddRange($context.Config.IgnoredFiles)
    $buttonPanel = New-Object System.Windows.Forms.Panel; $buttonPanel.Dock = "Bottom"; $buttonPanel.Height = 40
    $unignoreButton = New-Object System.Windows.Forms.Button; $unignoreButton.Text = "Unignore Selected"; $unignoreButton.Location = New-Object System.Drawing.Point(10, 5); $unignoreButton.AutoSize = $true
    $closeButton = New-Object System.Windows.Forms.Button; $closeButton.Text = "Close"; $closeButton.Location = New-Object System.Drawing.Point(500, 5); $closeButton.Anchor = "Right"
    $unignoreButton.Add_Click({
        if ($listBox.SelectedItem) {
            $context.Config.IgnoredFiles = $context.Config.IgnoredFiles | Where-Object { $_ -ne $listBox.SelectedItem }
            $listBox.Items.Remove($listBox.SelectedItem)
        }
    })
    $closeButton.Add_Click({ $managerForm.Close() })
    $buttonPanel.Controls.AddRange(@($unignoreButton, $closeButton)); $managerForm.Controls.AddRange(@($listBox, $buttonPanel))
    $managerForm.ShowDialog($form)
    Save-Configuration; Refresh-List -AllTabs; $managerForm.Dispose()
}

function Show-ApplicationPathEditor {
    $editorForm = New-Object System.Windows.Forms.Form
    $editorForm.Text = "Configure Script Application Paths"; $editorForm.Size = New-Object System.Drawing.Size(600, 350); $editorForm.FormBorderStyle = "Sizable"; $editorForm.StartPosition = "CenterParent"
    
    $dataGridView = New-Object System.Windows.Forms.DataGridView; $dataGridView.Dock = "Fill"
    $dataGridView.Columns.Add("Extension", "File Type"); $dataGridView.Columns.Add("Path", "Executable Path")
    $dataGridView.Columns["Extension"].ReadOnly = $true; $dataGridView.Columns["Extension"].Width = 100
    $dataGridView.Columns["Path"].AutoSizeMode = "Fill"
    
    $browseColumn = New-Object System.Windows.Forms.DataGridViewButtonColumn; $browseColumn.Name = "Browse"; $browseColumn.Text = "..."; $browseColumn.UseColumnTextForButtonValue = $true
    $browseColumn.Width = 40; $dataGridView.Columns.Add($browseColumn) | Out-Null
    
    foreach ($ext in $global:AppConfig.ScriptLauncher.ApplicationPaths.Keys) {
        $dataGridView.Rows.Add($ext, $global:AppConfig.ScriptLauncher.ApplicationPaths[$ext]) | Out-Null
    }
    
    $dataGridView.Add_CellContentClick({
        param($sender, $e)
        if ($e.ColumnIndex -eq $dataGridView.Columns["Browse"].Index -and $e.RowIndex -ge 0) {
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Filter = "Executables (*.exe)|*.exe|All files (*.*)|*.*"
            if ($openFileDialog.ShowDialog($editorForm) -eq "OK") { $dataGridView.Rows[$e.RowIndex].Cells["Path"].Value = $openFileDialog.FileName }
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
            $ext = $row.Cells["Extension"].Value; $path = $row.Cells["Path"].Value
            if ($ext -and $path) { $global:AppConfig.ScriptLauncher.ApplicationPaths[$ext] = $path }
        }
        Save-Configuration; $statusLabel.Text = "Application paths saved."
    }
    $editorForm.Dispose()
}

function Clean-TemporaryFiles {
    param([bool]$CleanDashboard, [bool]$CleanMetadata, [bool]$CleanConfig)
    $statusLabel.Text = "Cleaning temporary files..."
    if ($CleanMetadata) { 
        $allSourceFolders = $global:AppConfig.GlobalSettings.SourceFolders | Select-Object -Unique
        $allSourceFolders | ForEach-Object { 
            Get-ChildItem -Path $_ -Filter "*.meta.json" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue 
        } 
    }
    if ($CleanDashboard) { Remove-Item -Path (Join-Path -Path $ScriptDir -ChildPath $global:AppConfig.HtmlLauncher.DashboardFile) -Force -ErrorAction SilentlyContinue }
    if ($CleanConfig) { Remove-Item -Path $ConfigSourceFile -Force -ErrorAction SilentlyContinue }
    $statusLabel.Text = "Cleanup complete."; Refresh-List -AllTabs
}

function Run-SelectedScript {
    $context = Get-ActiveLauncherContext
    if ($context.Type -ne "Script" -or $context.ListView.SelectedItems.Count -eq 0) { return }
    $fullPath = $context.ListView.SelectedItems[0].Tag
    $extension = [System.IO.Path]::GetExtension($fullPath).ToLower()
    $statusLabel.Text = "Executing $($context.ListView.SelectedItems[0].Text)..."
    
    $appPath = $global:AppConfig.ScriptLauncher.ApplicationPaths[$extension]
    if (-not $appPath) {
        [System.Windows.Forms.MessageBox]::Show("No application path configured for '$extension' files. Please configure it under Options.", "Error", "OK", "Error"); return
    }

    try {
        $argList = switch ($extension) {
            ".ps1" { "-NoProfile -File `"$fullPath`"" }
            ".py"  { "`"$fullPath`"" }
            default { "/c `"$fullPath`"" }
        }
        Start-Process -FilePath $appPath -ArgumentList $argList -ErrorAction Stop
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to run script with '$appPath':`n$($_.Exception.Message)", "Execution Error", "OK", "Error")
    }
}

function Open-SelectedHtmlProject {
    $context = Get-ActiveLauncherContext
    if ($context.Type -ne "Html" -or $context.ListView.SelectedItems.Count -eq 0) { return }
    $fullPath = $context.ListView.SelectedItems[0].Tag
    # Inject navigation code if enabled
    if ($global:AppConfig.HtmlLauncher.InjectNavBar) {
        $content = Get-Content -Path $fullPath -Raw
        $injectionIdentifier = "<!-- Injected by Universal Launcher -->"
        if ($content -notmatch [regex]::Escape($injectionIdentifier)) {
            $dashboardPath = "file:///$((Join-Path -Path $ScriptDir -ChildPath $global:AppConfig.HtmlLauncher.DashboardFile).Replace('\', '/'))"
            $injectionCode = @"
$injectionIdentifier
<style>.launcher-nav{position:fixed;bottom:15px;right:15px;z-index:9999;display:flex;gap:8px;}.launcher-nav a{font-family:sans-serif;font-size:14px;text-decoration:none;padding:8px 12px;background:rgba(0,0,0,0.7);color:white;border-radius:20px;border:1px solid #555;transition:all .2s;backdrop-filter:blur(5px);}.launcher-nav a:hover{background:rgba(255,255,255,0.9);color:#000;}</style>
<div class="launcher-nav"><a href="#" onclick="window.history.back();return false;">&larr; Back</a><a href="$dashboardPath">Home</a></div>
"@
            $newContent = $content -replace '(?i)</body>', "$injectionCode`n</body>"; Set-Content -Path $fullPath -Value $newContent -Encoding UTF8
        }
    }
    Start-Process -FilePath $fullPath
}

function Generate-HtmlIndex {
    # This function specifically uses the HTML context
    $statusLabel.Text = "Generating web index..."; $form.Cursor = "WaitCursor"; $allItems = @()
    foreach ($item in $htmlListView.Items) { $allItems += [pscustomobject]@{ FileName = $item.Text; FullPath = $item.Tag; Author = $item.SubItems[3].Text } }
    $tileItems = $allItems | ForEach-Object {
        $fileUri = "file:///$($_.FullPath.Replace('\', '/'))"; $authorInfo = if ($_.Author) { "<div class='tile-author'>by $($_.Author)</div>" } else { "" }
        @"
    <a href="$fileUri" class="tile"><div class="preview-container"><iframe src="$fileUri" scrolling="no" sandbox="allow-scripts"></iframe></div><div class="tile-footer"><div class="tile-title">$($_.FileName)</div>$authorInfo</div></a>
"@
    }
    $htmlContent = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Project Launchpad</title><style>:root{--bg:#121212;--text:#e0e0e0;--tile-bg:#1e1e1e;--tile-hover:#2a2a2a;--border:#333;--accent:#3af;}body{font-family:sans-serif;background:var(--bg);color:var(--text);margin:0;padding:20px;}.container{max-width:1400px;margin:0 auto;}.header{text-align:center;margin-bottom:30px;}h1{border-bottom:2px solid var(--accent);display:inline-block;padding-bottom:5px;}.tile-container{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:25px;}.tile{text-decoration:none;color:var(--text);background:var(--tile-bg);border-radius:8px;overflow:hidden;border:1px solid var(--border);transition:all .2s ease;}.tile:hover{transform:translateY(-3px);box-shadow:0 8px 15px #0003;border-color:var(--accent);}.preview-container{width:100%;height:220px;overflow:hidden;background:#000;}.tile iframe{width:1024px;height:768px;transform-origin:top left;border:none;pointer-events:none;transform:scale(calc(320/1024));}.tile-footer{padding:15px;}.tile-title{font-size:1.1em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}.tile-author{font-size:.9em;color:#999;margin-top:5px;}</style></head><body><div class="container"><header class="header"><h1>Project Launchpad</h1></header><main class="tile-container">$($tileItems -join "`n")</main></div></body></html>
"@
    $dashboardPath = Join-Path -Path $ScriptDir -ChildPath $global:AppConfig.HtmlLauncher.DashboardFile; Set-Content -Path $dashboardPath -Value $htmlContent -Encoding UTF8
    $statusLabel.Text = "Successfully generated dashboard."; $form.Cursor = "Default"
    [System.Windows.Forms.MessageBox]::Show("Successfully generated dashboard.", "Success", "OK", "Information"); Start-Process -FilePath $dashboardPath
}

function Update-UIForActiveTab {
    $context = Get-ActiveLauncherContext
    if (-not $context) { return }

    $dashboardButton.Visible = ($context.Type -eq "Html")
    $appPathMenuItem.Visible = ($context.Type -eq "Script")
    
    # Update GroupBy menu to reflect the columns of the active tab
    $groupByMenuItem.DropDownItems.Clear()
    $groupByMenuItem.DropDownItems.Add("None", $null, { Update-Grouping -ColumnIndex -1 }) | Out-Null
    for ($i = 0; $i -lt $context.ListView.Columns.Count; $i++) {
        $columnName = $context.ListView.Columns[$i].Text
        # Skip the placeholder "File Type" column for the HTML tab's menu
        if ($context.Type -eq 'Html' -and $i -eq 1) { continue } 
        $columnIndex = $i
        $menuItem = New-Object System.Windows.Forms.ToolStripMenuItem($columnName, $null, { Update-Grouping -ColumnIndex $columnIndex })
        $menuItem.Tag = $columnIndex
        $groupByMenuItem.DropDownItems.Add($menuItem) | Out-Null
    }
}

function Backup-Settings {
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "JSON Config File (*.json)|*.json"
    $saveFileDialog.FileName = "Configuration_Backup.json"
    $saveFileDialog.Title = "Backup Application Settings"
    if ($saveFileDialog.ShowDialog($form) -eq "OK") {
        try {
            Save-Configuration # Ensure current state is saved before backing up
            Copy-Item -Path $ConfigSourceFile -Destination $saveFileDialog.FileName -Force -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("Settings successfully backed up to:`n$($saveFileDialog.FileName)", "Backup Complete", "OK", "Information")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to backup settings.`nError: $($_.Exception.Message)", "Backup Error", "OK", "Error")
        }
    }
    $saveFileDialog.Dispose()
}

function Restore-Settings {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "JSON Config File (*.json)|*.json"
    $openFileDialog.Title = "Restore Application Settings"
    if ($openFileDialog.ShowDialog($form) -eq "OK") {
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("This will overwrite your current settings and require an application restart. Are you sure you want to continue?", "Confirm Restore", "YesNo", "Warning")
        if ($confirmResult -eq "Yes") {
            try {
                Copy-Item -Path $openFileDialog.FileName -Destination $ConfigSourceFile -Force -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Settings successfully restored. Please restart the application for changes to take effect.", "Restore Complete", "OK", "Information")
                $form.Close()
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to restore settings.`nError: $($_.Exception.Message)", "Restore Error", "OK", "Error")
            }
        }
    }
    $openFileDialog.Dispose()
}


# 4.) Event Handlers
#------------------

# --- Main Form & Tab Control ---
$form.Add_Shown({ Handle-FirstRunAndLoadData; [void][Win32]::ShowWindow([Win32]::GetConsoleWindow(), [Win32]::SW_MINIMIZE) })
$form.Add_FormClosing({ 
    Save-Configuration
    if ($global:AppConfig.GlobalSettings.AutoCleanOnExit) { 
        Clean-TemporaryFiles -CleanDashboard $global:AppConfig.GlobalSettings.CleanDashboard -CleanMetadata $global:AppConfig.GlobalSettings.CleanMetadata -CleanConfig $global:AppConfig.GlobalSettings.CleanConfig
    } 
})
$tabControl.Add_SelectedIndexChanged({ Update-UIForActiveTab })

# --- Menu Items ---
$exitMenuItem.Add_Click({ $form.Close() })
$manageFoldersMenuItem.Add_Click({ Show-SourceManager })
$backupSettingsMenuItem.Add_Click({ Backup-Settings })
$restoreSettingsMenuItem.Add_Click({ Restore-Settings })
$refreshMenuItem.Add_Click({ Refresh-List -AllTabs })
$manageIgnoredMenuItem.Add_Click({ Show-IgnoredFilesManager })
$appPathMenuItem.Add_Click({ Show-ApplicationPathEditor })
$cleanFilesMenuItem.Add_Click({
    $cleanupOptions = Show-CleanupOptionsDialog -Title "Manual File Cleanup" -ButtonText "Clean Selected Files"
    if ($cleanupOptions) { 
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("This action cannot be undone. Are you sure you want to clean the selected files?", "Confirm Cleanup", "YesNo", "Warning")
        if ($confirmResult -eq "Yes") { 
            Clean-TemporaryFiles -CleanDashboard $cleanupOptions.CleanDashboard -CleanMetadata $cleanupOptions.CleanMetadata -CleanConfig $cleanupOptions.CleanConfig 
        } 
    }
})
$cleanupSettingsMenuItem.Add_Click({
    $newSettings = Show-CleanupOptionsDialog -Title "Auto-Cleanup Settings" -ButtonText "Save Settings"
    if ($newSettings) { 
        $global:AppConfig.GlobalSettings.AutoCleanOnExit = $newSettings.AutoCleanOnExit
        $global:AppConfig.GlobalSettings.CleanDashboard = $newSettings.CleanDashboard
        $global:AppConfig.GlobalSettings.CleanMetadata = $newSettings.CleanMetadata
        $global:AppConfig.GlobalSettings.CleanConfig = $newSettings.CleanConfig
        Save-Configuration
        $statusLabel.Text = "Auto-cleanup settings saved." 
    }
})

# --- View Menu ---
$viewByMenuItem.DropDownItems.Add("Details", $null, { $ctx = Get-ActiveLauncherContext; Set-ListView-View -ListView $ctx.ListView -View "Details" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("Tiles", $null, { $ctx = Get-ActiveLauncherContext; Set-ListView-View -ListView $ctx.ListView -View "Tile" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("Large Icons", $null, { $ctx = Get-ActiveLauncherContext; Set-ListView-View -ListView $ctx.ListView -View "LargeIcon" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("Small Icons", $null, { $ctx = Get-ActiveLauncherContext; Set-ListView-View -ListView $ctx.ListView -View "SmallIcon" }) | Out-Null
$viewByMenuItem.DropDownItems.Add("List", $null, { $ctx = Get-ActiveLauncherContext; Set-ListView-View -ListView $ctx.ListView -View "List" }) | Out-Null

# --- Bottom Buttons ---
$refreshButton.Add_Click({ Refresh-List -AllTabs })
$dashboardButton.Add_Click({ Generate-HtmlIndex })
$closeButton.Add_Click({ $form.Close() })

# --- ListView and Context Menus ---
$scriptListView.Add_DoubleClick({ Run-SelectedScript })
$htmlListView.Add_DoubleClick({ Open-SelectedHtmlProject })
$scriptListView.Add_ColumnClick({ param($s, $e); if ($scriptListView.Sorting -eq "Ascending") { $scriptListView.Sorting = "Descending" } else { $scriptListView.Sorting = "Ascending" }; $scriptListView.ListViewItemSorter = New-Object ListViewItemComparer($e.Column, $scriptListView.Sorting) })
$htmlListView.Add_ColumnClick({ param($s, $e); if ($htmlListView.Sorting -eq "Ascending") { $htmlListView.Sorting = "Descending" } else { $htmlListView.Sorting = "Ascending" }; $htmlListView.ListViewItemSorter = New-Object ListViewItemComparer($e.Column, $htmlListView.Sorting) })

$runScriptMenuItem.Add_Click({ Run-SelectedScript })
$editScriptMenuItem.Add_Click({ if ($scriptListView.SelectedItems.Count > 0) { Invoke-Item -Path $scriptListView.SelectedItems[0].Tag }})
$editScriptMetaMenuItem.Add_Click({ Show-MetadataEditor })
$openScriptFolderMenuItem.Add_Click({ if ($scriptListView.SelectedItems.Count > 0) { Invoke-Item -Path (Split-Path -Path $scriptListView.SelectedItems[0].Tag -Parent) } })
$ignoreScriptFileMenuItem.Add_Click({ 
    if ($scriptListView.SelectedItems.Count > 0) { 
        $path = $scriptListView.SelectedItems[0].Tag
        if (-not ($global:AppConfig.ScriptLauncher.IgnoredFiles -contains $path)) {
            $global:AppConfig.ScriptLauncher.IgnoredFiles += $path
        }
        Save-Configuration; Refresh-List
    }
})

$openHtmlMenuItem.Add_Click({ Open-SelectedHtmlProject })
$editHtmlMetaMenuItem.Add_Click({ Show-MetadataEditor })
$openHtmlFolderMenuItem.Add_Click({ if ($htmlListView.SelectedItems.Count > 0) { Invoke-Item -Path (Split-Path -Path $htmlListView.SelectedItems[0].Tag -Parent) } })
$ignoreHtmlFileMenuItem.Add_Click({ 
    if ($htmlListView.SelectedItems.Count > 0) { 
        $path = $htmlListView.SelectedItems[0].Tag
        if (-not ($global:AppConfig.HtmlLauncher.IgnoredFiles -contains $path)) {
            $global:AppConfig.HtmlLauncher.IgnoredFiles += $path
        }
        Save-Configuration; Refresh-List
    }
})


# 5.) Final Assembly and Display
#------------------------------
$form.Add_Load({
    Initialize-Application
    # Trigger the UI update logic to set initial state
    Update-UIForActiveTab
})

try {
    [void]$form.ShowDialog()
} catch {
    [System.Windows.Forms.MessageBox]::Show("An unexpected error occurred:`n`n$($_.Exception.Message)", "Fatal Error", "OK", "Error")
}

# 6.) Cleanup
#-----------
$form.Dispose()
