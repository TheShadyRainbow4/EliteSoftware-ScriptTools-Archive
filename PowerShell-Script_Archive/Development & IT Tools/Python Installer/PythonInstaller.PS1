<#
.SYNOPSIS
    Quick Python & Libraries Installer v1.0
    Created by: Zachary Whiteman & Google Gemini
    Date: 7/14/2025 - 1:34 PM

.DESCRIPTION
    A simple and direct script to install the latest version of Python 3 via winget,
    and then automatically install a set of essential libraries including wxPython and PyWin32.
#>

# --- Initial Setup: Minimize Console Window ---
try {
    $psWindow = (Get-Process -Id $PID).MainWindowHandle
    if ($psWindow) {
        Add-Type -Name Window -Namespace Console -MemberDefinition '
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        '
        [Console.Window]::ShowWindow($psWindow, 6) # 6 corresponds to SW_MINIMIZE
    }
}
catch { Write-Warning "Could not minimize the console window." }

# --- Script Configuration ---
# List of Python libraries to install after Python itself is installed.
$librariesToInstall = @(
    "wxpython",
    "pywin32",
    "requests", # For making HTTP requests
    "psutil"    # For system monitoring and process management
)

# --- Main Script Logic ---
function Start-PythonSetup {
    Write-Host "--- Starting Python Environment Setup ---" -ForegroundColor Cyan

    try {
        # Step 1: Install the latest version of Python using winget
        Write-Host "[1/3] Searching for and installing the latest Python 3..." -ForegroundColor Yellow
        $process = Start-Process winget -ArgumentList "install --id Python.Python.3 -e -h --accept-package-agreements --accept-source-agreements" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Winget failed to install Python. Exit Code: $($process.ExitCode). Please check the winget logs."
        }
        Write-Host "Latest Python 3 installed successfully." -ForegroundColor Green

        # Step 2: Find the new Python installation path
        Write-Host "[2/3] Locating the new Python installation..." -ForegroundColor Yellow
        # The default user installation path for Python from winget/store
        $pythonBasePath = Join-Path $env:LOCALAPPDATA "Programs\Python"
        $pythonExePath = Get-ChildItem -Path $pythonBasePath -Recurse -Filter python.exe | Sort-Object CreationTime -Descending | Select-Object -First 1
        
        if (-not $pythonExePath) {
            throw "Could not find python.exe after installation. Please check the installation path."
        }
        
        $pythonDirectory = $pythonExePath.DirectoryName
        Write-Host "Found Python at: $pythonDirectory" -ForegroundColor Green

        # Step 3: Install the required libraries using pip
        Write-Host "[3/3] Installing required libraries..." -ForegroundColor Yellow
        foreach ($library in $librariesToInstall) {
            Write-Host "  - Installing $library..."
            $pipProcess = Start-Process -FilePath $pythonExePath.FullName -ArgumentList "-m", "pip", "install", $library -Wait -PassThru -NoNewWindow
            if ($pipProcess.ExitCode -ne 0) {
                Write-Warning "    Failed to install $library. Pip exited with code $($pipProcess.ExitCode)."
            } else {
                Write-Host "    Successfully installed $library." -ForegroundColor Green
            }
        }

        Write-Host "`n--- Python Setup Complete! ---" -ForegroundColor Cyan
        Write-Host "You can now use Python and the installed libraries." -ForegroundColor White

    }
    catch {
        Write-Error "An error occurred during setup: $_"
        Write-Host "Setup failed. Please review the error message above." -ForegroundColor Red
    }
    finally {
        # Keep the console window open to review the output.
        Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
        Read-Host
    }
}

# --- Run the main function ---
Start-PythonSetup
