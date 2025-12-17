<#
.SYNOPSIS
    A stable, user-friendly GUI tool to create, manage, and remove custom file associations in the Windows Registry.

.DESCRIPTION
    This PowerShell script provides a graphical interface for managing file type associations.
    Users can define a file extension, link it to an executable, provide a description,
    and set custom command-line arguments. It supports creating associations for the
    current user or for all users (requires administrative privileges). It also includes
    functionality to cleanly remove created associations.

.VERSION
    2.2.0.0

.AUTHOR
    Gemini (based on original script by Zach)

.NOTES
    v2.2 - Added an automatic check and relaunch mechanism to ensure the script runs in Single-Threaded Apartment (STA) mode, fixing instant crashes in certain environments.
    v2.1 - Refactored core logic to be separate from UI updates, fixing instability and crash-on-launch issues.
         - Modernized assembly loading.
         - Improved error handling and user feedback.
#>

# ---------------------------------------------------------------------------------
# 0.) STA MODE ENFORCEMENT
# ---------------------------------------------------------------------------------
# PowerShell GUI applications require Single-Threaded Apartment (STA) mode.
# If the script is not running in STA mode, it can crash instantly upon launch.
# This block checks the current mode and automatically relaunches the script in STA mode if necessary.
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    try {
        # Relaunch powershell with the -STA switch and the current script path.
        $scriptPath = $MyInvocation.MyCommand.Definition
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$scriptPath`""
    }
    catch {
        Write-Error "Failed to relaunch script in STA mode. Please run manually: powershell.exe -STA -File `"$($MyInvocation.MyCommand.Definition)`""
    }
    # Exit the current (non-STA) session.
    exit
}


# ---------------------------------------------------------------------------------
# 1.) SETUP & HELPER FUNCTIONS
# ---------------------------------------------------------------------------------
#region Setup and Helpers

# Load required .NET assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a shared ToolTip object for the entire form
$script:ToolTip = New-Object System.Windows.Forms.ToolTip
$script:ToolTip.InitialDelay = 500
$script:ToolTip.AutoPopDelay = 10000 # Keep tooltip open for 10 seconds

function Show-HelpWindow {
    $helpForm = New-Object System.Windows.Forms.Form
    $helpForm.Text = "Help & Examples"
    $helpForm.Size = New-Object System.Drawing.Size(600, 500)
    $helpForm.StartPosition = "CenterParent"
    $helpForm.FormBorderStyle = "FixedDialog"
    $helpForm.MaximizeBox = $false
    $helpForm.MinimizeBox = $false

    $helpTextBox = New-Object System.Windows.Forms.TextBox
    $helpTextBox.Multiline = $true
    $helpTextBox.ReadOnly = $true
    $helpTextBox.Dock = "Fill"
    $helpTextBox.ScrollBars = "Vertical"
    $helpTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $helpTextBox.Text = @"
Welcome to the File Association Manager!

This tool helps you associate a file extension (like .ZACH) with a program that can open it.

--- FIELDS EXPLAINED ---

- File Extension: The part of the filename after the dot (e.g., .txt, .log, .ZACH).

- Programmatic ID (ProgID): A unique name for the file type in the registry. Convention is 'AppName.FileType.Version' (e.g., Zach.Script.1).

- File Description: A friendly name that appears in File Explorer (e.g., "ZACH PowerShell Script").

- Application Path: The full path to the .exe file that will open your custom file.

- Command Arguments: Special instructions for the program. Use `"%1"` as a placeholder for the path of the file you are opening.

----------------------------------------------------
--- EXAMPLE 1: Associate .ZACH with PowerShell 7 ---
----------------------------------------------------

This will make it so that double-clicking a .ZACH file runs it with PowerShell 7.

1.  File Extension:
    .ZACH

2.  Programmatic ID:
    Zach.PSScript.1

3.  File Description:
    ZACH PowerShell 7 Script

4.  Application Path: (Use the Browse button to find it)
    C:\Program Files\PowerShell\7\pwsh.exe

5.  Command Arguments:
    -NoProfile -File "%1"

----------------------------------------------------
--- EXAMPLE 2: Associate .CMDZ with Windows CMD ---
----------------------------------------------------

This will execute a .CMDZ file using the Windows Command Prompt.

1.  File Extension:
    .CMDZ

2.  Programmatic ID:
    Zach.CMDFile.1

3.  File Description:
    ZACH CMD Batch File

4.  Application Path: (Use the Browse button to find it)
    C:\Windows\System32\cmd.exe

5.  Command Arguments:
    /C "%1"

----------------------------------------------------
"@
    $helpForm.Controls.Add($helpTextBox)
    $helpForm.ShowDialog()
}
#endregion

