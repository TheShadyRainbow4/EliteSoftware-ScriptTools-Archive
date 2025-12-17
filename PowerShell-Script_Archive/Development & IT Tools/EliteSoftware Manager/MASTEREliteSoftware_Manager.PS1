# =============================================================================
# PowerShell Winget User Interface v3.6
#
# A modern interface for the Windows Package Manager (winget) with both a
# classic text-based shell mode and a new graphical user interface (GUI).
#
# Author: Gemini (based on script by Zach)
# Version: 3.6
#
# --- FIXES & IMPROVEMENTS (v3.6) ---
# - Added Right-Click Context Menu: A context menu has been added to the
#   results list with advanced sorting and grouping options.
# - Implemented Column Sorting: Users can now click any column header to sort
#   the results. Clicking again reverses the sort order.
# - Implemented Results Grouping: Users can group results by any column
#   via the new context menu, similar to Windows File Explorer.
# =============================================================================

# --- Script Configuration ---
$DefaultScriptTitle = "PowerShell Winget Interface"
$AccentColor = "Cyan"
$WarningColor = "Yellow"
$ErrorColor = "Red"
$SuccessColor = "Green"
$CommandColor = "White"

#region --- GUI MODE ---
# =============================================================================
# GUI MODE - All functions and logic for the graphical interface
# =============================================================================

