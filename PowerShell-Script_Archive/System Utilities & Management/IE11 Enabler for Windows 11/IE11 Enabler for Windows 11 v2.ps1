# IE11 Enabler for Windows 11 v1.2 - Refactored by Factory AI
#
# DESCRIPTION:
# This script provides a graphical user interface (GUI) to re-enable and launch
# a standalone Internet Explorer 11 instance on Windows 11. It works by modifying
# the registry to prevent automatic redirection to Edge and to reverse the Group Policy
# that disables standalone IE11.
#
# USAGE:
# Run the script. The GUI will appear, allowing you to specify a URL and launch IE11.
# This script requires administrator privileges to modify the registry.

# --- SCRIPT CONFIGURATION ---
Set-StrictMode -Version Latest

# --- CONSTANTS ---
$REG_PATH_BHO = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Ext\CLSID"
$REG_NAME_BHO = "{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}"
$REG_VALUE_BHO_DISABLE = "1" # Setting to "1" disables the IEToEdge Browser Helper Object

$REG_PATH_GP = "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main"
$REG_NAME_GP = "NotifyDisableIEOptions"
$REG_VALUE_GP_REENABLE = 0 # Setting to 0 re-enables standalone IE11, reversing Group Policy

$DEFAULT_URL = "https://192.168.1.12/"
$FORM_WIDTH = 420
$FORM_HEIGHT = 260
$LABEL_HEIGHT = 40
$BUTTON_HEIGHT = 40
$TEXTBOX_HEIGHT = 20
$CONTROL_PADDING = 10
$VERTICAL_SPACING = 15

# --- GUI SETUP ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

using namespace System.Windows.Forms
using namespace System.Drawing

# --- FUNCTIONS ---

function Set-RegistryValueSecurely {
    <#
    .SYNOPSIS
        Sets a registry value, creating the key if it doesn't exist.
    .DESCRIPTION
        This function is a wrapper for Set-ItemProperty that ensures the parent key
        exists before attempting to set the value. It requires administrator privileges.
    .PARAMETER Path
        The path to the registry key (e.g., HKLM:\SOFTWARE\YourApp).
    .PARAMETER Name
        The name of the registry value.
    .PARAMETER Value
        The data to set for the registry value.
    .PARAMETER Type
        The data type of the registry value (e.g., DWord, String).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [object]$Value,

        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.RegistryValueKind]$Type
    )

    if ($PSCmdlet.ShouldProcess($Path, "Set registry value '$Name' to '$Value'")) {
        try {
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force | Out-Null
            }
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop
            Write-Verbose "Successfully set registry value '$Name' at '$Path'."
            $true # Indicate success
        }
        catch {
            Write-Error "Failed to set registry value '$Name' at '$Path': $($_.Exception.Message)"
            $false # Indicate failure
        }
    }
}

