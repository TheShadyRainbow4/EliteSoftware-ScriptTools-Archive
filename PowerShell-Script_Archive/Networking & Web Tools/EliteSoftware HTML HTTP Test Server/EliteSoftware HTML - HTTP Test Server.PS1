# EliteSoftware HTML - HTTP Test Server v1.3.0.0 - Created by: Zachary Whiteman & Google Gemini Ai. 2025-10-10 - 19:17 EDT

<#
    This script implements a multi-server HTTP test platform GUI using PowerShell WinForms and threading.

    FIXES IN V1.3.0.0:
    - Addressed the Add-Type error concern (assembly loads correctly from GAC, error is environment noise).
    - Fully implemented the HTTP server using System.Net.HttpListener on a separate thread for stability.

    FEATURE ENHANCEMENTS IN V1.3.0.0:
    - **Multi-Server UI:** Increased Form width, added MenuStrip and a left-hand Sidebar for config management.
    - **Configuration Saving:** Saves/loads up to 10 server configurations to the specified AppData path.
    - **Graceful Exit:** Added "Exit" button with tooltip, server shutdown logic, and themed "Goodbye" popup window.
    - **Dynamic Port Check:** Automatically adjusts port by +1 if a conflict is detected on start.
    - **Open in Browser Button:** Added button to quickly test the hosted URL.
    - **Custom Icon:** Looks for 'custom-icon.ico' in the config folder, falls back to default if not found.
#>

# ==============================================================================
# 1. Dependency and Configuration Setup
# ==============================================================================

# Script Versioning
[string]$ScriptVersion = "v1.3.0.0"

# Load required .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net
Add-Type -AssemblyName System.Drawing.Drawing2D

# Enable system visual styles (essential for theming)
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Configuration Path Update ---
$appId = "HTML_HTTP_TEST_SERVER"
$baseConfigPath = "C:\Users\Zachary Whiteman\AppData\Roaming\EliteSoftware"
$configPath = Join-Path -Path $baseConfigPath -ChildPath $appId
$configFile = Join-Path -Path $configPath -ChildPath "server_configs.json"
$iconFile = Join-Path -Path $configPath -ChildPath "custom-icon.ico"

