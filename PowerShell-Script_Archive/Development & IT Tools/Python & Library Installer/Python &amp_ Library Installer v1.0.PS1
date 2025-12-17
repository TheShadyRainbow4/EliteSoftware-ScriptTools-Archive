<#
.SYNOPSIS
    A PowerShell GUI application to install the latest version of Python and common libraries for all users.
.DESCRIPTION
    This script provides a user-friendly interface to:
    1. Check for and request Administrator privileges.
    2. Use winget to download and install the latest official Python 3 release for all users (--scope machine).
    3. Use pip to install a list of popular and useful Python libraries, including pywin32 and wxpython.
    4. Display real-time installation progress and logs in a text box.
    5. Keep the console window open for error review if launched from a console.
.NOTES
    Python & Library Installer v1.2 - Created by: Zachary Whiteman & Google Gemini Ai. 07/14/2025 - 7:16 PM
    Requires an active internet connection.
    Must be run as an Administrator to function correctly.
    v1.1: Fixed cross-thread error by implementing a robust job message queue system.
    v1.2: Enabled visual styles for proper system theming of UI elements.
#>

# --- PRE-FLIGHT CHECK: ADMINISTRATOR PRIVILEGES ---
# This section ensures the script is running with elevated permissions.
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # If not running as admin, show a pop-up and re-launch the script as admin.
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# --- GUI SETUP: ASSEMBLIES AND FORM CREATION ---
# Load the necessary .NET assemblies for creating a Graphical User Interface.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- ENABLE VISUAL STYLES FOR THEMING ---
# This line is crucial for making the UI elements (like buttons) use the current Windows theme.
# It must be called before any forms are created.
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- FORM DEFINITION ---
# This is the main window of our application.
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Python & Library Installer (ComputerCare Co.)"
$mainForm.Size = New-Object System.Drawing.Size(620, 480)
$mainForm.MinimumSize = New-Object System.Drawing.Size(500, 400)
$mainForm.StartPosition = 'CenterScreen'
$mainForm.FormBorderStyle = 'Sizable' # Use system default resizable border
$mainForm.AutoScaleMode = 'Dpi'

# --- UI ELEMENT: TITLE LABEL ---
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Python All-in-One Installer"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)

# --- UI ELEMENT: DESCRIPTION LABEL ---
$descriptionLabel = New-Object System.Windows.Forms.Label
$descriptionLabel.Text = "This tool will install the latest Python for ALL users and a set of common libraries. Click 'Start Installation' to begin."
$descriptionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$descriptionLabel.AutoSize = $true
$descriptionLabel.MaximumSize = New-Object System.Drawing.Size(560, 0) # Allow word wrap
$descriptionLabel.Location = New-Object System.Drawing.Point(20, 60)

# --- UI ELEMENT: OUTPUT LOG TEXTBOX ---
# This RichTextBox will display the output from the installation commands.
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 100)
$outputBox.Size = New-Object System.Drawing.Size(560, 280)
$outputBox.Anchor = ('Top, Bottom, Left, Right') # Make it resize with the window
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::White
$outputBox.Text = "Welcome! Ready to install. Please ensure you have an active internet connection.`n`n"

# --- UI ELEMENT: INSTALL BUTTON ---
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Start Installation"
$installButton.Size = New-Object System.Drawing.Size(140, 35)
$installButton.Location = New-Object System.Drawing.Point(20, 390)
$installButton.Anchor = ('Bottom, Left')
$installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
# The line added earlier makes this property work as expected.
$installButton.UseVisualStyleBackColor = $true

# --- UI ELEMENT: CLOSE BUTTON ---
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Size = New-Object System.Drawing.Size(100, 35)
$closeButton.Location = New-Object System.Drawing.Point(480, 390)
$closeButton.Anchor = ('Bottom, Right')
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$closeButton.UseVisualStyleBackColor = $true

# --- ADD CONTROLS TO THE FORM ---
$mainForm.Controls.Add($titleLabel)
$mainForm.Controls.Add($descriptionLabel)
$mainForm.Controls.Add($outputBox)
$mainForm.Controls.Add($installButton)
$mainForm.Controls.Add($closeButton)

# --- FUNCTION TO LOG MESSAGES TO THE GUI ---
# This helper function makes it easy to append text to our output box.
function Log-Message {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Black
    )
    # This function is now only called from the main thread, so it's safe.
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionLength = 0
    $outputBox.SelectionColor = $Color
    $outputBox.AppendText("$Message`n")
    $outputBox.ScrollToCaret()
}

# --- EVENT HANDLERS (ACTIONS) ---

# Action for the "Close" button.
$closeButton.Add_Click({
    $mainForm.Close()
})

