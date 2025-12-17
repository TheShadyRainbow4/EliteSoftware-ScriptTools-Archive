#requires -RunAsAdministrator

<#
.SYNOPSIS
    Performs a clean installation of the Windows Package Manager (winget) to resolve installation issues.
.DESCRIPTION
    This script addresses common winget errors, including the "depends on the application 'winget.exe' to be available"
    error seen in PowerShell profiles. It systematically uninstalls the existing App Installer package, downloads
    the latest official release from GitHub, and installs it. It also verifies that the necessary directory is in the
    user's PATH environment variable.

    This script must be run with Administrator privileges to ensure it has the necessary permissions to manage
    AppX packages.
.NOTES
    Author: Gemini
    Version: 1.0
#>

#================================================================================================
# ⚙️ Configuration
#================================================================================================

# The AppX package name for winget.
$packageName = "Microsoft.DesktopAppInstaller"

# The official, stable URL for the latest winget release bundle.
$wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

# The destination path for the downloaded installer.
$downloadPath = Join-Path -Path $env:TEMP -ChildPath "winget_latest.msixbundle"

#------------------------------------------------------------------------------------------------

#================================================================================================
# 🏁 Initial Checks
#================================================================================================

$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run with Administrator privileges. Please re-run from an elevated PowerShell terminal."
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to exit..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
    }
    exit 1
}

#------------------------------------------------------------------------------------------------

#================================================================================================
# 🚀 Main Script Execution
#================================================================================================
try {
    #--- 🗑️ Section 1: Uninstall Existing Package ---
    Write-Host "--- 🗑️ Attempting to uninstall existing WinGet package ---"
    try {
        $existingPackage = Get-AppxPackage -Name $packageName -AllUsers | Select-Object -First 1
        if ($existingPackage) {
            Write-Host "Found existing package: $($existingPackage.PackageFullName). Attempting removal..."
            Remove-AppxPackage -Package $existingPackage.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "Successfully removed the existing package."
        }
        else {
            Write-Host "No existing '$packageName' package found. Proceeding to installation."
        }
    }
    catch {
        Write-Warning "Could not remove the existing package. It might not be installed or an error occurred: $_"
        Write-Warning "Continuing with installation attempt regardless."
    }

    Write-Host "`n" # Newline for spacing

    #--- 📥 Section 2: Download Latest WinGet Installer ---
    Write-Host "--- 📥 Downloading the latest WinGet installer ---"
    try {
        Write-Host "Downloading from '$wingetUrl'..."
        Invoke-WebRequest -Uri $wingetUrl -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop
        Write-Host "Download complete. Installer saved to '$downloadPath'."
    }
    catch {
        Write-Error "Failed to download the WinGet installer. Please check your internet connection and the URL. Error: $_"
        throw "Download failed."
    }

    Write-Host "`n"

    #--- 🛠️ Section 3: Install New WinGet Package ---
    Write-Host "--- 🛠️ Installing the new WinGet package ---"
    try {
        Write-Host "Installing package..."
        Add-AppxPackage -Path $downloadPath -ErrorAction Stop
        Write-Host "Successfully installed the new WinGet package."
    }
    catch {
        Write-Error "Failed to install the new WinGet package. The package may be corrupt or another issue is preventing installation. Error: $_"
        throw "Installation failed."
    }

    Write-Host "`n"

    #---  PATH Verification ---
    Write-Host "--- PATH Verification ---"
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $windowsAppsPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\WindowsApps"

        if ($userPath -like "*$windowsAppsPath*") {
            Write-Host "WindowsApps directory is already in the user PATH variable."
        }
        else {
            Write-Host "Adding WindowsApps directory to the user PATH variable."
            $newPath = "$userPath;$windowsAppsPath"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "User PATH updated. You must restart PowerShell for this to take effect."
        }
    }
    catch {
        Write-Error "An error occurred while trying to verify or update the user PATH. Error: $_"
    }

    Write-Host "`n"
    Write-Host "WinGet repair process completed successfully!"
    Write-Host "IMPORTANT: Please CLOSE and RE-OPEN your PowerShell terminal for all changes to take effect."
}
catch {
    Write-Error "A critical error occurred. The script could not complete."
}
finally {
    # Clean up the downloaded installer
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
    }
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to exit..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
    }
}
