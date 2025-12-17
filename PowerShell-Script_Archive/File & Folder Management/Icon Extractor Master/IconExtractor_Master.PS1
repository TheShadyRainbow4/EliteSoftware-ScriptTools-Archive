# Requires PowerShell 5.1 or later on Windows.
# This script creates a Graphical User Interface (GUI) to:
# 1. Search for executable files (.exe) in a specified folder, optionally including subfolders.
# 2. Display the found executables along with their associated icons in a list.
# 3. Allow the user to select multiple executables using checkboxes.
# 4. Extract the icon files (.ico) from the selected executables.
# 5. Save the extracted .ico files to a user-specified output directory.

# Add necessary .NET assemblies for GUI elements and drawing capabilities.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Global Variables for Icon Management ---
# This ImageList will store icons for display in the ListView.
# Icons added to this list are managed by the ListView itself, but individual
# System.Drawing.Icon objects created for display should be disposed after adding.
$global:ImageList = New-Object System.Windows.Forms.ImageList
$global:ImageList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit # High quality icons
$global:ImageList.ImageSize = New-Object System.Drawing.Size(32, 32) # Standard size for list view display

# --- Main Form Setup ---
# Create the main window for the application.
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell Icon Extractor" # Window title
$form.Size = New-Object System.Drawing.Size(800, 600) # Initial window size
$form.MinimumSize = New-Object System.Drawing.Size(700, 500) # Minimum resize size
$form.StartPosition = "CenterScreen" # Center the window on the screen
$form.Padding = New-Object System.Windows.Forms.Padding(10) # Padding around the form content
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9) # Default font for the form

# --- Search Options Group Box ---
# A visual container for search-related controls.
$searchOptionsGroupBox = New-Object System.Windows.Forms.GroupBox
$searchOptionsGroupBox.Text = "Search For Programs"
$searchOptionsGroupBox.Location = New-Object System.Drawing.Point(10, 10)
$searchOptionsGroupBox.Size = New-Object System.Drawing.Size(760, 120)
$searchOptionsGroupBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                               -bor [System.Windows.Forms.AnchorStyles]::Left `
                               -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($searchOptionsGroupBox)

# Label for the search path input.
$searchPathLabel = New-Object System.Windows.Forms.Label
$searchPathLabel.Text = "Folder to Search:"
$searchPathLabel.Location = New-Object System.Drawing.Point(15, 30)
$searchPathLabel.AutoSize = $true
$searchOptionsGroupBox.Controls.Add($searchPathLabel)

# Text box for the user to enter or display the search folder path.
$searchPathTextBox = New-Object System.Windows.Forms.TextBox
$searchPathTextBox.Location = New-Object System.Drawing.Point(120, 27)
$searchPathTextBox.Size = New-Object System.Drawing.Size(540, 25)
$searchPathTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                            -bor [System.Windows.Forms.AnchorStyles]::Left `
                            -bor [System.Windows.Forms.AnchorStyles]::Right
$searchPathTextBox.Text = "$env:ProgramFiles" # Default search path (Program Files)
$searchOptionsGroupBox.Controls.Add($searchPathTextBox)

# Button to open a folder browser dialog for the search path.
$browseSearchPathButton = New-Object System.Windows.Forms.Button
$browseSearchPathButton.Text = "Browse..."
$browseSearchPathButton.Location = New-Object System.Drawing.Point(670, 25)
$browseSearchPathButton.Size = New-Object System.Drawing.Size(75, 30)
$browseSearchPathButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                                -bor [System.Windows.Forms.AnchorStyles]::Right
$searchOptionsGroupBox.Controls.Add($browseSearchPathButton)

# Checkbox to determine if the search should include subfolders.
$recursiveSearchCheckBox = New-Object System.Windows.Forms.CheckBox
$recursiveSearchCheckBox.Text = "Include Subfolders"
$recursiveSearchCheckBox.Location = New-Object System.Drawing.Point(120, 60)
$recursiveSearchCheckBox.AutoSize = $true
$recursiveSearchCheckBox.Checked = $true # Default to recursive search
$searchOptionsGroupBox.Controls.Add($recursiveSearchCheckBox)

# Button to start the executable search.
$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = "Search for Executables"
$searchButton.Location = New-Object System.Drawing.Point(120, 85)
$searchButton.Size = New-Object System.Drawing.Size(160, 30)
$searchOptionsGroupBox.Controls.Add($searchButton)

# --- Program List View ---
# This control will display the found executables, their paths, and icons.
$programListView = New-Object System.Windows.Forms.ListView
$programListView.View = [System.Windows.Forms.View]::Details # Display items in a grid with columns
$programListView.CheckBoxes = $true # Enable checkboxes for selection
$programListView.GridLines = $true # Show grid lines for better readability
$programListView.FullRowSelect = $true # Select the entire row when an item is clicked
$programListView.Location = New-Object System.Drawing.Point(10, 140)
$programListView.Size = New-Object System.Drawing.Size(760, 300)
$programListView.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                          -bor [System.Windows.Forms.AnchorStyles]::Bottom `
                          -bor [System.Windows.Forms.AnchorStyles]::Left `
                          -bor [System.Windows.Forms.AnchorStyles]::Right
