# Requires -Version 5.1

# -----------------------------------------------------------------------------
# PowerShell Network Information Viewer GUI
# Author: Gemini
# Date: June 21, 2025
# Description: This script creates a graphical user interface (GUI) using
#              Windows Forms to display detailed network adapter information.
#              It now displays information on separate tabs for "IP Address",
#              "DNS Configuration", and "Adapter Details".
#              Additionally, it includes a button to launch an external batch script
#              (ipcfg.bat located in C:\Windows\System32) which runs 'ipconfig /all'
#              in a command prompt with green text.
# -----------------------------------------------------------------------------

#region DPI Awareness and Visual Styles
# IMPORTANT: These lines should be at the very beginning of the script
# before any UI elements are created, to ensure proper DPI scaling.
[System.Windows.Forms.Application]::SetHighDpiMode([System.Windows.Forms.HighDpiMode]::SystemAware)
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
#endregion

#region Required Assemblies
# Load the necessary .NET assemblies for creating Windows Forms GUI elements.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#endregion

#region Form Creation
# Create the main window (form) for the application.
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Network Information Viewer" # Set the title bar text
$Form.Size = New-Object System.Drawing.Size(700, 500) # Initial size (will be maximized)
$Form.MinimumSize = New-Object System.Drawing.Size(600, 450) # Set a minimum size
$Form.StartPosition = "CenterScreen" # Position the form in the center of the screen
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 10) # Set a modern font for the form
# Set the form to open maximized to take up the entire window
$Form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
# Fixed icon error: Using a system DLL for the icon, which is more reliable across PowerShell versions.
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
#endregion

#region Tab Control Setup
# Create a TabControl element to hold different sections of network information.
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Dock = "Fill" # Dock the TabControl to fill the entire form area
$TabControl.Location = New-Object System.Drawing.Point(0, 0) # Position at the top-left corner
$TabControl.Anchor = "Top, Bottom, Left, Right" # Ensure the TabControl resizes with the form
#endregion

#region Tab Page: IP Address Information
# Create a tab page specifically for displaying IP address details.
$TabPageIP = New-Object System.Windows.Forms.TabPage("IP Address")
$TabControl.Controls.Add($TabPageIP) # Add the tab page to the TabControl

# Create a RichTextBox to display IP address information.
$TextBoxIP = New-Object System.Windows.Forms.RichTextBox
$TextBoxIP.Dock = "Fill" # Dock the text box to fill its parent tab page
$TextBoxIP.ReadOnly = $true # Make the text box read-only to prevent user input
$TextBoxIP.Multiline = $true # Allow multiple lines of text
$TextBoxIP.ScrollBars = "Vertical" # Add vertical scroll bars if content exceeds visible area
$TextBoxIP.Font = New-Object System.Drawing.Font("Consolas", 10) # Use a monospaced font for better readability of network data
$TabPageIP.Controls.Add($TextBoxIP) # Add the text box to the IP Address tab page
#endregion

#region Tab Page: DNS Configuration Information
# Create a tab page for displaying DNS server configurations.
$TabPageDNS = New-Object System.Windows.Forms.TabPage("DNS Configuration")
$TabControl.Controls.Add($TabPageDNS)

# Create a RichTextBox to display DNS information.
$TextBoxDNS = New-Object System.Windows.Forms.RichTextBox
$TextBoxDNS.Dock = "Fill"
$TextBoxDNS.ReadOnly = $true
$TextBoxDNS.Multiline = $true
$TextBoxDNS.ScrollBars = "Vertical"
$TextBoxDNS.Font = New-Object System.Drawing.Font("Consolas", 10)
$TabPageDNS.Controls.Add($TextBoxDNS)
#endregion

#region Tab Page: Adapter Details
# Create a tab page for displaying general network adapter details.
$TabPageAdapter = New-Object System.Windows.Forms.TabPage("Adapter Details")
$TabControl.Controls.Add($TabPageAdapter)

