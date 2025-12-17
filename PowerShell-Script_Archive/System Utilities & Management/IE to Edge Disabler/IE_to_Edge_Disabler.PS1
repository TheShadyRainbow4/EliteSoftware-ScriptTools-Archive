<#
.SYNOPSIS
    A PowerShell GUI script to enable or disable automatic redirection from Internet Explorer 11 to Microsoft Edge.

.DESCRIPTION
    This script provides a simple graphical interface to manage a specific registry setting that controls
    whether Internet Explorer 11 automatically redirects websites to Microsoft Edge.

    It targets the following registry key, which corresponds to the Group Policy setting
    "Configure whether Internet Explorer sites are redirected to Microsoft Edge":
    Path:   HKLM:\SOFTWARE\Policies\Microsoft\Edge
    Value:  RedirectSitesFromInternetExplorerToMicrosoftEdge (DWORD)

    - Setting the value to '2' (Never redirect) disables the automatic redirection.
    - Removing the value (or setting to '0') re-enables the default redirection behavior.

    The script requires administrator privileges to modify HKLM (Local Machine) registry keys.
    It will automatically attempt to elevate if not run as administrator.

.NOTES
    Author: Gemini (Your helpful artificial intelligence assistant)
    Date:   June 21, 2025
    Version: 1.0
#>

#region Check for Administrator Privileges
# This section ensures the script is running with elevated permissions, which are required
# to modify registry keys under HKLM (Local Machine).
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $title = "Administrator Privileges Required"
    $message = "This script needs to run with Administrator privileges to modify system settings. Please right-click the .ps1 file and select 'Run with PowerShell' after confirming the UAC prompt."
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    # Exit without relaunching to prevent an infinite loop if UAC prompt is cancelled repeatedly.
    # The user must manually relaunch as administrator.
    Exit
}
#endregion

#region Load Assemblies for GUI
# These assemblies are necessary for creating a graphical user interface using WPF (Windows Presentation Foundation).
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
} catch {
    $title = "GUI Initialization Error"
    $message = "Failed to load required GUI assemblies. Please ensure .NET Framework 4.0 or higher is installed and that your system can run WPF applications.`n`nError: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    Exit
}
#endregion

#region GUI Definition (XAML)
# This is the XAML (Extensible Application Markup Language) definition for the GUI window.
# XAML allows for a declarative way to design the user interface.
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="IE to Edge Redirection Manager" Height="300" Width="450"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#F0F0F0">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Margin="0,0,0,15" TextAlignment="Center" FontSize="16" FontWeight="Bold" Foreground="#333333">
            Manage IE to Edge Redirection
        </TextBlock>

        <TextBlock Grid.Row="1" Margin="0,0,0,15" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" FontSize="12" Foreground="#555555">
            This tool helps you control whether Internet Explorer 11 automatically redirects to Microsoft Edge.
            Disabling this will prevent Edge from launching when you try to open certain sites in IE.
        </TextBlock>

        <!-- Removed CornerRadius and Padding from ScrollViewer as they are not supported directly -->
        <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalAlignment="Stretch" Margin="0,0,0,15" BorderBrush="#CCCCCC" BorderThickness="1">
            <!-- Added Padding to the TextBlock inside the ScrollViewer for visual spacing -->
            <TextBlock x:Name="StatusTextBlock" TextWrapping="Wrap" FontSize="12" Foreground="#0056B3" Text="Current Status: Checking..." Padding="10" />
        </ScrollViewer>

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Center">
            <!-- All custom styling and triggers removed to simplify the XAML for debugging -->
            <Button x:Name="DisableButton" Content="Disable Redirection" Width="150" Height="35" Margin="0,0,10,0" FontSize="14" FontWeight="SemiBold" Background="#DC3545" Foreground="White" BorderBrush="#C82333" BorderThickness="1" Cursor="Hand"/>
            <Button x:Name="EnableButton" Content="Enable Redirection" Width="150" Height="35" FontSize="14" FontWeight="SemiBold" Background="#28A745" Foreground="White" BorderBrush="#218838" BorderThickness="1" Cursor="Hand"/>
        </StackPanel>
    </Grid>
</Window>
"@

#endregion

#region Parse XAML and Get GUI Elements
# This converts the XAML string into actual WPF objects that can be manipulated in PowerShell.
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get references to the specific elements in the GUI by their x:Name.
$statusTextBlock = $window.FindName("StatusTextBlock")
$disableButton = $window.FindName("DisableButton")
$enableButton = $window.FindName("EnableButton")
#endregion

#region Registry Constants
# Define the registry path and value name for clarity and easy modification.
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
$regValueName = "RedirectSitesFromInternetExplorerToMicrosoftEdge"
#endregion

#region Functions for Registry Operations and GUI Updates

