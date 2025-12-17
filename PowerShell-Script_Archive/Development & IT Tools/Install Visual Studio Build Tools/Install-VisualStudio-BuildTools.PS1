#requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs Visual Studio 2022 Community and Build Tools, then adds their paths to the system PATH variable.
.DESCRIPTION
    This script automates the download and silent installation of both the VS 2022 Community IDE and the VS 2022 Build Tools.
    It installs them into a structured directory under the specified root path. A detailed log file is generated for each run.

    After successful installations, it finds the following paths and adds them to the system PATH:
    1. The Visual Studio IDE directory (containing devenv.exe).
    2. The MSVC C++ compiler toolchain from the Build Tools installation.
    3. The Windows SDK directory (containing rc.exe).

    This script must be run with Administrator privileges to modify the system PATH.
.NOTES
    Author: Gemini
    Version: 2.3
#>

#================================================================================================
# Configuration
#================================================================================================
# The root directory where all Visual Studio products will be installed.
$installRoot = "E:\VisualStudio"
# A unique, timestamped log file will be created in the user's temp directory.
$logFile = Join-Path -Path $env:TEMP -ChildPath "vs_install_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# --- Visual Studio Community Configuration ---
$vsCommunityWorkloads = @(
    "Microsoft.VisualStudio.Workload.ManagedDesktop", # .NET desktop development
    "Microsoft.VisualStudio.Workload.NativeDesktop"   # Desktop development with C++
)
$vsCommunityInstallerUrl = "https://aka.ms/vs/17/release/vs_community.exe"
$vsCommunityInstallerPath = Join-Path -Path $env:TEMP -ChildPath "vs_community.exe"
$vsCommunityInstallPath = Join-Path -Path $installRoot -ChildPath "Community"

# --- Build Tools Configuration ---
$buildToolsWorkload = "Microsoft.VisualStudio.Workload.NativeDesktop" # Includes the Windows SDK
$buildToolsInstallerUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
$buildToolsInstallerPath = Join-Path -Path $env:TEMP -ChildPath "vs_buildtools.exe"
$buildToolsInstallPath = Join-Path -Path $installRoot -ChildPath "BuildTools"

#================================================================================================
# Logging Function
#================================================================================================
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] :: $Message"

    # Append to log file
    try {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "FATAL: Failed to write to log file '$logFile'. Error: $_"
    }

    # Write to console with color coding
    switch ($Level) {
        "INFO"  { Write-Host $logEntry }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
    }
}