# Create a RichTextBox to display adapter details.
$TextBoxAdapter = New-Object System.Windows.Forms.RichTextBox
$TextBoxAdapter.Dock = "Fill"
$TextBoxAdapter.ReadOnly = $true
$TextBoxAdapter.Multiline = $true
$TextBoxAdapter.ScrollBars = "Vertical"
$TextBoxAdapter.Font = New-Object System.Drawing.Font("Consolas", 10)
$TabPageAdapter.Controls.Add($TextBoxAdapter)
#endregion

#region Function to Get and Populate Network Information
# Define a function to retrieve and format network information for the text boxes.
Function Get-NetworkInfo {
    # Initialize StringBuilder objects for efficient string construction for each tab.
    $ipInfo = New-Object System.Text.StringBuilder
    $dnsInfo = New-Object System.Text.StringBuilder
    $adapterInfo = New-Object System.Text.StringBuilder

    # Get all network adapter configurations that have IP enabled using WMI (Windows Management Instrumentation).
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Sort-Object Description

    # Loop through each IP-enabled network adapter found.
    foreach ($adapter in $adapters) {
        $adapterName = $adapter.Description # Get the descriptive name of the adapter.

        # Add a separator line with the adapter name for clarity in each section.
        $ipInfo.AppendLine("--- Adapter: $($adapterName) ---")
        $dnsInfo.AppendLine("--- Adapter: $($adapterName) ---")
        $adapterInfo.AppendLine("--- Adapter: $($adapterName) ---")

        #region IP Address Information Section
        if ($adapter.IPAddress) {
            $ipInfo.AppendLine("  IP Address(es):")
            foreach ($ip in $adapter.IPAddress) {
                $ipInfo.AppendLine("    $ip")
            }
        } else {
            $ipInfo.AppendLine("  No IP Address configured for this adapter.")
        }

        if ($adapter.IPSubnet) {
            $ipInfo.AppendLine("  Subnet Mask(s):")
            foreach ($subnet in $adapter.IPSubnet) {
                $ipInfo.AppendLine("    $subnet")
            }
        }

        if ($adapter.DefaultIPGateway) {
            $ipInfo.AppendLine("  Default Gateway(s):")
            foreach ($gateway in $adapter.DefaultIPGateway) {
                # CORRECTED: Appending to $ipInfo, not $gateway
                $ipInfo.AppendLine("    $gateway")
            }
        }

        if ($adapter.DHCPEnabled) {
            $ipInfo.AppendLine("  DHCP Enabled: True")
            $ipInfo.AppendLine("  DHCP Server: $($adapter.DHCPServer)")
            $ipInfo.AppendLine("  DHCP Lease Obtained: $($adapter.DHCPLeaseObtained)")
            $ipInfo.AppendLine("  DHCP Lease Expires: $($adapter.DHCPLeaseExpires)")
        } else {
            $ipInfo.AppendLine("  DHCP Enabled: False")
        }
        $ipInfo.AppendLine("")
        #endregion

        #region DNS Configuration Information Section
        if ($adapter.DNSServerSearchOrder) {
            $dnsInfo.AppendLine("  DNS Server(s):")
            foreach ($dns in $adapter.DNSServerSearchOrder) {
                $dnsInfo.AppendLine("    $dns")
            }
        } else {
            $dnsInfo.AppendLine("  No DNS Servers configured for this adapter.")
        }
        $dnsInfo.AppendLine("")
        #endregion

        #region General Adapter Details Section
        $netAdapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
        if ($netAdapter) {
            $adapterInfo.AppendLine("  Description: $($netAdapter.InterfaceDescription)")
            $adapterInfo.AppendLine("  Status: $($netAdapter.Status)")
            $adapterInfo.AppendLine("  MAC Address: $($netAdapter.MacAddress)")
            $adapterInfo.AppendLine("  Link Speed: $($netAdapter.LinkSpeed)")
            $adapterInfo.AppendLine("  Media Connection State: $($netAdapter.MediaConnectionState)")
            $adapterInfo.AppendLine("  Driver Version: $($netAdapter.DriverVersion)")
            $adapterInfo.AppendLine("  Device Name: $($netAdapter.DeviceName)")
            $adapterInfo.AppendLine("  Interface Index: $($netAdapter.InterfaceIndex)")
        } else {
            # Fallback to WMI properties if Get-NetAdapter doesn't provide additional info.
            $adapterInfo.AppendLine("  Description (WMI): $($adapter.Description)")
            $adapterInfo.AppendLine("  MAC Address (WMI): $($adapter.MACAddress)")
            $adapterInfo.AppendLine("  Service Name (WMI): $($adapter.ServiceName)")
            $adapterInfo.AppendLine("  Index (WMI): $($adapter.Index)")
        }
        $adapterInfo.AppendLine("")
        #endregion
    }

    # Set the content of the RichTextBoxes with the gathered and formatted information.
    $TextBoxIP.Text = $ipInfo.ToString()
    $TextBoxDNS.Text = $dnsInfo.ToString()
    $TextBoxAdapter.Text = $adapterInfo.ToString()
}
#endregion