# ---------------------------------------------------------------------------------
# 2.) CORE SCRIPT LOGIC (REGISTRY OPERATIONS)
# ---------------------------------------------------------------------------------
#region Core Logic

function Set-FileAssociation {
    param (
        [string]$Extension,
        [string]$ProgId,
        [string]$Description,
        [string]$AppPath,
        [string]$Arguments,
        [bool]$AllUsers
    )

    try {
        if ($AllUsers) {
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
            if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
                return [PSCustomObject]@{ Success = $false; Message = "Error: 'All Users' requires running the script as Administrator." }
            }
            $regRoot = "HKLM:\Software\Classes\"
        }
        else {
            $regRoot = "HKCU:\Software\Classes\"
        }

        # Create extension key and link to ProgID
        $extPath = Join-Path -Path $regRoot -ChildPath $Extension
        if (-not (Test-Path $extPath)) { New-Item -Path $extPath -Force | Out-Null }
        Set-ItemProperty -Path $extPath -Name "(Default)" -Value $ProgId -Force

        # Create ProgID key with description
        $progIdPath = Join-Path -Path $regRoot -ChildPath $ProgId
        if (-not (Test-Path $progIdPath)) { New-Item -Path $progIdPath -Force | Out-Null }
        Set-ItemProperty -Path $progIdPath -Name "(Default)" -Value $Description -Force

        # Create the command key with the application path and arguments
        $commandPath = Join-Path -Path $progIdPath -ChildPath "shell\Open\command"
        if (-not (Test-Path $commandPath)) { New-Item -Path $commandPath -Force | Out-Null }
        $commandValue = "`"$AppPath`" $Arguments"
        Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $commandValue -Force

        return [PSCustomObject]@{ Success = $true; Message = "Success! Association for '$Extension' created/updated." }
    }
    catch {
        return [PSCustomObject]@{ Success = $false; Message = "Error: $($_.Exception.Message)" }
    }
}

function Remove-FileAssociation {
    param (
        [string]$Extension,
        [string]$ProgId,
        [bool]$AllUsers
    )

    try {
        if ($AllUsers) {
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
            if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
                return [PSCustomObject]@{ Success = $false; Message = "Error: 'All Users' requires running the script as Administrator." }
            }
            $regRoot = "HKLM:\Software\Classes\"
        }
        else {
            $regRoot = "HKCU:\Software\Classes\"
        }

        $extPath = Join-Path -Path $regRoot -ChildPath $Extension
        $progIdPath = Join-Path -Path $regRoot -ChildPath $ProgId

        # Remove keys if they exist
        if (Test-Path $progIdPath) { Remove-Item -Path $progIdPath -Recurse -Force }
        if (Test-Path $extPath) { Remove-Item -Path $extPath -Recurse -Force }

        return [PSCustomObject]@{ Success = $true; Message = "Success! Association for '$Extension' removed." }
    }
    catch {
        return [PSCustomObject]@{ Success = $false; Message = "Error: $($_.Exception.Message)" }
    }
}
#endregion

# ---------------------------------------------------------------------------------
# 3.) UI ELEMENT CREATION & FORM LAYOUT
# ---------------------------------------------------------------------------------
#region Form and Controls

try {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "File Association Manager v2.1"
    $form.Size = New-Object System.Drawing.Size(550, 480)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

    # Main group box
    $mainGroup = New-Object System.Windows.Forms.GroupBox
    $mainGroup.Text = "Association Details"
    $mainGroup.Location = New-Object System.Drawing.Point(10, 10)
    $mainGroup.Size = New-Object System.Drawing.Size(515, 360)
    $form.Controls.Add($mainGroup)

    # --- Row 1: Extension ---
    $labelExt = New-Object System.Windows.Forms.Label
    $labelExt.Text = "File Extension:"
    $labelExt.Location = New-Object System.Drawing.Point(20, 35)
    $labelExt.Size = New-Object System.Drawing.Size(180, 20)
    $mainGroup.Controls.Add($labelExt)

    $textBoxExt = New-Object System.Windows.Forms.TextBox
    $textBoxExt.Location = New-Object System.Drawing.Point(200, 35)
    $textBoxExt.Size = New-Object System.Drawing.Size(290, 20)
    $script:ToolTip.SetToolTip($textBoxExt, "The extension to associate, starting with a dot (e.g., .zach)")
    $mainGroup.Controls.Add($textBoxExt)

    # --- Row 2: ProgID ---
    $labelProgID = New-Object System.Windows.Forms.Label
    $labelProgID.Text = "Programmatic ID (ProgID):"
    $labelProgID.Location = New-Object System.Drawing.Point(20, 75)
    $labelProgID.Size = New-Object System.Drawing.Size(180, 20)
    $mainGroup.Controls.Add($labelProgID)

    $textBoxProgID = New-Object System.Windows.Forms.TextBox
    $textBoxProgID.Location = New-Object System.Drawing.Point(200, 75)
    $textBoxProgID.Size = New-Object System.Drawing.Size(290, 20)
    $script:ToolTip.SetToolTip($textBoxProgID, "A unique registry identifier (e.g., Zach.Script.1)")
    $mainGroup.Controls.Add($textBoxProgID)

    # --- Row 3: Description ---
    $labelDesc = New-Object System.Windows.Forms.Label
    $labelDesc.Text = "File Description:"
    $labelDesc.Location = New-Object System.Drawing.Point(20, 115)
    $labelDesc.Size = New-Object System.Drawing.Size(180, 20)
    $mainGroup.Controls.Add($labelDesc)

    $textBoxDesc = New-Object System.Windows.Forms.TextBox
    $textBoxDesc.Location = New-Object System.Drawing.Point(200, 115)
    $textBoxDesc.Size = New-Object System.Drawing.Size(290, 20)
    $script:ToolTip.SetToolTip($textBoxDesc, "Friendly name shown in Windows Explorer (e.g., 'ZACH Script File')")
    $mainGroup.Controls.Add($textBoxDesc)

    # --- Row 4: Application Path ---
    $labelAppPath = New-Object System.Windows.Forms.Label
    $labelAppPath.Text = "Application Path:"
    $labelAppPath.Location = New-Object System.Drawing.Point(20, 155)
    $labelAppPath.Size = New-Object System.Drawing.Size(180, 20)
    $mainGroup.Controls.Add($labelAppPath)

    $textBoxAppPath = New-Object System.Windows.Forms.TextBox
    $textBoxAppPath.Location = New-Object System.Drawing.Point(200, 155)
    $textBoxAppPath.Size = New-Object System.Drawing.Size(200, 20)
    $script:ToolTip.SetToolTip($textBoxAppPath, "The full path to the executable file.")
    $mainGroup.Controls.Add($textBoxAppPath)

    $buttonBrowse = New-Object System.Windows.Forms.Button
    $buttonBrowse.Text = "Browse..."
    $buttonBrowse.Location = New-Object System.Drawing.Point(410, 153)
    $buttonBrowse.Size = New-Object System.Drawing.Size(80, 25)
    $mainGroup.Controls.Add($buttonBrowse)

    # --- Row 5: Arguments ---
    $labelArgs = New-Object System.Windows.Forms.Label
    $labelArgs.Text = "Command Arguments:"
    $labelArgs.Location = New-Object System.Drawing.Point(20, 195)
    $labelArgs.Size = New-Object System.Drawing.Size(180, 20)
    $mainGroup.Controls.Add($labelArgs)

    $textBoxArgs = New-Object System.Windows.Forms.TextBox
    $textBoxArgs.Location = New-Object System.Drawing.Point(200, 195)
    $textBoxArgs.Size = New-Object System.Drawing.Size(290, 20)
    $textBoxArgs.Text = `"%1"` # Default value
    $script:ToolTip.SetToolTip($textBoxArgs, "Command-line arguments. Use `"%1`" for the file path.")
    $mainGroup.Controls.Add($textBoxArgs)

    # --- Row 6: All Users Checkbox ---
    $checkBoxAllUsers = New-Object System.Windows.Forms.CheckBox
    $checkBoxAllUsers.Text = "Register for all users (Requires Admin)"
    $checkBoxAllUsers.Location = New-Object System.Drawing.Point(200, 230)
    $checkBoxAllUsers.Size = New-Object System.Drawing.Size(290, 24)
    $script:ToolTip.SetToolTip($checkBoxAllUsers, "Check this to create the association in HKEY_LOCAL_MACHINE.")
    $mainGroup.Controls.Add($checkBoxAllUsers)

    # --- Action Buttons ---
    $buttonCreate = New-Object System.Windows.Forms.Button
    $buttonCreate.Text = "Create / Update Association"
    $buttonCreate.Location = New-Object System.Drawing.Point(20, 270)
    $buttonCreate.Size = New-Object System.Drawing.Size(470, 35)
    $buttonCreate.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $buttonCreate.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
    $buttonCreate.ForeColor = [System.Drawing.Color]::White
    $buttonCreate.FlatStyle = "Flat"
    $mainGroup.Controls.Add($buttonCreate)

    $buttonRemove = New-Object System.Windows.Forms.Button
    $buttonRemove.Text = "Remove Association"
    $buttonRemove.Location = New-Object System.Drawing.Point(20, 315)
    $buttonRemove.Size = New-Object System.Drawing.Size(470, 35)
    $buttonRemove.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $buttonRemove.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $buttonRemove.ForeColor = [System.Drawing.Color]::White
    $buttonRemove.FlatStyle = "Flat"
    $mainGroup.Controls.Add($buttonRemove)

    # --- Status Label ---
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Status: Ready. Fill in the details and click a button."
    $statusLabel.Location = New-Object System.Drawing.Point(10, 380)
    $statusLabel.Size = New-Object System.Drawing.Size(515, 20)
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $statusLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($statusLabel)

    # --- Help Button ---
    $buttonHelp = New-Object System.Windows.Forms.Button
    $buttonHelp.Text = "Help & Examples"
    $buttonHelp.Location = New-Object System.Drawing.Point(385, 410)
    $buttonHelp.Size = New-Object System.Drawing.Size(140, 25)
    $form.Controls.Add($buttonHelp)

}
catch {
    # This will catch any errors during form initialization
    [System.Windows.Forms.MessageBox]::Show(
        "A fatal error occurred while initializing the GUI: $($_.Exception.Message)",
        "Initialization Error",
        "OK",
        "Error"
    )
    exit
}
#endregion