$programListView.SmallImageList = $global:ImageList # Assign the image list for icons
$form.Controls.Add($programListView)

# Define columns for the ListView.
$colProgramName = New-Object System.Windows.Forms.ColumnHeader
$colProgramName.Text = "Program Name"
$colProgramName.Width = 300 # Initial width
$programListView.Columns.Add($colProgramName)

$colExecutablePath = New-Object System.Windows.Forms.ColumnHeader
$colExecutablePath.Text = "Executable Path"
$colExecutablePath.Width = 440 # Initial width
$programListView.Columns.Add($colExecutablePath)

# --- Output Folder Group Box ---
# A visual container for output path related controls.
$outputOptionsGroupBox = New-Object System.Windows.Forms.GroupBox
$outputOptionsGroupBox.Text = "Icon Repository Destination"
$outputOptionsGroupBox.Location = New-Object System.Drawing.Point(10, 450)
$outputOptionsGroupBox.Size = New-Object System.Drawing.Size(760, 60)
$outputOptionsGroupBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom `
                               -bor [System.Windows.Forms.AnchorStyles]::Left `
                               -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($outputOptionsGroupBox)

# Label for the output path input.
$outputPathLabel = New-Object System.Windows.Forms.Label
$outputPathLabel.Text = "Save Icons To:"
$outputPathLabel.Location = New-Object System.Drawing.Point(15, 27)
$outputPathLabel.AutoSize = $true
$outputOptionsGroupBox.Controls.Add($outputPathLabel)

# Text box for the user to enter or display the output folder path.
$outputPathTextBox = New-Object System.Windows.Forms.TextBox
$outputPathTextBox.Location = New-Object System.Drawing.Point(120, 25)
$outputPathTextBox.Size = New-Object System.Drawing.Size(540, 25)
$outputPathTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                            -bor [System.Windows.Forms.AnchorStyles]::Left `
                            -bor [System.Windows.Forms.AnchorStyles]::Right
# Default output path to a folder on the desktop.
$outputPathTextBox.Text = Join-Path $env:USERPROFILE "Desktop\ExtractedIcons"
$outputOptionsGroupBox.Controls.Add($outputPathTextBox)

# Button to open a folder browser dialog for the output path.
$browseOutputPathButton = New-Object System.Windows.Forms.Button
$browseOutputPathButton.Text = "Browse..."
$browseOutputPathButton.Location = New-Object System.Drawing.Point(670, 23)
$browseOutputPathButton.Size = New-Object System.Drawing.Size(75, 30)
$browseOutputPathButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top `
                                -bor [System.Windows.Forms.AnchorStyles]::Right
$outputOptionsGroupBox.Controls.Add($browseOutputPathButton)