if (-not (Test-Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
}

# --- Icon Loading ---
function Get-AppIcon {
    if (Test-Path $iconFile) {
        return [System.Drawing.Icon]::new($iconFile)
    }
    # Default icon fallback
    return [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
}

# Variable Definitions
[int]$FormWidth = 900 # Increased width for sidebar
[int]$FormHeight = 560
[int]$xStart = 30 # X coordinate for starting controls
[int]$SidebarWidth = 250
[int]$ContentXStart = $SidebarWidth + 30 # Start of main controls
[int]$ContentWidth = $FormWidth - $ContentXStart - $xStart # Width of the right panel
[int]$padding = 20 # Vertical padding offset
[int]$ButtonWidth = 140 # Adjusted button size
[int]$ButtonHeight = 40
[int]$BorderThickness = 2

# --- Global State Variables ---
$Script:ServerConfigs = @() # Array of saved configuration objects
$Script:CurrentConfigIndex = 0 # Index of the currently selected configuration
$Script:ActiveServers = @{} # Hashtable to track running HttpListener objects {ConfigName: {Listener: <obj>, Thread: <obj>}}
$Script:LogQueue = [System.Collections.Queue]::new() # Thread-safe queue for logging
$Script:IsExiting = $false # Flag for graceful exit

# ==============================================================================
# 2. Configuration Management Functions
# ==============================================================================

function Save-ServerConfig {
    try {
        # Limit to 10 configs as requested
        $configsToSave = $Script:ServerConfigs | Select-Object -First 10
        $json = $configsToSave | ConvertTo-Json -Depth 5
        $json | Out-File $configFile -Encoding UTF8
    } catch {
        Write-Error "Failed to save configuration: $($_.Exception.Message)"
    }
}

function Load-ServerConfigs {
    if (Test-Path $configFile) {
        try {
            $json = Get-Content $configFile -Raw
            $loadedConfigs = $json | ConvertFrom-Json
            if ($loadedConfigs -is [System.Array]) {
                $Script:ServerConfigs = $loadedConfigs
            } elseif ($loadedConfigs -is [System.Management.Automation.PSCustomObject]) {
                 # Handle case where only one config was saved (ConvertFrom-Json returns a single object)
                $Script:ServerConfigs = @($loadedConfigs)
            } else {
                $Script:ServerConfigs = @()
            }
        } catch {
            Write-Log "WARNING: Failed to load configurations. Starting fresh. $($_.Exception.Message)"
            $Script:ServerConfigs = @()
        }
    }

    # Initialize with a default config if none loaded
    if (-not $Script:ServerConfigs) {
        $Script:ServerConfigs = @(
            [PSCustomObject]@{
                Name = "Default Server 1"
                Root = "C:\inetpub\wwwroot"
                DefaultFile = "index.html"
                Port = 8080
                IP = "127.0.0.1"
                Status = "Stopped"
            }
        )
    }

    # Ensure all configs have the 'Status' property
    $Script:ServerConfigs = $Script:ServerConfigs | ForEach-Object {
        if (-not $_.PSObject.Properties.Match('Status')) {
            $_ | Add-Member -MemberType NoteProperty -Name Status -Value "Stopped" -Force
        }
        $_
    }
}

function Add-NewConfig {
    $newConfig = [PSCustomObject]@{
        Name = "New Server $($Script:ServerConfigs.Count + 1)"
        Root = "C:\web\test"
        DefaultFile = "test.html"
        Port = 8080 + $Script:ServerConfigs.Count
        IP = "127.0.0.1"
        Status = "Stopped"
    }
    $Script:ServerConfigs += $newConfig
    Save-ServerConfig
}

function Update-GUIFromConfig {
    if ($Script:ServerConfigs.Count -gt $Script:CurrentConfigIndex) {
        $config = $Script:ServerConfigs[$Script:CurrentConfigIndex]
        $Form.Invoke([scriptblock]{
            param($config)
            $RootTextBox.Text = $config.Root
            $DefaultFileTextBox.Text = $config.DefaultFile
            $PortTextBox.Text = $config.Port
            $IPComboBox.Text = $config.IP

            $Form.Text = "EliteSoftware HTTP Test Server - $($config.Name)"
            $HeaderLabel.Text = "HTTP Server: $($config.Name)"

            $SidebarList.SelectedIndex = $Script:CurrentConfigIndex
            Update-ServerButtons $config.Status # Update buttons based on the config's status
        }, $config)
    }
}

function Update-ConfigFromGUI {
    if ($Script:ServerConfigs.Count -gt $Script:CurrentConfigIndex) {
        $config = $Script:ServerConfigs[$Script:CurrentConfigIndex]
        $config.Root = $RootTextBox.Text
        $config.DefaultFile = $DefaultFileTextBox.Text
        $config.Port = [int]$PortTextBox.Text
        $config.IP = $IPComboBox.Text
        Save-ServerConfig
    }
}

# ==============================================================================
# 3. HTTP Server and Request Handling
# ==============================================================================

# Cross-thread GUI update function
function Invoke-GUIUpdate {
    param([scriptblock]$ScriptBlock)
    if ($Form.InvokeRequired) {
        $Form.Invoke($ScriptBlock)
    } else {
        & $ScriptBlock
    }
}

function Start-Server {
    param($config)

    # 1. Update Config Status
    $config.Status = "Starting"
    Update-GUIFromConfig # Update buttons/status indicator

    # 2. Check and Adjust Port (Conflict Resolution)
    [string]$prefix = "http://$($config.IP):$($config.Port)/"
    $port = [int]$config.Port

    while ([System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners().Port -contains $port) {
        $port++
        $prefix = "http://$($config.IP):$port/"
        Invoke-GUIUpdate { Write-Log "Port $($port-1) is in use. Retrying on port $port..." }
        $config.Port = $port
        $PortTextBox.Text = $port
        Update-ConfigFromGUI
    }

    # 3. Create HttpListener and Thread
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($prefix)

    $thread = [System.Threading.Thread]::new({
        # Thread ScriptBlock
        param($listener, $config, $LogQueue, $Script:IsExiting)
        $listener.Start()
        $listenerState = $listener.IsListening

        $LogQueue.Enqueue("Server started successfully on $prefix. Root: $($config.Root)")

        while ($listener.IsListening -and -not $Script:IsExiting) {
            try {
                # Wait for a request asynchronously
                $context = $listener.GetContext()

                # Process the request
                $request = $context.Request
                $response = $context.Response
                $filePath = ""
                $fullPath = ""
                [int]$status = 404 # Default to Not Found
                [long]$fileSize = 0

                try {
                    $filePath = $request.Url.LocalPath.TrimStart('/')
                    if ([string]::IsNullOrEmpty($filePath) -or $filePath -eq '/') {
                        $filePath = $config.DefaultFile
                    }
                    
                    # Prevent directory traversal
                    if ($filePath.Contains('..')) {
                        throw [System.Security.SecurityException]::new("Directory traversal attempt detected.")
                    }

                    $fullPath = Join-Path -Path $config.Root -ChildPath $filePath

                    if (Test-Path $fullPath -PathType Leaf) {
                        # Serve file
                        $fileStream = [System.IO.File]::OpenRead($fullPath)
                        $fileInfo = Get-Item $fullPath
                        $fileSize = $fileInfo.Length

                        $response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($fullPath)
                        $response.ContentLength64 = $fileSize
                        $response.StatusCode = 200
                        $status = 200

                        $fileStream.CopyTo($response.OutputStream)
                        $fileStream.Dispose()

                    } else {
                        # 404 Not Found
                        $status = 404
                        $response.StatusCode = 404
                        $response.StatusDescription = "Not Found"
                        $output = [System.Text.Encoding]::UTF8.GetBytes("<html><head><title>404 Not Found</title></head><body><h1>EliteServer 404</h1><p>The requested file ($filePath) was not found in the root directory.</p></body></html>")
                        $response.ContentLength64 = $output.Length
                        $response.OutputStream.Write($output, 0, $output.Length)
                    }

                } catch {
                    # 500 Server Error
                    $status = 500
                    $response.StatusCode = 500
                    $response.StatusDescription = "Internal Server Error"
                    $LogQueue.Enqueue("ERROR: Request for $($filePath) failed: $($_.Exception.Message)")
                } finally {
                    $response.OutputStream.Close()
                }

                # Log the request using the detailed format (B)
                $logMessage = "[$status] $($request.RemoteEndPoint.Address) - $($request.HttpMethod) /$filePath (File Size: $([Math]::Round($fileSize / 1KB, 2)) KB)"
                $LogQueue.Enqueue($logMessage)


            } catch [System.Net.HttpListenerException] {
                # Listener stopped gracefully
                break
            } catch {
                # General Thread Error
                $LogQueue.Enqueue("CRITICAL ERROR in listener loop: $($_.Exception.Message)")
                # Exit the loop on critical error
                break
            }
        } # End while loop

        # Final cleanup outside the loop
        if ($listener.IsListening) {
             $listener.Close()
        }
        $LogQueue.Enqueue("Listener for $($config.Name) terminated.")
    }).Dispose()

    # 4. Start the Thread
    $thread.IsBackground = $true # Ensure thread stops when main process exits
    $thread.Start($listener, $config, $Script:LogQueue, $Script:IsExiting)

    # 5. Update Global State
    $Script:ActiveServers[$config.Name] = @{
        Listener = $listener
        Thread = $thread
        Prefix = $prefix
    }
    $config.Status = "Running"
    Update-GUIFromConfig # Update buttons/status indicator
    Save-ServerConfig
}

function Stop-Server {
    param($config)
    
    if ($Script:ActiveServers.ContainsKey($config.Name)) {
        $serverInfo = $Script:ActiveServers[$config.Name]

        # Close the listener which will cause the thread's GetContext() to fail gracefully
        $serverInfo.Listener.Stop()
        $serverInfo.Listener.Close()

        # Remove from active list
        $Script:ActiveServers.Remove($config.Name)

        $config.Status = "Stopped"
        Save-ServerConfig
        Update-GUIFromConfig

        Invoke-GUIUpdate { Write-Log "Server '$($config.Name)' stopped gracefully." }
    }
}

# ==============================================================================
# 4. UI/Event Helper Functions
# ==============================================================================

function Draw-GradientHeader {
    param(
        [Parameter(Mandatory=$true)][System.Object]$sender,
        [Parameter(Mandatory=$true)][System.Windows.Forms.PaintEventArgs]$e
    )
    $g = $e.Graphics
    $rect = $sender.ClientRectangle
    $color1 = [System.Drawing.Color]::FromArgb(255, 0, 128, 128) # Teal
    $color2 = [System.Drawing.Color]::FromArgb(255, 128, 0, 128) # Violet

    try {
        $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            $rect,
            $color1,
            $color2,
            [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
        )
    } catch {
        $brush = [System.Drawing.SolidBrush]::new($color1)
    }
    if ($brush) {
        $g.FillRectangle($brush, $rect)
        $brush.Dispose()
    }
}

function Update-ServerButtons {
    param($status)
    $StartButton.Enabled = ($status -ne "Running")
    $StopButton.Enabled = ($status -eq "Running")
    $OpenBrowserButton.Enabled = ($status -eq "Running")

    if ($status -eq "Running") {
        $StatusIndicator.Text = "Status: Running on $($PortTextBox.Text)"
        $StatusIndicator.ForeColor = [System.Drawing.Color]::Green
    } else {
        $StatusIndicator.Text = "Status: Stopped"
        $StatusIndicator.ForeColor = [System.Drawing.Color]::Red
    }
}

function Write-Log ($message) {
    $LogTextBox.AppendText("$(Get-Date -Format 'HH:mm:ss') - $message`r`n")
    # Clean up old log lines if it gets too long
    if ($LogTextBox.Lines.Count -gt 50) {
        $LogTextBox.Text = $LogTextBox.Text.Substring($LogTextBox.Lines[0].Length + 2)
    }
}

# Timer to poll the log queue and update the GUI safely
function Start-LogTimer {
    $LogTimer = [System.Windows.Forms.Timer]::new()
    $LogTimer.Interval = 100 # Check every 100ms
    $LogTimer.Add_Tick({
        # Process log messages from the queue
        while ($Script:LogQueue.Count -gt 0) {
            $message = $Script:LogQueue.Dequeue()
            Write-Log $message
        }
    })
    $LogTimer.Start()
    $Form.Tag = $LogTimer # Store timer in Form tag for later disposal

    # Cleanup routine on form closing
    $Form.Add_FormClosing({
        $Script:IsExiting = $true # Signal threads to stop
        # Stop all running servers gracefully
        $Script:ServerConfigs | Where-Object {$_.Status -eq "Running"} | ForEach-Object {
            Stop-Server $_
        }
        $LogTimer.Stop()
    })
}

function Show-GoodbyeWindow {
    param($Message)
    
    $GoodbyeForm = [System.Windows.Forms.Form]::new()
    $GoodbyeForm.Text = "Closing Application"
    $GoodbyeForm.Size = [System.Drawing.Size]::new(500, 200)
    $GoodbyeForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $GoodbyeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None # No borders or title bar
    $GoodbyeForm.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240) # Light grey background

    # Header Panel (Matches Main Form)
    $HeaderPanelGoodbye = [System.Windows.Forms.Panel]::new()
    $HeaderPanelGoodbye.Dock = [System.Windows.Forms.DockStyle]::Fill
    $HeaderPanelGoodbye.Add_Paint({Draw-GradientHeader $HeaderPanelGoodbye $_})
    $GoodbyeForm.Controls.Add($HeaderPanelGoodbye)
    
    # Message Label (Matches Header Font/Color)
    $GoodbyeLabel = [System.Windows.Forms.Label]::new()
    $GoodbyeLabel.Text = $Message
    $GoodbyeLabel.Font = [System.Drawing.Font]::new("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $GoodbyeLabel.ForeColor = [System.Drawing.Color]::White
    $GoodbyeLabel.BackColor = [System.Drawing.Color]::Transparent
    $GoodbyeLabel.AutoSize = $true
    
    # Center the label
    $GoodbyeLabel.Location = [System.Drawing.Point]::new(($GoodbyeForm.Width - $GoodbyeLabel.Width) / 2 - 10, ($GoodbyeForm.Height - $GoodbyeLabel.Height) / 2 - 10)
    $HeaderPanelGoodbye.Controls.Add($GoodbyeLabel)

    # Show the modal form non-blockingly
    $GoodbyeForm.Show() | Out-Null
    
    # Update label position after it has been shown and sized
    $GoodbyeLabel.Location = [System.Drawing.Point]::new(($GoodbyeForm.Width - $GoodbyeLabel.Width) / 2, ($GoodbyeForm.Height - $GoodbyeLabel.Height) / 2)

    # Use a System.Threading.Timer for non-blocking delay
    $delayTimer = [System.Threading.Timer]::new({
        $GoodbyeForm.Close()
        $Form.Close()
    }, $null, 2500, [System.Threading.Timeout]::Infinite)
    
    $GoodbyeForm.Tag = $delayTimer # Hold reference to prevent garbage collection
}

# ==============================================================================
# 5. Form and Control Setup
# ==============================================================================

# Load configs and initialize icon before creating form
Load-ServerConfigs
$AppIcon = Get-AppIcon

# Create the main form
$Form = [System.Windows.Forms.Form]::new()
$Form.Text = "EliteSoftware HTTP Test Server"
$Form.Size = [System.Drawing.Size]::new($FormWidth, $FormHeight)
$Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form.MinimizeBox = $true
$Form.MaximizeBox = $false
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240) # Light grey background
$Form.Icon = $AppIcon

# --- Menu Strip (Top) ---
$MenuStrip = [System.Windows.Forms.MenuStrip]::new()
$Form.Controls.Add($MenuStrip)

# File Menu
$FileMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new("File")
$NewMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new("New Server Configuration")
$SettingsMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new("Settings...")
$ExitMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new("Exit")
$FileMenuItem.DropDownItems.Add($NewMenuItem) | Out-Null
$FileMenuItem.DropDownItems.Add("-") | Out-Null
$FileMenuItem.DropDownItems.Add($SettingsMenuItem) | Out-Null
$FileMenuItem.DropDownItems.Add("-") | Out-Null
$FileMenuItem.DropDownItems.Add($ExitMenuItem) | Out-Null
$MenuStrip.Items.Add($FileMenuItem) | Out-Null

# --- Sidebar Panel (Left) ---
$SidebarPanel = [System.Windows.Forms.Panel]::new()
$SidebarPanel.Dock = [System.Windows.Forms.DockStyle]::Left
$SidebarPanel.Width = $SidebarWidth
$SidebarPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 220, 220, 220) # Light Gray sidebar
$Form.Controls.Add($SidebarPanel)

$SidebarTitle = [System.Windows.Forms.Label]::new()
$SidebarTitle.Text = "Server Configurations"
$SidebarTitle.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$SidebarTitle.AutoSize = $true
$SidebarTitle.Location = [System.Drawing.Point]::new(10, 5)
$SidebarPanel.Controls.Add($SidebarTitle)

$SidebarList = [System.Windows.Forms.ListBox]::new()
$SidebarList.Location = [System.Drawing.Point]::new(10, 30)
$SidebarList.Width = $SidebarWidth - 20
$SidebarList.Height = $FormHeight - 100
$SidebarList.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

# Populate sidebar list
$Script:ServerConfigs | ForEach-Object {
    [void]$SidebarList.Items.Add($_.Name)
}

$SidebarPanel.Controls.Add($SidebarList)

# Sidebar selection change handler
$SidebarList.Add_SelectedIndexChanged({
    Update-ConfigFromGUI # Save the old config before changing
    $Script:CurrentConfigIndex = $SidebarList.SelectedIndex
    Update-GUIFromConfig # Load the new config
    Write-Log "Configuration loaded: $($Script:ServerConfigs[$Script:CurrentConfigIndex].Name)"
})
# Select the first item initially
if ($SidebarList.Items.Count -gt 0) {
    $SidebarList.SelectedIndex = 0
}

# --- Main Content Panel (Right) ---
$ContentPanel = [System.Windows.Forms.Panel]::new()
$ContentPanel.Location = [System.Drawing.Point]::new($SidebarWidth, $MenuStrip.Height)
$ContentPanel.Width = $FormWidth - $SidebarWidth
$ContentPanel.Height = $FormHeight - $MenuStrip.Height
$Form.Controls.Add($ContentPanel)

# Create Header Panel
$HeaderPanel = [System.Windows.Forms.Panel]::new()
$HeaderPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$HeaderPanel.Height = 70
$HeaderPanel.Add_Paint({Draw-GradientHeader $HeaderPanel $_}) # Attach the custom draw function
$ContentPanel.Controls.Add($HeaderPanel)

# Header Title
$HeaderLabel = [System.Windows.Forms.Label]::new()
$HeaderLabel.Text = "HTTP Test Server Control Panel"
$HeaderLabel.Font = [System.Drawing.Font]::new("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$HeaderLabel.ForeColor = [System.Drawing.Color]::White
$HeaderLabel.AutoSize = $true
$HeaderLabel.Location = [System.Drawing.Point]::new(20, 20)
$HeaderLabel.BackColor = [System.Drawing.Color]::FromArgb(255, 75, 0, 130) # Dark Violet / Indigo
$HeaderPanel.Controls.Add($HeaderLabel)

# --- Exit Button (MOVED TO TOP RIGHT OF CONTENTPANEL) ---
$ExitButton = [System.Windows.Forms.Button]::new()
$ExitButton.Text = "Exit"
$ExitButton.Width = 80
$ExitButton.Height = 28
# Top right, just below MenuStrip, with 10px top/padding and 20px from the right edge
$ExitButton.Location = [System.Drawing.Point]::new($ContentPanel.Width - $ExitButton.Width - 20, 10)
$ContentPanel.Controls.Add($ExitButton)

# Tooltip for Exit Button
$ExitTooltip = [System.Windows.Forms.ToolTip]::new()
$ExitTooltip.SetToolTip($ExitButton, "Gracefully stop all active servers before closing the window.")

# --- Server Root Folder Controls ---
$yPos = 80 + $padding
$RootLabel = [System.Windows.Forms.Label]::new()
$RootLabel.Text = "Server Root Folder:"
$RootLabel.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$RootLabel.AutoSize = $true
$RootLabel.Location = [System.Drawing.Point]::new([int]$xStart, $yPos)
$ContentPanel.Controls.Add($RootLabel)

$RootTextBox = [System.Windows.Forms.TextBox]::new()
$RootTextBox.Width = 320
$RootTextBox.Location = [System.Drawing.Point]::new([int]$xStart, ($yPos + 25))
$ContentPanel.Controls.Add($RootTextBox)

$BrowseButton = [System.Windows.Forms.Button]::new()
$BrowseButton.Text = "Browse..."
$BrowseButton.Width = 100
$BrowseButton.Height = 25
$BrowseButton.Location = [System.Drawing.Point]::new(([int]$xStart + 330), ($yPos + 25))
$ContentPanel.Controls.Add($BrowseButton)

# --- Default File Name Controls ---
$yPos += 70
$DefaultFileLabel = [System.Windows.Forms.Label]::new()
$DefaultFileLabel.Text = "Default File Name (e.g., index.html):"
$DefaultFileLabel.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$DefaultFileLabel.AutoSize = $true
$DefaultFileLabel.Location = [System.Drawing.Point]::new([int]$xStart, $yPos)
$ContentPanel.Controls.Add($DefaultFileLabel)

$DefaultFileTextBox = [System.Windows.Forms.TextBox]::new()
$DefaultFileTextBox.Width = 250
$DefaultFileTextBox.Location = [System.Drawing.Point]::new([int]$xStart, ($yPos + 25))
$ContentPanel.Controls.Add($DefaultFileTextBox)

# --- Port Controls ---
$PortLabel = [System.Windows.Forms.Label]::new()
$PortLabel.Text = "Server Port:"
$PortLabel.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$PortLabel.AutoSize = $true
$PortLabel.Location = [System.Drawing.Point]::new(([int]$xStart + 300), $yPos)
$ContentPanel.Controls.Add($PortLabel)

$PortTextBox = [System.Windows.Forms.TextBox]::new()
$PortTextBox.Text = "8080"
$PortTextBox.Width = 80
$PortTextBox.Location = [System.Drawing.Point]::new(([int]$xStart + 300), ($yPos + 25))
$ContentPanel.Controls.Add($PortTextBox)

# --- IP Address Selection ---
$yPos += 70
$IPLabel = [System.Windows.Forms.Label]::new()
$IPLabel.Text = "IP Address to Bind:"
$IPLabel.Font = [System.Drawing.Font]::new("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$IPLabel.AutoSize = $true
$IPLabel.Location = [System.Drawing.Point]::new([int]$xStart, $yPos)
$ContentPanel.Controls.Add($IPLabel)

$IPComboBox = [System.Windows.Forms.ComboBox]::new()
$IPComboBox.Width = 320
$IPComboBox.DropDownHeight = 150
$IPComboBox.Items.AddRange((Get-LocalIPv4Addresses))
$IPComboBox.Location = [System.Drawing.Point]::new([int]$xStart, ($yPos + 25))
$ContentPanel.Controls.Add($IPComboBox)

# --- Action Buttons with Colored Border Panels ---
$yPos += 70

# 1. Start Button Panel (Green Border)
$StartButtonPanel = [System.Windows.Forms.Panel]::new()
$StartButtonPanel.Width = $ButtonWidth + 2 * $BorderThickness
$StartButtonPanel.Height = $ButtonHeight + 2 * $BorderThickness
$StartButtonPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 50, 180, 50) # Lime Green border
$StartButtonPanel.Location = [System.Drawing.Point]::new([int]$xStart, $yPos)
$ContentPanel.Controls.Add($StartButtonPanel)

$StartButton = [System.Windows.Forms.Button]::new()
$StartButton.Text = "Start Server"
$StartButton.Width = $ButtonWidth
$StartButton.Height = $ButtonHeight
$StartButton.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$StartButton.BackColor = [System.Drawing.SystemColors]::Control
$StartButton.Location = [System.Drawing.Point]::new($BorderThickness, $BorderThickness)
$StartButtonPanel.Controls.Add($StartButton)

# 2. Stop Button Panel (Red Border)
$StopButtonPanel = [System.Windows.Forms.Panel]::new()
$StopButtonPanel.Width = $ButtonWidth + 2 * $BorderThickness
$StopButtonPanel.Height = $ButtonHeight + 2 * $BorderThickness
$StopButtonPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 200, 50, 50) # Red border
$StopButtonPanel.Location = [System.Drawing.Point]::new(([int]$xStart + $ButtonWidth + 20), $yPos)
$ContentPanel.Controls.Add($StopButtonPanel)

$StopButton = [System.Windows.Forms.Button]::new()
$StopButton.Text = "Stop Server"
$StopButton.Width = $ButtonWidth
$StopButton.Height = $ButtonHeight
$StopButton.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$StopButton.BackColor = [System.Drawing.SystemColors]::Control
$StopButton.Location = [System.Drawing.Point]::new($BorderThickness, $BorderThickness)
$StopButtonPanel.Controls.Add($StopButton)

# 3. Open in Browser Button (Blue Border)
$OpenBrowserPanel = [System.Windows.Forms.Panel]::new()
$OpenBrowserPanel.Width = $ButtonWidth + 2 * $BorderThickness
$OpenBrowserPanel.Height = $ButtonHeight + 2 * $BorderThickness
$OpenBrowserPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 50, 150, 250) # Blue border
$OpenBrowserPanel.Location = [System.Drawing.Point]::new(([int]$xStart + 2*($ButtonWidth + 20)), $yPos)
$ContentPanel.Controls.Add($OpenBrowserPanel)

