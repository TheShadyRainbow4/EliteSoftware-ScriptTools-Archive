# Import necessary modules
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Program Manager"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Create a menu strip and add some items to it
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.Dock = [System.Windows.Forms.DockStyle]::Top
$form.Controls.Add($menuStrip)

$menuItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem1.Text = "File"
$menuItem1.DropDownItems.AddRange(@(
    (New-Object System.Windows.Forms.ToolStripMenuItem).Text = "Exit"
)
$menuItem1.Name = "exitToolStripMenuItem"

$menuItem2 = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem2.Text = "Programs"
$menuItem2.DropDownItems.AddRange(@(
    (New-Object System.Windows.Forms.ToolStripMenuItem).Text = "View Installed Programs"
    (New-Object System.Windows.Forms.ToolStripMenuItem).Text = "Search for a Program"
)
$menuItem2.Name = "programsToolStripMenuItem"

$menuItem3 = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItem3.Text = "Settings"
$menuItem3.DropDownItems.AddRange(@(
    (New-Object System.Windows.Forms.ToolStripMenuItem).Text = "Change Winget Source"
    (New-Object System.Windows.Forms.ToolStripMenuItem).Text = "Clear Download Cache"
)
$menuItem3.Name = "settingsToolStripMenuItem"

$menuStrip.Items.Add($menuItem1)
$menuStrip.Items.Add($menuItem2)
$menuStrip.Items.Add($menuItem3)

# Create a panel to hold the program list
$programListPanel = New-Object System.Windows.Forms.Panel
$programListPanel.Location = New-Object System.Drawing.Point(10, 100)
$programListPanel.Size = New-Object System.Drawing.Size(580, 200)
$form.Controls.Add($programListPanel)

# Create a list view to hold the program list
$listView1 = New-Object System.Windows.Forms.ListView
$listView1.Dock = [System.Windows.Forms.DockStyle]::Fill
$listView1.View = [System.Windows.Forms.View]::Details
$listView1.MultiSelect = $false
$programListPanel.Controls.Add($listView1)

# Create a column header for the program list
$listView1.Columns.Add("Name") | Out-Null
$listView1.Columns.Add("Version") | Out-Null

# Load installed programs into the list view
$wingetOutput = winget search --all
foreach ($package in $wingetOutput) {
    if ($package -match "^Package Name: "){
        $packageInfo = $package.Split(":")[1].Trim()
        $name = $packageInfo.Split(",")[0]
        $version = $packageInfo.Split(",")[2]

        $listViewItem = New-Object System.Windows.Forms.ListViewItem($name)
        $listViewItem.SubItems.Add($version)

        $listView1.Items.Add($listViewItem) | Out-Null
    }
}

# Create a panel to hold the search controls
$searchPanel = New-Object System.Windows.Forms.Panel
$searchPanel.Location = New-Object System.Drawing.Point(10, 20)
$searchPanel.Size = New-Object System.Drawing.Size(580, 30)
$form.Controls.Add($searchPanel)

# Create a label and text box for searching programs
$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "Search for a program:"
$searchLabel.Location = New-Object System.Drawing.Point(10, 10)
$searchPanel.Controls.Add($searchLabel)

$searchTextBox = New-Object System.Windows.Forms.TextBox
$searchTextBox.Location = New-Object System.Drawing.Point(130, 5)
$searchTextBox.Size = New-Object System.Drawing.Size(400, 20)
$searchPanel.Controls.Add($searchTextBox)

# Create a button to search for programs
$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = "Search"
$searchButton.Location = New-Object System.Drawing.Point(540, 5)
$searchButton.Click += {
    $searchTerm = $searchTextBox.Text
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        return
    }

    $wingetOutput = winget search --all | Where-Object { $_ -match "$searchTerm" }
    foreach ($package in $wingetOutput) {
        if ($package -match "^Package Name: "){
            $packageInfo = $package.Split(":")[1].Trim()
            $name = $packageInfo.Split(",")[0]
            $version = $packageInfo.Split(",")[2]

            $listViewItem = New-Object System.Windows.Forms.ListViewItem($name)
            $listViewItem.SubItems.Add($version)

            $listView1.Items.Add($listViewItem) | Out-Null
        }
    }

}
$searchPanel.Controls.Add($searchButton)

# Create a panel to hold the install controls
$installPanel = New-Object System.Windows.Forms.Panel
$installPanel.Location = New-Object System.Drawing.Point(10, 310)
$installPanel.Size = New-Object System.Drawing.Size(580, 30)
$form.Controls.Add($installPanel)

# Create a label and text box for selecting packages to install
$packageLabel = New-Object System.Windows.Forms.Label
$packageLabel.Text = "Select packages to install:"
$packageLabel.Location = New-Object System.Drawing.Point(10, 5)
$installPanel.Controls.Add($packageLabel)

$packageListBox = New-Object System.Windows.Forms.ListBox
$packageListBox.Location = New-Object System.Drawing.Point(130, 0)
$installPanel.Controls.Add($packageListBox)

# Create a button to install selected packages
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install"
$installButton.Location = New-Object System.Drawing.Point(540, 5)
$installButton.Click += {
    $selectedPackages = @()
    foreach ($item in $packageListBox.SelectedItems) {
        $selectedPackages += $item
    }

    if ($null -ne $selectedPackages[0]) {
        foreach ($packageName in $selectedPackages) {
            winget install --exact --id $packageName
        }
    }
}
$installPanel.Controls.Add($installButton)

# Show the form and wait for user input
$form.ShowDialog()
