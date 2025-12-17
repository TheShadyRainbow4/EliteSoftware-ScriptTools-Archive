# Define the PowerShell script with a GUI for Local Group Policy management
# This script focuses on managing Local Group Policy (LGP) settings,
# which are policies applied directly to a single computer, rather than
# domain-based Group Policies.

#region GUI Setup
# Load necessary .NET assemblies for creating the GUI.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form (window) for the application.
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Local Group Policy Manager" # Title of the window
$mainForm.Size = New-Object System.Drawing.Size(550, 430) # Set the initial size (width, height), increased for new button
$mainForm.StartPosition = "CenterScreen" # Center the window on the screen
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle # Prevent resizing
$mainForm.MaximizeBox = $false # Disable maximize button
$mainForm.MinimizeBox = $false # Disable minimize button
$mainForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0") # Set a light gray background color

# Create a status bar at the bottom of the form to display messages.
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready" # Initial status message
$statusBar.Items.Add($statusLabel) # Add the label to the status bar
$mainForm.Controls.Add($statusBar) # Add the status bar to the form controls

# Define a function to easily update the status message in the GUI.
# It allows setting the message text and its color.
function Update-Status ($message, $color = "Black") {
    $statusLabel.Text = $message
    $statusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($color)
}

# Create a GroupBox for path selection (where backups will be stored/restored from).
$pathGroupBox = New-Object System.Windows.Forms.GroupBox
$pathGroupBox.Text = "Backup/Restore Path" # Text displayed on the group box
$pathGroupBox.Location = New-Object System.Drawing.Point(20, 20) # Position (x, y)
$pathGroupBox.Size = New-Object System.Drawing.Size(490, 80) # Size (width, height)
$pathGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Set font
$mainForm.Controls.Add($pathGroupBox) # Add to the main form

# Create a TextBox to display and edit the backup/restore path.
$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Location = New-Object System.Drawing.Point(10, 30) # Position within the group box
$pathTextBox.Size = New-Object System.Drawing.Size(380, 25) # Size
# Corrected: Use -bOr for bitwise combination of AnchorStyles.
$pathTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bOr [System.Windows.Forms.AnchorStyles]::Right
$pathTextBox.Text = "$env:USERPROFILE\Documents\LGP_Backups" # Set a default path
$pathGroupBox.Controls.Add($pathTextBox) # Add to the path group box

# Create a Browse Button to open a folder selection dialog.
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse" # Button text
$browseButton.Location = New-Object System.Drawing.Point(400, 28) # Position
$browseButton.Size = New-Object System.Drawing.Size(75, 28) # Size
# Add an event handler for when the button is clicked.
$browseButton.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog # Create a new folder browser dialog
    $folderBrowserDialog.SelectedPath = $pathTextBox.Text # Set the initial path in the dialog
    # If the user selects a folder and clicks OK, update the text box.
    if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathTextBox.Text = $folderBrowserDialog.SelectedPath
    }
})
$pathGroupBox.Controls.Add($browseButton) # Add to the path group box

# Create a GroupBox for action buttons (Backup, Restore, Defaults, Open Editor, View Policy Files).
$actionGroupBox = New-Object System.Windows.Forms.GroupBox
$actionGroupBox.Text = "Actions" # Text for the group box
$actionGroupBox.Location = New-Object System.Drawing.Point(20, 110) # Position
$actionGroupBox.Size = New-Object System.Drawing.Size(490, 220) # Size (increased height for new button)
$actionGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Set font
$mainForm.Controls.Add($actionGroupBox) # Add to the main form

# Create the Backup Button.
$backupButton = New-Object System.Windows.Forms.Button
$backupButton.Text = "Backup Local GPO" # Button text
$backupButton.Location = New-Object System.Drawing.Point(20, 30) # Position
$backupButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$backupButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$backupButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50") # Green background
$backupButton.ForeColor = [System.Drawing.Color]::White # White text color
$backupButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$backupButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($backupButton) # Add to action group box

# Create the Restore Button.
$restoreButton = New-Object System.Windows.Forms.Button
$restoreButton.Text = "Restore Local GPO" # Button text
$restoreButton.Location = New-Object System.Drawing.Point(250, 30) # Position
$restoreButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$restoreButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$restoreButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2196F3") # Blue background
$restoreButton.ForeColor = [System.Drawing.Color]::White # White text
$restoreButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$restoreButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($restoreButton) # Add to action group box

