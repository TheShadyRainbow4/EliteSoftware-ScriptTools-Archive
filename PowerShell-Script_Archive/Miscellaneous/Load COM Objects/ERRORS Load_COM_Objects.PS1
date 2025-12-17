# Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Global Variables
# Store the currently loaded COM object
$global:ComObject = $null
# Store the currently selected member (method or property)
$global:SelectedMember = $null
# Cache all discovered ProgIDs to avoid re-scanning the registry repeatedly
$global:AllProgIDs = $null
#endregion

#region Form Creation
$form = New-Object System.Windows.Forms.Form
$form.Text = "COM Object Playground"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.MinimumSize = New-Object System.Drawing.Size(700, 550) # Allow some resizing, but limit it
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0") # Light grey background

# Font for better readability, similar to modern UI
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

#region Tab Control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(0, 0)
$tabControl.Size = New-Object System.Drawing.Size($form.ClientSize.Width, $form.ClientSize.Height)
$tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill # Make tab control fill the form
$form.Controls.Add($tabControl)

# Main Playground Tab
$tabPageMain = New-Object System.Windows.Forms.TabPage
$tabPageMain.Text = "Main Playground"
$tabControl.Controls.Add($tabPageMain)

# ProgID Search Tab
$tabPageSearch = New-Object System.Windows.Forms.TabPage
$tabPageSearch.Text = "ProgID Search"
$tabControl.Controls.Add($tabPageSearch)

#endregion

#region Controls - Main Playground Tab

# ProgID Label (for manual input)
$labelProgId = New-Object System.Windows.Forms.Label
$labelProgId.Text = "Enter COM ProgID (e.g., WScript.Shell, InternetExplorer.Application):"
$labelProgId.AutoSize = $true
$labelProgId.Location = New-Object System.Drawing.Point(10, 10)
$tabPageMain.Controls.Add($labelProgId)

# ProgID TextBox (manual input)
$textBoxProgId = New-Object System.Windows.Forms.TextBox
$textBoxProgId.Location = New-Object System.Drawing.Point(10, 30)
$textBoxProgId.Size = New-Object System.Drawing.Size(500, 25)
$textBoxProgId.Text = "WScript.Shell" # Default value for quick testing
$tabPageMain.Controls.Add($textBoxProgId)

# Label for ComboBox
$labelComboProgId = New-Object System.Windows.Forms.Label
$labelComboProgId.Text = "OR Select from System ProgIDs:"
$labelComboProgId.AutoSize = $true
$labelComboProgId.Location = New-Object System.Drawing.Point(10, 60)
$tabPageMain.Controls.Add($labelComboProgId)

# COM ProgID ComboBox (dropdown)
$comboBoxProgId = New-Object System.Windows.Forms.ComboBox
$comboBoxProgId.Location = New-Object System.Drawing.Point(10, 80)
$comboBoxProgId.Size = New-Object System.Drawing.Size(500, 25)
$comboBoxProgId.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList # Only allow selecting from list
$tabPageMain.Controls.Add($comboBoxProgId)

# Load Button (aligned to span both input types)
$buttonLoad = New-Object System.Windows.Forms.Button
$buttonLoad.Text = "Load COM Object"
$buttonLoad.Location = New-Object System.Drawing.Point(520, 30) # Adjusted Y to be centered
$buttonLoad.Size = New-Object System.Drawing.Size(150, 75) # Increased height to span both inputs
$buttonLoad.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D7") # Windows blue
$buttonLoad.ForeColor = [System.Drawing.Color]::White
$buttonLoad.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonLoad.FlatAppearance.BorderSize = 0
$tabPageMain.Controls.Add($buttonLoad)

# Members ListBox Label
$labelMembers = New-Object System.Windows.Forms.Label
$labelMembers.Text = "Object Members (Methods/Properties):"
$labelMembers.AutoSize = $true
$labelMembers.Location = New-Object System.Drawing.Point(10, 120) # Shifted down
$tabPageMain.Controls.Add($labelMembers)

