# Custom Icon Setter GUI for PowerShell
# Author: Gemini
# Date: June 20, 2025

# This script creates a simple GUI to allow users to set custom icons
# for application shortcuts found in the Start Menu. It modifies the
# 'IconLocation' property of .lnk (shortcut) files.

#region Load Assemblies
# Load necessary .NET assemblies for GUI creation
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.IO.Compression.FileSystem # For potential future use, not directly used here but good practice
} catch {
    Write-Host "Error loading .NET assemblies. Ensure you are running on a Windows system with .NET Framework installed." -ForegroundColor Red
    exit
}
#endregion

#region Main Form Setup
# Create the main form (window)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Custom Icon Setter"
$form.Size = New-Object System.Drawing.Size(700, 500) # Slightly larger for better layout
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0") # Light gray background
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9) # Modern font

# Prevent resizing
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.MinimizeBox = $false

#endregion

#region Controls Creation

# ListBox to display applications/shortcuts
$appListBox = New-Object System.Windows.Forms.ListBox
$appListBox.Location = New-Object System.Drawing.Point(20, 20)
$appListBox.Size = New-Object System.Drawing.Size(300, 400)
$appListBox.Anchor = "Top, Bottom, Left" # Anchor to keep it responsive if resizing was enabled
$appListBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($appListBox)

# Label for instructions
$lblInstructions = New-Object System.Windows.Forms.Label
$lblInstructions.Text = "Select an application shortcut from the list:"
$lblInstructions.Location = New-Object System.Drawing.Point(20, 5)
$lblInstructions.AutoSize = $true
$lblInstructions.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblInstructions)

# Label for icon path
$lblIconPath = New-Object System.Windows.Forms.Label
$lblIconPath.Text = "Selected Icon File:"
$lblIconPath.Location = New-Object System.Drawing.Point(340, 20)
$lblIconPath.AutoSize = $true
$lblIconPath.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblIconPath)

# TextBox to display selected icon file path
$txtIconPath = New-Object System.Windows.Forms.TextBox
$txtIconPath.Location = New-Object System.Drawing.Point(340, 40)
$txtIconPath.Size = New-Object System.Drawing.Size(320, 25)
$txtIconPath.ReadOnly = $true # Make it read-only
$txtIconPath.BackColor = [System.Drawing.Color]::WhiteSmoke
$form.Controls.Add($txtIconPath)

# Browse Icon Button
$btnBrowseIcon = New-Object System.Windows.Forms.Button
$btnBrowseIcon.Text = "Browse for Icon (.ico)"
$btnBrowseIcon.Location = New-Object System.Drawing.Point(340, 80)
$btnBrowseIcon.Size = New-Object System.Drawing.Size(150, 35)
$btnBrowseIcon.FlatStyle = "Flat"
$btnBrowseIcon.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D4") # Windows Blue
$btnBrowseIcon.ForeColor = [System.Drawing.Color]::White
$btnBrowseIcon.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnBrowseIcon.FlatAppearance.BorderSize = 0 # No border
$form.Controls.Add($btnBrowseIcon)

# Set Icon Button
$btnSetIcon = New-Object System.Windows.Forms.Button
$btnSetIcon.Text = "Set Custom Icon"
$btnSetIcon.Location = New-Object System.Drawing.Point(340, 130)
$btnSetIcon.Size = New-Object System.Drawing.Size(150, 35)
$btnSetIcon.FlatStyle = "Flat"
$btnSetIcon.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50") # Green
$btnSetIcon.ForeColor = [System.Drawing.Color]::White
$btnSetIcon.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnSetIcon.FlatAppearance.BorderSize = 0 # No border
$form.Controls.Add($btnSetIcon)

# Reset Icon Button
$btnResetIcon = New-Object System.Windows.Forms.Button
$btnResetIcon.Text = "Reset Icon"
$btnResetIcon.Location = New-Object System.Drawing.Point(340, 180)
$btnResetIcon.Size = New-Object System.Drawing.Size(150, 35)
$btnResetIcon.FlatStyle = "Flat"
$btnResetIcon.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFC107") # Amber/Orange
$btnResetIcon.ForeColor = [System.Drawing.Color]::Black
$btnResetIcon.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnResetIcon.FlatAppearance.BorderSize = 0 # No border
$form.Controls.Add($btnResetIcon)

# Status Label (for messages to the user)
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = ""
$lblStatus.Location = New-Object System.Drawing.Point(340, 230)
$lblStatus.AutoSize = $true
$lblStatus.ForeColor = [System.Drawing.Color]::DarkSlateGray
$form.Controls.Add($lblStatus)

#endregion

#region Functions

