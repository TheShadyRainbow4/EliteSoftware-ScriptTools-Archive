#.NET Environment Manager v1.2 - Created by: Zachary Whiteman & Google Gemini Ai. [2025-07-13] - [11:11 AM]
# --- SCRIPT START ---

#region --- Minimize Console Window ---
# This C# code block accesses the necessary Windows API to control the console window's state.
$code = @"
using System;
using System.Runtime.InteropServices;
public class Window
{
    // Import the ShowWindow function from user32.dll
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    // Import the GetConsoleWindow function from kernel32.dll
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
}
"@
Add-Type -TypeDefinition $code -Language CSharp

# Get the handle of the current console window.
$consoleHandle = [Window]::GetConsoleWindow()
# Minimize the window. The '2' is the command code for SW_MINIMIZE.
if ($consoleHandle -ne [IntPtr]::Zero) {
    [Window]::ShowWindow($consoleHandle, 2)
}
#endregion --- Minimize Console Window ---


#region --- Assembly & Namespace Imports ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
#endregion --- Assembly & Namespace Imports ---

#region --- Main Form GUI ---
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = ".NET Environment Manager"
$MainForm.Size = New-Object System.Drawing.Size(500, 420)
$MainForm.StartPosition = "CenterScreen"
$MainForm.FormBorderStyle = "FixedSingle"
$MainForm.MaximizeBox = $false
$MainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

# Add a label for instructions
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Select a .NET SDK version to install or use the verification tools below.
A new terminal window will open to show the installation progress."
$Label.Location = New-Object System.Drawing.Point(20, 20)
$Label.Size = New-Object System.Drawing.Size(460, 50)
$MainForm.Controls.Add($Label)

# GroupBox for Installers
$InstallGroupBox = New-Object System.Windows.Forms.GroupBox
$InstallGroupBox.Location = New-Object System.Drawing.Point(20, 80)
$InstallGroupBox.Size = New-Object System.Drawing.Size(210, 150)
$InstallGroupBox.Text = "Install .NET SDK"
$MainForm.Controls.Add($InstallGroupBox)

# GroupBox for Diagnostics
$VerifyGroupBox = New-Object System.Windows.Forms.GroupBox
$VerifyGroupBox.Location = New-Object System.Drawing.Point(250, 80)
$VerifyGroupBox.Size = New-Object System.Drawing.Size(210, 150)
$VerifyGroupBox.Text = "Diagnostics"
$MainForm.Controls.Add($VerifyGroupBox)

# --- Buttons for Installation ---
$ButtonDotNet8 = New-Object System.Windows.Forms.Button
$ButtonDotNet8.Text = "Install .NET 8 SDK (LTS)"
$ButtonDotNet8.Location = New-Object System.Drawing.Point(20, 30)
$ButtonDotNet8.Size = New-Object System.Drawing.Size(170, 30)
$ButtonDotNet8.add_Click({
    Write-Host "Starting .NET 8 SDK installation..."
    Start-Process powershell -ArgumentList "-NoExit -Command &{winget install Microsoft.DotNet.SDK.8}"
})
$InstallGroupBox.Controls.Add($ButtonDotNet8)

$ButtonDotNet6 = New-Object System.Windows.Forms.Button
$ButtonDotNet6.Text = "Install .NET 6 SDK (LTS)"
$ButtonDotNet6.Location = New-Object System.Drawing.Point(20, 100)
$ButtonDotNet6.Size = New-Object System.Drawing.Size(170, 30)
$ButtonDotNet6.add_Click({
    Write-Host "Starting .NET 6 SDK installation..."
    Start-Process powershell -ArgumentList "-NoExit -Command &{winget install Microsoft.DotNet.SDK.6}"
})
$InstallGroupBox.Controls.Add($ButtonDotNet6)

# --- Buttons for Diagnostics ---
$ButtonVerify = New-Object System.Windows.Forms.Button
$ButtonVerify.Text = "Verify .NET Info"
$ButtonVerify.Location = New-Object System.Drawing.Point(20, 30)
$ButtonVerify.Size = New-Object System.Drawing.Size(170, 30)
$ButtonVerify.add_Click({
    Write-Host "Verifying .NET installation..."
    Start-Process powershell -ArgumentList "-NoExit -Command &{dotnet --info; Read-Host 'Press Enter to close'}"
})
$VerifyGroupBox.Controls.Add($ButtonVerify)

$ButtonCheckPath = New-Object System.Windows.Forms.Button
$ButtonCheckPath.Text = "Check System PATH"
$ButtonCheckPath.Location = New-Object System.Drawing.Point(20, 100)
$ButtonCheckPath.Size = New-Object System.Drawing.Size(170, 30)
$ButtonCheckPath.add_Click({
    # Fetching the PATH from the Machine level for accuracy
    $MachinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $UserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    
    $PathInfo = "--- MACHINE PATH ---`n" + ($MachinePath -split ';' -join "`n") + "`n`n--- USER PATH ---`n" + ($UserPath -split ';' -join "`n")
    
    [System.Windows.Forms.MessageBox]::Show($PathInfo, "System PATH Variable")
})
$VerifyGroupBox.Controls.Add($ButtonCheckPath)

# --- Output TextBox ---
$OutputTextBox = New-Object System.Windows.Forms.TextBox
$OutputTextBox.Location = New-Object System.Drawing.Point(20, 240)
$OutputTextBox.Size = New-Object System.Drawing.Size(440, 120)
$OutputTextBox.Multiline = $true
$OutputTextBox.ScrollBars = "Vertical"
$OutputTextBox.ReadOnly = $true
$OutputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$OutputTextBox.Text = "Script output and status messages will appear in the PowerShell console window that launched this application. 
Installation progress will appear in new terminal windows."
$MainForm.Controls.Add($OutputTextBox)

#endregion --- Main Form GUI ---

#region --- Show Form ---
# This ensures the console stays open for any errors during form loading or interaction.
try {
    Write-Host "Launching .NET Environment Manager GUI..."
    $MainForm.ShowDialog() | Out-Null
    Write-Host ".NET Environment Manager GUI closed."
}
catch {
    Write-Host "An error occurred while running the GUI:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Read-Host "Press Enter to exit."
}
#endregion --- Show Form ---

# --- SCRIPT END ---