# Create the Restore Defaults Button.
$restoreDefaultsButton = New-Object System.Windows.Forms.Button
$restoreDefaultsButton.Text = "Restore Local GPO Defaults" # Button text
$restoreDefaultsButton.Location = New-Object System.Drawing.Point(20, 80) # Position
$restoreDefaultsButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$restoreDefaultsButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$restoreDefaultsButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFC107") # Amber background
$restoreDefaultsButton.ForeColor = [System.Drawing.Color]::Black # Black text
$restoreDefaultsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$restoreDefaultsButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($restoreDefaultsButton) # Add to action group box

# Create the Open Group Policy Editor Button.
$openGPEditorButton = New-Object System.Windows.Forms.Button
$openGPEditorButton.Text = "Open Local Group Policy Editor" # Button text
$openGPEditorButton.Location = New-Object System.Drawing.Point(250, 80) # Position
$openGPEditorButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$openGPEditorButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$openGPEditorButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#9E9E9E") # Gray background
$openGPEditorButton.ForeColor = [System.Drawing.Color]::White # White text
$openGPEditorButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$openGPEditorButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($openGPEditorButton) # Add to action group box

# Create the View Current Policy Files Button (New Feature).
$viewPolicyFilesButton = New-Object System.Windows.Forms.Button
$viewPolicyFilesButton.Text = "View Current Policy Files" # Button text
$viewPolicyFilesButton.Location = New-Object System.Drawing.Point(20, 130) # Position (new row)
$viewPolicyFilesButton.Size = New-Object System.Drawing.Size(450, 40) # Wider button for emphasis
$viewPolicyFilesButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$viewPolicyFilesButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#607D8B") # Blue-gray background
$viewPolicyFilesButton.ForeColor = [System.Drawing.Color]::White # White text
$viewPolicyFilesButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$viewPolicyFilesButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($viewPolicyFilesButton) # Add to action group box

# Information Label to remind the user about Administrator privileges.
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Note: This tool manages Local Group Policy. Run as Administrator!"
$infoLabel.Location = New-Object System.Drawing.Point(20, 340) # Position (adjusted due to increased actionGroupBox height)
$infoLabel.Size = New-Object System.Drawing.Size(490, 30) # Size
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic) # Italic font
$infoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter # Center text alignment
$infoLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D32F2F") # Dark Red text color
$mainForm.Controls.Add($infoLabel) # Add to the main form

#endregion GUI Setup

#region Local GPO Functions

# Function to check if the script is running with Administrator privileges.
function Test-IsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to force a Group Policy update after changes.
function Invoke-GPUpdate {
    Update-Status "Applying Group Policy update..." "Gray"
    try {
        # Start the gpupdate.exe process and wait for it to complete.
        $process = Start-Process -FilePath "gpupdate.exe" -ArgumentList "/force" -Wait -PassThru
        # Check the exit code of the gpupdate process.
        if ($process.ExitCode -eq 0) {
            Update-Status "Group Policy updated successfully." "Green"
        } else {
            Update-Status "Error during Group Policy update. Exit code: $($process.ExitCode)" "Red"
        }
    } catch {
        # Catch any errors during the process execution.
        Update-Status "Failed to run gpupdate: $($_.Exception.Message)" "Red"
    }
}

# Define the standard paths for Local Group Policy folders.
$localGPOPath = Join-Path $env:SystemRoot "System32\GroupPolicy" # Contains machine-specific policies
$localGPOUsersPath = Join-Path $env:SystemRoot "System32\GroupPolicyUsers" # Contains user-specific policies