# Function to populate the ListBox with Start Menu shortcuts
function Populate-ApplicationListBox {
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.ListBox]$ListBox
    )
    $ListBox.Items.Clear()
    $ListBox.BeginUpdate() # Prevent flickering during updates

    # Common Start Menu locations
    $startMenuPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" # Current User
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs" # All Users
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcuts = [System.Collections.Generic.List[Object]]::new()

    # Recursively find .lnk files
    foreach ($path in $startMenuPaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Recurse -Include "*.lnk" -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $shortcutPath = $_.FullName
                    $shortcutName = $_.BaseName
                    
                    # Create a shortcut object
                    $link = $shell.CreateShortcut($shortcutPath)
                    
                    # Store both the name and the full path of the shortcut
                    $shortcuts.Add(@{ Name = $shortcutName; Path = $shortcutPath })
                } catch {
                    # Handle cases where a shortcut might be broken or inaccessible
                    Write-Verbose "Could not process shortcut '$_.FullName': $($_.Exception.Message)"
                }
            }
        }
    }

    # Sort shortcuts alphabetically by name
    $shortcuts = $shortcuts | Sort-Object Name

    # Add sorted shortcuts to the ListBox
    foreach ($shortcut in $shortcuts) {
        $ListBox.Items.Add($shortcut.Name) # Display only the name in the ListBox
        # Store the full shortcut object (name and path) in the Tag property for easy retrieval
        $ListBox.Items[$ListBox.Items.Count - 1].Tag = $shortcut
    }
    
    $ListBox.EndUpdate() # Resume drawing
    $lblStatus.Text = "Found $($shortcuts.Count) application shortcuts."
}

# Function to handle Browse Icon button click
$btnBrowseIcon.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Icon Files (*.ico)|*.ico|All Files (*.*)|*.*"
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath("MyPictures") # Suggest Pictures folder

    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtIconPath.Text = $openFileDialog.FileName
        $lblStatus.Text = "Icon selected: $(Split-Path $openFileDialog.FileName -Leaf)"
        $lblStatus.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $lblStatus.Text = "Icon selection cancelled."
        $lblStatus.ForeColor = [System.Drawing.Color]::DarkOrange
    }
})

# Function to handle Set Icon button click
$btnSetIcon.Add_Click({
    if ($appListBox.SelectedItem -eq $null) {
        $lblStatus.Text = "Please select an application first."
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        return
    }

    if ([string]::IsNullOrEmpty($txtIconPath.Text)) {
        $lblStatus.Text = "Please browse and select an icon file (.ico)."
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        return
    }

    $selectedAppName = $appListBox.SelectedItem
    $selectedShortcut = $appListBox.Items[$appListBox.SelectedIndex].Tag # Retrieve the stored shortcut object
    $iconPath = $txtIconPath.Text

    if (-not (Test-Path $selectedShortcut.Path)) {
        $lblStatus.Text = "Error: Shortcut not found at $($selectedShortcut.Path)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        return
    }
    if (-not (Test-Path $iconPath)) {
        $lblStatus.Text = "Error: Icon file not found at $($iconPath)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        return
    }

    try {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($selectedShortcut.Path)
        
        # Set the IconLocation property to the new icon file path
        # You can specify an index if the ICO file contains multiple icons,
        # but typically for single ICO files, index 0 is used.
        $link.IconLocation = "$iconPath,0" 
        $link.Save() # Save the changes to the shortcut file

        # Optional: Force Windows to refresh the icon cache.
        # This is not always necessary for shortcuts but can help.
        # This method is a bit aggressive and might flash the screen.
        # (New-Object -ComObject Shell.Application).Refresh() 
        # Alternatively, a more common method is to call SHChangeNotify,
        # but that requires importing functions from shell32.dll, which adds complexity.
        # For shortcuts, often just saving the shortcut is enough, or a system restart.

        $lblStatus.Text = "Icon for '$selectedAppName' successfully set!"
        $lblStatus.ForeColor = [System.Drawing.Color]::Blue

    } catch {
        $lblStatus.Text = "Failed to set icon for '$selectedAppName': $($_.Exception.Message)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
})

# Function to handle Reset Icon button click
$btnResetIcon.Add_Click({
    if ($appListBox.SelectedItem -eq $null) {
        $lblStatus.Text = "Please select an application first to reset its icon."
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        return
    }

    $selectedAppName = $appListBox.SelectedItem
    $selectedShortcut = $appListBox.Items[$appListBox.SelectedIndex].Tag

    if (-not (Test-Path $selectedShortcut.Path)) {
        $lblStatus.Text = "Error: Shortcut not found at $($selectedShortcut.Path)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        return
    }

    try {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($selectedShortcut.Path)

        # To reset, typically you set IconLocation to the original target path,0
        # This makes the shortcut use the icon embedded in its target executable.
        $link.IconLocation = "$($link.TargetPath),0"
        $link.Save()

        $lblStatus.Text = "Icon for '$selectedAppName' successfully reset!"
        $lblStatus.ForeColor = [System.Drawing.Color]::DarkBlue

    } catch {
        $lblStatus.Text = "Failed to reset icon for '$selectedAppName': $($_.Exception.Message)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
})

#endregion

#region Form Load and Show

# Event handler for when the form loads
$form.Add_Load({
    Populate-ApplicationListBox -ListBox $appListBox
})

# Show the form
$form.ShowDialog()

# Clean up COM objects
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
Remove-Variable shell -ErrorAction SilentlyContinue

# Dispose the form when closed
$form.Dispose()

#endregion
