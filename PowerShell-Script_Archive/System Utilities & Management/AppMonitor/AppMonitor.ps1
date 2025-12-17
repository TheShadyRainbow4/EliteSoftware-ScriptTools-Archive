<#
    .SYNOPSIS
    The "Keep It Alive" Monitor (Frutiger Aero Edition)
    
    .DESCRIPTION
    Monitors legacy apps. Resurrects them if dead > 120s.
    
    Tray Icon Priority:
      1. ICON3.ICO (Alert) : Serious Error (File missing / Launch failed) or GLOBAL PAUSE
      2. ICON2.ICO (Red)   : Active / Launching
      3. ICON.ICO  (Green) : Idle / Monitoring
      
    Features:
      - Startup "Self-Test" Animation (Green-Red-Yellow x6)
      - Auto-Resurrection
      - Manual "Force Check" via Tray
      - Global Pause/Resume
      - INDIVIDUAL App Toggles (Submenu)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- ⚙️ CONFIGURATION ⚙️ ---
$MonitoredApps = @(
    @{ Name = "Textify"; Path = "E:\Users\Zachary Whiteman\AppData\Local\Programs\Textify\Textify.exe" },
    @{ Name = "windhawk"; Path = "C:\Program Files\Windhawk\windhawk.exe" },
    @{ Name = "WBSrv"; Path = "C:\Program Files (x86)\Stardock\WindowBlinds\WBSrv.exe" },
    @{ Name = "ActualWindowManagerCenter64"; Path = "C:\Program Files (x86)\Actual Window Manager\ActualWindowManagerCenter64.exe" },
    @{ Name = "PowerToys"; Path = "C:\Users\zwhiteman\AppData\Local\PowerToys\PowerToys.exe" },
    @{ Name = "Everything"; Path = "C:\Program Files\Everything\Everything.exe" }
)

$GracePeriodSeconds = 120
$LoopIntervalSeconds = 5

# --- 📂 PATH SETUP 📂 ---
$ScriptPath = $PSScriptRoot
if (-not $ScriptPath) { $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path }

# --- 🎨 ICON SETUP 🎨 ---
$IconPathGreen = Join-Path $ScriptPath "ICON.ICO"
$IconPathRed   = Join-Path $ScriptPath "ICON2.ICO"
$IconPathAlert = Join-Path $ScriptPath "ICON3.ICO"

function Get-IconSafe ($path) {
    if (Test-Path $path) { return New-Object System.Drawing.Icon($path) }
    return [System.Drawing.SystemIcons]::Application
}

$IconGreen = Get-IconSafe $IconPathGreen
$IconRed   = Get-IconSafe $IconPathRed
$IconAlert = Get-IconSafe $IconPathAlert

# --- ⏱️ STATE INITIALIZATION ⏱️ ---
$AppState = @{}
$script:AppMonitorState = @{} 
$script:Now = Get-Date

foreach ($app in $MonitoredApps) {
    $AppState[$app.Name] = $script:Now
    $script:AppMonitorState[$app.Name] = $true 
}

$script:LastLoopTime  = $script:Now
$script:RedLightUntil = $script:Now
$script:ErrorUntil    = $script:Now
$script:CurrentErrorMsg = ""
$script:IsGlobalPaused = $false

# --- 🖼️ TRAY UI SETUP 🖼️ ---
$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$NotifyIcon.Text = "App Monitor: Initializing..."
$NotifyIcon.Icon = $IconGreen
$NotifyIcon.Visible = $true

$ContextMenu = New-Object System.Windows.Forms.ContextMenuStrip

# 1. Force Check Item
$ForceCheckItem = $ContextMenu.Items.Add("Force Check Now")
$ForceCheckItem.Add_Click({
    $script:LastLoopTime = $script:Now.AddMinutes(-10)
    $NotifyIcon.BalloonTipTitle = "Manual Check"
    $NotifyIcon.BalloonTipText = "Scanning processes..."
    $NotifyIcon.ShowBalloonTip(1000)
})

$ContextMenu.Items.Add("-") | Out-Null

# 2. Manage Apps Submenu
$ManageMenu = $ContextMenu.Items.Add("Manage Apps")
foreach ($app in $MonitoredApps) {
    $subItem = $ManageMenu.DropDownItems.Add($app.Name)
    $subItem.Checked = $true
    $subItem.CheckOnClick = $true
    $subItem.Add_Click({
        $script:AppMonitorState[$this.Text] = $this.Checked
    })
}

$ContextMenu.Items.Add("-") | Out-Null