function Start-GuiMode {
    # --------------------------------------------------------------------------
    # STAGE 1: INITIAL SETUP & ASSEMBLY LOADING
    # --------------------------------------------------------------------------
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName Microsoft.VisualBasic

    # --------------------------------------------------------------------------
    # STAGE 1B: CONFIGURATION MANAGEMENT
    # --------------------------------------------------------------------------
    $configDir = Join-Path $env:APPDATA "PowerShellWingetUI"
    $configPath = Join-Path $configDir "config.json"

    function Load-Configuration {
        if (Test-Path $configPath) {
            try { return Get-Content -Path $configPath -Raw | ConvertFrom-Json }
            catch { return [PSCustomObject]@{ Title = $DefaultScriptTitle; IconPath = $null } }
        }
        return [PSCustomObject]@{ Title = $DefaultScriptTitle; IconPath = $null }
    }

    function Save-Configuration($configObject) {
        if (-not (Test-Path $configDir)) { New-Item -Path $configDir -ItemType Directory | Out-Null }
        $configObject | ConvertTo-Json | Set-Content -Path $configPath
    }

    $config = Load-Configuration

    # --------------------------------------------------------------------------
    # STAGE 2: CREATE ALL GUI CONTROL OBJECTS
    # --------------------------------------------------------------------------
    $form = New-Object System.Windows.Forms.Form
    $menuBar = New-Object System.Windows.Forms.MenuStrip
    $fileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&File")
    $renameMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Rename Utility...")
    $setIconMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Set Custom Icon...")
    $exportMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Export Installed Packages...")
    $importMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Import && Install from List...")
    $exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("E&xit")
    $advancedMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Advanced")
    $viewManifestMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("View Package &Manifest...")
    $resetSourcesMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Reset Winget Sources...")
    $searchLabel = New-Object System.Windows.Forms.Label
    $searchBox = New-Object System.Windows.Forms.TextBox
    $searchButton = New-Object System.Windows.Forms.Button
    $resultsListView = New-Object System.Windows.Forms.ListView
    $logGroupBox = New-Object System.Windows.Forms.GroupBox
    $logTextBox = New-Object System.Windows.Forms.TextBox
    $installButton = New-Object System.Windows.Forms.Button
    $upgradeSelectedButton = New-Object System.Windows.Forms.Button
    $uninstallButton = New-Object System.Windows.Forms.Button
    $detailsButton = New-Object System.Windows.Forms.Button
    $listInstalledButton = New-Object System.Windows.Forms.Button
    $checkForUpgradesButton = New-Object System.Windows.Forms.Button
    $upgradeAllButton = New-Object System.Windows.Forms.Button
    $toggleViewButton = New-Object System.Windows.Forms.Button
    $largeImageList = New-Object System.Windows.Forms.ImageList
    $smallImageList = New-Object System.Windows.Forms.ImageList
    $contextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip
    $sortByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Sort by")
    $groupByMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Group by")
    
    # --------------------------------------------------------------------------
    # STAGE 3: CONFIGURE PROPERTIES OF ALL CONTROLS
    # --------------------------------------------------------------------------
    $form.Text = $config.Title; $form.Size = New-Object System.Drawing.Size(1100, 720); $form.StartPosition = "CenterScreen"; $form.MinimumSize = $form.Size
    if ($config.IconPath -and (Test-Path $config.IconPath) -and ($config.IconPath -like '*.ico')) { try { $form.Icon = New-Object System.Drawing.Icon($config.IconPath) } catch { } }
    
    $fileMenuItem.DropDownItems.AddRange(@($renameMenuItem, $setIconMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $exportMenuItem, $importMenuItem, (New-Object System.Windows.Forms.ToolStripSeparator), $exitMenuItem))
    $advancedMenuItem.DropDownItems.AddRange(@($viewManifestMenuItem, $resetSourcesMenuItem))
    $menuBar.Items.AddRange(@($fileMenuItem, $advancedMenuItem)) | Out-Null
    
    $searchLabel.Text = "Search for Package:"; $searchLabel.Location = New-Object System.Drawing.Point(10, 35); $searchLabel.AutoSize = $true
    $searchBox.Location = New-Object System.Drawing.Point(140, 32); $searchBox.Size = New-Object System.Drawing.Size(690, 20); $searchBox.Anchor = "Top, Left, Right"
    $searchButton.Text = "Search"; $searchButton.Location = New-Object System.Drawing.Point(840, 30); $searchButton.Size = New-Object System.Drawing.Size(90, 30); $searchButton.Anchor = "Top, Right"

    $largeImageList.ImageSize = New-Object System.Drawing.Size(32, 32); $smallImageList.ImageSize = New-Object System.Drawing.Size(16, 16)
    $resultsListView.LargeImageList = $largeImageList; $resultsListView.SmallImageList = $smallImageList
    $resultsListView.Location = New-Object System.Drawing.Point(10, 65); $resultsListView.Size = New-Object System.Drawing.Size(920, 420); $resultsListView.View = "Details"
    $resultsListView.FullRowSelect = $true; $resultsListView.GridLines = $true; $resultsListView.MultiSelect = $false; $resultsListView.Anchor = "Top, Bottom, Left, Right"
    $resultsListView.Columns.Add("Name", 400) | Out-Null; $resultsListView.Columns.Add("ID", 350) | Out-Null
    $resultsListView.Columns.Add("Version", 80) | Out-Null; $resultsListView.Columns.Add("Available", 80) | Out-Null
    $resultsListView.ContextMenuStrip = $contextMenuStrip

    $contextMenuStrip.Items.AddRange(@($sortByMenuItem, $groupByMenuItem)) | Out-Null

    $logGroupBox.Location = New-Object System.Drawing.Point(10, 495); $logGroupBox.Size = New-Object System.Drawing.Size(920, 120); $logGroupBox.Text = "Status Log"; $logGroupBox.Anchor = "Bottom, Left, Right"
    $logTextBox.Location = New-Object System.Drawing.Point(10, 20); $logTextBox.Size = New-Object System.Drawing.Size(900, 90); $logTextBox.Multiline = $true
    $logTextBox.ReadOnly = $true; $logTextBox.ScrollBars = "Vertical"; $logTextBox.Anchor = "Top, Bottom, Left, Right"; $logTextBox.WordWrap = $false
    $logGroupBox.Controls.Add($logTextBox)

    $installButton.Text = "Install Selected"; $installButton.Location = New-Object System.Drawing.Point(195, 625); $installButton.Size = New-Object System.Drawing.Size(130, 40); $installButton.Anchor = "Bottom, Left"
    $upgradeSelectedButton.Text = "Upgrade Selected"; $upgradeSelectedButton.Location = New-Object System.Drawing.Point(335, 625); $upgradeSelectedButton.Size = New-Object System.Drawing.Size(130, 40); $upgradeSelectedButton.Anchor = "Bottom, Left"
    $uninstallButton.Text = "Uninstall Selected"; $uninstallButton.Location = New-Object System.Drawing.Point(475, 625); $uninstallButton.Size = New-Object System.Drawing.Size(130, 40); $uninstallButton.Anchor = "Bottom, Left"
    $detailsButton.Text = "Show Details"; $detailsButton.Location = New-Object System.Drawing.Point(615, 625); $detailsButton.Size = New-Object System.Drawing.Size(130, 40); $detailsButton.Anchor = "Bottom, Left"

    $listInstalledButton.Text = "List All Installed"; $listInstalledButton.Location = New-Object System.Drawing.Point(950, 80); $listInstalledButton.Size = New-Object System.Drawing.Size(130, 40); $listInstalledButton.Anchor = "Top, Right"
    $checkForUpgradesButton.Text = "Check for Upgrades"; $checkForUpgradesButton.Location = New-Object System.Drawing.Point(950, 130); $checkForUpgradesButton.Size = New-Object System.Drawing.Size(130, 40); $checkForUpgradesButton.Anchor = "Top, Right"
    $upgradeAllButton.Text = "Upgrade All"; $upgradeAllButton.Location = New-Object System.Drawing.Point(950, 180); $upgradeAllButton.Size = New-Object System.Drawing.Size(130, 40); $upgradeAllButton.Anchor = "Top, Right"
    $toggleViewButton.Text = "Toggle View"; $toggleViewButton.Location = New-Object System.Drawing.Point(950, 230); $toggleViewButton.Size = New-Object System.Drawing.Size(130, 40); $toggleViewButton.Anchor = "Top, Right"

    # --------------------------------------------------------------------------
    # STAGE 4: DEFINE EVENT HANDLERS & HELPER FUNCTIONS
    # --------------------------------------------------------------------------
    
    # Custom class to handle the logic for sorting ListView columns.
    class ListViewItemComparer : System.Collections.IComparer {
        [int]$ColumnToSort = 0
        [System.Windows.Forms.SortOrder]$OrderOfSort = [System.Windows.Forms.SortOrder]::None
        [int] Compare([object]$x, [object]$y) {
            $itemX = [System.Windows.Forms.ListViewItem]$x
            $itemY = [System.Windows.Forms.ListViewItem]$y
            $compareResult = [string]::Compare($itemX.SubItems[$this.ColumnToSort].Text, $itemY.SubItems[$this.ColumnToSort].Text)
            if ($this.OrderOfSort -eq [System.Windows.Forms.SortOrder]::Ascending) { return $compareResult }
            elseif ($this.OrderOfSort -eq [System.Windows.Forms.SortOrder]::Descending) { return (-$compareResult) }
            else { return 0 }
        }
    }
    $listViewSorter = [ListViewItemComparer]::new()
    $resultsListView.ListViewItemSorter = $listViewSorter

    function Write-Log {
        param([string]$Message, [string]$Type = "INFO")
        $timestamp = Get-Date -Format "HH:mm:ss"
        $logTextBox.AppendText("[$timestamp] $Type`: $Message`r`n")
    }

    function Populate-Icons {
        # This function runs after "List Installed" to find application icons.
        Write-Log -Message "Attempting to find icons for installed packages..."
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; $form.Update()
        $registryPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
        foreach($item in $resultsListView.Items) {
            $packageName = $item.Text; $packageId = $item.SubItems[1].Text; $foundIcon = $false
            foreach ($path in $registryPaths) {
                if ($foundIcon) { break }
                try {
                    $regKey = Get-Item -Path "$path\*" -ErrorAction SilentlyContinue | Where-Object { $_.GetValue("DisplayName") -eq $packageName } | Select-Object -First 1
                    if ($regKey) {
                        $iconPath = $regKey.GetValue("DisplayIcon")
                        if ($iconPath) {
                            $iconPath = ($iconPath -split ',')[0].Trim('"')
                            $iconPath = [System.Environment]::ExpandEnvironmentVariables($iconPath)
                            if (Test-Path $iconPath) {
                                $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
                                if ($icon) {
                                    $largeImageList.Images.Add($packageId, $icon); $smallImageList.Images.Add($packageId, $icon)
                                    $item.ImageKey = $packageId; $foundIcon = $true
                                }
                            }
                        }
                    }
                } catch {}
            }
        }
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        Write-Log -Message "Icon search complete."
    }
    
    function Update-ListViewFromWinget {
        param([scriptblock]$WingetCommand, [string]$StatusMessage, [switch]$FindIcons)
        $largeImageList.Images.Clear(); $smallImageList.Images.Clear()
        Write-Log -Message $StatusMessage
        $resultsListView.Items.Clear(); $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor; $form.Update()
        try {
            $commandOutput = & $WingetCommand | Out-String -Stream
            $headerLineIndex = -1
            for ($i = 0; $i -lt $commandOutput.Count; $i++) { if ($commandOutput[$i] -like '---*') { $headerLineIndex = $i; break } }
            if ($headerLineIndex -ne -1) {
                $dataRows = $commandOutput | Select-Object -Skip ($headerLineIndex + 1)
                foreach ($row in $dataRows) {
                    if ($row.Trim().Length -gt 0) {
                        $columns = $row -split '\s{2,}' | ForEach-Object { $_.Trim() }
                        if ($columns.Count -ge 3) {
                            $name = $columns[0]; $id = $columns[1]; $version = $columns[2]
                            $available = if ($columns.Count -ge 4) { $columns[3] } else { "" }
                            if (-not [string]::IsNullOrWhiteSpace($id)) {
                                $item = New-Object System.Windows.Forms.ListViewItem($name)
                                $item.SubItems.Add($id) | Out-Null; $item.SubItems.Add($version) | Out-Null; $item.SubItems.Add($available) | Out-Null
                                $resultsListView.Items.Add($item) | Out-Null
                            }
                        }
                    }
                }
            }
            Write-Log -Message "Operation complete. Found $($resultsListView.Items.Count) packages."
            if ($FindIcons) { Populate-Icons }
        } catch { Write-Log -Message "An error occurred: $($_.Exception.Message)" -Type "ERROR" }
        finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
    }

    function Run-CommandInNewWindow($command, [switch]$NoExit) {
        $arguments = "-Command `"$command`""; if ($NoExit) { $arguments = "-NoExit " + $arguments }
        Start-Process powershell.exe -ArgumentList $arguments
    }

    function Get-SelectedPackageId {
        if ($resultsListView.SelectedItems.Count -eq 0) { Write-Log -Message "No package selected." -Type "WARN"; return $null }
        return $resultsListView.SelectedItems[0].SubItems[1].Text
    }

    # --- Event Handlers for Menu and Buttons ---

    $resultsListView.add_ColumnClick({
        param($sender, $e)
        if ($e.Column -eq $listViewSorter.ColumnToSort) {
            $listViewSorter.OrderOfSort = if ($listViewSorter.OrderOfSort -eq 'Ascending') { 'Descending' } else { 'Ascending' }
        } else {
            $listViewSorter.ColumnToSort = $e.Column
            $listViewSorter.OrderOfSort = 'Ascending'
        }
        $resultsListView.Sort()
    })

    # Dynamically create context menu items based on ListView columns
    for ($i = 0; $i -lt $resultsListView.Columns.Count; $i++) {
        $colName = $resultsListView.Columns[$i].Text
        $sortItem = New-Object System.Windows.Forms.ToolStripMenuItem($colName)
        $sortItem.Tag = $i
        $sortItem.add_Click({
            $listViewSorter.ColumnToSort = $this.Tag
            $listViewSorter.OrderOfSort = 'Ascending'
            $resultsListView.Sort()
        })
        $sortByMenuItem.DropDownItems.Add($sortItem) | Out-Null

        $groupItem = New-Object System.Windows.Forms.ToolStripMenuItem($colName)
        $groupItem.Tag = $i
        $groupItem.add_Click({
            $resultsListView.Groups.Clear()
            $colIndex = $this.Tag
            foreach ($item in $resultsListView.Items) {
                $groupName = $item.SubItems[$colIndex].Text
                $group = $resultsListView.Groups[$groupName]
                if (-not $group) {
                    $group = New-Object System.Windows.Forms.ListViewGroup($groupName, $groupName)
                    $resultsListView.Groups.Add($group) | Out-Null
                }
                $item.Group = $group
            }
            $resultsListView.ShowGroups = $true
        })
        $groupByMenuItem.DropDownItems.Add($groupItem) | Out-Null
    }
    $groupByMenuItem.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
    $removeGroupingItem = New-Object System.Windows.Forms.ToolStripMenuItem("(None)")
    $removeGroupingItem.add_Click({ $resultsListView.ShowGroups = $false })
    $groupByMenuItem.DropDownItems.Add($removeGroupingItem) | Out-Null

    $renameMenuItem.add_Click({
        $newName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the new name for the utility:", "Rename Utility", $form.Text)
        if (-not [string]::IsNullOrWhiteSpace($newName)) {
            $form.Text = $newName; $config.Title = $newName; Save-Configuration -configObject $config
            Write-Log -Message "Utility renamed to '$newName' and saved."
        }
    })

    $setIconMenuItem.add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Title = "Select an Icon File"; $openFileDialog.Filter = "Icon Files (*.ico)|*.ico"
        if ($openFileDialog.ShowDialog() -eq "OK") {
            try {
                $form.Icon = New-Object System.Drawing.Icon($openFileDialog.FileName)
                $config.IconPath = $openFileDialog.FileName; Save-Configuration -configObject $config
                Write-Log -Message "Custom icon has been set and saved."
            } catch { [System.Windows.Forms.MessageBox]::Show("The selected file is not a valid icon.", "Invalid Icon", "OK", "Error") }
        }
    })

    $exitMenuItem.add_Click({ $form.Close() })

    $searchButton.add_Click({
        Update-ListViewFromWinget -WingetCommand { winget search $searchBox.Text --accept-source-agreements } -StatusMessage "Searching for '$($searchBox.Text)'..."
    })

    $listInstalledButton.add_Click({
        Update-ListViewFromWinget -WingetCommand { winget list --accept-source-agreements } -StatusMessage "Listing all installed packages..." -FindIcons
    })

    $checkForUpgradesButton.add_Click({
        Update-ListViewFromWinget -WingetCommand { winget upgrade --accept-source-agreements } -StatusMessage "Checking for available upgrades..."
    })

    $toggleViewButton.add_Click({ if ($resultsListView.View -eq 'Details') { $resultsListView.View = 'Tile' } else { $resultsListView.View = 'Details' } })

    $installButton.add_Click({
        $pkgId = Get-SelectedPackageId
        if ($pkgId) {
            Write-Log "Preparing to install $pkgId..."; Run-CommandInNewWindow "winget install --id `"$pkgId`" --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit
        }
    })
    
    $exportMenuItem.add_Click({
        Write-Log "Exporting list of installed packages..."
        $installedPackages = winget list --accept-source-agreements | Out-String
        $packageIds = ($installedPackages -split '\r?\n' | Select-String -Pattern '^[^\s-]' | ForEach-Object { ($_ -split '\s{2,}') | Select -Index 1 }).Trim()
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog; $saveFileDialog.Title = "Export Installed Packages"; $saveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"; $saveFileDialog.FileName = "winget-packages.txt"
        if ($saveFileDialog.ShowDialog() -eq "OK") {
            try { $packageIds | Set-Content -Path $saveFileDialog.FileName; Write-Log -Message "Successfully exported $($packageIds.Count) packages to $($saveFileDialog.FileName)" -Type "SUCCESS" }
            catch { Write-Log -Message "Failed to export package list: $($_.Exception.Message)" -Type "ERROR" }
        }
    })

    $importMenuItem.add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Title = "Select Package List to Import"; $openFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
        if ($openFileDialog.ShowDialog() -eq "OK") {
            try {
                $packageIds = Get-Content $openFileDialog.FileName
                $commandChain = $packageIds | ForEach-Object { "winget install --id `"$_`" --accept-package-agreements --accept-source-agreements;" }
                $fullCommand = $commandChain -join " "
                if ([System.Windows.Forms.MessageBox]::Show("This will attempt to install $($packageIds.Count) packages. Continue?", "Confirm Import", "YesNo", "Question") -eq 'Yes') {
                    Write-Log -Message "Starting batch install of $($packageIds.Count) packages..."; Run-CommandInNewWindow "$fullCommand; Read-Host 'Batch install process complete. Press Enter to close.'" -NoExit
                }
            } catch { Write-Log -Message "Failed to import package list: $($_.Exception.Message)" -Type "ERROR" }
        }
    })

    $viewManifestMenuItem.add_Click({
        $pkgId = Get-SelectedPackageId
        if (-not $pkgId) { return }
        try {
            Write-Log -Message "Fetching manifest for $pkgId..."
            $manifest = winget show --id $pkgId --manifest --accept-source-agreements | Out-String
            $manifestForm = New-Object System.Windows.Forms.Form; $manifestForm.Text = "Manifest: $pkgId"; $manifestForm.Size = New-Object System.Drawing.Size(600, 800); $manifestForm.StartPosition = "CenterParent"
            $textBox = New-Object System.Windows.Forms.TextBox; $textBox.Multiline = $true; $textBox.ReadOnly = $true; $textBox.ScrollBars = "Both"; $textBox.Dock = "Fill"; $textBox.Font = New-Object System.Drawing.Font("Consolas", 10); $textBox.Text = $manifest
            $manifestForm.Controls.Add($textBox); $manifestForm.Show()
        } catch { Write-Log -Message "Failed to fetch manifest: $($_.Exception.Message)" -Type "ERROR" }
    })

    $resetSourcesMenuItem.add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("This will reset your Winget sources to the default configuration. This can fix issues but will remove any custom sources you have added. Are you sure?", "Confirm Source Reset", "YesNo", "Warning") -eq 'Yes') {
            Write-Log -Message "Resetting Winget sources..."; Run-CommandInNewWindow "winget source reset --force; Read-Host 'Source reset complete. Press Enter to close.'" -NoExit
        }
    })

    $upgradeSelectedButton.add_Click({
        $pkgId = Get-SelectedPackageId
        if ($pkgId) { Write-Log "Preparing to upgrade $pkgId..."; Run-CommandInNewWindow "winget upgrade --id `"$pkgId`" --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit }
    })

    $uninstallButton.add_Click({
        $pkgId = Get-SelectedPackageId
        if ($pkgId) { Write-Log "Preparing to uninstall $pkgId..."; Run-CommandInNewWindow "winget uninstall --id `"$pkgId`" --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit }
    })

    $detailsButton.add_Click({
        $pkgId = Get-SelectedPackageId
        if ($pkgId) { Write-Log "Getting details for $pkgId..."; Run-CommandInNewWindow "winget show --id `"$pkgId`"; Read-Host 'Press Enter to close.'" -NoExit }
    })

    $upgradeAllButton.add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("This will attempt to upgrade ALL available packages. Are you sure?", "Confirm Upgrade All", "YesNo", "Warning") -eq 'Yes') {
            Write-Log "Starting 'upgrade --all' process..."; Run-CommandInNewWindow "winget upgrade --all --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit
        }
    })

    $searchBox.add_KeyDown({ if ($_.KeyCode -eq "Enter") { $searchButton.PerformClick() } })
    
    Write-Log -Message "Welcome to the $($config.Title)! Ready for commands."

    # --------------------------------------------------------------------------
    # STAGE 5: ADD CONTROLS TO THE FORM
    # --------------------------------------------------------------------------
    $form.Controls.Add($menuBar); $form.Controls.Add($searchLabel); $form.Controls.Add($searchBox); $form.Controls.Add($searchButton)
    $form.Controls.Add($resultsListView); $form.Controls.Add($logGroupBox); $form.Controls.Add($installButton)
    $form.Controls.Add($uninstallButton); $form.Controls.Add($detailsButton); $form.Controls.Add($upgradeSelectedButton)
    $form.Controls.Add($listInstalledButton); $form.Controls.Add($upgradeAllButton); $form.Controls.Add($checkForUpgradesButton)
    $form.Controls.Add($toggleViewButton)
    $form.MainMenuStrip = $menuBar

    # --------------------------------------------------------------------------
    # STAGE 6: SHOW THE FORM
    # --------------------------------------------------------------------------
    [void]$form.ShowDialog()
}
#endregion

