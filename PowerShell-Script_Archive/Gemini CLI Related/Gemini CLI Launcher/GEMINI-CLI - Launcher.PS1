# Requires PowerShell 7+
# Script: Gemini.ps1 - EliteSoftware CLI Launcher (Gradient Box Edition)

# --- PS7 BOOTSTRAP ---
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Relaunching script in pwsh.exe (PowerShell 7 or higher)..." -ForegroundColor Yellow
    $RelaunchArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath pwsh.exe -ArgumentList $RelaunchArgs
    Exit
}

# --- COLOR & STYLE DEFINITIONS ---
$GradientColors = @(
    [System.Drawing.Color]::FromArgb(67, 43, 163),  # Start: Deep Blue-Purple
    [System.Drawing.Color]::FromArgb(190, 80, 190), # Mid: Purple-Pink
    [System.Drawing.Color]::FromArgb(230, 100, 150) # End: Pink-Red
)
$Reset = "`e[0m"
# Box Styling
$BoxColor = "`e[38;2;80;80;80m"     # Subtle Dark Gray for borders
$TitleColor = "`e[38;2;120;120;250m" # Light Blue for title
$HighlightTextColor = "`e[97m"       # Bright White text for selection
$SelectedOptionColor = "`e[91m"      # Bright Red text for selection

# --- HELPER FUNCTIONS ---

$SettingsFilePath = Join-Path $PSScriptRoot ".gemini/settings.json"

function Get-AppSetting {
    param([string]$Name)
    if (-not (Test-Path $SettingsFilePath)) { return $null }
    $Settings = Get-Content $SettingsFilePath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -ne $Settings -and $Settings.PSObject.Properties.Name -contains $Name) {
        return $Settings.$Name
    }
    return $null
}

function Set-AppSetting {
    param([string]$Name, $Value)
    $Settings = @{}
    if (Test-Path $SettingsFilePath) {
        $Settings = Get-Content $SettingsFilePath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $Settings) { $Settings = @{} }
    }
    $Settings.$Name = $Value
    $Settings | ConvertTo-Json | Set-Content -Path $SettingsFilePath -Encoding UTF8
}

function Get-VisibleLength {
    param([string]$Text)
    # Regex to strip ANSI escape codes for accurate length calculation
    $Clean = $Text -replace "`e\[[0-9;]*m", ""
    return $Clean.Length
}

function Get-GradientColor {
    param(
        [int]$Index,
        [int]$Total,
        [bool]$Background = $false
    )
    if ($Total -le 0) { $Total = 1 }
    $t = [float]$Index / $Total
    
    # Gradient Interpolation Logic (Three-point interpolation)
    if ($t -le 0.5) {
        $t_local = $t * 2
        $R = [int](($GradientColors[1].R - $GradientColors[0].R) * $t_local + $GradientColors[0].R)
        $G = [int](($GradientColors[1].G - $GradientColors[0].G) * $t_local + $GradientColors[0].G)
        $B = [int](($GradientColors[1].B - $GradientColors[0].B) * $t_local + $GradientColors[0].B)
    } else {
        $t_local = ($t - 0.5) * 2
        $R = [int](($GradientColors[2].R - $GradientColors[1].R) * $t_local + $GradientColors[1].R)
        $G = [int](($GradientColors[2].G - $GradientColors[1].G) * $t_local + $GradientColors[1].G)
        $B = [int](($GradientColors[2].B - $GradientColors[1].B) * $t_local + $GradientColors[1].B)
    }
    
    if ($Background) {
        return "`e[48;2;$R;$G;$Bm" # Set Background
    }
    return "`e[38;2;$R;$G;$Bm" # Set Foreground
}

function Set-Cursor {
    param([int]$x, [int]$y)
    try {
        if ($x -lt 0) { $x = 0 }
        if ($y -lt 0) { $y = 0 }
        if ($x -ge $Host.UI.RawUI.WindowSize.Width) { $x = $Host.UI.RawUI.WindowSize.Width - 1 }
        
        $Host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new($x, $y)
    } catch {
        # Fallback if RawUI fails
    }
}

