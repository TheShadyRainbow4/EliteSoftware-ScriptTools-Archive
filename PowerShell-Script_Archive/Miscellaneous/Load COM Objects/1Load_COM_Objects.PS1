<#
.SYNOPSIS
    A PowerShell GUI tool to browse and launch COM objects.

.DESCRIPTION
    This script creates a Windows Forms application that enumerates registered
    COM objects on the system. It displays their ProgID (Programmatic ID) and
    CLSID (Class ID), and allows the user to filter/search through them.
    Selected COM objects can then be launched (instantiated).

    This tool is intended for advanced users and for educational/tinkering purposes.
    Instantiating unknown COM objects can lead to unexpected behavior or system instability.

.NOTES
    Author: Gemini (Your helpful artificial intelligence assistant)
    Date: 2025-06-20
    Version: 1.4 - Fixed boolean syntax error (true -> $true).

    IMPORTANT:
    1. PowerShell Execution Policy: You might need to adjust your PowerShell
       execution policy to run this script. Open PowerShell as administrator
       and run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
       (or Bypass if you're comfortable, but RemoteSigned is generally sufficient).
    2. COM Object Instantiation: Be cautious when launching COM objects. Some
       may have side effects, require specific parameters, or might not be
       designed for direct user interaction.
    3. Error Handling: The script includes basic error handling for COM object
       instantiation. More advanced error handling or specific parameter
       passing might be required for certain COM objects.

.EXAMPLE
    To run the script:
    1. Save the code below as a .ps1 file (e.g., ComObjectBrowser.ps1).
    2. Open PowerShell.
    3. Navigate to the directory where you saved the file.
    4. Run: .\ComObjectBrowser.ps1
#>

#region Load Assemblies
# Load necessary .NET assemblies for creating a Windows Forms GUI
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Write-Host "Successfully loaded System.Windows.Forms and System.Drawing assemblies."
}
catch {
    Write-Error "Failed to load required .NET assemblies. $($_.Exception.Message)"
    exit
}
#endregion

#region COM Object Definition Class
# Define a custom class to hold COM object properties for easier management
class ComObjectInfo {
    [string]$ProgID
    [string]$CLSID
    [string]$Description # This will be harder to find for all, so might be empty
    [string]$ServerType # InprocServer32 (DLL) or LocalServer32 (EXE)
    [string]$ServerPath # Path to the DLL/EXE
}
#endregion

#region Form Creation
# Create the main form for the GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell COM Object Browser"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle" # Prevent resizing for simplicity
$form.MaximizeBox = $false # Disable maximize button

# Set form icon (optional, default icon will be used if not specified)
# $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
#endregion

#region Controls Creation

# Label for search input
$labelSearch = New-Object System.Windows.Forms.Label
$labelSearch.Text = "Search (ProgID/CLSID/Description):"
$labelSearch.Location = New-Object System.Drawing.Point(10, 10)
$labelSearch.AutoSize = $true
$form.Controls.Add($labelSearch)

# Textbox for search input
$textBoxSearch = New-Object System.Windows.Forms.TextBox
$textBoxSearch.Location = New-Object System.Drawing.Point(10, 30)
$textBoxSearch.Size = New-Object System.Drawing.Size(860, 20)
$form.Controls.Add($textBoxSearch)

# DataGridView to display COM objects
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 60)
$dataGridView.Size = New-Object System.Drawing.Size(860, 500)
$dataGridView.AutoSizeColumnsMode = "Fill"
$dataGridView.SelectionMode = "FullRowSelect"
$dataGridView.MultiSelect = $false
$dataGridView.AllowUserToAddRows = $false
$dataGridView.ReadOnly = $true # Fixed: Changed 'true' to '$true'

# Add columns to the DataGridView
$colProgID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colProgID.Name = "ProgID"
$colProgID.HeaderText = "Programmatic ID"
$colProgID.Width = 250
$dataGridView.Columns.Add($colProgID)

$colCLSID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colCLSID.Name = "CLSID"
$colCLSID.HeaderText = "Class ID (GUID)"
$colCLSID.Width = 280
$dataGridView.Columns.Add($colCLSID)