#region --- SHELL MODE ---
# =============================================================================
# SHELL MODE - All the original text-based functions
# =============================================================================

function Write-BoxedTitle {
    param([string]$Title, [string]$Color = $AccentColor, [int]$Width = 63)
    $padding = $Width - $Title.Length - 2; $leftPad = [math]::Floor($padding / 2); $rightPad = [math]::Ceiling($padding / 2)
    Write-Host ("+" + ("-" * ($Width)) + "+") -ForegroundColor $Color
    Write-Host ("| " + (" " * $leftPad) + $Title + (" " * $rightPad) + "|") -ForegroundColor $Color
    Write-Host ("+" + ("-" * ($Width)) + "+") -ForegroundColor $Color
}

function Show-MainMenu {
    Clear-Host; Write-BoxedTitle -Title $DefaultScriptTitle; Write-Host ""
    Write-Host "   [1] Search for a package"; Write-Host "   [2] List all installed packages"
    Write-Host "   [3] Check for available upgrades"; Write-Host "   [4] Upgrade a package by ID"
    Write-Host "   [5] Upgrade ALL possible packages"; Write-Host "   [6] Show details for a specific package ID"
    Write-Host "   [7] Uninstall a package by ID"; Write-Host "   [8] View Winget sources"; Write-Host ""
    Write-Host "   [Q] Quit"; Write-Host ""; Write-Host ("-" * 65) -ForegroundColor $AccentColor
}