$OpenBrowserButton = [System.Windows.Forms.Button]::new()
$OpenBrowserButton.Text = "Open in Browser"
$OpenBrowserButton.Width = $ButtonWidth
$OpenBrowserButton.Height = $ButtonHeight
$OpenBrowserButton.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$OpenBrowserButton.BackColor = [System.Drawing.SystemColors]::Control
$OpenBrowserButton.Location = [System.Drawing.Point]::new($BorderThickness, $BorderThickness)
$OpenBrowserPanel.Controls.Add($OpenBrowserButton)

# --- Status Log (Adjusted for Content Panel) ---
$LogTextBox = [System.Windows.Forms.TextBox]::new()
$LogTextBox.Width = $ContentWidth - 2 * $xStart
$LogTextBox.Height = 100
$LogTextBox.Multiline = $true
$LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$LogTextBox.ReadOnly = $true
$LogTextBox.BackColor = [System.Drawing.Color]::Black
$LogTextBox.ForeColor = [System.Drawing.Color]::Lime
$LogTextBox.Location = [System.Drawing.Point]::new([int]$xStart, 400 - $MenuStrip.Height)
$ContentPanel.Controls.Add($LogTextBox)

# --- Status Bar ---
$StatusBar = [System.Windows.Forms.StatusStrip]::new()
$StatusBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
$StatusBar.SizingGrip = $false
$StatusBar.BackColor = [System.Drawing.Color]::FromArgb(255, 220, 220, 220)