$colDescription = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colDescription.Name = "Description"
$colDescription.HeaderText = "Description"
$colDescription.Width = 230
$dataGridView.Columns.Add($colDescription)

$colServerType = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colServerType.Name = "ServerType"
$colServerType.HeaderText = "Server Type"
$colServerType.Width = 100
$dataGridView.Columns.Add($colServerType)

$colServerPath = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colServerPath.Name = "ServerPath"
$colServerPath.HeaderText = "Server Path"
$colServerPath.Visible = $false # Hidden by default, can be shown in details
$dataGridView.Columns.Add($colServerPath)

$form.Controls.Add($dataGridView)

# Button to load COM objects
$buttonLoad = New-Object System.Windows.Forms.Button
$buttonLoad.Text = "Load COM Objects"
$buttonLoad.Location = New-Object System.Drawing.Point(10, 570)
$buttonLoad.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($buttonLoad)

# Button to launch selected COM object
$buttonLaunch = New-Object System.Windows.Forms.Button
$buttonLaunch.Text = "Launch Selected"
$buttonLaunch.Location = New-Object System.Drawing.Point(140, 570)
$buttonLaunch.Size = New-Object System.Drawing.Size(120, 30)
$buttonLaunch.Enabled = $false # Disable until an item is selected
$form.Controls.Add($buttonLaunch)

# Button to view details of selected COM object
$buttonDetails = New-Object System.Windows.Forms.Button
$buttonDetails.Text = "View Details"
$buttonDetails.Location = New-Object System.Drawing.Point(270, 570)
$buttonDetails.Size = New-Object System.Drawing.Size(120, 30)
$buttonDetails.Enabled = $false # Disable until an item is selected
$form.Controls.Add($buttonDetails)

# Label to display status messages
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = "Ready."
$labelStatus.Location = New-Object System.Drawing.Point(10, 610)
$labelStatus.AutoSize = $true
# Fix: Ensure $form.Width is treated as an integer for subtraction
$labelStatus.MaximumSize = New-Object System.Drawing.Size(([int]$form.Width - 20), 0) # Wrap text
$form.Controls.Add($labelStatus)

# List to hold all COM objects
$allComObjects = [System.Collections.Generic.List[ComObjectInfo]]::new()
# List to hold visible (filtered) COM objects
$filteredComObjects = [System.Collections.Generic.List[ComObjectInfo]]::new()

#endregion

#region Functions