function Process-And-Display-WingetResults {
    param([string[]]$WingetOutput)
    $packages = @(); $headerLineIndex = -1
    for ($i = 0; $i -lt $WingetOutput.Count; $i++) { if ($WingetOutput[$i] -like '---*') { $headerLineIndex = $i; break } }
    if ($headerLineIndex -ne -1) {
        $dataRows = $WingetOutput | Select-Object -Skip ($headerLineIndex + 1)
        foreach ($row in $dataRows) {
            if ($row.Trim().Length -gt 0) {
                $columns = $row -split '\s{2,}' | ForEach-Object { $_.Trim() }
                if ($columns.Count -ge 3) {
                    $packageObject = [PSCustomObject]@{ Name = $columns[0]; Id = $columns[1]; Version = $columns[2] }
                    if ($columns.Count -ge 4) { Add-Member -InputObject $packageObject -MemberType NoteProperty -Name "Available" -Value $columns[3] }
                    $packages += $packageObject
                }
            }
        }
    }
    if ($packages.Count -gt 0) { Write-Host ""; $packages | Format-Table -AutoSize; Write-Host "Found $($packages.Count) packages." -ForegroundColor $SuccessColor }
    else { Write-Host "No packages found." -ForegroundColor $WarningColor }
}

function Run-SimpleWingetCommand {
    param([string]$Title, [string]$Command, [string[]]$Arguments, [switch]$ShowAsTable)
    Clear-Host; Write-BoxedTitle -Title $Title
    Write-Host "[*] Running: winget $Command $Arguments" -ForegroundColor $AccentColor
    $output = & winget.exe $Command @Arguments | Out-String -Stream
    if ($ShowAsTable) { Process-And-Display-WingetResults -WingetOutput $output } else { $output | Write-Host }
    Read-Host "Press Enter to return..."
}