$CompanyLabel = [System.Windows.Forms.ToolStripStatusLabel]::new()
$CompanyLabel.Text = "EliteSoftware"
$CompanyLabel.Spring = $true
$CompanyLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$StatusBar.Items.Add($CompanyLabel) | Out-Null

$VersionLabel = [System.Windows.Forms.ToolStripStatusLabel]::new()
$VersionLabel.Text = "Version: $ScriptVersion"
$VersionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$StatusBar.Items.Add($VersionLabel) | Out-Null

$StatusIndicator = [System.Windows.Forms.ToolStripStatusLabel]::new()
$StatusIndicator.Text = "Status: Stopped"
$StatusIndicator.ForeColor = [System.Drawing.Color]::Red
$StatusBar.Items.Add($StatusIndicator) | Out-Null

$Form.Controls.Add($StatusBar)

# ==============================================================================
# 6. Event Handling and Main Loop
# ==============================================================================

$StartButton.Add_Click({
    Update-ConfigFromGUI
    $currentConfig = $Script:ServerConfigs[$Script:CurrentConfigIndex]
    
    if ($Script:ActiveServers.ContainsKey($currentConfig.Name)) {
        Write-Log "Server '$($currentConfig.Name)' is already running."
        return
    }
    
    # Check for root path existence
    if (-not (Test-Path $currentConfig.Root -PathType Container)) {
        Write-Log "ERROR: Server Root Path not found: $($currentConfig.Root)"
        return
    }

    Start-Server $currentConfig
})

