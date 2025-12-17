# =============================================================================
# PowerShell Winget User Interface v2.2
#
# A modern interface for the Windows Package Manager (winget) with both a
# classic text-based shell mode and a new graphical user interface (GUI).
#
# Author: Gemini (based on script by Zach)
# Version: 2.2
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
    Add-Type -AssemblyName System.Drawing

    # --- Create the main window (Form) ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$ScriptTitle - GUI Mode"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.MinimumSize = $form.Size

    # --- Create Top Panel for Search Controls ---
    $searchLabel = New-Object System.Windows.Forms.Label
    $searchLabel.Text = "Search for Package:"
    $searchLabel.Location = New-Object System.Drawing.Point(10, 15)
    $searchLabel.AutoSize = $true

    $searchBox = New-Object System.Windows.Forms.TextBox
    $searchBox.Location = New-Object System.Drawing.Point(140, 12)
    $searchBox.Size = New-Object System.Drawing.Size(430, 20)
    $searchBox.Anchor = "Top, Left, Right"

    $searchButton = New-Object System.Windows.Forms.Button
    $searchButton.Text = "Search"
    $searchButton.Location = New-Object System.Drawing.Point(580, 10)
    $searchButton.Size = New-Object System.Drawing.Size(90, 25)
    $searchButton.Anchor = "Top, Right"

    # --- Create the Main Results List (ListView) ---
    $resultsListView = New-Object System.Windows.Forms.ListView
    $resultsListView.Location = New-Object System.Drawing.Point(10, 45)
    $resultsListView.Size = New-Object System.Drawing.Size(765, 420)
    $resultsListView.View = "Details"
    $resultsListView.FullRowSelect = $true
    $resultsListView.GridLines = $true
    $resultsListView.MultiSelect = $false
    $resultsListView.Anchor = "Top, Bottom, Left, Right"
    $resultsListView.Columns.Add("Name", 350) | Out-Null
    $resultsListView.Columns.Add("ID", 250) | Out-Null
    $resultsListView.Columns.Add("Version", 120) | Out-Null

    # --- Create Bottom Panel for Action Buttons ---
    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Text = "Install Selected"
    $installButton.Location = New-Object System.Drawing.Point(10, 475)
    $installButton.Size = New-Object System.Drawing.Size(120, 30)
    $installButton.Anchor = "Bottom, Left"
    $installButton.Enabled = $false # Disabled until an item is selected

    $detailsButton = New-Object System.Windows.Forms.Button
    $detailsButton.Text = "Show Details"
    $detailsButton.Location = New-Object System.Drawing.Point(140, 475)
    $detailsButton.Size = New-Object System.Drawing.Size(120, 30)
    $detailsButton.Anchor = "Bottom, Left"
    $detailsButton.Enabled = $false # Disabled until an item is selected

    $uninstallButton = New-Object System.Windows.Forms.Button
    $uninstallButton.Text = "Uninstall Selected"
    $uninstallButton.Location = New-Object System.Drawing.Point(270, 475)
    $uninstallButton.Size = New-Object System.Drawing.Size(120, 30)
    $uninstallButton.Anchor = "Bottom, Left"
    $uninstallButton.Enabled = $false # Disabled until an item is selected

    # --- Create Side Panel for Other Actions ---
    $listInstalledButton = New-Object System.Windows.Forms.Button
    $listInstalledButton.Text = "List Installed"
    $listInstalledButton.Location = New-Object System.Drawing.Point(655, 80)
    $listInstalledButton.Size = New-Object System.Drawing.Size(120, 30)
    $listInstalledButton.Anchor = "Top, Right"

    $upgradeAllButton = New-Object System.Windows.Forms.Button
    $upgradeAllButton.Text = "Upgrade All"
    $upgradeAllButton.Location = New-Object System.Drawing.Point(655, 120)
    $upgradeAllButton.Size = New-Object System.Drawing.Size(120, 30)
    $upgradeAllButton.Anchor = "Top, Right"

    # --- Status Bar ---
    $statusBar = New-Object System.Windows.Forms.StatusBar
    $statusBar.Text = "Ready. Enter a search term or list installed packages."
    
    # --- Function to run commands in a new window to prevent GUI freezing ---
    function Run-CommandInNewWindow($command, [switch]$NoExit) {
        $arguments = "-Command `"$command`""
        if ($NoExit) {
            $arguments = "-NoExit " + $arguments
        }
        Start-Process powershell.exe -ArgumentList $arguments
    }

    # --- EVENT HANDLERS (What controls do when you interact with them) ---

    $searchButton.Add_Click({
        $searchTerm = $searchBox.Text
        if ([string]::IsNullOrWhiteSpace($searchTerm)) {
            $statusBar.Text = "Error: Please enter a search term."
            return
        }
        $statusBar.Text = "Searching for '$searchTerm'..."
        $resultsListView.Items.Clear()
        $form.Cursor = "WaitCursor"

        # Run winget search and parse the output
        try {
            $searchResults = winget search $searchTerm | Out-String
            # Find the line with dashes '---' to identify where the data starts
            $headerLineIndex = $searchResults.IndexOf("---")
            if ($headerLineIndex -gt 0) {
                # Get the string part that contains only data rows
                $dataRows = $searchResults.Substring($headerLineIndex).Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
                # The first row is the dashes, so skip it
                foreach ($row in $dataRows | Select-Object -Skip 1) {
                    if ($row.Trim().Length -gt 0) {
                        # A simple way to parse fixed-width output. May need adjustment.
                        $name = $row.Substring(0, 35).Trim()
                        $id = $row.Substring(36, 30).Trim()
                        $version = $row.Substring(66).Trim()

                        if (-not [string]::IsNullOrWhiteSpace($id)) {
                             $item = New-Object System.Windows.Forms.ListViewItem($name)
                            $item.SubItems.Add($id) | Out-Null
                            $item.SubItems.Add($version) | Out-Null
                            $resultsListView.Items.Add($item) | Out-Null
                        }
                    }
                }
            }
            $statusBar.Text = "Search complete. Found $($resultsListView.Items.Count) results."
        } catch {
            $statusBar.Text = "An error occurred during search."
        } finally {
            $form.Cursor = "Default"
        }
    })

    $resultsListView.Add_SelectedIndexChanged({
        if ($resultsListView.SelectedItems.Count -gt 0) {
            $installButton.Enabled = $true
            $detailsButton.Enabled = $true
            $uninstallButton.Enabled = $true
        } else {
            $installButton.Enabled = $false
            $detailsButton.Enabled = $false
            $uninstallButton.Enabled = $false
        }
    })

    $installButton.Add_Click({
        $selectedItem = $resultsListView.SelectedItems[0]
        $packageName = $selectedItem.SubItems[0].Text
        $packageId = $selectedItem.SubItems[1].Text
        
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to install `'$packageName`' (`'$packageId`')?", "Confirm Installation", "YesNo", "Question")

        if ($confirmResult -eq "Yes") {
            $statusBar.Text = "Starting installation for $packageId..."
            $command = "winget install --id `"$packageId`" --exact --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close'"
            Run-CommandInNewWindow -Command $command -NoExit
        }
    })
    
    $uninstallButton.Add_Click({
        $selectedItem = $resultsListView.SelectedItems[0]
        $packageName = $selectedItem.SubItems[0].Text
        $packageId = $selectedItem.SubItems[1].Text
        
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("You are about to PERMANENTLY UNINSTALL `'$packageName`' (`'$packageId`').`n`nAre you absolutely sure?", "Confirm Uninstallation", "YesNo", "Warning")

        if ($confirmResult -eq "Yes") {
            $statusBar.Text = "Starting uninstallation for $packageId..."
            $command = "winget uninstall --id `"$packageId`" --exact --accept-source-agreements; Read-Host 'Press Enter to close'"
            Run-CommandInNewWindow -Command $command -NoExit
        }
    })

    $detailsButton.Add_Click({
        $packageId = $resultsListView.SelectedItems[0].SubItems[1].Text
        $statusBar.Text = "Showing details for $packageId..."
        $command = "winget show --id `"$packageId`" --exact; Read-Host 'Press Enter to close'"
        Run-CommandInNewWindow -Command $command -NoExit
    })

    $listInstalledButton.Add_Click({
        $statusBar.Text = "Listing all installed packages... This may take a moment."
        $resultsListView.Items.Clear()
        $form.Cursor = "WaitCursor"

        # Run winget list and parse the output, same as search
        try {
            $listResults = winget list | Out-String
            # Find the line with dashes '---' to identify where the data starts
            $headerLineIndex = $listResults.IndexOf("---")
            if ($headerLineIndex -gt 0) {
                # Get the string part that contains only data rows
                $dataRows = $listResults.Substring($headerLineIndex).Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
                # The first row is the dashes, so skip it
                foreach ($row in $dataRows | Select-Object -Skip 1) {
                    if ($row.Trim().Length -gt 0) {
                        # A simple way to parse fixed-width output. May need adjustment.
                        $name = $row.Substring(0, 35).Trim()
                        $id = $row.Substring(36, 30).Trim()
                        $version = $row.Substring(66).Trim()
                        
                        if (-not [string]::IsNullOrWhiteSpace($id)) {
                             $item = New-Object System.Windows.Forms.ListViewItem($name)
                            $item.SubItems.Add($id) | Out-Null
                            $item.SubItems.Add($version) | Out-Null
                            $resultsListView.Items.Add($item) | Out-Null
                        }
                    }
                }
            }
            $statusBar.Text = "Listing complete. Found $($resultsListView.Items.Count) installed packages."
        } catch {
            $statusBar.Text = "An error occurred while listing packages."
        } finally {
            $form.Cursor = "Default"
        }
    })

    $upgradeAllButton.Add_Click({
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("This will attempt to upgrade ALL packages. This can take a long time.`n`nAre you sure you want to proceed?", "Confirm Upgrade All", "YesNo", "Warning")
        if ($confirmResult -eq "Yes") {
            $statusBar.Text = "Starting upgrade all process in new window..."
            $command = "winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements; Read-Host 'Press Enter to close'"
            Run-CommandInNewWindow -Command $command -NoExit
        }
    })

    # Add all the created controls to the form
    $form.Controls.AddRange(@(
        $searchLabel, $searchBox, $searchButton, $resultsListView,
        $installButton, $detailsButton, $uninstallButton,
        $listInstalledButton, $upgradeAllButton, $statusBar
    ))

    # Add key down event to searchbox to allow pressing Enter to search
    $searchBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            $searchButton.PerformClick()
        }
    })

    # Show the form
    [void]$form.ShowDialog()
}

