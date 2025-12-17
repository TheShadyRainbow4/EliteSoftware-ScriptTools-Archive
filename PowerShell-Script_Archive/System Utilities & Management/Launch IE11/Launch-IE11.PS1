<#
.SYNOPSIS
    Forces the Internet Explorer 11 UI to open on Windows 11.

.DESCRIPTION
    This script bypasses the default redirection of iexplore.exe to Microsoft Edge
    by directly creating an instance of the Internet Explorer COM object.
    This allows the full Internet Explorer 11 user interface to launch.

.NOTES
    Author: Gemini (Your helpful artificial intelligence assistant)
    Date: 2025-06-20
    Version: 1.0

    IMPORTANT:
    1. PowerShell Execution Policy: You might need to adjust your PowerShell
       execution policy to run this script. Open PowerShell as administrator
       and run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
       (or Bypass if you're comfortable, but RemoteSigned is generally sufficient).
    2. Internet Explorer 11 is deprecated and unsupported. Using it may expose
       you to security risks. This script is intended for experimental,
       tinkering, or compatibility purposes only.
    3. The browser will open to a blank page by default. You can navigate from there.

.EXAMPLE
    To run the script:
    1. Save the code below as a .ps1 file (e.g., Force-IE11.ps1).
    2. Open PowerShell.
    3. Navigate to the directory where you saved the file.
    4. Run: .\Force-IE11.ps1

.EXAMPLE
    To open IE11 to a specific URL:
    1. Modify the '$urlToOpen' variable in the script to your desired URL.
    2. Run the script as shown above.
#>

# Define the URL to open (optional, defaults to about:blank if not specified)
# You can change this to any website you want IE11 to open initially.
$urlToOpen = "about:blank" # Example: "https://www.google.com"

Write-Host "Attempting to launch Internet Explorer 11 UI..."

try {
    # Create a new instance of the Internet Explorer Application COM object.
    # This is the key to bypassing the Edge redirection, as it directly accesses
    # the IE components rather than running the iexplore.exe stub.
    $ie = New-Object -ComObject "InternetExplorer.Application"

    # Make the Internet Explorer window visible.
    # If this is set to $false, IE will run in the background without a visible UI.
    $ie.Visible = $true

    # Navigate to the specified URL.
    # The 0 indicates no flags for navigation (e.g., not opening in new window).
    $ie.Navigate2($urlToOpen, 0)

    Write-Host "Internet Explorer 11 UI launched successfully!"
    Write-Host "Please note: Internet Explorer is no longer supported and may have security vulnerabilities."

} catch {
    Write-Error "Failed to launch Internet Explorer 11 UI."
    Write-Error "Error details: $($_.Exception.Message)"
    Write-Host "Possible reasons:"
    Write-Host " - Internet Explorer 11 components might be too heavily disabled or removed on your system."
    Write-Host " - PowerShell Execution Policy might be preventing the script from running."
    Write-Host " - An unexpected system error occurred."
}