# Event handler for the Backup Button.
$backupButton.Add_Click({
    # Check for Administrator privileges.
    if (-not (Test-IsAdministrator)) {
        Update-Status "Error: Please run this script as Administrator to perform backups." "Red"
        return # Exit the function if not admin
    }

    # The script backs up the *active* Local Group Policy settings from their standard system locations.
    # The 'Backup/Restore Path' above specifies *where* the backup files will be saved *to*.
    $backupPath = $pathTextBox.Text # Get the desired backup destination path from the text box.
    # Create the backup directory if it doesn't exist.
    if (-not (Test-Path $backupPath)) {
        try {
            New-Item -ItemType Directory -Path $backupPath | Out-Null
            Update-Status "Created backup directory: $backupPath" "Blue"
        } catch {
            Update-Status "Error creating backup directory: $($_.Exception.Message)" "Red"
            return # Exit on error
        }
    }

    # Create a unique timestamp for the backup folder name.
    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $destinationPath = Join-Path $backupPath "LGP_Backup_$timestamp"

    Update-Status "Backing up active Local Group Policy to '$destinationPath'..." "Black"
    try {
        # Copy the machine GroupPolicy folder if it exists.
        if (Test-Path $localGPOPath) {
            Copy-Item -Path $localGPOPath -Destination $destinationPath -Recurse -Force -ErrorAction Stop
        } else {
            Update-Status "Warning: GroupPolicy folder not found at '$localGPOPath', skipping." "Orange"
        }
        # Copy the user GroupPolicyUsers folder if it exists.
        if (Test-Path $localGPOUsersPath) {
            Copy-Item -Path $localGPOUsersPath -Destination $destinationPath -Recurse -Force -ErrorAction Stop
        } else {
            Update-Status "Warning: GroupPolicyUsers folder not found at '$localGPOUsersPath', skipping." "Orange"
        }

        # Verify if the backup folder was successfully created.
        if (Test-Path $destinationPath) {
            Update-Status "Local GPO backup completed successfully to '$destinationPath'." "Green"
        } else {
            Update-Status "Backup failed: Destination path not created." "Red"
        }
    } catch {
        # Catch any errors during the copy process.
        Update-Status "Backup failed: $($_.Exception.Message)" "Red"
    }
})

# Event handler for the Restore Button.
$restoreButton.Add_Click({
    # Check for Administrator privileges.
    if (-not (Test-IsAdministrator)) {
        Update-Status "Error: Please run this script as Administrator to perform restores." "Red"
        return # Exit if not admin
    }

    $backupPath = $pathTextBox.Text # Get the base backup path.
    # Ensure the backup path exists.
    if (-not (Test-Path $backupPath)) {
        Update-Status "Error: Backup path '$backupPath' does not exist. Please specify a valid path first." "Red"
        return
    }

    # Open a folder browser dialog to allow the user to select a specific backup folder.
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select the specific Local GPO backup folder to restore from."
    $dialog.SelectedPath = $backupPath # Set initial path
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedBackupFolder = $dialog.SelectedPath # Get the selected folder path.

        # Ensure the selected path is actually a directory.
        if (-not (Test-Path $selectedBackupFolder -PathType Container)) {
            Update-Status "Error: Selected path is not a valid folder." "Red"
            return
        }

        Update-Status "Restoring Local GPO from '$selectedBackupFolder'..." "Black"
        try {
            # Attempt to clear existing policy folders to ensure a clean restore.
            if (Test-Path $localGPOPath) {
                Remove-Item -Path $localGPOPath -Recurse -Force -ErrorAction SilentlyContinue
                Update-Status "Cleared existing '$localGPOPath'." "Blue"
            }
            if (Test-Path $localGPOUsersPath) {
                Remove-Item -Path $localGPOUsersPath -Recurse -Force -ErrorAction SilentlyContinue
                Update-Status "Cleared existing '$localGPOUsersPath'." "Blue"
            }

            # Construct paths to the actual GroupPolicy and GroupPolicyUsers folders within the backup.
            $sourceGPO = Join-Path $selectedBackupFolder (Split-Path $localGPOPath -Leaf) # e.g., ...\LGP_Backup_2023...\GroupPolicy
            $sourceGPOUsers = Join-Path $selectedBackupFolder (Split-Path $localGPOUsersPath -Leaf) # e.g., ...\LGP_Backup_2023...\GroupPolicyUsers

            # Copy the backed-up policy folders back to their original locations.
            if (Test-Path $sourceGPO) {
                Copy-Item -Path $sourceGPO -Destination (Split-Path $localGPOPath -Parent) -Recurse -Force -ErrorAction Stop
            } else {
                Update-Status "Warning: 'GroupPolicy' folder not found in backup. Skipping its restoration." "Orange"
            }
            if (Test-Path $sourceGPOUsers) {
                Copy-Item -Path $sourceGPOUsers -Destination (Split-Path $localGPOUsersPath -Parent) -Recurse -Force -ErrorAction Stop
            } else {
                Update-Status "Warning: 'GroupPolicyUsers' folder not found in backup. Skipping its restoration." "Orange"
            }

            Update-Status "Local GPO restoration completed. Applying policy update..." "Green"
            Invoke-GPUpdate # Force a Group Policy update to apply restored settings.

        } catch {
            # Catch any errors during the restore process.
            Update-Status "Restoration failed: $($_.Exception.Message)" "Red"
        }
    } else {
        Update-Status "Restore operation cancelled." "Gray"
    }
})