# ---------------------------------------------------------------------------------
# 4.) EVENT HANDLERS
# ---------------------------------------------------------------------------------
#region Event Handlers

$buttonBrowse.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Executables (*.exe)|*.exe|All files (*.*)|*.*"
    $openFileDialog.Title = "Select Application"
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $textBoxAppPath.Text = $openFileDialog.FileName
    }
})

$buttonCreate.Add_Click({
    # --- Input Validation ---
    $extension = $textBoxExt.Text
    if ([string]::IsNullOrWhiteSpace($extension)) {
        $statusLabel.Text = "Error: File Extension cannot be empty."
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        return
    }
    if (-not $extension.StartsWith(".")) { $extension = ".$extension" }

    $progId = $textBoxProgID.Text
    $appPath = $textBoxAppPath.Text
    if ([string]::IsNullOrWhiteSpace($progId) -or [string]::IsNullOrWhiteSpace($appPath)) {
        $statusLabel.Text = "Error: ProgID and Application Path are required."
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        return
    }

    # Call the logic function and get a result object back
    $result = Set-FileAssociation -Extension $extension -ProgId $progId -Description $textBoxDesc.Text -AppPath $appPath -Arguments $textBoxArgs.Text -AllUsers $checkBoxAllUsers.Checked

    # Update the UI based on the result
    $statusLabel.Text = $result.Message
    $statusLabel.ForeColor = if ($result.Success) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
})

