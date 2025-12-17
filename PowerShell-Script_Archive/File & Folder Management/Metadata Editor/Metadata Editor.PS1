<#
.SYNOPSIS
    A GUI-based tool to view and edit metadata for files and folders.
.DESCRIPTION
    This PowerShell script launches a Windows Forms application that allows a user to select a file or a folder,
    view its common metadata properties (Title, Subject, Author, Tags, Comments), and modify them.
    For files, it uses the Shell.Application COM object to interact with extended properties.
    For folders, it modifies the desktop.ini file to set the 'InfoTip' (Comments) and a custom 'Tags' property.
    This is designed to help organize project templates and integrate with tools like Stardock Fences.
.NOTES
    Project Name: PowerShell Metadata Editor v1.0
    Created by: Zachary Whiteman & Google Gemini AI
    Date: 7/13/2025
    Time: 5:28 AM
    Requires: PowerShell 5.1 or higher (Tested on PowerShell 7). GUI may look slightly different between versions.
#>

# --- Assembly Loading ---
# Load the necessary .NET assemblies for creating a Graphical User Interface (GUI).
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Error "Failed to load required .NET assemblies. This script requires a Windows environment with .NET Framework."
    pause
    exit
}

# --- Main Form Definition ---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Metadata Editor v1.0"
$mainForm.Size = New-Object System.Drawing.Size(500, 450)
$mainForm.MinimumSize = New-Object System.Drawing.Size(500, 450)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = 'FixedSingle'
$mainForm.MaximizeBox = $false

# --- Function to Get Shell Application Object ---
# This is a reusable function to get the COM object needed for metadata manipulation.
function Get-Shell {
    try {
        return New-Object -ComObject Shell.Application
    }
    catch {
        Write-Warning "Could not create Shell.Application COM object. Metadata features will be unavailable."
        return $null
    }
}

# --- Function to Load Metadata ---
# This function reads the metadata from the selected file or folder and populates the text boxes.
function Load-Metadata {
    param(
        [string]$path
    )

    # Clear previous values
    $txtTitle.Text = ""
    $txtSubject.Text = ""
    $txtAuthor.Text = ""
    $txtTags.Text = ""
    $txtComments.Text = ""
    $lblStatus.Text = "Select a file or folder to begin."

    if (-not (Test-Path $path)) {
        $lblStatus.Text = "Error: Path not found."
        return
    }

    $item = Get-Item $path
    # Check if the selected item is a file or a folder
    if ($item.PSIsContainer) {
        # --- FOLDER METADATA LOGIC ---
        $lblItemType.Text = "Type: Folder"
        $desktopIniPath = Join-Path $path "desktop.ini"
        if (Test-Path $desktopIniPath) {
            # If desktop.ini exists, read its contents
            $iniContent = Get-Content $desktopIniPath | Out-String
            $comments = ($iniContent | Select-String 'InfoTip=(.*)' -AllMatches).Matches.Groups[1].Value
            $tags = ($iniContent | Select-String 'Tags=(.*)' -AllMatches).Matches.Groups[1].Value
            $txtComments.Text = $comments
            $txtTags.Text = $tags
            $lblStatus.Text = "Loaded metadata from desktop.ini."
        } else {
            $lblStatus.Text = "No desktop.ini found for this folder. Save to create one."
        }
        # Folder don't have these properties natively, so we disable the textboxes
        $txtTitle.Enabled = $false
        $txtSubject.Enabled = $false
        $txtAuthor.Enabled = $false
        $txtTags.Enabled = $true # We will use a custom field
        $txtComments.Enabled = $true # Corresponds to InfoTip
    } else {
        # --- FILE METADATA LOGIC ---
        $lblItemType.Text = "Type: File"
        $txtTitle.Enabled = $true
        $txtSubject.Enabled = $true
        $txtAuthor.Enabled = $true
        $txtTags.Enabled = $true
        $txtComments.Enabled = $true

        $shell = Get-Shell
        if (-not $shell) { return }

        $parentFolder = Split-Path -Path $path -Parent
        $fileName = Split-Path -Path $path -Leaf
        $shellFolder = $shell.Namespace($parentFolder)
        $shellFile = $shellFolder.ParseName($fileName)

        # Metadata properties are indexed. We need to find the index for each property.
        # This can vary by OS language, but these are the standard English values.
        # Title(21), Subject(23), Author(20), Tags(25), Comments(24)
        # We will iterate to find them to be more robust.
        $propMapping = @{
            Title = 0; Subject = 0; Author = 0; Tags = 0; Comments = 0;
        }
        # This loop finds the correct index for each property name.
        for ($i = 0; $i -lt 300; $i++) {
            $propName = $shellFolder.GetDetailsOf($null, $i)
            if ($propMapping.ContainsKey($propName)) {
                $propMapping[$propName] = $i
            }
        }

        # Populate text boxes with file metadata
        $txtTitle.Text = $shellFolder.GetDetailsOf($shellFile, $propMapping['Title'])
        $txtSubject.Text = $shellFolder.GetDetailsOf($shellFile, $propMapping['Subject'])
        $txtAuthor.Text = $shellFolder.GetDetailsOf($shellFile, $propMapping['Author'])
        $txtTags.Text = $shellFolder.GetDetailsOf($shellFile, $propMapping['Tags'])
        $txtComments.Text = $shellFolder.GetDetailsOf($shellFile, $propMapping['Comments'])
        
        $lblStatus.Text = "Successfully loaded file metadata."
    }
}


# --- UI Controls Definition ---