function Show-LaunchAnimation {
    param([string]$Message)
    $BarLength = 30
    $SleepMs = 35
    $BarChar = "█"
    
    Write-Host ""
    Write-Host " $Message" -ForegroundColor White
    
    # Get the starting position to draw the bar
    $BarStartPosition = $Host.UI.RawUI.CursorPosition
    
    # Draw empty bar structure
    Write-Host " [" -NoNewline
    $BarInteriorStart = $Host.UI.RawUI.CursorPosition
    Write-Host (' ' * $BarLength) -NoNewline
    Write-Host "]" -NoNewline

    # Fill bar with gradient using cursor positioning
    for ($i = 1; $i -le $BarLength; $i++) {
        $newPos = [System.Management.Automation.Host.Coordinates]::new(($BarInteriorStart.X + $i - 1), $BarInteriorStart.Y)
        $Host.UI.RawUI.CursorPosition = $newPos

        $Color = Get-GradientColor -Index $i -Total $BarLength
        Write-Host -NoNewline "$Color$BarChar$Reset"
        Start-Sleep -Milliseconds $SleepMs
    }
    
    # Position cursor after the bar to write percentage
    $newPos = [System.Management.Automation.Host.Coordinates]::new(($BarInteriorStart.X + $BarLength + 2), $BarInteriorStart.Y)
    $Host.UI.RawUI.CursorPosition = $newPos
    Write-Host "100%" -ForegroundColor Green
    Write-Host "" # Newline
    Start-Sleep -Milliseconds 300
}

# --- MENU RENDERING ENGINE ---

