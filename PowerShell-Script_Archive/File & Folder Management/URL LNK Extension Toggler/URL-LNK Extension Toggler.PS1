<#
    .SYNOPSIS
    System Tray Utility to toggle .LNK and .URL extension visibility.
    
    .DESCRIPTION
    - Double-click tray icon: Toggle extensions.
    - Right-click: Context menu (Exit).
    - Icon Source: [ScriptRoot]\Resources\URL-LNK-Extension-Toggler.ICO
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. Robust Path Detection (Fixes your error) ---
# This logic determines if we are running as a script or a compiled EXE
# and sets $BaseDir to the actual location of the file you are running.

$currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()

if ($currentProcess.ProcessName -match "^(powershell|pwsh|powershell_ise)$") {
    # We are running as a raw .ps1 script in a PowerShell host
    if ($PSScriptRoot) {
        $BaseDir = $PSScriptRoot
    } else {
        # Fallback for older hosts or weird contexts
        $BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }
} else {
    # We are running as a compiled EXE (The process name is your EXE name)
    # This ensures we get the folder of the EXE, not the temp folder PS2EXE extracts to.
    $BaseDir = Split-Path -Parent $currentProcess.MainModule.FileName
}

# Define the relative path to the icon
$iconPath = Join-Path $BaseDir "Resources\URL-LNK-Extension-Toggler.ICO"

# --- 2. Native Methods for Explorer Refresh ---
$code = @"
    using System;
    using System.Runtime.InteropServices;
    public class NativeMethods {
        [DllImport("shell32.dll")]
        public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
    }
"@
Add-Type -TypeDefinition $code
$SHCNE_ASSOCCHANGED = 0x08000000
$SHCNF_IDLIST = 0x0000

# --- 3. Resource Loading ---
# Try to load the custom icon, fallback gracefully if missing so the app doesn't crash
try {
    if (Test-Path $iconPath) {
        $appIcon = New-Object System.Drawing.Icon($iconPath)
    } else {
        Write-Warning "Icon not found at: $iconPath"
        Write-Warning "Using system default icon."
        $appIcon = [System.Drawing.SystemIcons]::Application
    }
} catch {
    $appIcon = [System.Drawing.SystemIcons]::Application
}

# --- 4. The Logic ---
function Toggle-ShortcutExtensions {
    $paths = @(
        "Registry::HKEY_CLASSES_ROOT\lnkfile",
        "Registry::HKEY_CLASSES_ROOT\InternetShortcut"
    )
    
    # We check one key to decide the state for all
    $isHidden = Test-Path "Registry::HKEY_CLASSES_ROOT\lnkfile\NeverShowExt"

    foreach ($path in $paths) {
        if ($isHidden) {
            # Delete value to SHOW extension
            Remove-ItemProperty -Path $path -Name "NeverShowExt" -ErrorAction SilentlyContinue
        } else {
            # Add value to HIDE extension
            New-ItemProperty -Path $path -Name "NeverShowExt" -Value "" -PropertyType String -Force | Out-Null
        }
    }

    # Refresh Explorer Icons immediately
    [NativeMethods]::SHChangeNotify($SHCNE_ASSOCCHANGED, $SHCNF_IDLIST, [IntPtr]::Zero, [IntPtr]::Zero)
    
    # Balloon tip feedback
    $stateText = If ($isHidden) { "Shown" } Else { "Hidden" }
    $notifyIcon.BalloonTipTitle = "Extension Toggler"
    $notifyIcon.BalloonTipText = ".LNK and .URL extensions are now $stateText"
    $notifyIcon.ShowBalloonTip(1000)
}

# --- 5. UI Setup ---

# Create Context Menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuItemExit = $contextMenu.Items.Add("Exit")
$menuItemExit.Add_Click({
    # Cleanup before exit
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    if ($appIcon) { $appIcon.Dispose() }
    [System.Windows.Forms.Application]::Exit()
})

# Create Tray Icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "Extension Toggler"
$notifyIcon.Icon = $appIcon 
$notifyIcon.ContextMenuStrip = $contextMenu
$notifyIcon.Visible = $true

# Double Click Event
$notifyIcon.Add_MouseDoubleClick({
    Toggle-ShortcutExtensions
})

# --- 6. Execution Loop ---
# This keeps the process alive waiting for clicks
[System.Windows.Forms.Application]::Run()