function Show-IE11EnablerGUI {
    # --- MAIN FORM ---
    $form = [Form]@{
        Text = "IE11 Enabler for Windows 11"
        Size = [Size]::new($FORM_WIDTH, $FORM_HEIGHT)
        StartPosition = [FormStartPosition]::CenterScreen
        FormBorderStyle = [FormBorderStyle]::FixedSingle
        MaximizeBox = $false
        MinimizeBox = $true
    }

    # --- FONT & CONTROLS ---
    $font = [System.Drawing.SystemFonts]::DefaultFont

    # --- LABEL: INSTRUCTIONS ---
    $labelInstructions = [Label]@{
        Location = [Point]::new($CONTROL_PADDING, $CONTROL_PADDING)
        Size = [Size]::new($FORM_WIDTH - ($CONTROL_PADDING * 2) - 16, $LABEL_HEIGHT)
        Text = "This tool will apply the necessary registry changes to launch Internet Explorer 11. Enter a URL below or leave it blank for the default start page."
        Font = $font
    }

    # --- TEXTBOX: URL INPUT ---
    $urlTextBox = [TextBox]@{
        Location = [Point]::new($CONTROL_PADDING, $labelInstructions.Bottom + $VERTICAL_SPACING)
        Size = [Size]::new($FORM_WIDTH - ($CONTROL_PADDING * 2) - 16, $TEXTBOX_HEIGHT)
        Text = $DEFAULT_URL
        Font = $font
    }

    # --- BUTTON: LAUNCH IE ---
    $buttonLaunch = [Button]@{
        Location = [Point]::new($CONTROL_PADDING, $urlTextBox.Bottom + $VERTICAL_SPACING)
        Size = [Size]::new($FORM_WIDTH - ($CONTROL_PADDING * 2) - 16, $BUTTON_HEIGHT)
        Text = "&Enable & Launch Internet Explorer 11"
        Font = $font
        UseVisualStyleBackColor = $true
    }

    # --- LABEL: STATUS ---
    $statusLabel = [Label]@{
        Location = [Point]::new($CONTROL_PADDING, $buttonLaunch.Bottom + $VERTICAL_SPACING)
        Size = [Size]::new($FORM_WIDTH - ($CONTROL_PADDING * 2) - 16, $LABEL_HEIGHT)
        Text = "Status: Ready. Click the button to begin."
        Font = $font
        ForeColor = [Color]::Green
    }

    # --- LABEL: CREDITS ---
    $creditsLabel = [Label]@{
        Location = [Point]::new($CONTROL_PADDING, $statusLabel.Bottom + $VERTICAL_SPACING)
        Size = [Size]::new($FORM_WIDTH - ($CONTROL_PADDING * 2) - 16, $TEXTBOX_HEIGHT)
        Text = "IE11 Enabler v1.1 | ComputerCare Co. | Created by: Zachary Whiteman & Google Gemini AI"
        TextAlign = [ContentAlignment]::MiddleCenter
        Font = $font
    }

    # --- BUTTON CLICK EVENT HANDLER ---
    $buttonLaunch.Add_Click({
        # Check for Administrator privileges before attempting registry modifications.
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            $statusLabel.ForeColor = [Color]::Red
            $statusLabel.Text = "Status: ERROR! Administrator privileges required."
            [MessageBox]::Show("This script requires Administrator privileges to modify system registry settings. Please run as Administrator.", "Permissions Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
            return
        }

        try {
            $statusLabel.ForeColor = [Color]::Blue
            $statusLabel.Text = "Status: Applying registry changes..."

            # --- REGISTRY FIX 1: DISABLE BHO REDIRECTION ---
            # This disables the IEToEdge Browser Helper Object (BHO) responsible for redirecting IE to Edge.
            if (-not (Set-RegistryValueSecurely -Path $REG_PATH_BHO -Name $REG_NAME_BHO -Value $REG_VALUE_BHO_DISABLE -Type String)) {
                throw "Failed to disable IEToEdge BHO."
            }

            # --- REGISTRY FIX 2: RE-ENABLE STANDALONE IE (GROUP POLICY) ---
            # This reverses the "Disable Internet Explorer 11 as a standalone browser" policy,
            # which is crucial for preventing the "Server execution failed" COM error.
            if (-not (Set-RegistryValueSecurely -Path $REG_PATH_GP -Name $REG_NAME_GP -Value $REG_VALUE_GP_REENABLE -Type DWord)) {
                throw "Failed to re-enable standalone IE Group Policy."
            }

            $statusLabel.ForeColor = [Color]::DarkBlue
            $statusLabel.Text = "Status: Registry updated. Launching Internet Explorer..."

            # Create an instance of the Internet Explorer application using a COM object.
            # This is the most reliable way to launch a standalone IE instance.
            $ie = New-Object -ComObject 'InternetExplorer.Application'

            # Get the URL from the textbox. If it's empty or whitespace, use 'about:blank'.
            $urlToNavigate = $urlTextBox.Text
            if ([string]::IsNullOrWhiteSpace($urlToNavigate)) {
                $urlToNavigate = "about:blank"
            }

            $ie.Navigate($urlToNavigate)

            # Make the IE window visible.
            $ie.Visible = $true

            $statusLabel.ForeColor = [Color]::Green
            $statusLabel.Text = "Status: Success! Internet Explorer 11 has been launched. 🚀"
        }
        catch {
            # Error handling: Display the error message in the status label.
            $statusLabel.ForeColor = [Color]::Red
            $statusLabel.Text = "Status: ERROR! Could not launch IE. See console for details."

            # Write the full error to the console for debugging.
            Write-Error $_.Exception.Message -ErrorAction Continue

            # Display a more user-friendly message box.
            [MessageBox]::Show(
                "An error occurred: $($_.Exception.Message)`n`nPlease ensure you are running this script as an Administrator and that Internet Explorer components are still present on your system.",
                "Error",
                [MessageBoxButtons]::OK,
                [MessageBoxIcon]::Error
            )
        }
    })

    # --- ADD CONTROLS TO FORM ---
    $form.Controls.Add($labelInstructions)
    $form.Controls.Add($urlTextBox)
    $form.Controls.Add($buttonLaunch)
    $form.Controls.Add($statusLabel)
    $form.Controls.Add($creditsLabel)

    # --- SHOW THE FORM ---
    [void]$form.ShowDialog()
}

# --- SCRIPT ENTRY POINT ---
Show-IE11EnablerGUI

# --- CONSOLE PAUSE ---
# Keep the console window open after the GUI is closed to allow for reading any output or error messages.
Read-Host -Prompt "Application has finished. Press Enter to close this window"