function Show-BoxedMenu {
    param([int]$DefaultSelection = 3)
    
    # Names confirmed correct to prevent 'emini' typo
    $ModelNames = @(
        "Gemini 2.5 Pro", 
        "Gemini 2.5 Flash", 
        "Gemini 3.0 Pro", 
        "Default (No model flag)", 
        "Advanced Launch Options..."
    )
    
    # Set the initial selected index to what the user requested: the "Default" option.
    $DefaultOptionIndex = [array]::IndexOf($ModelNames, "Default (No model flag)")
    if ($DefaultOptionIndex -lt 0) { $DefaultOptionIndex = $DefaultSelection } # Fallback
    
    $SelectedIndex = $DefaultOptionIndex

    # --- DYNAMIC WIDTH CALCULATION ---
    $TitleText = "EliteSoftware CLI Launcher"
    $HeaderText = "Select the Gemini model for this project:"
    
    # Calculate Max Length required
    $MaxContentLength = 0
    $AllContent = @($TitleText, $HeaderText)
    for ($i = 0; $i -lt $ModelNames.Count; $i++) {
        $AllContent += "$($i + 1). $($ModelNames[$i])"
    }
    foreach ($str in $AllContent) {
        $len = Get-VisibleLength $str
        if ($len -gt $MaxContentLength) { $MaxContentLength = $len }
    }
    
    # Width Logic: Content + Padding (4 left) + Padding (4 right) + Borders (2)
    $BoxWidth = $MaxContentLength + 20
    if ($BoxWidth -lt 70) { $BoxWidth = 70 }
    
    $Looping = $true
    
    while ($Looping) {
        Clear-Host
        
        # --- CALCULATE CENTER COORDINATES ---
        $WinWidth = $Host.UI.RawUI.WindowSize.Width
        $WinHeight = $Host.UI.RawUI.WindowSize.Height
        $StartX = [math]::Floor(($WinWidth - $BoxWidth) / 2)
        if ($StartX -lt 0) { $StartX = 0 }
        
        # Start Y at ~20% down or at least line 2
        $StartY = 2
        
        # Drawing Helpers
        $H_Line = "-" * ($BoxWidth - 2)
        $TopBorder = "$BoxColor+$H_Line+$Reset"
        $MidSeparator = "$BoxColor+$H_Line+$Reset"
        $BotBorder = "$BoxColor+$H_Line+$Reset"
        
        # --- DRAWING PHASE (MONOLITHIC STRINGS) ---
        
        # 1. Top Border
        Set-Cursor $StartX $StartY
        Write-Host $TopBorder
        
        # 2. Title
        $StartY++
        Set-Cursor $StartX $StartY
        $VisTitle = Get-VisibleLength $TitleText
        $TPad = [math]::Floor(($BoxWidth - 2 - $VisTitle) / 2)
        $LeftSpace = " " * $TPad
        $RightSpace = " " * ($BoxWidth - 2 - $VisTitle - $TPad)
        # Construct Single String
        $LineStr = "$BoxColor|$Reset$LeftSpace$TitleColor$TitleText$Reset$RightSpace$BoxColor|$Reset"
        Write-Host $LineStr
        
        $StartY++
        Set-Cursor $StartX $StartY
        Write-Host $MidSeparator
        
        # 3. Header
        $StartY++
        Set-Cursor $StartX $StartY
        $VisHead = Get-VisibleLength $HeaderText
        $HPad = " " * ($BoxWidth - 2 - $VisHead - 2) # -2 for left pad
        # Construct Single String
        $LineStr = "$BoxColor|$Reset  $HeaderText$HPad$BoxColor|$Reset"
        Write-Host $LineStr
        
        $StartY++
        Set-Cursor $StartX $StartY
        Write-Host $MidSeparator
        
        # 4. Options
                                            for ($i = 0; $i -lt $ModelNames.Count; $i++) {
                                                $StartY++
                                                Set-Cursor $StartX $StartY
                                                
                                                $ModelName = $ModelNames[$i]
                                                $OptionRaw = "$($i + 1). $ModelName"
                                                $VisOpt = Get-VisibleLength $OptionRaw
                                                
                                                # Calculate padding based on visible length
                                                $paddingNeeded = ($BoxWidth - 2 - 2 - $VisOpt)
                                                $RemainingSpace = " " * [math]::Max(0, $paddingNeeded)
                                                
                                                if ($i -eq $SelectedIndex) {
                                                                        # Use bright red for selected option text
                                                                        $LineStr = "$BoxColor|$Reset  $SelectedOptionColor$OptionRaw$Reset$RemainingSpace$BoxColor|$Reset"
                                                                        Write-Host $LineStr                                                } else {
                                                    # Plain text for unselected options (no specific color)
                                                    $LineStr = "$BoxColor|$Reset  $OptionRaw$RemainingSpace$BoxColor|$Reset"
                                                    Write-Host $LineStr
                                                }
                                            }        # 5. Bottom
        $StartY++
        Set-Cursor $StartX $StartY
        Write-Host $BotBorder
        
        $StartY++
        Set-Cursor $StartX $StartY
        $Msg = "(Use Up/Down Arrows to Navigate, Enter/Space/Number to Select)"
        $MPad = [math]::Max(0, [math]::Floor(($BoxWidth - $Msg.Length) / 2))
        Write-Host (" " * $MPad) -NoNewline
        Write-Host $Msg -ForegroundColor DarkGray
        
        # 6. INPUT HANDLING
        $TimeoutSeconds = 15
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $CountdownY = $StartY + 2
        $LastRemaining = -1
        $UserInteracted = $false
        $CountdownColorOverride = $false # New flag for color override

        $ClearCountdownAction = {
            param($YPos)
            Set-Cursor 0 $YPos
            Write-Host (" " * ($Host.UI.RawUI.WindowSize.Width - 1)) -NoNewline
        }

        while ($true) {
            $Elapsed = $Stopwatch.Elapsed.TotalSeconds
            if ($Elapsed -ge $TimeoutSeconds) {
                Invoke-Command $ClearCountdownAction -ArgumentList $CountdownY
                return $SelectedIndex
            }
            
            if (-not $UserInteracted) { # Only display countdown if user hasn't interacted
                $Remaining = [math]::Ceiling($TimeoutSeconds - $Elapsed)
                if ($Remaining -ne $LastRemaining) {
                    Set-Cursor $StartX $CountdownY
                    
                    $BarLength = 15
                    $FilledCount = $Remaining
                    $EmptyCount = $BarLength - $FilledCount
                    if ($FilledCount -lt 0) { $FilledCount = 0 }
                    if ($EmptyCount -gt $BarLength) { $EmptyCount = $BarLength }
                    
                    $FilledChar = '█'
                    $EmptyChar = '─'
                    $CountdownBar = "$($FilledChar * $FilledCount)$($EmptyChar * $EmptyCount)"
                    
                    # Determine bar color based on override flag
                    if ($CountdownColorOverride) {
                        # Black foreground on black background to hide
                        $CountdownDisplayColor = "`e[30;40m" 
                    } else {
                        $CountdownDisplayColor = Get-GradientColor -Index ($BarLength - $Remaining) -Total $BarLength
                    }

                    # Monolithic Countdown Line
                    $LineStr = "Auto-launch: $CountdownDisplayColor$CountdownBar$Reset ($Remaining`s)"
                    Write-Host $LineStr -NoNewline
                    
                    $LastRemaining = $Remaining
                }
            }
            
            if ($Host.UI.RawUI.KeyAvailable) {
                $Key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                $Stopwatch.Restart() 
                $UserInteracted = $true 
                # This is the point where navigation starts, so override color
                $CountdownColorOverride = $true 
                Invoke-Command $ClearCountdownAction -ArgumentList $CountdownY 

                $NeedsRedraw = $false
                try {
                    switch ($Key.VirtualKeyCode) {
                        38 { # Up Arrow
                            $SelectedIndex--
                            if ($SelectedIndex -lt 0) { $SelectedIndex = $ModelNames.Count - 1 }
                            $NeedsRedraw = $true
                        }
                        40 { # Down Arrow
                            $SelectedIndex++
                            if ($SelectedIndex -ge $ModelNames.Count) { $SelectedIndex = 0 }
                            $NeedsRedraw = $true
                        }
                        13 { # Enter
                            return $SelectedIndex 
                        } 
                        32 { # Space
                            return $SelectedIndex
                        }
                        {$_ -ge 49 -and $_ -le 53} {
                            return ($_ - 49)
                        }
                        Default { continue } 
                    }
                    if ($NeedsRedraw) { break }
                } catch { break }
            }
            Start-Sleep -Milliseconds 50
        }
    }
}

