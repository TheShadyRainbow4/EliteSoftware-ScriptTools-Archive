<#
.SYNOPSIS
    Performs a full Windows Update component reset, unenrolls the device from the Windows Insider Program, 
    and hard-locks the system to Windows 11 23H2 for security updates only.

.DESCRIPTION
    This script is the definitive solution to conflicts, as it stops all related services, deletes downloaded 
    update files and the update history, resets the Insider registry key, and re-applies the feature update lock.

.NOTES
    Project Name: Advanced PowerShell Concepts - Update & Insider Reset - v3.0.0.0
    Created by: Zachary Whiteman & Google Gemini Ai. [2025-10-18] - [19:20:15]
    Target OS Version: Windows 11, version 23H2 (Security Updates Only)
    Configuration Path: C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftwareCorp\UpdateInsiderReset
#>
#region Initialization and Console Setup

# Minimize the console window upon running
$host.UI.RawUI.WindowTitle = "Update & Insider Reset - Running Deep Clean..."
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@ -PassThru | Out-Null
    
    $Hwnd = (Get-Process -Id $PID).MainWindowHandle
    if ($Hwnd -ne 0) {
        $SW_MINIMIZE = 6
        [Win32]::ShowWindow($Hwnd, $SW_MINIMIZE) | Out-Null
    }
}
catch {
    Write-Warning "Could not minimize console window."
}

#endregion Initialization and Console Setup

#region Configuration Variables
$FeatureLockKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$InsiderKeyPath = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost"
$ConfigSubFolder = "UpdateInsiderReset"
$ConfigPath = "C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftwareCorp\$ConfigSubFolder"
$TargetVersion = "23H2"
$ProductVersion = "Windows 11"
$UpdateServices = @("wuauserv", "bits", "dosvc", "cryptsvc") # Windows Update, BITS, Delivery Optimization, Cryptographic Services
#endregion Configuration Variables

#region Function Definitions