#endregion

#region --- SHELL MODE ---
# =============================================================================
# SHELL MODE - All the original text-based functions
# =============================================================================

# Helper function to draw a standardized boxed title
function Write-BoxedTitle {
    param(
        [string]$Title,
        [string]$Color = $AccentColor,
        [int]$Width = 63
    )
    $padding = $Width - $Title.Length - 4
    $leftPad = [math]::Floor($padding / 2)
    $rightPad = [math]::Ceiling($padding / 2)
    
    Write-Host ("+" + ("-" * ($Width - 2)) + "+") -ForegroundColor $Color
    Write-Host ("|" + (" " * $leftPad) + $Title + (" " * $rightPad) + "|") -ForegroundColor $Color
    Write-Host ("+" + ("-" * ($Width - 2)) + "+") -ForegroundColor $Color
}

function Show-MainMenu {
    Clear-Host
    Write-BoxedTitle -Title $ScriptTitle
    Write-Host ""
    Write-Host "   [1] Search for a package"
    Write-Host "   [2] List all explicitly installed packages"
    Write-Host "   [3] Upgrade all possible packages"
    Write-Host "   [4] Show details for a specific package ID"
    Write-Host "   [5] Uninstall a package by ID"
    Write-Host "   [6] View Winget sources"
    Write-Host ""
    Write-Host "   [Q] Quit"
    Write-Host ""
    Write-Host ("-" * 63) -ForegroundColor $AccentColor
}

