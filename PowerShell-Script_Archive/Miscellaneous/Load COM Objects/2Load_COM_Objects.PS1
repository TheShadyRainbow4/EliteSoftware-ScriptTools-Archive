# Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Global Variables
# Store the currently loaded COM object
$global:ComObject = $null
# Store the currently selected member (method or property)
$global:SelectedMember = $null
#endregion

#region Form Creation
$form = New-Object System.Windows.Forms.Form
$form.Text = "COM Object Playground"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0") # Light grey background

# Font for better readability, similar to modern UI
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

#region Controls

# ProgID Label (for manual input)
$labelProgId = New-Object System.Windows.Forms.Label
$labelProgId.Text = "Enter COM ProgID (e.g., WScript.Shell, InternetExplorer.Application):"
$labelProgId.AutoSize = $true
$labelProgId.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($labelProgId)

# ProgID TextBox (manual input)
$textBoxProgId = New-Object System.Windows.Forms.TextBox
$textBoxProgId.Location = New-Object System.Drawing.Point(10, 30)
$textBoxProgId.Size = New-Object System.Drawing.Size(500, 25)
$textBoxProgId.Text = "WScript.Shell" # Default value for quick testing
$form.Controls.Add($textBoxProgId)

# Label for ComboBox
$labelComboProgId = New-Object System.Windows.Forms.Label
$labelComboProgId.Text = "OR Select from System ProgIDs:"
$labelComboProgId.AutoSize = $true
$labelComboProgId.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($labelComboProgId)

# COM ProgID ComboBox (dropdown)
$comboBoxProgId = New-Object System.Windows.Forms.ComboBox
$comboBoxProgId.Location = New-Object System.Drawing.Point(10, 80)
$comboBoxProgId.Size = New-Object System.Drawing.Size(500, 25)
$comboBoxProgId.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList # Only allow selecting from list
$form.Controls.Add($comboBoxProgId)

# Load Button (aligned to span both input types)
$buttonLoad = New-Object System.Windows.Forms.Button
$buttonLoad.Text = "Load COM Object"
$buttonLoad.Location = New-Object System.Drawing.Point(520, 30) # Adjusted Y to be centered
$buttonLoad.Size = New-Object System.Drawing.Size(150, 75) # Increased height to span both inputs
$buttonLoad.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D7") # Windows blue
$buttonLoad.ForeColor = [System.Drawing.Color]::White
$buttonLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonLoad.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonLoad)

# Members ListBox Label
$labelMembers = New-Object System.Windows.Forms.Label
$labelMembers.Text = "Object Members (Methods/Properties):"
$labelMembers.AutoSize = $true
$labelMembers.Location = New-Object System.Drawing.Point(10, 120) # Shifted down
$form.Controls.Add($labelMembers)

# Members ListBox
$listBoxMembers = New-Object System.Windows.Forms.ListBox
$listBoxMembers.Location = New-Object System.Drawing.Point(10, 140) # Shifted down
$listBoxMembers.Size = New-Object System.Drawing.Size(350, 350) # Reduced height
$listBoxMembers.HorizontalScrollbar = $true # Allow horizontal scrolling for long member names
$form.Controls.Add($listBoxMembers)

# Execute/Get Value Button
$buttonExecute = New-Object System.Windows.Forms.Button
$buttonExecute.Text = "Execute Method / Get Property"
$buttonExecute.Location = New-Object System.Drawing.Point(10, 500)
$buttonExecute.Size = New-Object System.Drawing.Size(350, 40)
$buttonExecute.Enabled = $false # Disable until an object is loaded
$buttonExecute.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#009688") # Teal-like color
$buttonExecute.ForeColor = [System.Drawing.Color]::White
$buttonExecute.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonExecute.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonExecute)

# Output Label
$labelOutput = New-Object System.Windows.Forms.Label
$labelOutput.Text = "Output:"
$labelOutput.AutoSize = $true
$labelOutput.Location = New-Object System.Drawing.Point(370, 120) # Shifted down
$form.Controls.Add($labelOutput)