# Event handler for the Restore Defaults Button.
$restoreDefaultsButton.Add_Click({
    # Check for Administrator privileges.
    if (-not (Test-IsAdministrator)) {
        Update-Status "Error: Please run this script as Administrator to restore defaults." "Red"
        return # Exit if not admin
    }

    # Show a confirmation message box before proceeding with deleting policies.
    $dialogResult = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to restore Local Group Policy to defaults? This will delete existing local policy settings.",
        "Confirm Restore Defaults", # Dialog title
        [System.Windows.Forms.MessageBoxButtons]::YesNo, # Buttons available
        [System.Windows.Forms.MessageBoxIcon]::Warning # Icon displayed
    )

    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
        Update-Status "Restoring Local Group Policy to defaults..." "Black"
        try {
            # Delete the GroupPolicy folder if it exists.
            if (Test-Path $localGPOPath) {
                Remove-Item -Path $localGPOPath -Recurse -Force -ErrorAction SilentlyContinue
                Update-Status "Deleted '$localGPOPath'." "Blue"
            }
            # Delete the GroupPolicyUsers folder if it exists.
            if (Test-Path $localGPOUsersPath) {
                Remove-Item -Path $localGPOUsersPath -Recurse -Force -ErrorAction SilentlyContinue
                Update-Status "Deleted '$localGPOUsersPath'." "Blue"
            }
            
            Update-Status "Local Group Policy settings cleared. Applying policy update..." "Green"
            Invoke-GPUpdate # Force a Group Policy update.
            
        } catch {
            # Catch any errors during the deletion process.
            Update-Status "Failed to restore defaults: $($_.Exception.Message)" "Red"
        }
    } else {
        Update-Status "Restore defaults cancelled." "Gray"
    }
})

# Event handler for the Open GP Editor Button.
$openGPEditorButton.Add_Click({
    Update-Status "Opening Local Group Policy Editor..." "Black"
    try {
        # Start the gpedit.msc process.
        Start-Process -FilePath "gpedit.msc" -ErrorAction Stop
        Update-Status "Local Group Policy Editor opened." "Green"
    } catch {
        # Catch errors, e.g., if gpedit.msc is not found (not available on Home editions).
        Update-Status "Failed to open gpedit.msc. Make sure it's installed on your system (not available on Windows Home editions). Error: $($_.Exception.Message)" "Red"
    }
})

# Event handler for the new View Current Policy Files Button.
$viewPolicyFilesButton.Add_Click({
    Update-Status "Opening Local Group Policy directories in File Explorer..." "Black"
    try {
        # Open the machine GroupPolicy folder in File Explorer.
        if (Test-Path $localGPOPath) {
            Start-Process -FilePath "explorer.exe" -ArgumentList $localGPOPath -ErrorAction Stop
            Update-Status "Opened '$localGPOPath'." "Green"
        } else {
            Update-Status "Warning: GroupPolicy folder not found at '$localGPOPath'." "Orange"
        }

        # Open the user GroupPolicyUsers folder in File Explorer.
        if (Test-Path $localGPOUsersPath) {
            Start-Process -FilePath "explorer.exe" -ArgumentList $localGPOUsersPath -ErrorAction Stop
            Update-Status "Opened '$localGPOUsersPath'." "Green"
        } else {
            Update-Status "Warning: GroupPolicyUsers folder not found at '$localGPOUsersPath'." "Orange"
        }
    } catch {
        # Catch any errors during the process execution.
        Update-Status "Failed to open policy directories: $($_.Exception.Message)" "Red"
    }
})

#endregion Local GPO Functions

# Display the main form to the user. This line is blocking until the form is closed.
$mainForm.ShowDialog() | Out-Null

# Clean up variables after the form is closed.
Remove-Variable -Name mainForm, pathGroupBox, pathTextBox, browseButton, actionGroupBox, backupButton, restoreButton, restoreDefaultsButton, openGPEditorButton, viewPolicyFilesButton, infoLabel, statusBar, statusLabel -ErrorAction SilentlyContinue
