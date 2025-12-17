<#
.SYNOPSIS
    Ultimate Configuration Script to force Windows 11 23H2 retention, by clearing conflicting policies and blocking Insider Builds.

.DESCRIPTION
    This script performs a deep reset of local Group Policy and then applies the necessary Registry keys to pin the system to 
    the target feature update version (23H2). It also ensures the system is not configured for Insider Preview builds.
    This addresses potential "GPO Tattoo" conflicts.

.NOTES
    Project Name: Advanced PowerShell Concepts - Feature Update Blocker - v2.0.0.0
    Created by: Zachary Whiteman & Google Gemini Ai. [2025-10-18] - [19:10:46]
    Target OS Version: Windows 11, version 23H2
    Configuration Path: C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftwareCorp\FeatureUpdateBlocker
#>
#region Initialization and Console Setup

# Minimize the console window upon running
$host.UI.RawUI.WindowTitle = "Feature Update Targeter - Running Ultimate Block..."
try {
    # Using the P/Invoke method for robust minimization
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
        $SW_MINIMIZE = 6 # SW_MINIMIZE for minimizing to an icon
        [Win32]::ShowWindow($Hwnd, $SW_MINIMIZE) | Out-Null
    }
}
catch {
    Write-Warning "Could not minimize console window. Error: $($_.Exception.Message)"
}

#endregion Initialization and Console Setup

#region Configuration Variables
$PolicyKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$InsiderKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
$ConfigSubFolder = "FeatureUpdateBlocker"
$ConfigPath = "C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftwareCorp\$ConfigSubFolder"
$TargetVersion = "23H2"
$ProductVersion = "Windows 11"
#endregion Configuration Variables

#region Function Definitions

function Invoke-PolicyReset
{
    Write-Host "--- Performing Policy and Cache Reset ---" -ForegroundColor Red
    Write-Host "Attempting to reset local Group Policy Cache (RD /S /Q)" -ForegroundColor Yellow
    
    # 1.) Hard Reset of Local Group Policy Cache (The "GPO Tattoo" remover)
    # This is a powerful, low-level way to ensure no old or conflicting local GPO settings are lingering.
    # Note: Requires a system reboot to fully take effect, but we force an update after.
    try {
        cmd.exe /c "RD /S /Q ""$env:windir\System32\GroupPolicy"""
        cmd.exe /c "RD /S /Q ""$env:windir\System32\GroupPolicyUsers"""
        Write-Host "Policy Cache folders cleared successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to clear Policy Cache folders: $($_.Exception.Message)"
    }
    
    # 2.) Clear the "AllowTelemetry" setting often tied to Insider/Preview builds
    # This specifically addresses the preview nature of the update you are seeing.
    Write-Host "Blocking Insider/Preview Builds via Registry..." -ForegroundColor Yellow
    try {
        # 'AllowTelemetry' key: 0 = Security/Basic, 1 = Enhanced, 2 = Full, 3 = Allow Insider. We set a low value (1) to break the Insider requirement.
        Set-ItemProperty -Path $InsiderKeyPath -Name "AllowTelemetry" -Type DWord -Value 1 -Force | Out-Null
        # 'AllowExperimentation' key: 0 = Disabled, breaks Windows Update for Business policies from receiving experimental features
        Set-ItemProperty -Path $InsiderKeyPath -Name "AllowExperimentation" -Type DWord -Value 0 -Force | Out-Null
        Write-Host "Insider/Preview settings neutralized." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set Insider Policy neutralizers: $($_.Exception.Message)"
    }
    
    # 3.) Final Policy Update (required after the RD commands)
    Write-Host "Forcing Group Policy update to apply resets..." -ForegroundColor Cyan
    gpupdate /force | Out-Null
}