function Invoke-InsiderUnenrollment
{
    Write-Host "`n--- Phase 1: Unenrolling from Windows Insider Program ---" -ForegroundColor Cyan
    
    try {
        # The ultimate Insider unenrollment is to delete the entire WindowsSelfHost key
        # This key holds all enrollment and flighting data. Deleting it forces a full reset.
        if (Test-Path -Path $InsiderKeyPath) {
            Write-Host "Deleting WindowsSelfHost Registry Key to unenroll..." -ForegroundColor Yellow
            Remove-Item -Path $InsiderKeyPath -Recurse -Force
        }
        
        # Additionally, remove any remaining Windows Update for Business Insider settings (from previous v2 script)
        $InsiderDataKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        Write-Host "Removing DataCollection Insider flags..." -ForegroundColor Yellow
        Remove-ItemProperty -Path $InsiderDataKey -Name "AllowTelemetry" -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-ItemProperty -Path $InsiderDataKey -Name "AllowExperimentation" -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Host "Insider Enrollment reset complete." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to unenroll from Insider Program: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-UpdateReset
{
    Write-Host "`n--- Phase 2: Windows Update Component Reset and Deletion ---" -ForegroundColor Cyan
    
    try {
        # 1.) Stop all related update services
        Write-Host "Stopping Windows Update services..." -ForegroundColor Yellow
        Get-Service -Name $UpdateServices | Stop-Service -Force -ErrorAction Stop
        
        # 2.) Rename SoftwareDistribution folder (deletes downloaded updates and history)
        # We rename instead of delete to follow the legacy, safe approach of the ultimate tinkerer!
        $SoftwareDistribution = "$env:SystemRoot\SoftwareDistribution"
        $CatRoot2 = "$env:SystemRoot\System32\catroot2"
        
        if (Test-Path $SoftwareDistribution) {
            Write-Host "Renaming SoftwareDistribution (deleting downloaded updates)..." -ForegroundColor Yellow
            Rename-Item -Path $SoftwareDistribution -NewName "SoftwareDistribution.bak" -Force
        }
        if (Test-Path $CatRoot2) {
            Write-Host "Renaming catroot2 (clearing Windows Update catalog cache)..." -ForegroundColor Yellow
            Rename-Item -Path $CatRoot2 -NewName "catroot2.bak" -Force
        }

        # 3.) Clear BITS queue files (Background Intelligent Transfer Service)
        Write-Host "Deleting BITS transfer logs (qmgr*.dat)..." -ForegroundColor Yellow
        Get-ChildItem -Path "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader" -Include "qmgr*.dat" -Force | Remove-Item -Force -ErrorAction SilentlyContinue

        # 4.) Start services again
        Write-Host "Starting Windows Update services..." -ForegroundColor Yellow
        Get-Service -Name $UpdateServices | Start-Service -ErrorAction Stop

        Write-Host "Update Component Reset complete. All downloaded updates are gone." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to reset Windows Update components: $($_.Exception.Message)"
        # Attempt to restart services on failure to prevent system instability
        Write-Warning "Attempting to restart services now..."
        $UpdateServices | ForEach-Object { Start-Service -Name $_ -ErrorAction SilentlyContinue } | Out-Null
        return $false
    }
}

function Invoke-SecurityUpdateLock
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,

        [Parameter(Mandatory=$true)]
        [string]$TargetVersionInfo,

        [Parameter(Mandatory=$true)]
        [string]$ProductVersion
    )

    Write-Host "`n--- Phase 3: Hard-Locking to 23H2 (Security Updates Only) ---" -ForegroundColor Cyan

    try {
        # 1.) Enable the Feature Update Target Lock (v2.0.0.0 fix)
        Write-Host "Applying Target Release Lock to $TargetVersionInfo..." -ForegroundColor Yellow
        if (-not (Test-Path -Path $KeyPath)) { $null = New-Item -Path $KeyPath -Force }
        Set-ItemProperty -Path $KeyPath -Name "TargetReleaseVersion" -Type DWord -Value 1 -Force | Out-Null
        Set-ItemProperty -Path $KeyPath -Name "TargetReleaseVersionInfo" -Type String -Value $TargetVersionInfo -Force | Out-Null
        Set-ItemProperty -Path $KeyPath -Name "ProductVersion" -Type String -Value $ProductVersion -Force | Out-Null

        # 2.) Ensure only required updates are fetched (i.e., NO OPTIONAL FEATURES)
        # Setting AutoUpdate to 3 = Auto download and notify for install (This allows security patches)
        # We need to make sure we don't accidentally enable the 'Optional' update feature which could pull enablement packages.
        Set-ItemProperty -Path "$KeyPath\AU" -Name "AUOptions" -Type DWord -Value 3 -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-ItemProperty -Path $KeyPath -Name "AllowOptionalUpdates" -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-ItemProperty -Path $KeyPath -Name "DisableOSUpgrade" -Force -ErrorAction SilentlyContinue | Out-Null
        
        # 3.) Force Group Policy Update
        Write-Host "Forcing Group Policy update (gpupdate /force)..." -ForegroundColor Magenta
        gpupdate /force | Out-Null

        Write-Host "Hard-Lock to $TargetVersionInfo (Security Only) applied successfully." -ForegroundColor Green
        return $true

    }
    catch {
        Write-Error "Catastrophic error during Hard-Lock application: $($_.Exception.Message)"
        return $false
    }
}

#endregion Function Definitions

#region Main Script Execution

Write-Host "Ultimate Windows Update & Insider Reset (v3.0.0.0)" -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta

# Create the EliteSoftwareCorp configuration directory
try {
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Host "Creating configuration directory: $ConfigPath" -ForegroundColor DarkCyan
        $null = New-Item -Path $ConfigPath -ItemType Directory -Force
    }
}
catch {
    Write-Warning "Could not create configuration directory."
}

# --- Action Sequence ---
$Success = $true
$Success = $Success -and (Invoke-InsiderUnenrollment)
$Success = $Success -and (Invoke-UpdateReset)
$Success = $Success -and (Invoke-SecurityUpdateLock -KeyPath $FeatureLockKeyPath -TargetVersionInfo $TargetVersion -ProductVersion $ProductVersion)


# Final Check and Stop
if ($Success) {
    Write-Host "`nAll phases completed. The system is unrolled, cleaned, and locked." -ForegroundColor Green
    Write-Host "You must REBOOT the system to clear the in-memory service status and complete the changes." -ForegroundColor Red
}
else {
    Write-Error "`nOne or more phases failed. Review the error messages and REBOOT to ensure stability."
}

# Implement the stop function to keep the console open
Write-Host "`n==========================================================" -ForegroundColor Magenta
Write-Host "Script finished. Press any key to close this console." -ForegroundColor Yellow
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeypress") | Out-Null

#endregion Main Script Execution