# Members ListBox
$listBoxMembers = New-Object System.Windows.Forms.ListBox
$listBoxMembers.Location = New-Object System.Drawing.Point(10, 140) # Shifted down
$listBoxMembers.Size = New-Object System.Drawing.Size(350, 350) # Reduced height
$listBoxMembers.HorizontalScrollbar = $true # Allow horizontal scrolling for long member names
$tabPageMain.Controls.Add($listBoxMembers)

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
$tabPageMain.Controls.Add($buttonExecute)

# Output Label
$labelOutput = New-Object System.Windows.Forms.Label
$labelOutput.Text = "Output:"
$labelOutput.AutoSize = $true
$labelOutput.Location = New-Object System.Drawing.Point(370, 120) # Shifted down
$tabPageMain.Controls.Add($labelOutput)

# Output TextBox
$textBoxOutput = New-Object System.Windows.Forms.TextBox
$textBoxOutput.Location = New-Object System.Drawing.Point(370, 140) # Shifted down
$textBoxOutput.Size = New-Object System.Drawing.Size(400, 390) # Reduced height
$textBoxOutput.Multiline = $true
$textBoxOutput.ScrollBars = "Vertical"
$textBoxOutput.ReadOnly = $true
$textBoxOutput.BackColor = [System.Drawing.Color]::White
$tabPageMain.Controls.Add($textBoxOutput)

#endregion

#region Controls - ProgID Search Tab

# Search Query Label
$labelSearchQuery = New-Object System.Windows.Forms.Label
$labelSearchQuery.Text = "Search ProgID (e.g., shell, internet, excel) or leave empty for full list:"
$labelSearchQuery.AutoSize = $true
$labelSearchQuery.Location = New-Object System.Drawing.Point(10, 10)
$tabPageSearch.Controls.Add($labelSearchQuery)

# Search Query TextBox
$textBoxSearchQuery = New-Object System.Windows.Forms.TextBox
$textBoxSearchQuery.Location = New-Object System.Drawing.Point(10, 30)
$textBoxSearchQuery.Size = New-Object System.Drawing.Size(500, 25)
$tabPageSearch.Controls.Add($textBoxSearchQuery)

# Search Button
$buttonSearch = New-Object System.Windows.Forms.Button
$buttonSearch.Text = "Search / Show All" # Updated button text
$buttonSearch.Location = New-Object System.Drawing.Point(520, 28)
$buttonSearch.Size = New-Object System.Drawing.Size(150, 30)
$buttonSearch.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D7") # Windows blue
$buttonSearch.ForeColor = [System.Drawing.Color]::White
$buttonSearch.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonSearch.FlatAppearance.BorderSize = 0
$tabPageSearch.Controls.Add($buttonSearch)

# Search Results ListBox Label
$labelSearchResults = New-Object System.Windows.Forms.Label
$labelSearchResults.Text = "Search Results:"
$labelSearchResults.AutoSize = $true
$labelSearchResults.Location = New-Object System.Drawing.Point(10, 70)
$tabPageSearch.Controls.Add($labelSearchResults)

# Search Results ListBox
$listBoxSearchResults = New-Object System.Windows.Forms.ListBox
$listBoxSearchResults.Location = New-Object System.Drawing.Point(10, 90)
$listBoxSearchResults.Size = New-Object System.Drawing.Size(760, 350)
$listBoxSearchResults.HorizontalScrollbar = $true # Allow horizontal scrolling for long member names
$tabPageSearch.Controls.Add($listBoxSearchResults)

# Select from Search Button
$buttonSelectFromSearch = New-Object System.Windows.Forms.Button
$buttonSelectFromSearch.Text = "Select ProgID & Go to Main"
$buttonSelectFromSearch.Location = New-Object System.Drawing.Point(10, 450)
$buttonSelectFromSearch.Size = New-Object System.Drawing.Size(760, 40)
$buttonSelectFromSearch.Enabled = $false # Disable until a result is selected
$buttonSelectFromSearch.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#009688") # Teal-like color
$buttonSelectFromSearch.ForeColor = [System.Drawing.Color]::White
$buttonSelectFromSearch.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonSelectFromSearch.FlatAppearance.BorderSize = 0
$tabPageSearch.Controls.Add($buttonSelectFromSearch)