# New function to process and display winget results in a formatted table
function Process-And-Display-WingetResults {
    param(
        [string[]]$WingetOutput
    )

    $packages = @()
    $headerLineIndex = $WingetOutput.IndexOf("---")
    if ($headerLineIndex -gt 0) {
        $dataRows = $WingetOutput | Select-Object -Skip ($headerLineIndex + 1)
        foreach ($row in $dataRows) {
            if ($row.Trim().Length -gt 0) {
                $name = $row.Substring(0, 35).Trim()
                $id = $row.Substring(36, 30).Trim()
                $version = $row.Substring(66).Trim()
                
                if (-not [string]::IsNullOrWhiteSpace($id)) {
                    $packages += [PSCustomObject]@{
                        Name    = $name
                        Id      = $id
                        Version = $version
                    }
                }
            }
        }
    }

    if ($packages.Count -eq 0) {
        Write-Host "[!] No packages found." -ForegroundColor $WarningColor
        return
    }

    # Ask user for sorting preference
    Write-Host ""
    Write-Host "Sort results by:" -ForegroundColor $AccentColor
    Write-Host "  1. Name (Default)"
    Write-Host "  2. ID"
    $sortChoice = Read-Host "Enter your choice [1-2]"
    
    $sortProperty = "Name" # Default sort
    if ($sortChoice -eq '2') {
        $sortProperty = "Id"
    }

    Write-Host ""
    $packages | Sort-Object $sortProperty | Format-Table -AutoSize
    Write-Host "Found $($packages.Count) packages." -ForegroundColor $SuccessColor
}