function Show-AdvancedFlagsMenu {
    while ($true) {
        Clear-Host
        $AutoElevateEnabled = Get-AppSetting -Name "AutoElevate"
        if ($null -eq $AutoElevateEnabled) { $AutoElevateEnabled = $false }
        
        $StatusText = if ($AutoElevateEnabled) { "`e[92mEnabled`e[0m" } else { "`e[91mDisabled`e[0m" }
        $CleanStatus = if ($AutoElevateEnabled) { "Enabled" } else { "Disabled" }
        
        $Title = "ADVANCED LAUNCH OPTIONS"
        $Line1Raw = "1. Toggle Auto-Elevation (Currently: $CleanStatus)"
        $Line2Raw = "2. Enter additional CLI flags"
        $Line3Raw = "3. Back to Main Menu"
        
        $MaxLen = $Title.Length
        if ($Line1Raw.Length -gt $MaxLen) { $MaxLen = $Line1Raw.Length }
        if ($Line2Raw.Length -gt $MaxLen) { $MaxLen = $Line2Raw.Length }
        if ($Line3Raw.Length -gt $MaxLen) { $MaxLen = $Line3Raw.Length }
        
        $BoxWidth = $MaxLen + 20
        if ($BoxWidth -lt 70) { $BoxWidth = 70 }
        
        $WinWidth = $Host.UI.RawUI.WindowSize.Width
        $StartX = [math]::Floor(($WinWidth - $BoxWidth) / 2)
        if ($StartX -lt 0) { $StartX = 0 }
        $StartY = 2
        
        $H_Line = "-" * ($BoxWidth - 2)
        $Top    = "$BoxColor+$H_Line+$Reset"
        $Bot    = "$BoxColor+$H_Line+$Reset"
        
        Set-Cursor $StartX $StartY; Write-Host $Top
        
        # Title
        $StartY++; Set-Cursor $StartX $StartY
        $TPad = [math]::Floor(($BoxWidth - 2 - $Title.Length) / 2)
        $LSpace = " " * $TPad
        $RSpace = " " * ($BoxWidth - 2 - $Title.Length - $TPad)
        Write-Host "$BoxColor|$Reset$LSpace$TitleColor$Title$Reset$RSpace$BoxColor|$Reset"
        
        $StartY++; Set-Cursor $StartX $StartY; Write-Host $Bot
        
        # Helper
        $DrawOpt = {
            param($Txt, $VisLen)
            $paddingNeeded = ($BoxWidth - 2 - 2 - $VisLen)
            $Remaining = " " * [math]::Max(0, $paddingNeeded)
            # The $Txt parameter might already contain ANSI codes (e.g., for status).
            # We ensure it's reset after $Txt and before padding.
            Write-Host "$BoxColor|$Reset  $Txt$Reset$Remaining$BoxColor|$Reset"
        }
        
        # Opt 1
        $StartY++; Set-Cursor $StartX $StartY
        $Txt1 = "1. Toggle Auto-Elevation (Currently: $StatusText)"
        $Vis1 = Get-VisibleLength $Txt1
        &$DrawOpt $Txt1 $Vis1
        
        # Opt 2
        $StartY++; Set-Cursor $StartX $StartY
        $Txt2 = "2. Enter additional CLI flags"
        &$DrawOpt $Txt2 $Txt2.Length
        
        # Opt 3
        $StartY++; Set-Cursor $StartX $StartY
        $Txt3 = "3. Back to Main Menu"
        &$DrawOpt $Txt3 $Txt3.Length
        
        $StartY++; Set-Cursor $StartX $StartY; Write-Host $Bot
        
        $StartY += 2
        Set-Cursor $StartX $StartY
        $Choice = Read-Host " Select Option"
        
        switch ($Choice) {
            '1' { Set-AppSetting -Name "AutoElevate" -Value (-not $AutoElevateEnabled) }
            '2' {
                Write-Host "`n Available: -d/--debug, -p/--prompt, -c/--config, -k/--key`n"
                $Flags = Read-Host " Enter Flags > "
                $Result = @{ Flags = $Flags.Trim(); Prompt = "" }
                if ($Result.Flags -match "(-p|--prompt)") {
                    $P = Read-Host " Enter Prompt Content > "
                    $Result.Prompt = $P.Trim()
                }
                return $Result
            }
            '3' { return $null }
        }
    }
}