# Function to safely get a registry property
function Get-RegProperty {
    param (
        [string]$Path,
        [string]$Name
    )
    try {
        (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    }
    catch {
        $null # Return null if not found or error
    }
}

# Function to enumerate and load COM objects
function Load-ComObjects {
    $labelStatus.Text = "Loading COM objects, please wait..."
    $form.Update() # Force GUI update

    $allComObjects.Clear() # Clear previous data

    # Determine the base path for CLSID enumeration
    # Check if HKCR: drive exists. If not, use the full HKEY_CLASSES_ROOT path.
    $baseClsidPath = if (Test-Path 'HKCR:\') { 'HKCR:\CLSID' } else { 'Registry::HKEY_CLASSES_ROOT\CLSID' }

    # Iterate through CLSIDs in the registry
    # This is where COM objects are registered.
    Get-Item -Path "$baseClsidPath\*" | ForEach-Object {
        $clsidPath = $_.PSPath
        $clsid = $_.PSChildName # The GUID
        
        # Fix for "null-valued expression" - ensure the result is a string before calling .Replace()
        $rawProgId = Get-RegProperty -Path $clsidPath -Name ""
        $progId = if ($rawProgId -ne $null) { $rawProgId.ToString().Replace(" ", "") } else { "" } # Default value is often ProgID

        # Try to find a description
        $description = (Get-RegProperty -Path $clsidPath -Name "LocalizedString")
        if (-not $description) {
            $description = (Get-RegProperty -Path $clsidPath -Name "") # Often contains ProgID or friendly name
            # Check for a more friendly name under the ProgID key if available
            # Adjust the Test-Path for ProgID as well
            $progIdRegPath = if (Test-Path 'HKCR:\') { "HKCR:\$progId" } else { "Registry::HKEY_CLASSES_ROOT\$progId" }
            if ($progId -and (Test-Path $progIdRegPath)) {
                $progIdDefault = (Get-RegProperty -Path $progIdRegPath -Name "")
                if ($progIdDefault -and $progIdDefault -ne $progId) {
                    $description = $progIdDefault
                }
            }
        }

        # Determine server type and path (InprocServer32 for DLLs, LocalServer32 for EXEs)
        $serverType = $null
        $serverPath = $null

        $inprocServer32Path = Join-Path $clsidPath "InprocServer32"
        if (Test-Path $inprocServer32Path) {
            $serverType = "InprocServer32"
            $serverPath = (Get-RegProperty -Path $inprocServer32Path -Name "")
            if (-not $serverPath) {
                # Sometimes the default is not set, look for CodeBase or similar
                $serverPath = (Get-RegProperty -Path $inprocServer32Path -Name "CodeBase")
            }
        }
        else {
            $localServer32Path = Join-Path $clsidPath "LocalServer32"
            if (Test-Path $localServer32Path) {
                $serverType = "LocalServer32"
                $serverPath = (Get-RegProperty -Path $localServer32Path -Name "")
            }
        }

        $comObject = [ComObjectInfo]::new()
        $comObject.ProgID = $progId
        $comObject.CLSID = $clsid
        $comObject.Description = $description
        $comObject.ServerType = $serverType
        $comObject.ServerPath = $serverPath

        $allComObjects.Add($comObject)
    }

    # Populate the DataGridView
    $filteredComObjects = $allComObjects | Select-Object ProgID, CLSID, Description, ServerType, ServerPath
    $dataGridView.DataSource = $filteredComObjects | Sort-Object ProgID # Sort alphabetically by ProgID

    $labelStatus.Text = "Loaded $($allComObjects.Count) COM objects."
}

# Function to filter COM objects based on search input
function Filter-ComObjects {
    $searchText = $textBoxSearch.Text.ToLower().Trim()

    if ([string]::IsNullOrEmpty($searchText)) {
        # If search box is empty, show all objects
        $dataGridView.DataSource = $allComObjects | Sort-Object ProgID
        $labelStatus.Text = "Displaying all $($allComObjects.Count) COM objects."
    }
    else {
        # Filter objects based on ProgID, CLSID, or Description
        $filtered = $allComObjects | Where-Object {
            $_.ProgID.ToLower().Contains($searchText) -or
            $_.CLSID.ToLower().Contains($searchText) -or
            ($_.Description -ne $null -and $_.Description.ToLower().Contains($searchText))
        } | Sort-Object ProgID

        $dataGridView.DataSource = $filtered
        $labelStatus.Text = "Found $($filtered.Count) matching COM objects."
    }
    $buttonLaunch.Enabled = $false
    $buttonDetails.Enabled = $false
}

# Function to launch the selected COM object
function Launch-SelectedComObject {
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGridView.SelectedRows[0]
        $progIdToLaunch = $selectedRow.Cells["ProgID"].Value

        if ([string]::IsNullOrEmpty($progIdToLaunch)) {
            [System.Windows.Forms.MessageBox]::Show("Selected item does not have a ProgID to launch.", "Error", "OK", "Error") | Out-Null
            $labelStatus.Text = "Error: No ProgID for selected item."
            return
        }

        try {
            $labelStatus.Text = "Attempting to launch '$progIdToLaunch'..."
            $form.Update()

            # Create an instance of the COM object
            $comObjectInstance = New-Object -ComObject $progIdToLaunch

            # Attempt to make it visible if it has a 'Visible' property (like IE, Word, Excel)
            # This is a common property for applications with a UI.
            if ($comObjectInstance -is [System.__ComObject] -and $comObjectInstance.PSMembers.MemberType -contains "Property") {
                $visibleProperty = $comObjectInstance.PSMembers | Where-Object {$_.Name -eq "Visible" -and $_.MemberType -eq "Property"} | Select-Object -First 1
                if ($visibleProperty -ne $null -and $visibleProperty.TypeNameOfValue -eq "System.Boolean") {
                    try {
                        $comObjectInstance.Visible = $true
                        $labelStatus.Text = "'$progIdToLaunch' launched and made visible."
                    }
                    catch {
                        $labelStatus.Text = "'$progIdToLaunch' launched, but failed to make visible (Error: $($_.Exception.Message))."
                    }
                }
                else {
                    $labelStatus.Text = "'$progIdToLaunch' launched (no 'Visible' property or not a boolean)."
                }
            }
            else {
                $labelStatus.Text = "'$progIdToLaunch' launched successfully, but no common 'Visible' property found."
            }

            # NOTE: For many COM objects, launching them just creates an in-memory instance
            # and doesn't necessarily open a GUI. You might need to interact with
            # $comObjectInstance further depending on its purpose.
            # E.g., for Word application: $comObjectInstance.Documents.Add()
            # For now, we'll just instantiate it.

        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to launch COM object '$progIdToLaunch'. Error: $($_.Exception.Message)", "Launch Error", "OK", "Error") | Out-Null
            $labelStatus.Text = "Launch failed: $($_.Exception.Message)"
        }
    }
}

# Function to show detailed information about the selected COM object
function Show-ComObjectDetails {
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGridView.SelectedRows[0]
        $selectedProgID = $selectedRow.Cells["ProgID"].Value
        $selectedCLSID = $selectedRow.Cells["CLSID"].Value
        $selectedDescription = $selectedRow.Cells["Description"].Value
        $selectedServerType = $selectedRow.Cells["ServerType"].Value
        $selectedServerPath = $selectedRow.Cells["ServerPath"].Value

        $details = @"
        ProgID: $selectedProgID
        CLSID: {$selectedCLSID}
        Description: $selectedDescription
        Server Type: $selectedServerType
        Server Path: $selectedServerPath

        Registry Path: HKCR:\CLSID\$selectedCLSID
"@

        # Optionally, add more registry details
        try {
            # Adjust the Test-Path for CLSID as well
            $clsidDetailsRegPath = if (Test-Path 'HKCR:\') { "HKCR:\CLSID\$selectedCLSID" } else { "Registry::HKEY_CLASSES_ROOT\CLSID\$selectedCLSID" }
            $registryDetails = Get-Item -Path $clsidDetailsRegPath -Recurse | Out-String
            $details += "`n`nRegistry Details:`n" + $registryDetails
        }
        catch {
            $details += "`n`nCould not retrieve full registry details for this CLSID."
        }

        [System.Windows.Forms.MessageBox]::Show($details, "COM Object Details", "OK", "Information") | Out-Null
    }
}

#endregion

#region Event Handlers

# Event handler for the search textbox (live filtering)
$textBoxSearch.Add_TextChanged({
    Filter-ComObjects
})

# Event handler for Load button click
$buttonLoad.Add_Click({
    Load-ComObjects
    $buttonLaunch.Enabled = $false
    $buttonDetails.Enabled = $false
})

# Event handler for Launch button click
$buttonLaunch.Add_Click({
    Launch-SelectedComObject
})

# Event handler for Details button click
$buttonDetails.Add_Click({
    Show-ComObjectDetails
})

# Event handler for DataGridView selection change
$dataGridView.Add_SelectionChanged({
    # Enable launch/details buttons if a row is selected
    $buttonLaunch.Enabled = ($dataGridView.SelectedRows.Count -gt 0)
    $buttonDetails.Enabled = ($dataGridView.SelectedRows.Count -gt 0)
})

#endregion

#region Show Form
# Initial load of COM objects when the form is shown
$form.Add_Shown({
    Load-ComObjects
})

# Show the form
$form.ShowDialog() | Out-Null

# Clean up any created COM objects if necessary (important for some applications)
# For this script, we're not maintaining references to launched objects beyond the function call,
# so explicit cleanup here isn't strictly necessary unless we added a 'Close' or 'Quit' button for them.
# Example: if ($comObjectInstance -ne $null) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObjectInstance) | Out-Null }
# For now, processes will run independently.
#endregion
