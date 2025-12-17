# PS1 to JSON Converter v1.0 - Created by: Zachary Whiteman & Google Gemini Ai. 2025-07-15 - 07:20 AM EDT

#region Script Header
<#
.SYNOPSIS
    Converts all PowerShell script files (.ps1) in a selected directory into a single JSON file.
    Each script's content is stored alongside its filename, making it easily parsable by an artificial intelligence.

.DESCRIPTION
    This script provides a graphical user interface (GUI) to allow the user to:
    1. Select a source folder containing PowerShell (.ps1) files.
    2. Specify an output file name and location for the generated JSON.

    The script will recursively find all .ps1 files within the chosen source folder and its subdirectories.
    For each file, it reads the entire content and stores it in a structured object along with the file's full path.
    Finally, all these objects are combined into a single array and converted into a JSON string,
    which is then saved to the specified output file.

    Error handling is implemented to catch common issues like invalid paths or file access problems,
    and messages are displayed in the GUI. The console window will remain open to display any unhandled errors.

.NOTES
    Author: Zachary Whiteman & Google Gemini Ai
    Version: 1.0
    Date: 2025-07-15
    Requires: PowerShell 5.1 or later (PowerShell 7 recommended for best experience)
#>
#endregion

#region Function: Show-Message
Function Show-Message {
    Param (
        [string]$Message,
        [string]$Title = "PS1 to JSON Converter",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon) | Out-Null
}
#endregion

#region GUI Setup
# Load required assemblies for GUI
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Show-Message "Failed to load System.Windows.Forms or System.Drawing assemblies. Please ensure your PowerShell environment supports GUI applications." "Error" "OK" "Error"
    exit
}

# Enable visual styles for system theming
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PS1 to JSON Converter"
$form.Size = New-Object System.Drawing.Size(500, 250)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle" # Prevent resizing
$form.MaximizeBox = $false
$form.MinimizeBox = $true

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Click 'Select Folder and Convert' to begin."
$statusLabel.Location = New-Object System.Drawing.Point(20, 20)
$statusLabel.AutoSize = $true
# Explicitly cast $form.Width to [int] to ensure subtraction works correctly
$statusLabel.MaximumSize = New-Object System.Drawing.Size([int]$form.Width - 40, 0) # Wrap text
$form.Controls.Add($statusLabel)

# Convert Button
$convertButton = New-Object System.Windows.Forms.Button
$convertButton.Text = "Select Folder and Convert"
$convertButton.Location = New-Object System.Drawing.Point(150, 100)
$convertButton.Size = New-Object System.Drawing.Size(180, 40)
$form.Controls.Add($convertButton)

#endregion

#region Event Handler for Convert Button
$convertButton.Add_Click({
    $statusLabel.Text = "Please select the folder containing your .ps1 files..."

    # Folder Browser Dialog
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the folder containing your PowerShell scripts (.ps1)"
    $folderBrowser.ShowNewFolderButton = $false # Don't allow creating new folders here

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $sourcePath = $folderBrowser.SelectedPath
        $statusLabel.Text = "Scanning folder: '$sourcePath' for .ps1 files..."

        $scriptData = @() # Initialize an empty array to hold script data

        try {
            # Get all .ps1 files recursively
            $ps1Files = Get-ChildItem -Path $sourcePath -Filter "*.ps1" -Recurse -ErrorAction Stop

            if ($ps1Files.Count -eq 0) {
                $statusLabel.Text = "No .ps1 files found in '$sourcePath' or its subdirectories."
                Show-Message "No PowerShell script files (.ps1) were found in the selected folder or its subdirectories." "No Files Found" "OK" "Information"
                return
            }

            $statusLabel.Text = "Found $($ps1Files.Count) .ps1 files. Reading content..."

            foreach ($file in $ps1Files) {
                try {
                    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                    $scriptObject = [PSCustomObject]@{
                        FileName = $file.FullName
                        Content  = $content
                    }
                    $scriptData += $scriptObject
                } catch {
                    # Log individual file read errors but continue with others
                    Write-Error "Could not read file: $($file.FullName). Error: $($_.Exception.Message)"
                    $statusLabel.Text = "Error reading some files. Check console for details. Continuing..."
                }
            }

            $statusLabel.Text = "Content read. Preparing to save JSON file..."

            # Save File Dialog
            $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveFileDialog.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
            $saveFileDialog.Title = "Save the compiled JSON file"
            $saveFileDialog.FileName = "compiled_ps1_scripts.json" # Default file name
            $saveFileDialog.InitialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop) # Default to Desktop

            if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $outputPath = $saveFileDialog.FileName

                try {
                    # Convert the array of script objects to JSON
                    # Use a high depth to ensure full content is included, especially for complex scripts
                    $jsonContent = $scriptData | ConvertTo-Json -Depth 100 -Compress # Compress for single line if preferred, remove -Compress for pretty print

                    # Save the JSON content to the specified file
                    Set-Content -Path $outputPath -Value $jsonContent -Encoding UTF8 -ErrorAction Stop

                    $statusLabel.Text = "Successfully converted and saved to: '$outputPath'"
                    Show-Message "All .ps1 files have been successfully compiled into '$outputPath'." "Conversion Complete" "OK" "Information"
                } catch {
                    $errorMessage = "Error saving JSON file: $($_.Exception.Message)"
                    $statusLabel.Text = $errorMessage
                    Show-Message $errorMessage "Error" "OK" "Error"
                    Write-Error $errorMessage # Also write to console for debugging
                }
            } else {
                $statusLabel.Text = "Save operation cancelled by user."
            }
        } catch {
            $errorMessage = "An error occurred during file scanning or processing: $($_.Exception.Message)"
            $statusLabel.Text = $errorMessage
            Show-Message $errorMessage "Error" "OK" "Error"
            Write-Error $errorMessage # Also write to console for debugging
        }
    } else {
        $statusLabel.Text = "Folder selection cancelled by user."
    }
})
#endregion

#region Run Form
# Show the form and keep the script running until the form is closed
$form.ShowDialog() | Out-Null

# Keep the console window open if the script is run directly (e.g., via double-click)
# This provides a pause for error messages to be visible.
if ($Host.UI.RawUI.WindowSize.Height -gt 0) { # Check if a console window exists
    Write-Host "`nScript finished. Press any key to close this console window..." -ForegroundColor Green
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}
#endregion