function Search-And-Install {
    while ($true) {
        Clear-Host
        Write-BoxedTitle -Title "Winget Package Search"
        Write-Host ""
        $searchTerm = Read-Host "Enter search term (or 'back' to return to menu)"
        
        if ($searchTerm -eq 'back') { break }
        if ([string]::IsNullOrWhiteSpace($searchTerm)) {
            Write-Host "[!] No search term entered. Please try again." -ForegroundColor $WarningColor
            Start-Sleep -Seconds 2
            continue
        }

        Write-Host ""
        Write-Host "[*] Searching winget for '$searchTerm'..." -ForegroundColor $SuccessColor
        $searchResults = winget search $searchTerm
        
        Process-And-Display-WingetResults -WingetOutput $searchResults

        while ($true) {
            Write-Host ""
            Write-Host "What would you like to do?" -ForegroundColor $AccentColor
            Write-Host "  1. Install a package from these results"
            Write-Host "  2. Start a new search"
            Write-Host "  3. Return to Main Menu"
            $choice = Read-Host "Enter your choice [1, 2, or 3]"

            switch ($choice) {
                '1' { Install-Package }
                '2' { break }
                '3' { return }
                default { Write-Host "[!] Invalid option." -ForegroundColor $ErrorColor }
            }
        }
    }
}

function Install-Package {
    Write-Host ""
    $packageId = Read-Host "Enter the EXACT Package ID to install (or 'back' to return)"
    if ($packageId -eq 'back') { return }
    if ([string]::IsNullOrWhiteSpace($packageId)) {
        Write-Host "[!] No Package ID entered." -ForegroundColor $WarningColor
        Start-Sleep -Seconds 2
        return
    }

    $confirmation = Read-Host "You are about to install '$packageId'. Confirm? [Y/N]"
    if ($confirmation -notmatch '^y') {
        Write-Host "[*] Installation cancelled." -ForegroundColor $WarningColor
        return
    }

    Write-Host ""
    Write-Host "[*] Installing '$packageId'... Please wait." -ForegroundColor $SuccessColor
    winget install --id "$packageId" --exact --accept-package-agreements --accept-source-agreements
    Write-Host "[*] Installation attempt for '$packageId' has finished." -ForegroundColor $SuccessColor
    Write-Host "--- Check the output above for success or errors ---"
    Read-Host "Press Enter to continue..."
}