# Output TextBox
$textBoxOutput = New-Object System.Windows.Forms.TextBox
$textBoxOutput.Location = New-Object System.Drawing.Point(370, 140) # Shifted down
$textBoxOutput.Size = New-Object System.Drawing.Size(400, 390) # Reduced height
$textBoxOutput.Multiline = $true
$textBoxOutput.ScrollBars = "Vertical"
$textBoxOutput.ReadOnly = $true
$textBoxOutput.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($textBoxOutput)

#endregion

#region Event Handlers

# Function to update the output textbox
function Update-Output ($message, $append = $true) {
    if ($append) {
        $textBoxOutput.AppendText("$message`r`n")
    } else {
        $textBoxOutput.Text = "$message`r`n"
    }
    $textBoxOutput.SelectionStart = $textBoxOutput.Text.Length
    $textBoxOutput.ScrollToCaret()
}

# Function to get all COM ProgIDs from the system registry
function Get-ComProgIDs {
    Update-Output "Enumerating system COM ProgIDs. This may take a moment..." -append $false # Clear and show loading
    $progIds = New-Object System.Collections.Generic.List[string]
    $clsidPath = "HKCR:\CLSID"

    try {
        # Get all CLSIDs subkeys
        # Using -LiteralPath to avoid issues with special characters in CLSID names
        $clsids = Get-ChildItem -LiteralPath $clsidPath -ErrorAction SilentlyContinue

        foreach ($clsid in $clsids) {
            try {
                # Look for ProgID or VersionIndependentProgID values under each CLSID
                # Using -LiteralPath for Get-ItemProperty as well
                $progIdKey = Get-ItemProperty -LiteralPath $clsid.PSPath -Name "ProgID", "VersionIndependentProgID" -ErrorAction SilentlyContinue
                if ($progIdKey) {
                    if ($progIdKey.ProgID) {
                        $progIds.Add($progIdKey.ProgID)
                    }
                    if ($progIdKey.VersionIndependentProgID) {
                        $progIds.Add($progIdKey.VersionIndependentProgID)
                    }
                }
            } catch {
                # Ignore errors for individual CLSIDs that might not have these properties
                # or might be inaccessible due to permissions.
            }
        }
    } catch {
        Update-Output "Error enumerating COM ProgIDs from registry: $($_.Exception.Message)"
    }
    # Clear output after enumeration is done
    Update-Output "" -append $false
    return $progIds | Sort-Object -Unique
}

# Load COM Object Button Click Event
$buttonLoad.Add_Click({
    $progId = $textBoxProgId.Text.Trim()
    # If the text box is empty, check if something is selected in the combo box
    if (-not $progId -and $comboBoxProgId.SelectedItem) {
        $progId = $comboBoxProgId.SelectedItem.ToString()
        $textBoxProgId.Text = $progId # Update text box with selected value for consistency
    }

    $listBoxMembers.Items.Clear() # Clear previous members
    Update-Output -message "" -append $false # Clear output

    if (-not $progId) {
        Update-Output "Please enter a COM ProgID or select one from the dropdown."
        $buttonExecute.Enabled = $false
        return
    }

    Update-Output "Attempting to create COM object: '$progId'..."

    try {
        # Attempt to create the COM object
        $global:ComObject = New-Object -ComObject $progId
        Update-Output "Successfully loaded COM object."

        # Get all members (methods and properties) and add to listbox
        $members = $global:ComObject | Get-Member -MemberType Method, Property | Select-Object Name, MemberType | Sort-Object Name
        if ($members) {
            foreach ($member in $members) {
                $listBoxMembers.Items.Add("$($member.Name) [$($member.MemberType)]")
            }
            Update-Output "Found $($members.Count) members."
            $buttonExecute.Enabled = $true # Enable execute button
        } else {
            Update-Output "No members found for this object."
            $buttonExecute.Enabled = $false
        }
    } catch {
        $global:ComObject = $null
        Update-Output "Error loading COM object: $($_.Exception.Message)"
        $buttonExecute.Enabled = $false
    }
})