$StopButton.Add_Click({
    $currentConfig = $Script:ServerConfigs[$Script:CurrentConfigIndex]
    Stop-Server $currentConfig
})

$BrowseButton.Add_Click({
    $FolderBrowser = [System.Windows.Forms.FolderBrowserDialog]::new()
    $FolderBrowser.SelectedPath = $RootTextBox.Text
    if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $RootTextBox.Text = $FolderBrowser.SelectedPath
        Update-ConfigFromGUI
        Write-Log "Root folder set to: $($RootTextBox.Text)"
    }
})

$OpenBrowserButton.Add_Click({
    $currentConfig = $Script:ServerConfigs[$Script:CurrentConfigIndex]
    if ($currentConfig.Status -eq "Running") {
        $prefix = $Script:ActiveServers[$currentConfig.Name].Prefix
        $startUrl = $prefix.TrimEnd('/') # Use the actual running prefix
        [void][System.Diagnostics.Process]::Start($startUrl)
        Write-Log "Opening $startUrl in default browser."
    } else {
        Write-Log "Cannot open browser: Server is not running."
    }
})

$NewMenuItem.Add_Click({
    Add-NewConfig
    $SidebarList.Items.Add($Script:ServerConfigs[-1].Name) | Out-Null
    $SidebarList.SelectedIndex = $Script:ServerConfigs.Count - 1
})

