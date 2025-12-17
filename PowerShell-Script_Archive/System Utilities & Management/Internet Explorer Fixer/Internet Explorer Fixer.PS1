# Requires Administrator privileges (or TrustedInstaller)

# --- GLOBAL CONTROL FLAG ---
$Canceled = $false

# --- CONFIGURATION ---
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDirectory = Join-Path -Path $ScriptDirectory -ChildPath "IE_Modular_Backup_$Timestamp"

# Keys to be DELETED/MODIFIED (used for both backup and action)
$EdgeBHOCLSIDs = @(
    "{92755D85-2268-466D-B029-A7F2D875F616}",
    "{B164E343-AA7F-4554-949B-5105EE397669}"
)
$BHORegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects"
)
$ComponentRegPath = "HKCR:\CLSID"
$PolicyPathsToModify = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Edge",
    "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_USE_IE_STANDARDS_MODE",
    "HKLM:\SOFTWARE\Microsoft\Internet Explorer\AdvancedOptions\CRYPTO\TLS12"
)

# --- HELPER FUNCTIONS ---

# Function to pause and check for cancellation, setting the global flag
function Pause-And-Check-Cancellation {
    param(
        [Parameter(Mandatory=$true)][string]$Message
    )
    # Only pause if the script hasn't been canceled yet
    if (-not $script:Canceled) {
        Write-Host ""
        Write-Host ">>> CHECKPOINT: $Message" -ForegroundColor Yellow
        $Input = Read-Host "Press ENTER to continue, or type 'C' to Cancel the script."
        if ($Input -imatch '^c') {
            Write-Host "Cancellation requested. Setting exit flag." -ForegroundColor Red
            $script:Canceled = $true
        }
    }
}

