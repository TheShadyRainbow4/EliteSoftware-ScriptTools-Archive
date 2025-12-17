<#
.SYNOPSIS
    A PowerShell script to act as a simple launcher and installer for Node.js applications.
    It provides a GUI to run 'npm install' and 'npm run dev' from any project folder.

.DESCRIPTION
    This script is designed to be placed directly within a Node.js project folder.
    When executed, it checks for Node.js and npm, and if they exist, it displays a GUI.
    The GUI allows the user to click a button to install dependencies or run the development server.
    This version launches the 'npm run dev' command in its own visible console window to prevent GUI freezing. It then monitors that window's output for the server URL and provides a dedicated button to open the browser.
    The console window of the main GUI is minimized on startup.
    Error messages are still logged to the console, and it will remain open if the GUI is closed due to an error.

.CREDITS
    Created by: Zachary Whiteman & Google Gemini Ai. (8/18/2025 - 10:07 AM EDT)
#>

# Add a function to ensure the console window stays open on crash.
function global:Wait-For-Key {
    Write-Host "Press any key to close this window..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
# Set a trap to call the function on script termination due to error.
trap {
    Write-Error $_.Exception.Message
    Wait-For-Key
}

# Add a function to minimize the console window.
function Minimize-Console {
    $code = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
    $minimize = Add-Type -MemberDefinition $code -Name WindowHelper -Namespace ConsoleHelper -PassThru
    $windowHandle = (Get-Process -Id $PID).MainWindowHandle
    $minimize::ShowWindow($windowHandle, 2) # 2 corresponds to SW_MINIMIZE
}

# Add a function to check for Node.js and npm dependencies.
function Check-Dependencies {
    try {
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            $msg = "Node.js is not found on your system. Please install it from `https://nodejs.org/` to continue."
            [System.Windows.Forms.MessageBox]::Show($msg, "Dependency Missing", 'OK', 'Error')
            throw $msg
        }
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            $msg = "npm is not found on your system. It should be installed with Node.js. Please reinstall Node.js."
            [System.Windows.Forms.MessageBox]::Show($msg, "Dependency Missing", 'OK', 'Error')
            throw $msg
        }
    } catch {
        Write-Error "Dependency check failed: $_"
        exit
    }
}

# Global variables
$script:devProcess = $null
$script:serverUrl = $null
$script:consoleProcessId = $null

# Add a function to find the console window by its title.
function Get-ConsoleHandleByTitle($title) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class WindowHelper {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@
    [WindowHelper]::FindWindow($null, $title)
}

# Add a function to get window text.
function Get-WindowText($hWnd) {
    Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class WindowHelper {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowTextLength(IntPtr hWnd);
}
"@
    $len = [WindowHelper]::GetWindowTextLength($hWnd)
    if ($len -eq 0) { return "" }
    $sb = New-Object System.Text.StringBuilder($len + 1)
    [WindowHelper]::GetWindowText($hWnd, $sb, $sb.Capacity)
    return $sb.ToString()
}

# Add a function to get the process ID of a window.
function Get-ProcessIdFromWindowHandle($hWnd) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class WindowHelper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@
    $procId = 0
    [WindowHelper]::GetWindowThreadProcessId($hWnd, [ref]$procId)
    return $procId
}

# Minimize the console window on startup.
Minimize-Console

# Run the dependency check.
Check-Dependencies

# Load the required .NET assemblies.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable visual styles for system theming as per user preference.
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create the main form.
$form = New-Object System.Windows.Forms.Form
$form.Text = "Node.js App Launcher"
$form.Size = New-Object System.Drawing.Size(400, 350)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle' # Prevent resizing
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Create the two-tone header panel.
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size($form.Width, 50)
$headerPanel.Dock = 'Top'
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 12, 100, 160)
$form.Controls.Add($headerPanel)

# Add the title label to the header panel.
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Node.Js App Launcher"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Location = New-Object System.Drawing.Point(10, 15)
$titleLabel.AutoSize = $true
$headerPanel.Controls.Add($titleLabel)

# Create a rich text box for output display.
$outputTextBox = New-Object System.Windows.Forms.RichTextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 60)
$outputTextBox.Size = New-Object System.Drawing.Size(364, 150)
$outputTextBox.Anchor = 'Top, Left, Right, Bottom'
$outputTextBox.ReadOnly = $true
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = 'Vertical'
$form.Controls.Add($outputTextBox)

# Create the "npm install" button.
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Run npm install"
$installButton.Location = New-Object System.Drawing.Point(10, 220)
$installButton.Size = New-Object System.Drawing.Size(115, 40)
$installButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($installButton)