# Action for the "Start Installation" button.
$installButton.Add_Click({
    # Disable the button to prevent multiple clicks.
    $installButton.Enabled = $false
    $installButton.Text = "Installing..."

    # Define the list of Python libraries to be installed.
    $libraries = @(
        "wheel", "pip", "pywin32", "wxPython", "requests", "numpy", "pandas",
        "matplotlib", "scipy", "Pillow", "beautifulsoup4", "lxml", "openpyxl", "virtualenv"
    )

    # PowerShell Jobs are used to run the installation in the background.
    # This keeps the GUI responsive and prevents it from freezing.
    $scriptBlock = {
        param($libs)

        # Helper function to create a structured log object to send back to the main thread.
        function New-LogEntry {
            param($Message, $Color = 'Black')
            [PSCustomObject]@{
                Message = $Message
                Color   = $Color
            } | Write-Output
        }

        try {
            # --- STEP 1: INSTALL PYTHON ---
            New-LogEntry "Starting Python installation for all users..." -Color "Blue"
            New-LogEntry "This may take several minutes. Please be patient." -Color "Blue"
            
            # Use winget to install Python system-wide. All output is sent back to the main thread.
            winget install --id Python.Python.3 --scope machine --accept-package-agreements --accept-source-agreements --silent | ForEach-Object { New-LogEntry $_ }
            
            New-LogEntry "Python installation command finished." -Color "Green"
            
            # --- STEP 2: FIND PYTHON'S PIP EXECUTABLE ---
            New-LogEntry "Searching for Python installation path..."
            # Refresh environment variables to find the newly installed Python path.
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            $pipPath = Get-Command pip.exe -ErrorAction SilentlyContinue
            if (-not $pipPath) {
                # Fallback search if it's not in PATH immediately.
                $pythonInstallDir = Get-ChildItem -Path "C:\Program Files\Python*", "C:\Program Files (x86)\Python*" -Recurse -Filter "pip.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                $pipPath = $pythonInstallDir.FullName
            } else {
                 $pipPath = $pipPath.Source
            }

            if (-not $pipPath) {
                throw "FATAL: Could not find pip.exe after installation. Please check your system's PATH environment variables."
            }
            
            New-LogEntry "Found pip at: $pipPath" -Color "Green"

            # --- STEP 3: INSTALL LIBRARIES ---
            New-LogEntry "Starting library installation..." -Color "Blue"
            
            foreach ($lib in $libs) {
                New-LogEntry "-------------------------------------------"
                New-LogEntry "Installing library: $lib" -Color "DarkCyan"
                
                # Execute pip install for each library. Output is sent back.
                & $pipPath install --upgrade $lib | ForEach-Object { New-LogEntry $_ }
                
                if ($LASTEXITCODE -ne 0) {
                    New-LogEntry "Warning: Installation of '$lib' may have failed (Exit code: $LASTEXITCODE)." -Color "OrangeRed"
                } else {
                    New-LogEntry "Successfully installed/updated '$lib'." -Color "Green"
                }
            }
            
            New-LogEntry "-------------------------------------------"
            New-LogEntry "✅ Installation Complete! ✅" -Color "Green"
            New-LogEntry "You can now close this window."

        } catch {
            # --- ERROR HANDLING ---
            New-LogEntry "❌ AN ERROR OCCURRED! ❌" -Color "Red"
            New-LogEntry $_.Exception.Message -Color "Red"
        }
    }

    # This try/finally block ensures the button is always re-enabled and the job is cleaned up.
    $job = $null
    try {
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList (,$libraries)

        # This loop checks for messages from the job and displays them, keeping the UI responsive.
        while ($job.State -in 'Running', 'NotStarted') {
            Receive-Job -Job $job | ForEach-Object {
                if ($_ -is [System.Management.Automation.PSCustomObject] -and $_.PSObject.Properties.Name -contains 'Message') {
                    Log-Message -Message $_.Message -Color $_.Color
                } else {
                    Log-Message -Message $_.ToString() # For raw output from commands
                }
            }
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.Application]::DoEvents()
        }

        # Process any final messages after the job completes.
        Receive-Job -Job $job | ForEach-Object {
            if ($_ -is [System.Management.Automation.PSCustomObject] -and $_.PSObject.Properties.Name -contains 'Message') {
                Log-Message -Message $_.Message -Color $_.Color
            } else {
                Log-Message -Message $_.ToString()
            }
        }
    }
    finally {
        if ($job) {
            Remove-Job $job -Force
        }
        $installButton.Enabled = $true
        $installButton.Text = "Start Installation"
    }
})

# --- DISPLAY THE FORM ---
# This command shows the GUI and waits for the user to interact with it.
$mainForm.ShowDialog() | Out-Null

# --- CLEANUP ---
# Dispose of the form object to free up memory.
$mainForm.Dispose()