# --- Extract Button ---
# Button to initiate the icon extraction process for selected items.
$extractButton = New-Object System.Windows.Forms.Button
$extractButton.Text = "Extract Selected Icons"
$extractButton.Location = New-Object System.Drawing.Point(10, 520)
$extractButton.Size = New-Object System.Drawing.Size(180, 40)
$extractButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom `
                       -bor [System.Windows.Forms.AnchorStyles]::Left
$form.Controls.Add($extractButton)

# --- Event Handlers ---

# Event handler for browsing the search path.
$browseSearchPathButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder to search for executable files (.exe)."
    $folderBrowser.SelectedPath = $searchPathTextBox.Text # Set initial path
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $searchPathTextBox.Text = $folderBrowser.SelectedPath
    }
})

# Event handler for browsing the output path.
$browseOutputPathButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder where the extracted icons will be saved."
    $folderBrowser.SelectedPath = $outputPathTextBox.Text # Set initial path
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $outputPathTextBox.Text = $folderBrowser.SelectedPath
    }
})

# Event handler for the Search button click.
$searchButton.Add_Click({
    # Clear previous search results from the ListView and ImageList.
    $programListView.Items.Clear()
    $global:ImageList.Images.Clear()

    $searchPath = $searchPathTextBox.Text.Trim()
    # Validate the search path.
    if ([string]::IsNullOrEmpty($searchPath) -or -not (Test-Path $searchPath -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter a valid search folder path.",
            "Invalid Search Path",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    # Determine search option based on checkbox.
    $searchOption = if ($recursiveSearchCheckBox.Checked) {
        [System.IO.SearchOption]::AllDirectories # Search all subdirectories
    } else {
        [System.IO.SearchOption]::TopDirectoryOnly # Search only the top directory
    }

    try {
        # Find all executable files (.exe) in the specified path.
        # -LiteralPath is used to ensure paths are treated literally, avoiding wildcard interpretation issues.
        # -ErrorAction SilentlyContinue prevents individual file access errors from stopping the script.
        $executables = Get-ChildItem -LiteralPath $searchPath -Filter "*.exe" -Recurse:$recursiveSearchCheckBox.Checked -ErrorAction SilentlyContinue |
                       Where-Object { -not $_.PSIsContainer } # Ensure it's a file, not a directory named .exe

        $itemIndex = 0 # Used to assign unique image index to each item in ListView
        foreach ($exe in $executables) {
            # Create a ListViewItem for each executable.
            $listViewItem = New-Object System.Windows.Forms.ListViewItem($exe.BaseName) # Program Name
            $listViewItem.SubItems.Add($exe.FullName) # Executable Path

            try {
                # Attempt to extract the icon associated with the executable.
                # ExtractAssociatedIcon returns the icon that would be displayed for the file.
                $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exe.FullName)
                if ($icon) {
                    # Add the extracted icon to the ImageList and associate it with the ListViewItem.
                    $global:ImageList.Images.Add($icon)
                    $listViewItem.ImageIndex = $itemIndex
                    $icon.Dispose() # Dispose the Icon object after adding to ImageList to free unmanaged resources.
                    $itemIndex++
                }
            } catch {
                # If icon extraction fails (e.g., file locked, corrupted icon),
                # an error message is written to the console, and the item is added without an icon.
                Write-Warning "Could not extract icon from $($exe.FullName): $($_.Exception.Message)"
            }
            $programListView.Items.Add($listViewItem) # Add the item to the ListView.
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Search complete. Found $($executables.Count) executable(s).",
            "Search Results",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } catch {
        # Catch any general errors during the search process.
        [System.Windows.Forms.MessageBox]::Show(
            "An unexpected error occurred during search: $($_.Exception.Message)",
            "Search Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Event handler for the Extract Selected Icons button click.
$extractButton.Add_Click({
    $selectedItems = $programListView.CheckedItems # Get all items checked by the user.

    # Validate if any items are selected.
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select at least one program from the list to extract icons.",
            "No Selection",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    $outputPath = $outputPathTextBox.Text.Trim()
    # Validate the output path and create it if it doesn't exist.
    if ([string]::IsNullOrEmpty($outputPath)) {
         [System.Windows.Forms.MessageBox]::Show(
            "Please specify a valid output folder for the icons.",
            "Invalid Output Path",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    if (-not (Test-Path $outputPath -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
            Write-Host "Created output directory: $outputPath" # For console feedback
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Could not create the specified output folder: $($_.Exception.Message)",
                "Error Creating Folder",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return
        }
    }

    $extractedCount = 0 # Counter for successfully extracted icons.
    foreach ($item in $selectedItems) {
        $exePath = $item.SubItems[1].Text # Get the full executable path from the second sub-item.
        $programName = $item.SubItems[0].Text # Get the program name for the icon filename.

        # Sanitize the program name to create a valid filename.
        # Replace invalid filename characters with underscores.
        $sanitizedProgramName = ($programName | ForEach-Object {
            $_.ToCharArray() | ForEach-Object {
                if ([System.IO.Path]::GetInvalidFileNameChars() -contains $_) {
                    "_"
                } else {
                    $_
                }
            }
        }) -join ''

        $fileName = "$sanitizedProgramName.ico" # Construct the full icon filename.
        $fullOutputPath = Join-Path $outputPath $fileName

        try {
            # Extract the icon.
            $iconToSave = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
            if ($iconToSave) {
                # Save the icon to the specified output path.
                # The .Save() method creates a standard .ico file, often multi-resolution.
                $iconToSave.Save($fullOutputPath)
                $iconToSave.Dispose() # Dispose the Icon object after saving.
                $extractedCount++
            } else {
                Write-Warning "No icon found for $($exePath)."
            }
        } catch {
            # Report individual extraction failures without stopping the entire process.
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to extract icon from $($exePath): $($_.Exception.Message)",
                "Extraction Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    }

    # Show a final message box with the results of the extraction.
    [System.Windows.Forms.MessageBox]::Show(
        "Icon extraction complete. Successfully extracted $($extractedCount) icon(s) to '$outputPath'.",
        "Extraction Complete",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

# --- Show the Form and Clean Up ---
# Display the GUI form. This call blocks until the form is closed.
$form.ShowDialog()

# Dispose of the form and the global image list to release system resources
# once the application is closed. This is crucial for memory management.
$form.Dispose()
$global:ImageList.Dispose()

# Remove the loaded assemblies from the current PowerShell session.
# This ensures a clean exit and prevents potential conflicts if running other scripts.
Remove-Type -AssemblyName System.Windows.Forms
Remove-Type -AssemblyName System.Drawing