# Search Output TextBox
$textBoxSearchOutput = New-Object System.Windows.Forms.TextBox
$textBoxSearchOutput.Location = New-Object System.Drawing.Point(10, 500)
$textBoxSearchOutput.Size = New-Object System.Drawing.Size(760, 40)
$textBoxSearchOutput.Multiline = $true
$textBoxSearchOutput.ScrollBars = "Vertical"
$textBoxSearchOutput.ReadOnly = $true
$textBoxSearchOutput.BackColor = [System.Drawing.Color]::White
$tabPageSearch.Controls.Add($textBoxSearchOutput)

#endregion

#region Event Handlers

# Function to update the output textbox on the Main Playground tab
function Update-Output ($message, $append = $true) {
    if ($append) {
        $textBoxOutput.AppendText("$message`r`n")
    } else {
        $textBoxOutput.Text = "$message`r`n"
    }
    $textBoxOutput.SelectionStart = $textBoxOutput.Text.Length
    $textBoxOutput.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents() # Force UI update
}

# Function to update the output textbox on the ProgID Search tab
function Update-SearchOutput ($message, $append = $true) {
    if ($append) {
        $textBoxSearchOutput.AppendText("$message`r`n")
    } else {
        $textBoxSearchOutput.Text = "$message`r`n"
    }
    $textBoxSearchOutput.SelectionStart = $textBoxSearchOutput.Text.Length
    $textBoxSearchOutput.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents() # Force UI update
}

# Function to get all COM ProgIDs from the system registry (cached)
function Get-ComProgIDsInternal {
    # Set wait cursor for the entire form
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        if ($null -ne $global:AllProgIDs -and $global:AllProgIDs.Count -gt 0) {
            # If ProgIDs are already cached and not empty, update search output and return them
            Update-SearchOutput "Found $($global:AllProgIDs.Count) cached ProgIDs."
            return $global:AllProgIDs
        }

        Update-SearchOutput "Enumerating system COM ProgIDs. This may take a moment..." -append $false # Clear and show loading
        $progIds = New-Object System.Collections.Generic.List[string]
        $clsidPath = "HKCR:\CLSID"

        try {
            # Get all CLSIDs subkeys
            $clsids = Get-ChildItem -LiteralPath $clsidPath -ErrorAction SilentlyContinue

            foreach ($clsid in $clsids) {
                try {
                    # Look for ProgID or VersionIndependentProgID values under each CLSID
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
                    Update-SearchOutput "Warning: Could not process CLSID '$($clsid.Name)': $($_.Exception.Message)"
                }
            }
        } catch {
            Update-SearchOutput "Error enumerating CLSIDs from registry: $($_.Exception.Message)"
            # Do not clear output here, let the error message persist
        }
        
        # If no ProgIDs were found through registry enumeration, use a fallback list
        if ($progIds.Count -eq 0) {
            Update-SearchOutput "No ProgIDs found via registry enumeration. Using a default list of common ProgIDs."
            # Fallback list focusing on Shell, IE, and common scripting objects
            $defaultProgIds = @(
                "WScript.Shell",
                "InternetExplorer.Application",
                "Shell.Application",
                "Scripting.FileSystemObject",
                "Scripting.Dictionary",
                "Outlook.Application",
                "Excel.Application",
                "Word.Application",
                "PowerPoint.Application",
                "MMC20.Application", # Microsoft Management Console
                "WindowsUpdate.AutoUpdate",
                "Speech.SpeechRecognizer",
                "UIAutomationCore.CUIAutomation"
            )
            $progIds.AddRange($defaultProgIds)
        }

        $global:AllProgIDs = $progIds | Sort-Object -Unique # Store unique sorted results in cache
        Update-SearchOutput "Finished enumerating. Found $($global:AllProgIDs.Count) unique ProgIDs." # Final status
        return $global:AllProgIDs
    } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default # Reset cursor
    }
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

# ListBox Selection Change Event (Main Tab)
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