#================================================================================================
# Main Script Execution
#================================================================================================
# Main try-catch-finally block for global handling and cleanup
try {
    Write-Log -Message "--- Script execution started ---"
    Write-Log -Message "Log file will be saved to: $logFile"

    # --- Section 0: Initial Checks ---
    Write-Log -Message "--- Performing Initial Checks ---"
    
    # Check for Administrator privileges
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run with Administrator privileges. Please re-run from an elevated PowerShell terminal."
    }
    Write-Log -Message "Administrator privileges confirmed."

    # Check if the target installation drive exists
    $installDrive = Split-Path -Path $installRoot -Qualifier
    if (-not (Test-Path -Path $installDrive)) {
        throw "The target installation drive '$installDrive' does not exist. Please update the `$installRoot variable or ensure the drive is available."
    }
    Write-Log -Message "Target install drive '$installDrive' exists."

    # --- Section 1: Downloading Installers ---
    Write-Log -Message "--- Section 1: Downloading Installers ---"

    # Download VS Community Installer
    if (Test-Path $vsCommunityInstallerPath) {
        Write-Log -Message "Visual Studio Community installer already exists. Skipping download."
    }
    else {
        try {
            Write-Log -Message "Downloading VS Community installer from '$vsCommunityInstallerUrl'..."
            Invoke-WebRequest -Uri $vsCommunityInstallerUrl -OutFile $vsCommunityInstallerPath -UseBasicParsing -ErrorAction Stop
            Write-Log -Message "Community installer download complete."
        }
        catch {
            throw "Failed to download the VS Community installer. Error: $_"
        }
    }

    # Download Build Tools Installer
    if (Test-Path $buildToolsInstallerPath) {
        Write-Log -Message "Visual Studio Build Tools installer already exists. Skipping download."
    }
    else {
        try {
            Write-Log -Message "Downloading VS Build Tools installer from '$buildToolsInstallerUrl'..."
            Invoke-WebRequest -Uri $buildToolsInstallerUrl -OutFile $buildToolsInstallerPath -UseBasicParsing -ErrorAction Stop
            Write-Log -Message "Build Tools installer download complete."
        }
        catch {
            throw "Failed to download the Build Tools installer. Error: $_"
        }
    }

    # --- Section 2: Installing Visual Studio Products ---
    Write-Log -Message "--- Section 2: Installing Visual Studio Products ---"
    Write-Log -Message "This process may take a significant amount of time. Please be patient."

    # Install Visual Studio Community
    Write-Log -Message "Installing Visual Studio Community to '$vsCommunityInstallPath'..."
    $vsCommunityInstallArgs = "--installPath `"$vsCommunityInstallPath`" --add $($vsCommunityWorkloads -join ' --add ') --includeRecommended --quiet --norestart --wait"
    try {
        Write-Log -Message "Executing with arguments: $vsCommunityInstallArgs"
        $process = Start-Process -FilePath $vsCommunityInstallerPath -ArgumentList $vsCommunityInstallArgs -Wait -PassThru -ErrorAction Stop
        Write-Log -Message "Installer process finished with Exit Code: $($process.ExitCode)."
        if ($process.ExitCode -ne 0) {
            throw "VS Community installer exited with code: $($process.ExitCode). Check installer logs in %TEMP%."
        }
        Write-Log -Message "Visual Studio Community installation completed successfully."
    }
    catch {
        throw "An error occurred during the VS Community installation. Error: $_"
    }

    # Install Build Tools
    Write-Log -Message "Installing Visual Studio Build Tools to '$buildToolsInstallPath'..."
    $buildToolsInstallArgs = "--installPath `"$buildToolsInstallPath`" --add $buildToolsWorkload --includeRecommended --quiet --norestart --wait"
    try {
        Write-Log -Message "Executing with arguments: $buildToolsInstallArgs"
        $process = Start-Process -FilePath $buildToolsInstallerPath -ArgumentList $buildToolsInstallArgs -Wait -PassThru -ErrorAction Stop
        Write-Log -Message "Installer process finished with Exit Code: $($process.ExitCode)."
        if ($process.ExitCode -ne 0) {
            throw "Build Tools installer exited with code: $($process.ExitCode). Check installer logs in %TEMP%."
        }
        Write-Log -Message "Build Tools installation completed successfully."
    }
    catch {
        throw "An error occurred during the Build Tools installation. Error: $_"
    }

    # --- Section 3: Locating Key Paths ---
    Write-Log -Message "--- Section 3: Locating Key Paths to Add ---"
    $pathsToAdd = [System.Collections.Generic.List[string]]@()

    # Locate MSVC Path from Build Tools
    try {
        $msvcRootPath = Join-Path -Path $buildToolsInstallPath -ChildPath "VC\Tools\MSVC"
        if (-not (Test-Path $msvcRootPath)) { throw "MSVC root directory not found in Build Tools path." }
        $latestVersionDir = Get-ChildItem -Path $msvcRootPath -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if (-not $latestVersionDir) { throw "Could not find any MSVC version directory inside '$msvcRootPath'." }
        $msvcBinPath = Join-Path -Path $latestVersionDir.FullName -ChildPath "bin\Hostx64\x64"
        if (-not (Test-Path $msvcBinPath)) { throw "The target MSVC bin directory does not exist: '$msvcBinPath'" }
        $pathsToAdd.Add($msvcBinPath)
        Write-Log -Message "Found MSVC path: $msvcBinPath"
    }
    catch {
        Write-Log -Message "Failed to locate the MSVC compiler path. Error: $_" -Level WARN
    }

    # Locate Visual Studio IDE Path
    try {
        $vsIdePath = Join-Path -Path $vsCommunityInstallPath -ChildPath "Common7\IDE"
        if (-not (Test-Path $vsIdePath)) { throw "Visual Studio IDE path not found at '$vsIdePath'." }
        $pathsToAdd.Add($vsIdePath)
        Write-Log -Message "Found VS IDE path: $vsIdePath"
    }
    catch {
        Write-Log -Message "Failed to locate the Visual Studio IDE path. Error: $_" -Level WARN
    }
    
    # Locate Windows SDK Path
    try {
        $sdkRootPath = "C:\Program Files (x86)\Windows Kits\10\bin"
        if (-not (Test-Path $sdkRootPath)) { throw "Windows SDK root directory not found at '$sdkRootPath'. It may not have been installed correctly by the C++ workload." }
        $latestSdkDir = Get-ChildItem -Path $sdkRootPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | Sort-Object Name -Descending | Select-Object -First 1
        if (-not $latestSdkDir) { throw "Could not find any valid Windows SDK version directory inside '$sdkRootPath'." }
        $sdkBinPath = Join-Path -Path $latestSdkDir.FullName -ChildPath "x64"
        if (-not (Test-Path (Join-Path $sdkBinPath "rc.exe"))) { throw "The target Windows SDK bin directory ('$sdkBinPath') does not exist or is missing rc.exe." }
        $pathsToAdd.Add($sdkBinPath)
        Write-Log -Message "Found Windows SDK path: $sdkBinPath"
    }
    catch {
        Write-Log -Message "Failed to locate the Windows SDK path. Error: $_" -Level WARN
    }

    # --- Section 4: Updating System PATH ---
    Write-Log -Message "--- Section 4: Updating System PATH Variable ---"
    if ($pathsToAdd.Count -eq 0) {
        Write-Log -Message "No new valid paths were found to add to the system PATH." -Level WARN
    }
    else {
        try {
            $currentSystemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            $pathArray = $currentSystemPath -split ';' | ForEach-Object { $_.TrimEnd('\') } | Where-Object { $_ }
            $finalPath = $pathArray

            foreach ($path in $pathsToAdd) {
                if ($pathArray -notcontains $path.TrimEnd('\')) {
                    $finalPath += $path
                    Write-Log -Message "Adding '$path' to PATH."
                } else {
                    Write-Log -Message "Path '$path' is already present in the system PATH."
                }
            }
            
            $newSystemPath = ($finalPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique) -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newSystemPath, "Machine")
            Write-Log -Message "System PATH variable updated successfully."
            Write-Log -Message "IMPORTANT: You must restart any open terminal windows or reboot your system for this change to take full effect."
        }
        catch {
            throw "Failed to update the system PATH variable. Error: $_"
        }
    }

    Write-Log -Message "--- All operations completed successfully! ---"
}
catch {
    Write-Log -Message "An unrecoverable error occurred. Script execution halted." -Level ERROR
    Write-Log -Message "Error details: $($_.Exception.Message)" -Level ERROR
    exit 1
}
finally {
    # This block will run whether the script succeeds or fails.
    Write-Host "`nA detailed log of this session has been saved to: $logFile"
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to exit..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
    }
}

