# =============================================================================
# PowerShell Winget User Interface v2.5
#
# A modern interface for the Windows Package Manager (winget) with both a
# classic text-based shell mode and a new graphical user interface (GUI).
#
# Author: Gemini (based on script by Zach)
# Version: 2.5
#
# --- FIXES & IMPROVEMENTS (v2.5) ---
# - Fixed critical error: "Cannot find an overload for 'FindIndex'". Replaced
#   the method with a more compatible loop-based approach to ensure it works
#   across different PowerShell versions. This resolves the search failure.
# - Fixed GUI layout issue where buttons on the right were cut off. The main
#   window has been widened to provide adequate space.
# - Adjusted size and position of right-hand buttons for better visibility
#   and usability, preventing them from being clipped by the window edge.
# =============================================================================

# --- Script Configuration ---
$ScriptTitle = "PowerShell Winget Interface"
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
    # Load the necessary .NET assemblies for GUI creation
    Add-Type -AssemblyName System.Windows.Forms
	[System.Windows.Forms.Application]::EnableVisualStyles()
    Add-Type -AssemblyName System.Drawing

    # Create the main window (Form)
    # FIXED: Increased window width to prevent controls from being cut off.
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$ScriptTitle - GUI Mode"
    $form.Size = New-Object System.Drawing.Size(980, 700) 
    $form.StartPosition = "CenterScreen"
    $form.MinimumSize = $form.Size

    # --- Top Panel for Search Controls ---
    $searchLabel = New-Object System.Windows.Forms.Label
    $searchLabel.Text = "Search for Package:"
    $searchLabel.Location = New-Object System.Drawing.Point(10, 15)
    $searchLabel.AutoSize = $true

    $searchBox = New-Object System.Windows.Forms.TextBox
    $searchBox.Location = New-Object System.Drawing.Point(140, 12)
    $searchBox.Size = New-Object System.Drawing.Size(570, 20) # Adjusted width
    $searchBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    $searchButton = New-Object System.Windows.Forms.Button
    $searchButton.Text = "Search"
    $searchButton.Location = New-Object System.Drawing.Point(720, 10)
    $searchButton.Size = New-Object System.Drawing.Size(90, 25)
    $searchButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    # --- Main Results List (ListView) ---
    $resultsListView = New-Object System.Windows.Forms.ListView
    $resultsListView.Location = New-Object System.Drawing.Point(10, 45)
    $resultsListView.Size = New-Object System.Drawing.Size(810, 480) # Adjusted size
    $resultsListView.View = "Details"
    $resultsListView.FullRowSelect = $true
    $resultsListView.GridLines = $true
    $resultsListView.MultiSelect = $false
    $resultsListView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $resultsListView.Columns.Add("Name", 350) | Out-Null
    $resultsListView.Columns.Add("ID", 280) | Out-Null
    $resultsListView.Columns.Add("Version", 80) | Out-Null
    $resultsListView.Columns.Add("Available", 80) | Out-Null

    # --- Bottom Panel for Action Buttons ---
    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Text = "Install Selected"
    $installButton.Location = New-Object System.Drawing.Point(260, 535)
    $installButton.Size = New-Object System.Drawing.Size(130, 30)
    $installButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    $upgradeSelectedButton = New-Object System.Windows.Forms.Button
    $upgradeSelectedButton.Text = "Upgrade Selected"
    $upgradeSelectedButton.Location = New-Object System.Drawing.Point(400, 535)
    $upgradeSelectedButton.Size = New-Object System.Drawing.Size(130, 30)
    $upgradeSelectedButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    $uninstallButton = New-Object System.Windows.Forms.Button
    $uninstallButton.Text = "Uninstall Selected"
    $uninstallButton.Location = New-Object System.Drawing.Point(540, 535)
    $uninstallButton.Size = New-Object System.Drawing.Size(130, 30)
    $uninstallButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    $detailsButton = New-Object System.Windows.Forms.Button
    $detailsButton.Text = "Show Details"
    $detailsButton.Location = New-Object System.Drawing.Point(680, 535)
    $detailsButton.Size = New-Object System.Drawing.Size(130, 30)
    $detailsButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    # --- Right Side Panel for Other Actions ---
    # FIXED: Adjusted location and size of buttons to prevent them from being cut off.
    $listInstalledButton = New-Object System.Windows.Forms.Button
    $listInstalledButton.Text = "List All Installed"
    $listInstalledButton.Location = New-Object System.Drawing.Point(830, 80)
    $listInstalledButton.Size = New-Object System.Drawing.Size(130, 35)
    $listInstalledButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    $checkForUpgradesButton = New-Object System.Windows.Forms.Button
    $checkForUpgradesButton.Text = "Check for Upgrades"
    $checkForUpgradesButton.Location = New-Object System.Drawing.Point(830, 125)
    $checkForUpgradesButton.Size = New-Object System.Drawing.Size(130, 35)
    $checkForUpgradesButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    $upgradeAllButton = New-Object System.Windows.Forms.Button
    $upgradeAllButton.Text = "Upgrade All"
    $upgradeAllButton.Location = New-Object System.Drawing.Point(830, 170)
    $upgradeAllButton.Size = New-Object System.Drawing.Size(130, 35)
    $upgradeAllButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    # --- Status Bar ---
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = "Ready. Enter a search term or select an action from the right."
    $statusStrip.Items.Add($statusLabel) | Out-Null

    # --- Helper Functions ---

    function Update-ListViewFromWinget {
        param([scriptblock]$WingetCommand, [string]$StatusMessage)
        
        $statusLabel.Text = $StatusMessage
        $resultsListView.Items.Clear()
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $form.Update()

        try {
            $commandOutput = & $WingetCommand | Out-String -Stream
            
            # FIXED: Replaced [array]::FindIndex with a more compatible 'for' loop
            # to prevent crashing on different PowerShell versions.
            $headerLineIndex = -1
            for ($i = 0; $i -lt $commandOutput.Count; $i++) {
                if ($commandOutput[$i] -like '---*') {
                    $headerLineIndex = $i
                    break
                }
            }

            if ($headerLineIndex -ne -1) {
                $dataRows = $commandOutput | Select-Object -Skip ($headerLineIndex + 1)
                foreach ($row in $dataRows) {
                    if ($row.Trim().Length -gt 0) {
                        $columns = $row -split '\s{2,}' | ForEach-Object { $_.Trim() }
                        if ($columns.Count -ge 3) {
                            $name = $columns[0]
                            $id = $columns[1]
                            $version = $columns[2]
                            $available = if ($columns.Count -ge 4) { $columns[3] } else { "" }

                            if (-not [string]::IsNullOrWhiteSpace($id)) {
                                $item = New-Object System.Windows.Forms.ListViewItem($name)
                                $item.SubItems.Add($id) | Out-Null
                                $item.SubItems.Add($version) | Out-Null
                                $item.SubItems.Add($available) | Out-Null
                                $resultsListView.Items.Add($item) | Out-Null
                            }
                        }
                    }
                }
            }
            $statusLabel.Text = "Operation complete. Found $($resultsListView.Items.Count) packages."
        }
        catch {
            $statusLabel.Text = "An error occurred: $($_.Exception.Message)"
        }
        finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }

    function Run-CommandInNewWindow($command, [switch]$NoExit) {
        $arguments = "-Command `"$command`""
        if ($NoExit) { $arguments = "-NoExit " + $arguments }
        Start-Process pwsh.exe -ArgumentList $arguments
    }

    function Get-SelectedPackageId {
        if ($resultsListView.SelectedItems.Count -eq 0) {
            $statusLabel.Text = "Error: No package selected."
            return $null
        }
        return $resultsListView.SelectedItems[0].SubItems[1].Text
    }

    # --- EVENT HANDLERS ---

    $searchButton.Add_Click({
        $searchTerm = $searchBox.Text
        if ([string]::IsNullOrWhiteSpace($searchTerm)) {
            $statusLabel.Text = "Error: Please enter a search term."
            return
        }
        Update-ListViewFromWinget -WingetCommand { winget search $searchTerm } -StatusMessage "Searching for '$searchTerm'..."
    })

    $listInstalledButton.Add_Click({
        Update-ListViewFromWinget -WingetCommand { winget list } -StatusMessage "Listing all installed packages..."
    })

    $checkForUpgradesButton.Add_Click({
        Update-ListViewFromWinget -WingetCommand { winget upgrade } -StatusMessage "Checking for available upgrades..."
    })

    $installButton.Add_Click({
        $packageId = Get-SelectedPackageId
        if ($packageId) {
            $statusLabel.Text = "Preparing to install $packageId..."
            Run-CommandInNewWindow "winget install --id `"$packageId`" --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit
        }
    })

    $upgradeSelectedButton.Add_Click({
        $packageId = Get-SelectedPackageId
        if ($packageId) {
            $statusLabel.Text = "Preparing to upgrade $packageId..."
            Run-CommandInNewWindow "winget upgrade --id `"$packageId`" --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit
        }
    })

    $uninstallButton.Add_Click({
        $packageId = Get-SelectedPackageId
        if ($packageId) {
            $statusLabel.Text = "Preparing to uninstall $packageId..."
            Run-CommandInNewWindow "winget uninstall --id `"$packageId`"; Read-Host 'Press Enter to close.'" -NoExit
        }
    })

    $detailsButton.Add_Click({
        $packageId = Get-SelectedPackageId
        if ($packageId) {
            $statusLabel.Text = "Getting details for $packageId..."
            Run-CommandInNewWindow "winget show --id `"$packageId`"; Read-Host 'Press Enter to close.'" -NoExit
        }
    })

    $upgradeAllButton.Add_Click({
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("This will attempt to upgrade ALL available packages. This can take a long time. Are you sure you want to proceed?", "Confirm Upgrade All", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirmResult -eq 'Yes') {
            $statusLabel.Text = "Starting 'upgrade --all' process in a new window..."
            Run-CommandInNewWindow "winget upgrade --all --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close.'" -NoExit
        } else {
            $statusLabel.Text = "Upgrade all operation cancelled."
        }
    })
    
    $form.Controls.AddRange(@(
        $searchLabel, $searchBox, $searchButton, $resultsListView,
        $installButton, $uninstallButton, $detailsButton, $upgradeSelectedButton,
        $listInstalledButton, $upgradeAllButton, $checkForUpgradesButton, $statusStrip
    ))

    $searchBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") { $searchButton.PerformClick() }
    })

    [void]$form.ShowDialog()
}
#endregion

#region --- SHELL MODE ---
# =============================================================================
# SHELL MODE - All the original text-based functions
# =============================================================================

function Write-BoxedTitle {
    param([string]$Title, [string]$Color = $AccentColor, [int]$Width = 63)
    $padding = $Width - $Title.Length - 2
    $leftPad = [math]::Floor($padding / 2)
    $rightPad = [math]::Ceiling($padding / 2)
    Write-Host ("+" + ("-" * ($Width)) + "+") -ForegroundColor $Color
    Write-Host ("| " + (" " * $leftPad) + $Title + (" " * $rightPad) + "|") -ForegroundColor $Color
    Write-Host ("+" + ("-" * ($Width)) + "+") -ForegroundColor $Color
}

function Show-MainMenu {
    Clear-Host
    Write-BoxedTitle -Title $ScriptTitle
    Write-Host ""
    Write-Host "   [1] Search for a package"
    Write-Host "   [2] List all installed packages"
    Write-Host "   [3] Check for available upgrades"
    Write-Host "   [4] Upgrade a package by ID"
    Write-Host "   [5] Upgrade ALL possible packages"
    Write-Host "   [6] Show details for a specific package ID"
    Write-Host "   [7] Uninstall a package by ID"
    Write-Host "   [8] View Winget sources"
    Write-Host ""
    Write-Host "   [Q] Quit"
    Write-Host ""
    Write-Host ("-" * 65) -ForegroundColor $AccentColor
}

function Process-And-Display-WingetResults {
    param([string[]]$WingetOutput)
    $packages = @()
    $headerLineIndex = -1
    for ($i = 0; $i -lt $WingetOutput.Count; $i++) {
        if ($WingetOutput[$i] -like '---*') {
            $headerLineIndex = $i
            break
        }
    }

    if ($headerLineIndex -ne -1) {
        $dataRows = $WingetOutput | Select-Object -Skip ($headerLineIndex + 1)
        foreach ($row in $dataRows) {
            if ($row.Trim().Length -gt 0) {
                $columns = $row -split '\s{2,}' | ForEach-Object { $_.Trim() }
                if ($columns.Count -ge 3) {
                    $packageObject = [PSCustomObject]@{
                        Name    = $columns[0]
                        Id      = $columns[1]
                        Version = $columns[2]
                    }
                    if ($columns.Count -ge 4) {
                        Add-Member -InputObject $packageObject -MemberType NoteProperty -Name "Available" -Value $columns[3]
                    }
                    $packages += $packageObject
                }
            }
        }
    }

    if ($packages.Count -gt 0) {
        Write-Host ""
        $packages | Format-Table -AutoSize
        Write-Host "Found $($packages.Count) packages." -ForegroundColor $SuccessColor
    } else {
        Write-Host "No packages found matching the criteria." -ForegroundColor $WarningColor
    }
}

function Search-And-Install {
    while ($true) {
        Clear-Host
        Write-BoxedTitle -Title "Winget Package Search"
        $searchTerm = Read-Host "Enter search term(s), or 'back' to return"
        if ($searchTerm -eq 'back') { break }
        if ([string]::IsNullOrWhiteSpace($searchTerm)) { continue }
        Write-Host "[*] Searching..." -ForegroundColor $AccentColor
        $searchResults = winget search $searchTerm | Out-String -Stream
        Process-And-Display-WingetResults -WingetOutput $searchResults
        Read-Host "Press Enter to return to the search prompt"
    }
}

function Install-Package {
    param([string]$Title = "Install a Package")
    Clear-Host
    Write-BoxedTitle -Title $Title
    $pkgId = Read-Host "Enter the EXACT Package ID to install"
    if (-not [string]::IsNullOrWhiteSpace($pkgId)) {
        Write-Host "[*] Attempting to install '$pkgId'..." -ForegroundColor $SuccessColor
        winget install --id $pkgId --accept-package-agreements --accept-source-agreements
        Read-Host "Press Enter to return to the main menu..."
    }
}

function Upgrade-Package {
    param([string]$Title = "Upgrade a Package")
    Clear-Host
    Write-BoxedTitle -Title $Title
    $pkgId = Read-Host "Enter the EXACT Package ID to upgrade"
    if (-not [string]::IsNullOrWhiteSpace($pkgId)) {
        Write-Host "[*] Attempting to upgrade '$pkgId'..." -ForegroundColor $SuccessColor
        winget upgrade --id $pkgId --accept-package-agreements --accept-source-agreements
        Read-Host "Press Enter to return to the main menu..."
    }
}

function Run-SimpleWingetCommand {
    param([string]$Title, [string]$Command, [string[]]$Arguments, [switch]$ShowAsTable)
    Clear-Host
    Write-BoxedTitle -Title $Title
    Write-Host "[*] Running command: winget $Command $Arguments..." -ForegroundColor $AccentColor
    $output = & winget.exe $Command @Arguments | Out-String -Stream
    if ($ShowAsTable) { Process-And-Display-WingetResults -WingetOutput $output }
    else { $output | Write-Host }
    Write-Host "--- Command Finished ---" -ForegroundColor $AccentColor
    Read-Host "Press Enter to return to the main menu..."
}

function Start-ShellMode {
    while ($true) {
        Show-MainMenu
        $selection = Read-Host "Enter your choice"
        switch ($selection) {
            '1' { Search-And-Install }
            '2' { Run-SimpleWingetCommand -Title "List Installed Packages" -Command "list" -ShowAsTable }
            '3' { Run-SimpleWingetCommand -Title "Available Package Upgrades" -Command "upgrade" -ShowAsTable }
            '4' { Upgrade-Package }
            '5' {
                Clear-Host
                Write-BoxedTitle "Upgrade All Packages"
                Write-Host "[!] WARNING: This will attempt to upgrade ALL installed packages." -ForegroundColor $WarningColor
                $confirm = Read-Host "Are you absolutely sure you want to proceed? [Y/N]"
                if ($confirm -match '^y') {
                    winget upgrade --all --accept-package-agreements --accept-source-agreements
                    Read-Host "Press Enter to return to menu."
                } else { Write-Host "[*] Upgrade process cancelled." -ForegroundColor $WarningColor; Start-Sleep -Seconds 2 }
            }
            '6' {
                $pkgId = Read-Host "Enter the EXACT Package ID to show details for"
                if (-not [string]::IsNullOrWhiteSpace($pkgId)) {
                    Run-SimpleWingetCommand -Title "Details for $pkgId" -Command "show" -Arguments @("--id", $pkgId, "--exact")
                }
            }
            '7' {
                $pkgId = Read-Host "Enter the EXACT Package ID to uninstall"
                if (-not [string]::IsNullOrWhiteSpace($pkgId)) {
                    $confirm = Read-Host "[!] You are about to PERMANENTLY uninstall '$pkgId'. Are you sure? [Y/N]"
                    if ($confirm -match '^y') {
                        Run-SimpleWingetCommand -Title "Uninstalling $pkgId" -Command "uninstall" -Arguments @("--id", $pkgId, "--exact", "--accept-source-agreements")
                    } else { Write-Host "[*] Uninstall cancelled." -ForegroundColor $WarningColor; Start-Sleep -Seconds 2 }
                }
            }
            '8' { Run-SimpleWingetCommand -Title "Winget Source List" -Command "source" -Arguments "list" }
            'q' { Write-Host "Exiting script. Goodbye!"; break }
            default { Write-Host "[!] '$selection' is not a valid option." -ForegroundColor $ErrorColor; Start-Sleep -Seconds 2 }
        }
    }
}
#endregion

# =============================================================================
# --- SCRIPT EXECUTION LAUNCHER ---
# =============================================================================

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Clear-Host
    Write-Host "!!! ERROR: winget command not found." -ForegroundColor $ErrorColor
    Write-Host "!!! This script requires 'App Installer' from the Microsoft Store." -ForegroundColor $ErrorColor
    Read-Host "Press Enter to exit."; exit
}

Clear-Host
Write-Host "Welcome to the $ScriptTitle" -ForegroundColor $AccentColor
Write-Host "------------------------------------" -ForegroundColor $AccentColor
Write-Host ""
Write-Host "Which interface would you like to use?"
Write-Host "  [1] Shell Mode (Text-based in this window)"
Write-Host "  [2] GUI Mode   (Graphical window with clickable buttons)"
Write-Host ""
$modeChoice = Read-Host "Enter your choice [1 or 2]"
switch ($modeChoice) {
    '1' { Start-ShellMode }
    '2' { Start-GuiMode }
    default { Write-Host "Invalid selection. Exiting." -ForegroundColor $ErrorColor }
}