# Label and TextBox for the selected path
$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "Selected Item:"
$lblPath.Location = New-Object System.Drawing.Point(10, 15)
$lblPath.AutoSize = $true
$mainForm.Controls.Add($lblPath)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(10, 35)
$txtPath.Size = New-Object System.Drawing.Size(370, 20)
$txtPath.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$mainForm.Controls.Add($txtPath)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(390, 34)
$btnBrowse.Size = New-Object System.Drawing.Size(85, 23)
$btnBrowse.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$mainForm.Controls.Add($btnBrowse)

# Label to show if it's a file or folder
$lblItemType = New-Object System.Windows.Forms.Label
$lblItemType.Text = "Type: (none selected)"
$lblItemType.Location = New-Object System.Drawing.Point(10, 65)
$lblItemType.AutoSize = $true
$mainForm.Controls.Add($lblItemType)

# Metadata fields
$metadataFields = @(
    @{ Name = "Title";    Location = New-Object System.Drawing.Point(10, 100) },
    @{ Name = "Subject";  Location = New-Object System.Drawing.Point(10, 150) },
    @{ Name = "Author";   Location = New-Object System.Drawing.Point(10, 200) },
    @{ Name = "Tags";     Location = New-Object System.Drawing.Point(10, 250) },
    @{ Name = "Comments"; Location = New-Object System.Drawing.Point(10, 300) }
)

foreach ($field in $metadataFields) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "$($field.Name):"
    $label.Location = $field.Location
    $label.AutoSize = $true
    $mainForm.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Name = "txt$($field.Name)" # Give it a name we can reference later
    $textBox.Location = New-Object System.Drawing.Point($field.Location.X, $field.Location.Y + 20)
    $textBox.Size = New-Object System.Drawing.Size(465, 20)
    $textBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $mainForm.Controls.Add($textBox)

    # Store the textbox object in a dynamically created variable for easy access
    New-Variable -Name "txt$($field.Name)" -Value $textBox -Scope Script
}

# Save Button
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Metadata"
$btnSave.Location = New-Object System.Drawing.Point(375, 380)
$btnSave.Size = New-Object System.Drawing.Size(100, 30)
$btnSave.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$mainForm.Controls.Add($btnSave)

# Status Label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Select a file or folder to begin."
$lblStatus.Location = New-Object System.Drawing.Point(10, 388)
$lblStatus.AutoSize = $true
$lblStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$mainForm.Controls.Add($lblStatus)


# --- Event Handlers ---

# Event handler for the Browse button
$btnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder or browse to a file's location"
    
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $txtPath.Text = $folderBrowser.SelectedPath
        Load-Metadata -path $txtPath.Text
    }
})

# Event handler for the Path text box (if user pastes a path)
$txtPath.Add_Leave({
    if ($txtPath.Text) {
        Load-Metadata -path $txtPath.Text
    }
})


# Event handler for the Save button
$btnSave.Add_Click({
    $path = $txtPath.Text
    if (-not (Test-Path $path)) {
        $lblStatus.Text = "Error: Path not found. Cannot save."
        return
    }

    $item = Get-Item $path
    if ($item.PSIsContainer) {
        # --- SAVE FOLDER METADATA ---
        try {
            # Make the folder a system folder to enable desktop.ini functionality
            $item.Attributes = $item.Attributes -bor "System"
            
            $desktopIniPath = Join-Path $path "desktop.ini"
            # Create or overwrite the desktop.ini file
            $iniContent = @"
[.ShellClassInfo]
InfoTip=$($txtComments.Text)
Tags=$($txtTags.Text)
IconResource=%SystemRoot%\system32\imageres.dll,-112
"@
            Set-Content -Path $desktopIniPath -Value $iniContent -Force
            # Set the desktop.ini file to be hidden and system
            (Get-Item $desktopIniPath).Attributes = "Hidden", "System"

            $lblStatus.Text = "Folder metadata saved to desktop.ini successfully."
        }
        catch {
            $lblStatus.Text = "Error saving folder metadata: $($_.Exception.Message)"
        }
    } else {
        # --- SAVE FILE METADATA ---
        try {
            $shell = Get-Shell
            if (-not $shell) { return }

            $parentFolder = Split-Path -Path $path -Parent
            $fileName = Split-Path -Path $path -Leaf
            $shellFolder = $shell.Namespace($parentFolder)
            $shellFile = $shellFolder.ParseName($fileName)

            # Note: This method of setting properties is reliable but can be slow.
            # It updates properties by name.
            $shellFile.ExtendedProperty("System.Title") = $txtTitle.Text
            $shellFile.ExtendedProperty("System.Subject") = $txtSubject.Text
            $shellFile.ExtendedProperty("System.Author") = $txtAuthor.Text -split '; ' # Author can be an array
            $shellFile.ExtendedProperty("System.Keywords") = $txtTags.Text -split '; ' # Tags (Keywords) is an array
            $shellFile.ExtendedProperty("System.Comment") = $txtComments.Text
            
            $lblStatus.Text = "File metadata saved successfully."
        }
        catch {
            $lblStatus.Text = "Error saving file metadata: $($_.Exception.Message)"
        }
    }
})


# --- Show the Form ---
# The .ShowDialog() method opens the form and waits until it's closed.
# This keeps the script running and the console open.
$mainForm.Add_Shown({$mainForm.Activate()})
[void]$mainForm.ShowDialog()

# --- Cleanup ---
# Dispose of the form object after it's closed to free up memory.
$mainForm.Dispose()