function Run-SimpleWingetCommand {
    param(
        [string]$Title,
        [string]$Command,
        [string[]]$Arguments,
        [switch]$ShowAsTable
    )
    Clear-Host
    Write-BoxedTitle -Title $Title
    Write-Host ""
    Write-Host "[*] Running command: winget $Command..." -ForegroundColor $SuccessColor
    
    $output = if ($Arguments) {
        winget.exe $Command $Arguments
    } else {
        winget.exe $Command
    }
    
    if ($ShowAsTable) {
        Process-And-Display-WingetResults -WingetOutput $output
    } else {
        # For commands that don't produce a table (like upgrade, show, etc)
        $output
    }

    Write-Host ""
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
            '3' {
                Clear-Host
                Write-BoxedTitle "Upgrade All Packages"
                Write-Host "[!] WARNING: This will attempt to upgrade ALL installed packages." -ForegroundColor $WarningColor
                $confirm = Read-Host "Are you absolutely sure you want to proceed? [Y/N]"
                if ($confirm -match '^y') {
                    Run-SimpleWingetCommand -Title "Upgrading All Packages" -Command "upgrade" -Arguments "--all", "--accept-package-agreements", "--accept-source-agreements"
                } else {
                    Write-Host "[*] Upgrade process cancelled." -ForegroundColor $WarningColor
                    Start-Sleep -Seconds 2
                }
            }
            '4' {
                Clear-Host
                Write-BoxedTitle "Show Package Details"
                $pkgId = Read-Host "Enter the EXACT Package ID to show details for"
                if (-not [string]::IsNullOrWhiteSpace($pkgId)) {
                    Run-SimpleWingetCommand -Title "Details for $pkgId" -Command "show" -Arguments "--id", $pkgId, "--exact"
                }
            }
            '5' {
                Clear-Host
                Write-BoxedTitle "Uninstall a Package"
                $pkgId = Read-Host "Enter the EXACT Package ID to uninstall"
                 if (-not [string]::IsNullOrWhiteSpace($pkgId)) {
                    $confirm = Read-Host "[!] You are about to PERMANENTLY uninstall '$pkgId'. Are you sure? [Y/N]"
                    if ($confirm -match '^y') {
                        Run-SimpleWingetCommand -Title "Uninstalling $pkgId" -Command "uninstall" -Arguments "--id", $pkgId, "--exact", "--accept-source-agreements"
                    } else {
                        Write-Host "[*] Uninstall cancelled." -ForegroundColor $WarningColor
                        Start-Sleep -Seconds 2
                    }
                }
            }
            '6' { Run-SimpleWingetCommand -Title "Winget Source List" -Command "source" -Arguments "list" }
            'q' {
                Write-Host "Exiting script. Goodbye!"
                break
            }
            default {
                Write-Host "[!] '$selection' is not a valid option. Please try again." -ForegroundColor $ErrorColor
                Start-Sleep -Seconds 2
            }
        }
    }
}
#endregion

# =============================================================================
# --- SCRIPT EXECUTION LAUNCHER---
# =============================================================================

# First, check if winget exists
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Clear-Host
    Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor $ErrorColor
    Write-Host "!!! ERROR: winget command not found." -ForegroundColor $ErrorColor
    Write-Host "!!! This script requires the Windows Package Manager (winget)." -ForegroundColor $ErrorColor
    Write-Host "!!! Please get 'App Installer' from the Microsoft Store." -ForegroundColor $ErrorColor
    Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor $ErrorColor
    Read-Host "Press Enter to exit."
    exit
}

# Ask the user which mode they want to run
Clear-Host
Write-Host "Welcome to the $ScriptTitle" -ForegroundColor $AccentColor
Write-Host "------------------------------------" -ForegroundColor $AccentColor
Write-Host ""
Write-Host "Which interface would you like to use?"
Write-Host "  [1] Shell Mode (Text-based in this window)"
Write-Host "  [2] GUI Mode (Graphical window with clickable buttons)"
Write-Host ""
$modeChoice = Read-Host "Enter your choice [1 or 2]"

switch ($modeChoice) {
    '1' { Start-ShellMode }
    '2' { Start-GuiMode }
    default { Write-Host "Invalid selection. Exiting." -ForegroundColor $ErrorColor }
}