#region Launch ipcfg.bat Button Panel
# Create a panel to hold the button, which helps with docking and layout.
$ButtonPanel = New-Object System.Windows.Forms.Panel
$ButtonPanel.Dock = "Bottom" # Dock the panel to the bottom of the form.
$ButtonPanel.Height = 50 # Set a fixed height for the panel.
$ButtonPanel.BackColor = [System.Drawing.Color]::LightGray # Set a light gray background for the panel.

# Create the button to launch the ipcfg.bat script.
$LaunchButton = New-Object System.Windows.Forms.Button
$LaunchButton.Text = "Launch ipcfg.bat" # Set the text displayed on the button.
$LaunchButton.Size = New-Object System.Drawing.Size(180, 35) # Slightly larger button
$LaunchButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$LaunchButton.BackColor = [System.Drawing.Color]::LightSteelBlue # A nice blue shade
$LaunchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$LaunchButton.FlatAppearance.BorderSize = 0
$LaunchButton.ForeColor = [System.Drawing.Color]::WhiteSmoke
$LaunchButton.Anchor = "None" # Do not anchor the button within the panel for manual centering.

# Adding a hover effect
$LaunchButton.Add_MouseEnter({ $LaunchButton.BackColor = [System.Drawing.Color]::RoyalBlue })
$LaunchButton.Add_MouseLeave({ $LaunchButton.BackColor = [System.Drawing.Color]::LightSteelBlue })

# Add an event handler for when the button is clicked.
$LaunchButton.Add_Click({
    try {
        $batFilePath = "C:\Windows\System32\ipcfg.bat"
        if (-not (Test-Path $batFilePath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "The 'ipcfg.bat' file was not found at C:\Windows\System32\. Please create it first.",
                "File Not Found",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batFilePath`""
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "An error occurred while launching ipcfg.bat: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

$ButtonPanel.Controls.Add($LaunchButton) # Add the button to the button panel.
$Form.Controls.Add($ButtonPanel) # Add the button panel to the form.
# The calculation for centering the button will be done in the Form_Shown event
# or Form_Resize event to ensure the ButtonPanel's width is set.
#endregion

#region Add Controls to Form and Display
$Form.Controls.Add($TabControl) # Add the TabControl to the form. This will fill the remaining space.

# Add a 'Shown' event handler to the form.
# This ensures that the network information is populated *after* the form has been displayed,
# and also correctly positions the button.
$Form.Add_Shown({
    Get-NetworkInfo # Call the function to populate the network information into the text boxes.

    # Fix for button centering: calculate location after panel size is determined.
    # This addresses the 'op_Subtraction' error by ensuring Width properties are valid numbers.
    $LaunchButton.Location = New-Object System.Drawing.Point(($ButtonPanel.Width / 2) - ($LaunchButton.Width / 2), ($ButtonPanel.Height / 2) - ($LaunchButton.Height / 2))
})

# Display the form as a modal dialog.
$Form.ShowDialog() | Out-Null
#endregion