# 1. Admin Check (if configured)
$AutoElevateEnabled = Get-AppSetting -Name "AutoElevate"
if ($AutoElevateEnabled -eq $true -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "`n Auto-Elevation is enabled. Elevating privileges..." -ForegroundColor DarkGray
    $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath pwsh.exe -Verb Runas -ArgumentList $CommandLine
    Exit
}

# 2. Main Menu Loop
while ($true) {
    $ModelIDs = @("gemini-2.5-pro", "gemini-2.5-flash", "gemini-3.0-pro", "", "ADVANCED")
    [int]$SelectionIndex = Show-BoxedMenu

    # 3. Handle Advanced Options
    $AdditionalFlags = ""
    $PromptContent = ""

    if ($ModelIDs[$SelectionIndex] -eq "ADVANCED") {
        $AdvResult = Show-AdvancedFlagsMenu
        if ($null -eq $AdvResult) {
            continue # User chose 'Back', re-show main menu
        }
        $AdditionalFlags = $AdvResult.Flags
        $PromptContent = $AdvResult.Prompt
        $SelectionIndex = 3 # Revert to Default model index for the launch
    }
    break # Exit menu loop and proceed to launch
}

# 4. Prepare Launch
$SelectedModel = $ModelIDs[$SelectionIndex]
$FinalFlags = ""

try {
    # Set context to script directory
    Set-Location -Path $PSScriptRoot -ErrorAction Stop
} catch {
    $PSScriptRoot = Get-Location
}

if (-not [string]::IsNullOrEmpty($SelectedModel)) { $FinalFlags += "-m $SelectedModel" }
$FinalFlags += " $AdditionalFlags"
if (-not [string]::IsNullOrEmpty($PromptContent)) {
    # Escape quotes for CLI safety
    $SafePrompt = $PromptContent.Replace('"', '\"')
    $FinalFlags += " `"$SafePrompt`""
}

# 5. Launch Sequence
Clear-Host
Write-Host "`n +----------------------------------------------------------+" -ForegroundColor DarkGray
Write-Host " |              EliteSoftware Launching...                  |" -ForegroundColor White
Write-Host " +----------------------------------------------------------+" -ForegroundColor DarkGray
Write-Host " | Dir:    $PSScriptRoot"
Write-Host " | Model: $($SelectedModel -replace '^$', 'Default')"
Write-Host " +----------------------------------------------------------+`n" -ForegroundColor DarkGray

Show-LaunchAnimation "Initializing Gemini CLI..."

try {
    if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) {
        throw "Gemini CLI executable ('gemini') not found."
    }
    Invoke-Expression "gemini $FinalFlags"
} catch {
    Write-Host "`n [!] CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host " Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}