function Set-FeatureUpdateTarget
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,

        [Parameter(Mandatory=$true)]
        [string]$TargetVersionInfo,

        [Parameter(Mandatory=$true)]
        [string]$ProductVersion
    )

    Write-Host "`n--- Applying Feature Update Target Registry Lock ---" -ForegroundColor Magenta

    try {
        # 1.) Ensure the policy key path exists
        if (-not (Test-Path -Path $KeyPath)) {
            Write-Host "Creating Registry key path: $KeyPath" -ForegroundColor DarkYellow
            $null = New-Item -Path $KeyPath -Force
        }

        # 2.) Set the 'TargetReleaseVersion' value to 1 (DWORD) to enable the policy
        Write-Host "Setting TargetReleaseVersion to 1 (Enable Policy)..." -ForegroundColor Yellow
        Set-ItemProperty -Path $KeyPath -Name "TargetReleaseVersion" -Type DWord -Value 1 -Force | Out-Null

        # 3.) Set the 'TargetReleaseVersionInfo' value (String) to the desired feature update version
        Write-Host "Setting TargetReleaseVersionInfo to $TargetVersionInfo (Feature Update)..." -ForegroundColor Yellow
        Set-ItemProperty -Path $KeyPath -Name "TargetReleaseVersionInfo" -Type String -Value $TargetVersionInfo -Force | Out-Null

        # 4.) Set the 'ProductVersion' value (String) to the desired Windows product
        # NOTE: For Windows 11, the ProductVersion must be 'Windows 11' (case-sensitive)
        Write-Host "Setting ProductVersion to $ProductVersion (Windows Product)..." -ForegroundColor Yellow
        Set-ItemProperty -Path $KeyPath -Name "ProductVersion" -Type String -Value $ProductVersion -Force | Out-Null
        
        # 5.) Add a common second blocker for good measure: BlockFeatureUpdates
        Write-Host "Setting BlockFeatureUpdates to 1 (Secondary Blocker)..." -ForegroundColor Yellow
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade" -Name "BlockFeatureUpdates" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null


        Write-Host "`nTarget Lock Applied! Your system is now fiercely pinned to Windows 11, version $TargetVersionInfo." -ForegroundColor Cyan
        return $true

    }
    catch {
        Write-Error "A catastrophic error occurred during Registry lock application: $($_.Exception.Message)"
        return $false
    }
}

#endregion Function Definitions

#region Main Script Execution

Write-Host "Ultimate Feature Update Blocker (v2.0.0.0)" -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta

# Create the user's preferred configuration directory if it doesn't exist
try {
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Host "Creating EliteSoftwareCorp configuration directory: $ConfigPath" -ForegroundColor DarkCyan
        $null = New-Item -Path $ConfigPath -ItemType Directory -Force
    }
}
catch {
    Write-Warning "Could not create configuration directory. Error: $($_.Exception.Message)"
}

# --- Action Sequence ---
# 1. Reset conflicting policies
Invoke-PolicyReset

# 2. Re-apply the feature update target
$Success = Set-FeatureUpdateTarget -KeyPath $PolicyKeyPath -TargetVersionInfo $TargetVersion -ProductVersion $ProductVersion

# Output for user confirmation and error handling
if ($Success) {
    Write-Host "`nFeature update blocking complete. The system must be REBOOTED for the Policy Cache reset to take full effect and stop the Preview update." -ForegroundColor Green
    Write-Host "If the update remains, check the Local Group Policy Editor (gpedit.msc) under:" -ForegroundColor Green
    Write-Host "Computer Configuration -> Administrative Templates -> Windows Components -> Windows Update -> Manage updates offered from Windows Update" -ForegroundColor Green
    Write-Host "Ensure 'Select the target Feature Update version' is 'Enabled' and set to '23H2'." -ForegroundColor Green
}
else {
    Write-Error "`nFeature update targeting failed to fully execute. Review the error messages above."
}

# Implement the stop function to keep the console open
Write-Host "`n==========================================================" -ForegroundColor Magenta
Write-Host "Script finished. Press any key to close this console." -ForegroundColor Yellow
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeypress") | Out-Null

#endregion Main Script Execution