# Function to backup keys to individual .reg files
function Backup-RegistryKeys {
    param(
        [Parameter(Mandatory=$true)][string]$BackupFolderPath
    )
    Write-Host "---"
    Write-Host "Initiating Modular Registry Backup to $BackupFolderPath" -ForegroundColor Yellow

    New-Item -Path $BackupFolderPath -ItemType Directory -Force | Out-Null

    $KeysToBackup = @()
    foreach ($CLSID in $EdgeBHOCLSIDs) {
        $KeysToBackup += ($BHORegPaths | ForEach-Object { Join-Path $_ $CLSID })
        $KeysToBackup += Join-Path $ComponentRegPath $CLSID
    }
    $KeysToBackup += $PolicyPathsToModify

    $ExportedKeys = 0
    $KeysToBackup | ForEach-Object {
        $KeyPath = $_
        $RegExePath = $KeyPath.Replace(":", "").Replace("\", "\")
        $FileName = ($RegExePath -split '\\')[-1] + "_backup.reg"
        $BackupFilePath = Join-Path $BackupFolderPath $FileName
        
        if (Test-Path $KeyPath) {
            Write-Host "  - Backing up: $FileName" -ForegroundColor DarkGray
            reg export $RegExePath $BackupFilePath /reg:64 /y | Out-Null
            $ExportedKeys++
        }
    }

    if ($ExportedKeys -gt 0) {
        Write-Host "SUCCESS: $ExportedKeys unique Registry keys backed up individually to $BackupFolderPath." -ForegroundColor Green
    } else {
        Write-Host "WARNING: No existing keys found to back up. Continue with caution." -ForegroundColor DarkYellow
    }
    Write-Host "---"
}

# --- MAIN EXECUTION BLOCK ---

# Use a trap to ensure execution is clean upon termination (though the Read-Host is the main keeper)
trap {
    Write-Host "`nAn unexpected error occurred. Review output and press ENTER to close." -ForegroundColor Red
    break # Exits the trap and continues execution after the main block
}

try {
    # 1. PERFORM BACKUP
    Backup-RegistryKeys -BackupFolderPath $BackupDirectory

    # Checkpoint 1: Before Registry Deletion
    Pause-And-Check-Cancellation -Message "Backup Complete. Start Registry Deletion (BHO Removal)?"
    if ($Canceled) { throw "Cancelled at Checkpoint 1" }


    # 2. EXECUTION: BHO Removal (Deletion)
    Write-Host "`nStarting comprehensive removal of IE to Edge BHO keys (DELETION phase)..." -ForegroundColor Yellow
    foreach ($CLSID in $EdgeBHOCLSIDs) {
        Write-Host "Processing CLSID: $CLSID" -ForegroundColor Cyan
        # 1. Remove from Browser Helper Objects Paths
        foreach ($BHOPath in $BHORegPaths) {
            $FullBHOPath = Join-Path $BHOPath $CLSID
            if (Test-Path $FullBHOPath) {
                Remove-Item -Path $FullBHOPath -Force -Recurse
            }
        }
        # 2. Remove from the Component Definition Path (CLSID root)
        $FullComponentPath = Join-Path $ComponentRegPath $CLSID
        if (Test-Path $FullComponentPath) {
            Remove-Item -Path $FullComponentPath -Force -Recurse
        }
    }
    Write-Host "Edge BHO Removal Complete." -ForegroundColor Green


    # Checkpoint 2: Before GPO Modification
    Pause-And-Check-Cancellation -Message "Deletion Phase Complete. Start Registry Modification (GPO Enforcement)?"
    if ($Canceled) { throw "Cancelled at Checkpoint 2" }


    # 3. EXECUTION: Group Policy Enforcement (Modification)
    Write-Host "`nStarting Group Policy Enforcement for IE 11 Stability (MODIFICATION phase)..." -ForegroundColor Yellow

    $EdgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    $CompViewPath = "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_USE_IE_STANDARDS_MODE"
    $TLSPath = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\AdvancedOptions\CRYPTO\TLS12"

    # 1. Edge Redirection Policies
    New-Item -Path $EdgePolicyPath -Force | Out-Null
    Set-ItemProperty -Path $EdgePolicyPath -Name "RedirectSitesFromInternetExplorerRedirectMode" -Type DWORD -Value 0 -Force
    Set-ItemProperty -Path $EdgePolicyPath -Name "RedirectSitesFromInternetExplorerPreventBHOInstall" -Type DWORD -Value 1 -Force
    Set-ItemProperty -Path $EdgePolicyPath -Name "HideInternetExplorerRedirectUXForIncompatibleSitesEnabled" -Type DWORD -Value 1 -Force

    # 2. Compatibility View Policy
    New-Item -Path $CompViewPath -Force | Out-Null
    Set-ItemProperty -Path $CompViewPath -Name "iexplore.exe" -Type DWORD -Value 0 -Force

    # 3. Force TLS 1.2
    New-Item -Path $TLSPath -Force | Out-Null
    Set-ItemProperty -Path $TLSPath -Name "Enabled" -Type DWORD -Value 1 -Force

    Write-Host "`nGroup Policy Enforcement Complete." -ForegroundColor Green


    # Checkpoint 3: Final Confirmation
    Pause-And-Check-Cancellation -Message "All Registry operations finished. Confirm exit and perform system restart?"
    # If cancelled here, we still want to show the final instructions, so we don't throw an error.

}
catch {
    # Catches the 'throw' command used for clean user-initiated cancellation
    if ($_.Exception.Message -like "Cancelled*") {
        Write-Host "`n--- SCRIPT STOPPED BY USER ---" -ForegroundColor Red
        Write-Host "Review the log above to see what changes were successfully completed." -ForegroundColor Red
        # The script flow will continue to the finally block and then the final Read-Host
    }
    else {
        # Handle actual errors
        Write-Host "`n--- CRITICAL ERROR ---" -ForegroundColor Red
        Write-Host "An unexpected error stopped the script: $($_.Exception.Message)" -ForegroundColor Red
    }
}
finally {
    # This block executes regardless of success or failure (including user cancellation)

    # --- FINAL INSTRUCTIONS ---
    Write-Host "--------------------------------------------------------------------------------"
    if ($Canceled) {
        Write-Host "SCRIPT HALTED. FINAL LOG REVIEW:" -ForegroundColor Yellow
    } else {
        Write-Host "IE Configuration Complete. Please perform final actions." -ForegroundColor Red
    }
    
    Write-Host "1. Run 'gpupdate /force' in an elevated window."
    Write-Host "2. Restart your computer immediately to finalize changes."
    Write-Host "`nYour modular backup folder is located at: $BackupDirectory" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------------------"
    
    # This is the key: keeps the window open until the user manually closes it.
    Read-Host "Press ENTER to close this console window." | Out-Null
}