Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Helper Functions ---

# Function to test if winget is installed and accessible
function Test-Winget {
    try {
        # Attempt to run winget and check its exit code (0 for success)
        # Using -ErrorAction SilentlyContinue to prevent script termination on error
        $null = & winget --version -ErrorAction SilentlyContinue
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Get-WingetPackages is defined here, but will be passed as a string to the job
# for execution in its isolated scope.
function Get-WingetPackages {
    param (
        [string]$SearchTerm = ""
    )
    # Use winget's JSON output for reliable parsing
    # Requires winget version 1.1 or newer.
    try {
        $wingetCmd = "winget"
        $wingetArgs = "search", "--output", "JSON"
        if (![string]::IsNullOrWhiteSpace($SearchTerm)) {
            $wingetArgs += @("--query", $SearchTerm)
        }
        
        # Execute winget and capture JSON output
        # Use -ErrorAction Stop to ensure the catch block handles command errors
        $wingetOutputJson = & $wingetCmd $wingetArgs -ErrorAction Stop | Out-String
        $wingetOutput = $wingetOutputJson | ConvertFrom-Json

        # Extract relevant package info (Name, Id, Version, Source)
        $packages = @()
        if ($wingetOutput -and $wingetOutput.Packages) {
            foreach ($pkg in $wingetOutput.Packages) {
                $packages += [PSCustomObject]@{
                    Name    = $pkg.Name
                    Id      = $pkg.Id
                    Version = $pkg.Versions[0].Version  # Get the first version
                    Source  = $pkg.Sources[0].Name      # Get the first source
                }
            }
        }
        return $packages
    }
    catch {
        Write-Error "Failed to get winget packages: $($_.Exception.Message)"
        # Return an empty array on error so the main script can continue gracefully
        return @()
    }
}

# Define the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Program Manager"
$form.Size = New-Object System.Drawing.Size(700, 550) # Increased size
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create a menu strip and add some items to it
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.Dock = [System.Windows.Forms.DockStyle]::Top
$form.Controls.Add($menuStrip)

$menuItemFile = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemFile.Text = "&File"
$menuStrip.Items.Add($menuItemFile)

$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "E&xit"
$exitMenuItem.Name = "exitToolStripMenuItem"
$exitMenuItem.Add_Click({ $form.Close() }) # Add exit functionality
$menuItemFile.DropDownItems.Add($exitMenuItem)

$menuItemPrograms = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemPrograms.Text = "&Programs"
$menuStrip.Items.Add($menuItemPrograms)

$viewProgramsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$viewProgramsMenuItem.Text = "&View All Installed Programs"
$viewProgramsMenuItem.Add_Click({ 
    # Clear search box and list to show all
    $searchTextBox.Text = ""
    # Call the search function (which now loads all if search box is empty)
    & $searchButton.PerformClick()
})
$menuItemPrograms.DropDownItems.Add($viewProgramsMenuItem)

$searchProgramsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$searchProgramsMenuItem.Text = "&Search for a Program"
# This would typically activate the search panel or set focus, 
# but it's redundant with the text box already visible.
$menuItemPrograms.DropDownItems.Add($searchProgramsMenuItem)

$menuItemSettings = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemSettings.Text = "&Settings"
$menuStrip.Items.Add($menuItemSettings)

$changeSourceMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$changeSourceMenuItem.Text = "Change &Winget Source"
$menuItemSettings.DropDownItems.Add($changeSourceMenuItem)

$clearCacheMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$clearCacheMenuItem.Text = "Clear &Download Cache"
$menuItemSettings.DropDownItems.Add($clearCacheMenuItem)

# --- Search Panel ---
$searchPanel = New-Object System.Windows.Forms.Panel
$searchPanel.Location = New-Object System.Drawing.Point(10, $menuStrip.Height + 5) # Adjust location below menu strip
$searchPanel.Size = New-Object System.Drawing.Size($form.Width - 40, 30) # Adjust width
$searchPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top
$form.Controls.Add($searchPanel)

$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "Search for a program:"
$searchLabel.Location = New-Object System.Drawing.Point(0, 7) # Relative to panel
$searchLabel.AutoSize = $true
$searchPanel.Controls.Add($searchLabel)

$searchTextBox = New-Object System.Windows.Forms.TextBox
$searchTextBox.Location = New-Object System.Drawing.Point($searchLabel.Right + 5, 5) # Relative to panel, right of label
$searchTextBox.Size = New-Object System.Drawing.Size($searchPanel.Width - $searchLabel.Width - 100, 20)
$searchTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$searchPanel.Controls.Add($searchTextBox)

$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = "Search"
$searchButton.Location = New-Object System.Drawing.Point($searchPanel.Width - 70, 3) # Relative to panel, right-aligned
$searchButton.Size = New-Object System.Drawing.Size(65, 25)
$searchButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right
$searchPanel.Controls.Add($searchButton)

# --- Program List Panel (ListView) ---
$programListPanel = New-Object System.Windows.Forms.Panel
$programListPanel.Location = New-Object System.Drawing.Point(10, $searchPanel.Bottom + 10) # Below search panel
$programListPanel.Size = New-Object System.Drawing.Size($form.Width - 40, $form.Height - $searchPanel.Bottom - 100) # Fill remaining space
$programListPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($programListPanel)

$listView1 = New-Object System.Windows.Forms.ListView
$listView1.Dock = [System.Windows.Forms.DockStyle]::Fill
$listView1.View = [System.Windows.Forms.View]::Details
$listView1.FullRowSelect = $true # Makes entire row selectable
$listView1.MultiSelect = $true   # Allow multi-selection for install
$programListPanel.Controls.Add($listView1)

# Create column headers for the program list
$listView1.Columns.Add("Name", 200) | Out-Null
$listView1.Columns.Add("Id", 200) | Out-Null
$listView1.Columns.Add("Version", 100) | Out-Null
$listView1.Columns.Add("Source", 80) | Out-Null

# --- Install Panel ---
$installPanel = New-Object System.Windows.Forms.Panel
$installPanel.Location = New-Object System.Drawing.Point(10, $form.Height - 70) # Position near bottom
$installPanel.Size = New-Object System.Drawing.Size($form.Width - 40, 30)
$installPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($installPanel)

# Label for instructions
$packageLabel = New-Object System.Windows.Forms.Label
$packageLabel.Text = "Select programs from list above to install:"
$packageLabel.Location = New-Object System.Drawing.Point(0, 7) # Relative to panel
$packageLabel.AutoSize = $true
$installPanel.Controls.Add($packageLabel)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install Selected"
$installButton.Location = New-Object System.Drawing.Point($installPanel.Width - 110, 3) # Relative to panel, right-aligned
$installButton.Size = New-Object System.Drawing.Size(100, 25)
$installButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right
$installPanel.Controls.Add($installButton)

# --- Event Handlers ---

# Function to populate the ListView
function Populate-ListView ($packages) {
    # Ensure we are on the UI thread if this is called from a job/runspace
    if ($listView1.InvokeRequired) {
        $listView1.Invoke([Action[object]]{ param($p) Populate-ListView $p }, $packages)
        return
    }

    $listView1.BeginUpdate()
    $listView1.Items.Clear() # Clear existing items
    foreach ($package in $packages) {
        $listViewItem = New-Object System.Windows.Forms.ListViewItem($package.Name)
        $listViewItem.SubItems.Add($package.Id)
        $listViewItem.SubItems.Add($package.Version)
        $listViewItem.SubItems.Add($package.Source)
        # Store the full package object in Tag for later use (e.g., installation)
        $listViewItem.Tag = $package
        $listView1.Items.Add($listViewItem)
    }
    $listView1.EndUpdate()
    # Auto-resize columns based on content if items exist, then header size
    if ($listView1.Items.Count -gt 0) {
        $listView1.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
    }
    $listView1.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
}

# Search button click event
$searchButton.Click += {
    $searchTerm = $searchTextBox.Text
    $listView1.Items.Clear()
    $listView1.Columns[0].Text = "Loading..." # Provide feedback

    # Pre-check for winget accessibility
    if (-not (Test-Winget)) {
        [System.Windows.Forms.MessageBox]::Show(
            "***Shell***: Winget (Windows Package Manager) is not found or not accessible. Please ensure it's installed and in your system's PATH. Cannot perform search.",
            "Winget Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $listView1.Columns[0].Text = "Name" # Reset header
        return # Exit the event handler
    }

    # Get the definition of Get-WingetPackages to pass to the job
    $wingetFunctionDef = (Get-Command -Name Get-WingetPackages -CommandType Function).Definition
    $job = $null # Initialize job variable for finally block

    try {
        $job = Start-Job -ScriptBlock {
            param($searchTerm, $functionDefinition)
            
            # Define Get-WingetPackages within the job's scope
            Invoke-Expression $functionDefinition
            
            # Now call the function within the job's scope
            Get-WingetPackages -SearchTerm $searchTerm
        } -ArgumentList $searchTerm, $wingetFunctionDef
        
        # Wait for the job to complete (this will still freeze the UI briefly if winget is slow)
        Wait-Job $job | Out-Null
        
        # Check job state and errors
        if ($job.State -eq 'Failed' -or $job.HasErrors) {
            $errorOutput = Receive-Job $job -ErrorVariable jobErrors -Keep
            $errorMessage = if ($jobErrors) {
                "$($jobErrors | ForEach-Object { $_.Exception.Message })"
            } else {
                "Unknown error during winget search."
            }
            [System.Windows.Forms.MessageBox]::Show(
                "***Shell***: The winget search operation failed in the background. Error: $errorMessage",
                "Winget Search Failed",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            Populate-ListView @() # Clear list on error
        } else {
            $resultPackages = Receive-Job $job -Keep # Receive results from the job
            Populate-ListView $resultPackages
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "***Shell***: An unexpected error occurred while trying to run the search job: $($_.Exception.Message)",
            "Search Job Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        Populate-ListView @() # Clear list on unexpected error
    }
    finally {
        # Clean up the job whether it succeeded or failed
        if ($job) {
            Remove-Job $job -Force
        }
        $listView1.Columns[0].Text = "Name" # Reset header text
    }
}

# Install button click event
$installButton.Click += {
    if ($listView1.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("***Shell***: Please select at least one program to install.", "No Program Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    $selectedProgramIds = @()
    foreach ($item in $listView1.SelectedItems) {
        # Retrieve the full package object stored in the Tag property
        $packageToInstall = $item.Tag
        if ($packageToInstall -and $packageToInstall.Id) {
            $selectedProgramIds += $packageToInstall.Id
        }
    }

    if ($selectedProgramIds.Count -gt 0) {
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to install the following programs:nn" + ($selectedProgramIds -join "n"),
            "Confirm Installation",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            foreach ($packageId in $selectedProgramIds) {
                try {
                    [System.Windows.Forms.MessageBox]::Show("***Shell***: Installing $packageId...", "Installation", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    # Use --accept-package-agreements for silent install
                    # Removed redundant -Confirm:$false
                    winget install --id $packageId --exact --accept-package-agreements
                    [System.Windows.Forms.MessageBox]::Show("***Shell***: $packageId installed successfully!", "Installation Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("***Shell***: Failed to install $packageId: $($_.Exception.Message)", "Installation Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
        }
    }
}

# --- Initial Load ---
# Call the search button's click method to load all programs initially
$form.Add_Shown({
    # PerformClick runs the click event, effectively starting the initial load
    $searchButton.PerformClick()
})

# Show the form and wait for user input
$form.ShowDialog()

# Clean up any remaining jobs (important for Start-Job)
Get-Job | Remove-Job -Force