# 3. Global Pause Toggle
$PauseItem = $ContextMenu.Items.Add("Pause All Monitoring")
$PauseItem.CheckOnClick = $true
$PauseItem.Add_Click({
    $script:IsGlobalPaused = $PauseItem.Checked
    if ($script:IsGlobalPaused) {
        $NotifyIcon.Text = "App Monitor: ⏸ PAUSED"
    } else {
        $NotifyIcon.Text = "App Monitor: Active"
        $script:LastLoopTime = $script:Now.AddMinutes(-10) 
    }
})

$ContextMenu.Items.Add("-") | Out-Null

# 4. Exit
$ExitMenuItem = $ContextMenu.Items.Add("Exit")
$ExitMenuItem.Add_Click({
    $NotifyIcon.Visible = $false
    $NotifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

$NotifyIcon.ContextMenuStrip = $ContextMenu

# --- 🚦 STARTUP SEQUENCE (Self-Test Animation) 🚦 ---
Write-Host "Initiating Startup Sequence..." -ForegroundColor Cyan

# UPDATED: Loop increased to 6 times
for ($i = 1; $i -le 6; $i++) {
    # 1. Green
    $NotifyIcon.Icon = $IconGreen
    [System.Windows.Forms.Application]::DoEvents() # Force UI Repaint
    Start-Sleep -Milliseconds 150

    # 2. Red
    $NotifyIcon.Icon = $IconRed
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 150

    # 3. Alert (Yellow)
    $NotifyIcon.Icon = $IconAlert
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 150
}
# Settle on Green
$NotifyIcon.Icon = $IconGreen
$NotifyIcon.Text = "App Monitor: Idle"
[System.Windows.Forms.Application]::DoEvents()

Write-Host "Monitor started. Backgrounding..." -ForegroundColor Cyan

# --- 🔄 MAIN LOOP 🔄 ---
$Running = $true
while ($Running) {
    $script:Now = Get-Date
    
    if (-not $script:IsGlobalPaused) {
        foreach ($app in $MonitoredApps) {
            $ProcessName = $app.Name
            
            if (-not $script:AppMonitorState[$ProcessName]) { continue }

            $ExePath = $app.Path
            $Proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

            if ($Proc) {
                $AppState[$ProcessName] = $script:Now
            } else {
                $LastSeen = $AppState[$ProcessName]
                $TimeDead = ($script:Now - $LastSeen).TotalSeconds
                
                if ($TimeDead -gt $GracePeriodSeconds) {
                    $script:RedLightUntil = $script:Now.AddSeconds(5)

                    if (Test-Path $ExePath) {
                        try {
                            Write-Host "⚠️ Launching $ProcessName..." -ForegroundColor Yellow
                            Start-Process -FilePath $ExePath -WorkingDirectory (Split-Path $ExePath) -ErrorAction Stop
                            
                            $AppState[$ProcessName] = $script:Now 
                            
                            $NotifyIcon.BalloonTipTitle = "Resurrected App"
                            $NotifyIcon.BalloonTipText = "$ProcessName was relaunched."
                            $NotifyIcon.ShowBalloonTip(3000)
                        } catch {
                            Write-Host "❌ Failed to launch $ProcessName : $_" -ForegroundColor Red
                            $script:ErrorUntil = $script:Now.AddSeconds(10)
                            $script:CurrentErrorMsg = "Error: Failed to launch $ProcessName"
                        }
                    } else {
                        Write-Host "❌ Critical: Missing $ExePath" -ForegroundColor Red
                        $script:ErrorUntil = $script:Now.AddSeconds(5)
                        $script:CurrentErrorMsg = "Error: Missing $ProcessName"
                    }
                }
            }
        }
    }

    # --- 🚥 ICON STATE LOGIC 🚥 ---
    if ($script:IsGlobalPaused) {
        if ($NotifyIcon.Icon -ne $IconAlert) { $NotifyIcon.Icon = $IconAlert }
        $NotifyIcon.Text = "App Monitor: ⏸ PAUSED (Global)"
    }
    elseif ($script:Now -lt $script:ErrorUntil) {
        if ($NotifyIcon.Icon -ne $IconAlert) { 
            $NotifyIcon.Icon = $IconAlert 
            $NotifyIcon.Text = $script:CurrentErrorMsg
        }
    } 
    elseif ($script:Now -lt $script:RedLightUntil) {
        if ($NotifyIcon.Icon -ne $IconRed) { 
            $NotifyIcon.Icon = $IconRed 
            $NotifyIcon.Text = "App Monitor: Launching apps..."
        }
    } 
    else {
        if ($NotifyIcon.Icon -ne $IconGreen) { 
            $NotifyIcon.Icon = $IconGreen 
            $NotifyIcon.Text = "App Monitor: Idle"
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 100 
    
    if (($script:Now - $script:LastLoopTime).TotalSeconds -lt $LoopIntervalSeconds) { continue }
    $script:LastLoopTime = $script:Now
}