# ListBox Selection Change Event
$listBoxMembers.Add_SelectedIndexChanged({
    $selectedIndex = $listBoxMembers.SelectedIndex
    if ($selectedIndex -ge 0) {
        $selectedText = $listBoxMembers.SelectedItem.ToString()
        # Extract member name and type from the listbox item text
        $global:SelectedMember = $selectedText -replace ' \[.+\]$' # Remove the [MemberType] part
        Update-Output "Selected member: $($global:SelectedMember)"
    } else {
        $global:SelectedMember = $null
    }
})

# ComboBox Selection Change Event - automatically update the textbox
$comboBoxProgId.Add_SelectedIndexChanged({
    if ($comboBoxProgId.SelectedIndex -ge 0) {
        $textBoxProgId.Text = $comboBoxProgId.SelectedItem.ToString()
        Update-Output "Selected ProgID from dropdown: $($textBoxProgId.Text)" -append $false
    }
})


# Execute/Get Value Button Click Event
$buttonExecute.Add_Click({
    Update-Output "" -append $false # Clear output for new execution

    if (-not $global:ComObject) {
        Update-Output "No COM object is loaded."
        return
    }
    if (-not $global:SelectedMember) {
        Update-Output "No member selected. Please select a method or property from the list."
        return
    }

    Update-Output "Attempting to interact with member: '$($global:SelectedMember)'"

    try {
        # Get the actual member object from the COM object
        $memberInfo = $global:ComObject | Get-Member -Name $global:SelectedMember -ErrorAction SilentlyContinue

        if (-not $memberInfo) {
            Update-Output "Error: Selected member '$($global:SelectedMember)' not found on the object."
            return
        }

        # Check if it's a method or a property
        if ($memberInfo.MemberType -eq [System.Management.Automation.PSMemberTypes]::Method) {
            # It's a method
            Update-Output "Attempting to invoke method '$($global:SelectedMember)'..."
            # Try to invoke the method. This will fail if it requires parameters.
            $result = Invoke-Expression "`$global:ComObject.$($global:SelectedMember)()"
            Update-Output "Method Invoked. Result: $($result | Out-String)"
        } elseif ($memberInfo.MemberType -eq [System.Management.Automation.PSMemberTypes]::Property) {
            # It's a property
            Update-Output "Attempting to get property value for '$($global:SelectedMember)'..."
            $result = Invoke-Expression "`$global:ComObject.$($global:SelectedMember)"
            Update-Output "Property Value: $($result | Out-String)"
        } else {
            Update-Output "Selected member '$($global:SelectedMember)' is neither a method nor a property. Type: $($memberInfo.MemberType)"
        }
    } catch {
        Update-Output "Error interacting with member: $($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            Update-Output "Inner Exception: $($_.Exception.InnerException.Message)"
        }
        Update-Output "Error details: $($_.Exception | Out-String)"
    }
})

#endregion

# Populate ComboBox on form load
$form.Add_Load({
    $progIds = Get-ComProgIDs
    # Defensive check to ensure $comboBoxProgId and its Items collection are not null
    if ($null -ne $comboBoxProgId -and $null -ne $comboBoxProgId.Items) {
        # Loop through each ProgID and add it individually to the ComboBox
        foreach ($id in $progIds) {
            $comboBoxProgId.Items.Add($id)
        }
        if ($comboBoxProgId.Items.Count -gt 0) {
            $comboBoxProgId.SelectedIndex = 0 # Select the first item by default
            $textBoxProgId.Text = $comboBoxProgId.SelectedItem.ToString() # Update text box with default selection
        }
    } else {
        Update-Output "Error: ComboBox or its Items collection is null during form load. Cannot populate ProgIDs."
        # Optionally, disable controls that rely on ComboBox for further interaction
        $buttonLoad.Enabled = $false
        if ($null -ne $comboBoxProgId) {
            $comboBoxProgId.Enabled = $false
        }
    }
})

# Show the Form
[void]$form.ShowDialog()

# Clean up the COM object when the form closes
if ($global:ComObject -ne $null) {
    try {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($global:ComObject) | Out-Null
        Remove-Variable -Name ComObject -Scope Global
        # This output won't be seen in the GUI as it's already closed, but useful for console if run directly
    } catch {
        Write-Error "Error releasing COM object: $($_.Exception.Message)"
    }
}