# Search Button Click Event (Search Tab)
$buttonSearch.Add_Click({
    $searchTerm = $textBoxSearchQuery.Text.Trim()
    $listBoxSearchResults.Items.Clear()
    Update-SearchOutput -message "" -append $false # Clear search output

    if ($null -eq $global:AllProgIDs -or $global:AllProgIDs.Count -eq 0) {
        Update-SearchOutput "ProgIDs are not yet loaded or previous enumeration failed. Attempting to enumerate now. This may take a moment..."
        # Force UI update to show the loading message immediately
        [System.Windows.Forms.Application]::DoEvents()
        
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor # Show busy cursor
        try {
            # Call Get-ComProgIDsInternal to try and populate AllProgIDs
            $global:AllProgIDs = Get-ComProgIDsInternal
        } finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default # Reset cursor
        }

        if ($null -eq $global:AllProgIDs -or $global:AllProgIDs.Count -eq 0) {
             Update-SearchOutput "Failed to load ProgIDs even with fallback. Cannot perform search."
             $buttonSelectFromSearch.Enabled = $false
             return
        }
    }

    if (-not $searchTerm) {
        # If search term is empty, display all ProgIDs (Full List option)
        Update-SearchOutput "Displaying all registered COM ProgIDs (Full List):"
        $foundProgIds = $global:AllProgIDs | Sort-Object
    } else {
        # Otherwise, perform a filtered search
        Update-SearchOutput "Searching for '$searchTerm'..."
        $foundProgIds = $global:AllProgIDs | Where-Object { $_ -like "*$searchTerm*" } | Sort-Object
    }

    if ($foundProgIds.Count -gt 0) {
        foreach ($id in $foundProgIds) {
            $listBoxSearchResults.Items.Add($id)
        }
        # Force UI update after populating the list box
        [System.Windows.Forms.Application]::DoEvents()
        Update-SearchOutput "Found $($foundProgIds.Count) matching ProgIDs."
        $buttonSelectFromSearch.Enabled = $true
    } else {
        Update-SearchOutput "No ProgIDs found matching '$searchTerm'."
        $buttonSelectFromSearch.Enabled = $false
    }
})

# ListBox Search Results Selection Change Event (Search Tab)
$listBoxSearchResults.Add_SelectedIndexChanged({
    if ($listBoxSearchResults.SelectedIndex -ge 0) {
        $buttonSelectFromSearch.Enabled = $true
    } else {
        $buttonSelectFromSearch.Enabled = $false
    }
})

# Select from Search Button Click Event (Search Tab)
$buttonSelectFromSearch.Add_Click({
    $selectedProgId = $listBoxSearchResults.SelectedItem.ToString()
    if ($selectedProgId) {
        $textBoxProgId.Text = $selectedProgId # Populate the main tab's textbox
        $tabControl.SelectedIndex = 0 # Switch to the Main Playground tab
        Update-Output "Selected ProgID '$selectedProgId' from search results." -append $false
    }
})

#endregion

# Populate ComboBox on form load and cache all ProgIDs
$form.Add_Load({
    # Clear output on search tab before starting enumeration
    Update-SearchOutput "" -append $false 
    # The Get-ComProgIDsInternal function already handles the cursor and DoEvents() internally.
    $global:AllProgIDs = Get-ComProgIDsInternal # Populate and cache all ProgIDs
    
    # Populate the main tab's ComboBox if AllProgIDs is not null and has items
    if ($null -ne $comboBoxProgId -and $null -ne $comboBoxProgId.Items -and $global:AllProgIDs.Count -gt 0) {
        foreach ($id in $global:AllProgIDs) {
            $comboBoxProgId.Items.Add($id)
        }
        # Only select an index if there are items to select
        if ($comboBoxProgId.Items.Count -gt 0) {
            $comboBoxProgId.SelectedIndex = 0 # Select the first item by default
            $textBoxProgId.Text = $comboBoxProgId.SelectedItem.ToString() # Update text box with default selection
        }
    } else {
        Update-Output "Error: ComboBox or its Items collection is null or no ProgIDs available during form load. Cannot populate ProgIDs dropdown."
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
