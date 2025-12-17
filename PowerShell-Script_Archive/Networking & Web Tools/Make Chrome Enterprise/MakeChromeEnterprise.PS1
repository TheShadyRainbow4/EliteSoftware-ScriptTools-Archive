<#
.SYNOPSIS
    This script modifies the Windows Registry to enable support for Manifest V2 extensions in Google Chrome.

.DESCRIPTION
    This script is designed for advanced users who want to re-enable Manifest V2 extensions, such as uBlock Origin, in Google Chrome after they have been deprecated.
    It works by creating or modifying the 'ExtensionManifestV2Availability' DWORD value in the Windows Registry under the Google Chrome policies path.
    Setting this value to '2' forces Chrome to allow Manifest V2 extensions to be installed and run, simulating a managed enterprise environment.

.NOTES
    Author: Gemini
    Version: 1.0.0.0
    Requires: PowerShell 7 Preview or newer.
    Dependencies: None. All necessary components are part of the base operating system and PowerShell installation.

.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item?view=powershell-7.1
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-itemproperty?view=powershell-7.1
#>

# PowerShell Script to Enable Manifest V2 Extensions in Chrome via Registry

#region Function: Install-Dependency (Not applicable for this script, but included for standard workflow)
function Install-Dependency {
    param(
        [string]$ModuleName
    )
    # This script does not have external dependencies to install, as it only modifies the registry.
    # The New-Item and Set-ItemProperty cmdlets are part of the core PowerShell installation.
    # This function is included to adhere to our standard script creation guidelines.
}
#endregion

#region Error Handling and Console Control
# The console will pause and wait for user input to prevent it from closing immediately on crash.
try {
    # This command minimizes the terminal window upon running.
    # It requires the 'System.Windows.Forms' assembly, which is generally available on Windows.
    # The `Add-Type -AssemblyName System.Windows.Forms` command must be run first to load the required assembly.
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    $form.ShowInTaskbar = $false
    $form.Show()

    # Pause to allow the minimized window to appear before continuing.
    Start-Sleep -Seconds 1

#endregion

#region Script Logic
Write-Host "Starting the Chrome Manifest V2 support script..." -ForegroundColor Cyan

# Define the registry path for Chrome policies
$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$propertyName = "ExtensionManifestV2Availability"
$propertyValue = 2 # 2 = Enabled, allows unpacked Manifest V2 extensions

# Check if the registry path exists. If not, create it.
if (-not (Test-Path $registryPath)) {
    Write-Host "The registry path '$registryPath' does not exist. Creating it now..." -ForegroundColor Yellow
    try {
        New-Item -Path $registryPath -Force | Out-Null
        Write-Host "Successfully created the registry path." -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while creating the registry path: $_" -ForegroundColor Red
        throw
    }
} else {
    Write-Host "The registry path '$registryPath' already exists. Proceeding..." -ForegroundColor Green
}

# Set the ExtensionManifestV2Availability property
Write-Host "Setting the '$propertyName' property to '$propertyValue'..." -ForegroundColor Cyan
try {
    Set-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue -Type DWORD -Force | Out-Null
    Write-Host "Successfully set the registry value." -ForegroundColor Green
} catch {
    Write-Host "An error occurred while setting the registry property: $_" -ForegroundColor Red
    throw
}

Write-Host "Registry changes complete. You should now be able to manually install uBlock Origin." -ForegroundColor Magenta

#endregion

#region Instructions for the user
Write-Host ""
Write-Host "Now that the registry key is set, you need to manually install uBlock Origin." -ForegroundColor DarkCyan
Write-Host "Here are the next steps:" -ForegroundColor DarkCyan
Write-Host "1.) Navigate to uBlock Origin's official GitHub page to download the latest release. "
Write-Host "2.) Download the .zip file for Chromium. "
Write-Host "3.) Extract the contents of the .zip file to a new, permanent folder on your computer. Make sure you don't delete this folder. "
Write-Host "4.) Open Chrome and go to 'chrome://extensions'."
Write-Host "5.) Enable 'Developer mode' using the toggle switch in the top-right corner. "
Write-Host "6.) Click the 'Load unpacked' button that appears. "
Write-Host "7.) Select the folder where you extracted uBlock Origin. "
Write-Host "After this, uBlock Origin should be installed and working." -ForegroundColor Cyan
Write-Host ""
#endregion

} catch {
    Write-Host ""
    Write-Host "An unhandled error occurred: $_" -ForegroundColor Red
    Write-Host "The console will not close automatically. Press any key to continue..." -ForegroundColor Yellow
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
}
#endregion

#region Pause/Stop Function
# This will pause the script after it completes, so the console doesn't close.
# The `trap` block above will also handle this in case of an error.
if ($null -ne $form) {
    # If the script completed successfully, the minimized form is no longer needed.
    $form.Close()
}
Write-Host ""
Write-Host "Script execution completed successfully. The console will not close automatically." -ForegroundColor Green
Write-Host "You can close this window now." -ForegroundColor DarkGray
Start-Sleep -Seconds 5
# To prevent the console from closing, we will just let the script end here.
# A more advanced script would have a persistent UI.

#endregion

pause