# Create the "npm run dev" button.
$devButton = New-Object System.Windows.Forms.Button
$devButton.Text = "Run npm run dev"
$devButton.Location = New-Object System.Drawing.Point(135, 220)
$devButton.Size = New-Object System.Drawing.Size(120, 40)
$devButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($devButton)

# Create the close button.
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Location = New-Object System.Drawing.Point(265, 220)
$closeButton.Size = New-Object System.Drawing.Size(109, 40)
$closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($closeButton)

# Create the "Stop Server" button with a red background.
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop Server"
$stopButton.Location = New-Object System.Drawing.Point(10, 265)
$stopButton.Size = New-Object System.Drawing.Size(250, 40)
$stopButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$stopButton.Enabled = $false
$stopButton.BackColor = [System.Drawing.Color]::Crimson
$form.Controls.Add($stopButton)

# Create the "Open Browser" button.
$browserButton = New-Object System.Windows.Forms.Button
$browserButton.Text = "Open Browser"
$browserButton.Location = New-Object System.Drawing.Point(265, 265)
$browserButton.Size = New-Object System.Drawing.Size(109, 40)
$browserButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$browserButton.Enabled = $false
$form.Controls.Add($browserButton)

# Add a timer to poll for console output
$consoleTimer = New-Object System.Windows.Forms.Timer
$consoleTimer.Interval = 500 # Check every 0.5 seconds

$consoleTimer.add_Tick({
    if ($script:devProcess -and -not $script:serverUrl) {
        $hWnd = Get-ConsoleHandleByTitle("Node.js Server - ")
        if ($hWnd -ne [IntPtr]::Zero) {
            $consoleText = Get-WindowText($hWnd)
            $match = [regex]::Match($consoleText, 'http[s]?://[^\s,]+')
            if ($match.Success) {
                $script:serverUrl = $match.Value
                $outputTextBox.AppendText("`n`nServer URL found: " + $script:serverUrl)
                $browserButton.Enabled = $true
                $consoleTimer.Enabled = $false
            }
        }
    }
})

# Add click event handlers to the buttons.
$installButton.Add_Click({
    $installButton.Enabled = $false
    $devButton.Enabled = $false
    $stopButton.Enabled = $false
    $browserButton.Enabled = $false
    $outputTextBox.Text = "Running 'npm install'..." | Out-String
    $form.Refresh()
    
    $installProcess = Start-Process -FilePath "npm.cmd" -ArgumentList "install" -Wait -PassThru -NoNewWindow
    $installProcess.WaitForExit()
    
    if ($installProcess.ExitCode -ne 0) {
        [System.Windows.Forms.MessageBox]::Show("The 'npm install' command failed. Check console for details.", "Error", 'OK', 'Error')
    } else {
        $outputTextBox.Text = "npm install completed successfully.`n`nReady to run 'npm run dev'."
    }
    
    $installButton.Enabled = $true
    $devButton.Enabled = $true
})

$devButton.Add_Click({
    $installButton.Enabled = $false
    $devButton.Enabled = $false
    
    if ($script:devProcess) {
        [System.Windows.Forms.MessageBox]::Show("A dev server is already running. Please stop it first.", "Warning", 'OK', 'Warning')
        return
    }

    $outputTextBox.Text = "Starting dev server in new console window..."
    $stopButton.Enabled = $true
    
    # Use a unique title to find the window later.
    $title = "Node.js Server - " + (Get-Date).Ticks
    $script:devProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/k title $title & npm run dev" -PassThru
    $script:consoleProcessId = $script:devProcess.Id
    
    $outputTextBox.AppendText("`nWaiting for server to start and provide a URL...")
    $consoleTimer.Enabled = $true
})

$browserButton.Add_Click({
    if ($script:serverUrl) {
        Start-Process $script:serverUrl
    }
})

$stopButton.Add_Click({
    if ($script:consoleProcessId) {
        Stop-Process -Id $script:consoleProcessId -Force
        $outputTextBox.AppendText("`n`nServer process has been stopped.")
        $script:consoleProcessId = $null
        $script:devProcess = $null
        $script:serverUrl = $null
        $stopButton.Enabled = $false
        $browserButton.Enabled = false
        $installButton.Enabled = $true
        $devButton.Enabled = true
    }
})

$closeButton.Add_Click({
    # Stop the dev process if it's still running when the user closes the form.
    if ($script:consoleProcessId) {
        Stop-Process -Id $script:consoleProcessId -Force
    }
    $form.Close()
})

# Show the GUI form.
[void]$form.ShowDialog()