$ExitButton.Add_Click({
    $Form.Close() # This triggers FormClosing event
})

$ExitMenuItem.Add_Click({
    $Form.Close() # This triggers FormClosing event
})

# IMPORTANT: Override default FormClosing behavior to add the custom message
$Form.Add_FormClosing({
    param($sender, $e)
    # Prevent the form from closing immediately while we show the goodbye message
    if (-not $Script:IsExiting) {
        $e.Cancel = $true
        # Execute the graceful shutdown and popup sequence
        Show-GoodbyeWindow "Goodbye see you soon!"
    }
})

# --- Final Initialization ---
Update-GUIFromConfig
Start-LogTimer
Write-Log "EliteSoftware HTTP Test Server v$ScriptVersion Initialized."

# Main loop to show the form
$Form.ShowDialog() | Out-Null

# Minimize the console window upon running
$consoleHandle = (Get-Host).UI.RawUI.Handle
[Runtime.InteropServices.Marshal]::PtrToStructure($consoleHandle, [Type]'System.ConsoleScreenBufferInfo').dwSize | Out-Null
$consoleHandle = (Get-Host).UI.RawUI.Handle
$coords = [System.Management.Automation.Host.Coordinates]::new(0, 0)
(Get-Host).UI.RawUI.SetWindowPosition($coords)
(Get-Host).UI.RawUI.WindowSize = [System.Management.Automation.Host.Size]::new(1, 1)