function Update-Status ($message, $append = $false, $color = "#0056B3") {
    # Updates the status text block in the GUI.
    # $append: If true, adds the message to existing text; otherwise, overwrites.
    # $color: Sets the foreground color of the text.
    if ($append) {
        $statusTextBlock.Text += "`n" + $message
    } else {
        $statusTextBlock.Text = $message
    }
    # Ensure $statusTextBlock is not null before trying to set Foreground
    if ($statusTextBlock) {
        # Parse hex color string to R, G, B components and create a SolidColorBrush
        # Handle cases where $color might not be a valid hex string by providing a default.
        try {
            $hexColor = $color.TrimStart('#')
            $red = [Convert]::ToByte($hexColor.Substring(0, 2), 16)
            $green = [Convert]::ToByte($hexColor.Substring(2, 2), 16)
            $blue = [Convert]::ToByte($hexColor.Substring(4, 2), 16)
            $solidColor = [System.Windows.Media.Color]::FromRgb($red, $green, $blue)
            $statusTextBlock.Foreground = New-Object System.Windows.Media.SolidColorBrush($solidColor)
        } catch {
            Write-Warning "Could not parse color '$color'. Defaulting to black. Error: $($_.Exception.Message)"
            $statusTextBlock.Foreground = [System.Windows.Media.Brushes]::Black # Fallback color
        }

        # Scroll to end to show latest messages, ensure Parent is not null
        if ($statusTextBlock.Parent) {
            $statusTextBlock.Parent.ScrollToEnd()
        }
    }
}

function Get-RedirectionStatus {
    # Checks the current state of the IE to Edge redirection registry setting.
    Update-Status "Checking current redirection status..."
    try {
        if (Test-Path $regPath) {
            $regValue = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue
            if ($regValue) {
                if ($regValue.$regValueName -eq 2) {
                    Update-Status "Current Status: Automatic redirection is DISABLED." -color "#DC3545"
                    return $true # Disabled
                } else {
                    Update-Status "Current Status: Automatic redirection is ENABLED (default or other value)." -color "#28A745"
                    return $false # Enabled
                }
            } else {
                Update-Status "Current Status: Registry value not found. Redirection is likely ENABLED by default." -color "#28A745"
                return $false # Enabled (default)
            }
        } else {
            Update-Status "Current Status: Registry path '$regPath' not found. Redirection is likely ENABLED by default." -color "#28A745"
            return $false # Enabled (default)
        }
    } catch {
        Update-Status "Error checking status: $($_.Exception.Message)" -color "#FFC107"
        return $false # Assume enabled on error
    }
}

function Disable-IERedirection {
    # Sets the registry key to disable IE to Edge redirection.
    Update-Status "Attempting to DISABLE automatic redirection..."
    Update-Status "Modifying registry key:`nPath: $regPath`nValue: $regValueName (DWORD)`nData: 2 (Never redirect)" -append $true -color "#007BFF"

    try {
        # Create the path if it doesn't exist
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
            Update-Status "Created registry path: $regPath" -append $true -color "#007BFF"
        }
        Set-ItemProperty -Path $regPath -Name $regValueName -Value 2 -Force -Confirm:$false -ErrorAction Stop
        Update-Status "SUCCESS: Automatic redirection has been DISABLED." -append $true -color "#28A745"
    } catch {
        Update-Status "ERROR: Failed to disable redirection. $($_.Exception.Message)" -append $true -color "#DC3545"
    }
    Get-RedirectionStatus # Refresh status after operation
}

function Enable-IERedirection {
    # Removes the registry key to re-enable IE to Edge redirection (revert to default).
    Update-Status "Attempting to ENABLE automatic redirection..."
    Update-Status "Removing registry value:`nPath: $regPath`nValue: $regValueName" -append $true -color "#007BFF"

    try {
        if (Test-Path $regPath) {
            Remove-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue -Confirm:$false
            Update-Status "SUCCESS: Automatic redirection has been ENABLED (registry value removed)." -append $true -color "#28A745"
        } else {
            Update-Status "Registry path '$regPath' does not exist. Redirection is already ENABLED by default." -append $true -color "#28A745"
        }
    } catch {
        Update-Status "ERROR: Failed to enable redirection. $($_.Exception.Message)" -append $true -color "#DC3545"
    }
    Get-RedirectionStatus # Refresh status after operation
}

#endregion

#region Event Handlers
# These define what happens when the buttons are clicked.
# Added try/catch to event handlers for robustness
try {
    $disableButton.Add_Click({
        try {
            Disable-IERedirection
        } catch {
            $title = "Button Click Error"
            $message = "An error occurred while attempting to disable redirection: `n`n$($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    })

    $enableButton.Add_Click({
        try {
            Enable-IERedirection
        } catch {
            $title = "Button Click Error"
            $message = "An error occurred while attempting to enable redirection: `n`n$($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    })
} catch {
    $title = "Event Handler Registration Error"
    $message = "Failed to register button click events. This likely means GUI elements were not found. `n`nError: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}
#endregion

#region Initial Setup and Show GUI
# Perform an initial status check when the GUI loads.
# Wrap the main GUI display in a try/catch for global error handling
try {
    # Added try/catch around Add_Loaded as well
    $window.Add_Loaded({
        try {
            Get-RedirectionStatus
        } catch {
            $title = "Initial Status Check Error"
            $message = "An error occurred during initial status check: `n`n$($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    })

    # Display the GUI window.
    $window.ShowDialog() | Out-Null
} catch {
    $title = "Application Error"
    $message = "An unexpected error occurred while running the application: `n`n$($_.Exception.Message)`n`nPress OK to exit."
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}
#endregion
