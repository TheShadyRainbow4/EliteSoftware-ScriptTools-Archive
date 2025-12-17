# IE11 Enabler for Windows 11 v1.1 - Created by: Zachary Whiteman & Google Gemini Ai. 7/13/2025 - 4:05 PM
#
# DESCRIPTION:
# This script provides a graphical user interface (GUI) to re-enable and launch
# a standalone Internet Explorer 11 instance on Windows 11. It works by modifying
# the registry to prevent automatic redirection to Edge and to reverse the Group Policy
# that disables standalone IE11.

# --- GUI SETUP ---
# Load the necessary assemblies for Windows Forms.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- MAIN FORM ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "IE11 Enabler for Windows 11"
$form.Size = New-Object System.Drawing.Size(420, 260)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.MinimizeBox = $true # As requested, allow minimizing the console.

# --- FONT & CONTROLS ---
# Use the system's default font to ensure it matches your theme.
$font = [System.Drawing.SystemFonts]::DefaultFont

# --- LABEL: INSTRUCTIONS ---
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(380, 40)
$label.Text = "This tool will apply the necessary registry changes to launch Internet Explorer 11. Enter a URL below or leave it blank for the default start page."
$label.Font = $font

# --- TEXTBOX: URL INPUT ---
$urlTextBox = New-Object System.Windows.Forms.TextBox
$urlTextBox.Location = New-Object System.Drawing.Point(10, 55)
$urlTextBox.Size = New-Object System.Drawing.Size(380, 20)
$urlTextBox.Text = "https://192.168.1.12/" # Default URL updated as requested
$urlTextBox.Font = $font

# --- BUTTON: LAUNCH IE ---
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 90)
$button.Size = New-Object System.Drawing.Size(380, 40)
$button.Text = "Enable & Launch Internet Explorer 11"
$button.Font = $font
# This UseVisualStyleBackColor ensures the button uses the default system theme.
$button.UseVisualStyleBackColor = $true

# --- LABEL: STATUS ---
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 140)
$statusLabel.Size = New-Object System.Drawing.Size(380, 40)
$statusLabel.Text = "Status: Ready. Click the button to begin."
$statusLabel.Font = $font
$statusLabel.ForeColor = [System.Drawing.Color]::Green

# --- LABEL: CREDITS ---
$creditsLabel = New-Object System.Windows.Forms.Label
$creditsLabel.Location = New-Object System.Drawing.Point(10, 190)
$creditsLabel.Size = New-Object System.Drawing.Size(380, 20)
$creditsLabel.Text = "IE11 Enabler v1.1 | ComputerCare Co. | Created by: Zachary Whiteman & Google Gemini AI"
$creditsLabel.TextAlign = "MiddleCenter"
$creditsLabel.Font = $font

# --- BUTTON CLICK EVENT HANDLER ---
$button.Add_Click({
    try {
        $statusLabel.ForeColor = [System.Drawing.Color]::Blue
        $statusLabel.Text = "Status: Applying registry changes... This requires administrator privileges."

        # --- REGISTRY FIX 1: DISABLE BHO REDIRECTION ---
        # The key to this process is disabling the IEToEdge Browser Helper Object (BHO).
        $bhoRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Ext\CLSID"
        $bhoRegValueName = "{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}"
        $bhoRegValue = "1" # Setting to "1" disables the BHO
        if (-not (Test-Path $bhoRegPath)) { New-Item -Path $bhoRegPath -Force | Out-Null }
        Set-ItemProperty -Path $bhoRegPath -Name $bhoRegValueName -Value $bhoRegValue -Type String -Force

        # --- REGISTRY FIX 2: RE-ENABLE STANDALONE IE (GROUP POLICY) ---
        # This reverses the "Disable Internet Explorer 11 as a standalone browser" policy.
        # This is the crucial fix for the "Server execution failed" COM error.
        $gpRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main"
        $gpRegValueName = "NotifyDisableIEOptions"
        $gpRegValue = 0 # Setting to 0 re-enables IE11.
        if (-not (Test-Path $gpRegPath)) { New-Item -Path $gpRegPath -Force | Out-Null }
        Set-ItemProperty -Path $gpRegPath -Name $gpRegValueName -Value $gpRegValue -Type DWord -Force


        $statusLabel.ForeColor = [System.Drawing.Color]::DarkBlue
        $statusLabel.Text = "Status: Registry updated. Launching Internet Explorer..."

        # Create an instance of the Internet Explorer application using a COM object.
        # This is the most reliable way to bypass the shell's redirection of iexplore.exe.
        $ie = New-Object -ComObject 'InternetExplorer.Application'

        # Get the URL from the textbox. If it's empty, use 'about:blank'.
        $urlToNavigate = $urlTextBox.Text
        if ([string]::IsNullOrWhiteSpace($urlToNavigate)) {
            $urlToNavigate = "about:blank"
        }

        $ie.Navigate($urlToNavigate)

        # Make the IE window visible.
        $ie.Visible = $true

        $statusLabel.ForeColor = [System.Drawing.Color]::Green
        $statusLabel.Text = "Status: Success! Internet Explorer 11 has been launched. 🚀"

    }
    catch {
        # Error handling: Display the error message in the status label.
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        $statusLabel.Text = "Status: ERROR! Could not launch IE. See console for details."
        
        # Write the full error to the console for debugging.
        Write-Error $_.Exception.Message
        
        # Display a more user-friendly message box.
        [System.Windows.Forms.MessageBox]::Show(
            "An error occurred: $($_.Exception.Message)`n`nPlease ensure you are running this script as an Administrator.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# --- ADD CONTROLS TO FORM ---
$form.Controls.Add($label)
$form.Controls.Add($urlTextBox)
$form.Controls.Add($button)
$form.Controls.Add($statusLabel)
$form.Controls.Add($creditsLabel)

# --- SHOW THE FORM ---
# This will make the script wait until the form is closed.
# The [void] cast suppresses the 'OK'/'Cancel' output from the dialog.
[void]$form.ShowDialog()

# --- CONSOLE PAUSE ---
# As requested, this will keep the console window open after the GUI is closed
# to allow for reading any output or error messages.
Read-Host -Prompt "Application has finished. Press Enter to close this window"