function Start-ShellMode {
    while ($true) {
        Show-MainMenu; $selection = Read-Host "Enter your choice"
        switch ($selection) {
            '1' { $searchTerm = Read-Host "Enter search term"; if($searchTerm){ Clear-Host; Write-BoxedTitle 'Search Results'; Process-And-Display-WingetResults -WingetOutput (winget search $searchTerm --accept-source-agreements | Out-String -Stream); Read-Host } }
            '2' { Run-SimpleWingetCommand -Title "List Installed Packages" -Command "list" -Arguments "--accept-source-agreements" -ShowAsTable }
            '3' { Run-SimpleWingetCommand -Title "Available Package Upgrades" -Command "upgrade" -Arguments "--accept-source-agreements" -ShowAsTable }
            '4' { $pkgId = Read-Host "Enter Package ID to upgrade"; if($pkgId){ Run-SimpleWingetCommand -Title "Upgrading $pkgId" -Command "upgrade" -Arguments "--id", $pkgId, "--accept-package-agreements", "--accept-source-agreements" } }
            '5' { if ((Read-Host "Confirm upgrade ALL? [Y/N]") -match '^y') { Run-SimpleWingetCommand -Title "Upgrading All Packages" -Command "upgrade" -Arguments "--all", "--accept-package-agreements", "--accept-source-agreements" } }
            '6' { $pkgId = Read-Host "Enter Package ID for details"; if ($pkgId) { Run-SimpleWingetCommand -Title "Details for $pkgId" -Command "show" -Arguments "--id", $pkgId, "--exact" } }
            '7' { $pkgId = Read-Host "Enter Package ID to uninstall"; if ($pkgId -and (Read-Host "Confirm uninstall of '$pkgId'? [Y/N]") -match '^y') { Run-SimpleWingetCommand -Title "Uninstalling $pkgId" -Command "uninstall" -Arguments "--id", $pkgId, "--accept-package-agreements", "--accept-source-agreements" } }
            '8' { Run-SimpleWingetCommand -Title "Winget Source List" -Command "source" -Arguments "list" -ShowAsTable }
            'q' { break }
        }
    }
}
#endregion

# =============================================================================
# --- SCRIPT EXECUTION LAUNCHER ---
# =============================================================================
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: winget command not found. Please install 'App Installer' from the Microsoft Store." -ForegroundColor $ErrorColor
    Read-Host "Press Enter to exit."; exit
}
Clear-Host
Write-Host "Welcome to the $DefaultScriptTitle" -ForegroundColor $AccentColor
$modeChoice = Read-Host "GUI [1] or Shell [2]?"
switch ($modeChoice) {
    '1' { Start-GuiMode }
    '2' { Start-ShellMode }
    default { Write-Host "Invalid selection." -ForegroundColor $ErrorColor }
}