$buttonRemove.Add_Click({
    # --- Input Validation ---
    $extension = $textBoxExt.Text
    if ([string]::IsNullOrWhiteSpace($extension)) {
        $statusLabel.Text = "Error: File Extension cannot be empty."
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        return
    }
    if (-not $extension.StartsWith(".")) { $extension = ".$extension" }

    $progId = $textBoxProgID.Text
    if ([string]::IsNullOrWhiteSpace($progId)) {
        $statusLabel.Text = "Error: ProgID is required to remove an association."
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        return
    }

    $confirmResult = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to remove the association for '$extension'?",
        "Confirm Deletion",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($confirmResult -eq 'Yes') {
        # Call the logic function and get a result object back
        $result = Remove-FileAssociation -Extension $extension -ProgId $progId -AllUsers $checkBoxAllUsers.Checked
        
        # Update the UI based on the result
        $statusLabel.Text = $result.Message
        $statusLabel.ForeColor = if ($result.Success) { [System.Drawing.Color]::DarkBlue } else { [System.Drawing.Color]::Red }
    }
})

$buttonHelp.Add_Click({
    Show-HelpWindow
})

#endregion

# ---------------------------------------------------------------------------------
# 5.) SHOW THE FORM
# ---------------------------------------------------------------------------------
#region Show Form
$form.ShowDialog() | Out-Null
$form.Dispose() # Clean up the form resources when closed
#endregion

