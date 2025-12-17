<#
.SYNOPSIS
    Elite Network & Web Administration Suite - v4.1.0.0
    Created by: Zachary Whiteman & Google Gemini
    Date: 8/12/2025 - 5:12 AM

.DESCRIPTION
    The definitive all-in-one GUI utility for local development and network management. This script synthesizes
    several powerful tools into a single, cohesive, and feature-rich application.

    Core Functionalities:
    - Dashboard: An at-a-glance overview of all running services and system IP information.
    - Multi-Server Management:
        - Web Servers: Run multiple local web servers with options for Basic Authentication, custom 404 pages, HTTPS/SSL, and binding to specific IP addresses.
        - FTP Servers: Create and manage local FTP servers for file transfers.
        - Proxy Servers: Run simple TCP forwarding proxies.
        - Email (SMTP) Sink: A local SMTP server to catch, log, and save all outgoing test emails.
    - Certificate Authority:
        - Create a self-signed Root Certificate Authority (CA).
        - Issue server certificates signed by your local Root CA for seamless browser trust.
        - Install the Root CA to the system's trusted stores.
    - Hosts File Management:
        - A dedicated GUI to easily view, add, update, and remove entries from the Windows hosts file.
    - Network Tools:
        - A utility tab with Ping, Traceroute, and Port Scan tools to diagnose network issues, as well as hotspot and bridging management.
    - System Integration:
        - Minimizes to the system tray for unobtrusive background operation.
        - Persists all server configurations and UI settings between sessions.
        - Includes a helper to create/delete a Scheduled Task for auto-starting servers on login.

.NOTES
    Requires:
    - PowerShell 5.1 or higher, .NET Framework 4.5 or higher.
    - Python 3.x installed and added to the system's PATH.
    - The 'pyftpdlib' Python library for the FTP Server (`pip install pyftpdlib`).

    This script must be run with Administrator privileges. It includes a self-elevation mechanism.
#>

#region --- Script Parameters and Initial Setup ---
param(
    [switch]$ScheduledRun
)

$appDataPath = "$env:APPDATA\EliteSoftware\WebAppDevelopmentSuite"
if (-not (Test-Path $appDataPath)) { New-Item -Path $appDataPath -ItemType Directory -Force | Out-Null }
$configFilePath = Join-Path $appDataPath "EliteSuiteConfig.json"
$uiStateConfigPath = Join-Path $appDataPath "uistate.json"
$hostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"
#endregion

#region --- Admin Rights Check and Self-Elevation ---
function Test-IsAdmin {
    try {
        return ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

if (-not (Test-IsAdmin)) {
    try {
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
        if ($ScheduledRun.IsPresent) { $arguments += "-ScheduledRun" }
        Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
        exit
    }
    catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Failed to relaunch with administrator privileges: $_", "Error", "OK", "Error")
        exit
    }
}
#endregion

#region --- Dependency Checks (Python & Libraries) ---
try {
    $null = python.exe --version 2>&1
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Python 3.x is required for the server backends but was not found in your system's PATH.`nPlease install Python and ensure it's added to your PATH.", "Dependency Missing: Python", "OK", "Error")
    exit
}

try {
    python.exe -c "import pyftpdlib" 2>&1 | Out-Null
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    $result = [System.Windows.Forms.MessageBox]::Show("The Python library 'pyftpdlib' is required for the FTP Server feature but was not found.`n`nWould you like to attempt to install it now? (Requires pip)", "Dependency Missing: pyftpdlib", "YesNo", "Question")
    if ($result -eq 'Yes') {
        try {
            pip install pyftpdlib
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            exit
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to install 'pyftpdlib'. Please install it manually by running: pip install pyftpdlib", "Installation Failed", "OK", "Error")
            exit
        }
    }
}
#endregion

#region --- Embedded Python Backend Scripts ---
$scriptDir = $PSScriptRoot
$pythonScripts = @{
    "web_server_backend.py" = @'
import http.server, socketserver, ssl, sys, os
class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.directory = os.environ.get('WEB_ROOT', os.getcwd())
        super().__init__(*args, directory=self.directory, **kwargs)
    def send_error(self, code, message=None):
        if code == 404:
            custom_404_path = os.environ.get('CUSTOM_404_PAGE')
            if custom_404_path and os.path.exists(custom_404_path):
                try:
                    with open(custom_404_path, 'rb') as f:
                        self.send_response(404); self.send_header("Content-type", "text/html"); self.end_headers(); self.wfile.write(f.read())
                    return
                except Exception as e: print(f"Error serving custom 404 page: {e}")
        super().send_error(code, message)
if __name__ == "__main__":
    BIND_IP, PORT, WEB_ROOT, USE_SSL = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4].lower() == 'true'
    os.environ['WEB_ROOT'] = WEB_ROOT
    if len(sys.argv) > 7 and sys.argv[7] != 'none': os.environ['CUSTOM_404_PAGE'] = sys.argv[7]
    os.chdir(WEB_ROOT)
    httpd = socketserver.TCPServer((BIND_IP, PORT), CustomHTTPRequestHandler)
    if USE_SSL:
        CERT_PATH, KEY_PATH = sys.argv[5], sys.argv[6]
        try:
            httpd.socket = ssl.wrap_socket(httpd.socket, server_side=True, certfile=CERT_PATH, keyfile=KEY_PATH, ssl_version=ssl.PROTOCOL_TLS)
            print(f"Serving HTTPS on {BIND_IP}:{PORT}")
        except Exception as e: print(f"Failed to start HTTPS server: {e}"); sys.exit(1)
    else: print(f"Serving HTTP on {BIND_IP}:{PORT}")
    httpd.serve_forever()
'@
    "auth_web_server_backend.py" = @'
import http.server, socketserver, ssl, sys, os, base64
class AuthHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.directory = os.environ.get('WEB_ROOT', os.getcwd())
        self.key = os.environ.get('AUTH_KEY', '')
        super().__init__(*args, directory=self.directory, **kwargs)
    def do_HEAD(self): self.send_response(200); self.send_header('Content-type', 'text/html'); self.end_headers()
    def do_AUTHHEAD(self): self.send_response(401); self.send_header('WWW-Authenticate', 'Basic realm=\"Login Required\"'); self.send_header('Content-type', 'text/html'); self.end_headers()
    def do_GET(self):
        if self.headers.get('Authorization') is None: self.do_AUTHHEAD(); self.wfile.write(b'Login Required'); return
        if self.headers.get('Authorization') == 'Basic ' + self.key: super().do_GET(); return
        self.do_AUTHHEAD(); self.wfile.write(b'Invalid Credentials')
    def send_error(self, code, message=None):
        if code == 404:
            custom_404_path = os.environ.get('CUSTOM_404_PAGE')
            if custom_404_path and os.path.exists(custom_404_path):
                try:
                    with open(custom_404_path, 'rb') as f:
                        self.send_response(404); self.send_header("Content-type", "text/html"); self.end_headers(); self.wfile.write(f.read())
                    return
                except Exception as e: print(f"Error serving custom 404 page: {e}")
        super().send_error(code, message)
if __name__ == "__main__":
    BIND_IP, PORT, WEB_ROOT, USE_SSL, USER, PASS = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4].lower() == 'true', sys.argv[7], sys.argv[8]
    os.environ['WEB_ROOT'] = WEB_ROOT
    os.environ['AUTH_KEY'] = base64.b64encode(f"{USER}:{PASS}".encode()).decode()
    os.chdir(WEB_ROOT)
    httpd = socketserver.TCPServer((BIND_IP, PORT), AuthHTTPRequestHandler)
    if USE_SSL:
        CERT_PATH, KEY_PATH = sys.argv[5], sys.argv[6]
        try:
            httpd.socket = ssl.wrap_socket(httpd.socket, server_side=True, certfile=CERT_PATH, keyfile=KEY_PATH, ssl_version=ssl.PROTOCOL_TLS)
            print(f"Serving Authenticated HTTPS on {BIND_IP}:{PORT}")
        except Exception as e: print(f"Failed to start HTTPS server: {e}"); sys.exit(1)
    else: print(f"Serving Authenticated HTTP on {BIND_IP}:{PORT}")
    httpd.serve_forever()
'@
    "ftp_server_backend.py" = @'
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
import sys
if __name__ == "__main__":
    BIND_IP, PORT, USER, PASS, FTP_ROOT = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5]
    authorizer = DummyAuthorizer()
    authorizer.add_user(USER, PASS, FTP_ROOT, perm='elradfmw')
    handler = FTPHandler
    handler.authorizer = authorizer
    handler.banner = "Elite Local FTP Server Ready."
    server = FTPServer((BIND_IP, PORT), handler)
    print(f"Starting FTP server for user '{USER}' on {BIND_IP}:{PORT} at path '{FTP_ROOT}'")
    server.serve_forever()
'@
    "email_server_backend.py" = @'
import smtpd, asyncore, sys, datetime, os, time
class EliteMailSink(smtpd.SMTPServer):
    def __init__(self, localaddr, remoteaddr, save_dir):
        super().__init__(localaddr, remoteaddr)
        self.save_dir = save_dir
        if self.save_dir and not os.path.exists(self.save_dir):
            os.makedirs(self.save_dir)

    def process_message(self, peer, mailfrom, rcpttos, data, **kwargs):
        timestamp = datetime.datetime.now()
        log_message = (f"--- New Email Received at {timestamp} ---\n"
                       f"From: {mailfrom}\n"
                       f"To: {', '.join(rcpttos)}\n"
                       f"Peer: {peer}\n"
                       f"-- Message Body --\n")
        print(log_message)
        sys.stdout.flush()
        
        try:
            decoded_data = data.decode('utf-8', errors='replace')
            print(decoded_data)
        except Exception as e:
            print(f"Could not decode message: {e}")
        
        print("--- End of Email ---\n")
        sys.stdout.flush()

        if self.save_dir:
            try:
                filename = f"{timestamp.strftime('%Y-%m-%d_%H-%M-%S')}_{mailfrom.replace('/', '_').replace(':', '_')}.eml"
                filepath = os.path.join(self.save_dir, filename)
                with open(filepath, 'wb') as f:
                    f.write(data)
                print(f"Email saved to {filepath}\n")
                sys.stdout.flush()
            except Exception as e:
                print(f"Failed to save email to file: {e}\n")
                sys.stdout.flush()

if __name__ == "__main__":
    BIND_IP, PORT = sys.argv[1], int(sys.argv[2])
    SAVE_DIR = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != 'none' else None
    server = EliteMailSink((BIND_IP, PORT), None, SAVE_DIR)
    print(f"Elite Mail Sink started on {BIND_IP}:{PORT}. Waiting for emails...")
    sys.stdout.flush()
    asyncore.loop()
'@
    "proxy_server_backend.py" = @'
import socket, sys, threading
def handle_client(client_socket, target_host, target_port):
    target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        target_socket.connect((target_host, target_port))
    except Exception as e:
        print(f"Proxy: Unable to connect to {target_host}:{target_port} - {e}")
        client_socket.close()
        return

    def forward(src, dst):
        try:
            while True:
                data = src.recv(4096)
                if not data: break
                dst.sendall(data)
        except:
            pass
        finally:
            src.close()
            dst.close()

    threading.Thread(target=forward, args=(client_socket, target_socket)).start()
    threading.Thread(target=forward, args=(target_socket, client_socket)).start()

if __name__ == "__main__":
    BIND_IP, LISTEN_PORT = sys.argv[1], int(sys.argv[2])
    TARGET_HOST = sys.argv[3]
    TARGET_PORT = int(sys.argv[4])
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((BIND_IP, LISTEN_PORT))
    server.listen(5)
    print(f"Proxy server listening on {BIND_IP}:{LISTEN_PORT}, forwarding to {TARGET_HOST}:{TARGET_PORT}")
    
    while True:
        client_sock, addr = server.accept()
        print(f"Proxy: Accepted connection from {addr[0]}:{addr[1]}")
        thread = threading.Thread(target=handle_client, args=(client_sock, TARGET_HOST, TARGET_PORT))
        thread.start()
'@
}

# Overwrite Python scripts on every launch to ensure they are correct.
$pythonScripts.GetEnumerator() | ForEach-Object {
    $scriptPath = Join-Path $scriptDir $_.Key
    $_.Value | Out-File -FilePath $scriptPath -Encoding utf8 -Force
}
#endregion

#region --- Scheduled Task Mode ---
if ($ScheduledRun.IsPresent) {
    # Headless operation mode for scheduled tasks
    Write-Host "Running in scheduled task mode..."
    
    # Load configuration
    $serverConfigPath = Join-Path $appDataPath "servers.json"
    if (Test-Path $serverConfigPath) {
        try {
            $servers = Get-Content $serverConfigPath -Raw | ConvertFrom-Json -AsHashtable
            if ($servers.Values) {
                Write-Host "Checking for servers to auto-start..."
                foreach ($server in $servers.Values | Where-Object { $_.IsRunning -eq $true }) {
                    Write-Host "Starting server for $($server.Hostname)..."
                    Start-WebServer -server $server # Assume Start-WebServer exists and is self-contained
                }
            }
        } catch {
            Write-Error "Could not load or parse server config file: $_"
        }
    }
    
    Write-Host "Scheduled startup complete."
    exit
}
#endregion

#region --- GUI Setup and Global Variables ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net
# Enable native Windows UI styling. This is crucial for theming.
[System.Windows.Forms.Application]::EnableVisualStyles()

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Elite Network & Web Administration Suite v4.1.0.0"
$mainForm.Size = New-Object System.Drawing.Size(1200, 800)
$mainForm.MinimumSize = New-Object System.Drawing.Size(1000, 700)
$mainForm.StartPosition = "CenterScreen"
try { $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell.exe).Path) } catch {}

# --- Global Variables & State ---
$Global:Config = [pscustomobject]@{
    WebServers     = @{}
    FtpServers     = @{}
    ProxyServers   = @{}
    EmailServer    = @{}
    GlobalSettings = @{ Custom404Page = ""; AutoStart = $true; KeepConsoleOpen = $false }
}
$Global:Jobs = [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]::new()
$Global:KeepConsoleOpen = $false
$Global:forceExit = $false
$Global:rootCACert = $null
$Global:serverCert = $null
$Global:emailServerProcess = $null
$emailStoragePath = Join-Path $PSScriptRoot "My Saved Emails"
if (-not (Test-Path $emailStoragePath)) { New-Item -Path $emailStoragePath -ItemType Directory | Out-Null }
$webHostingBasePath = Join-Path $PSScriptRoot "My Local Web Pages"
if (-not (Test-Path $webHostingBasePath)) { New-Item -Path $webHostingBasePath -ItemType Directory | Out-Null }


# --- System Tray Icon ---
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = $mainForm.Icon; $notifyIcon.Text = $mainForm.Text; $notifyIcon.Visible = $false
$trayContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$showTrayMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Show Suite")
$exitTrayMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$trayContextMenu.Items.AddRange(@($showTrayMenuItem, $exitTrayMenuItem))
$notifyIcon.ContextMenuStrip = $trayContextMenu

# --- Main UI Controls ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$tabControl = New-Object System.Windows.Forms.TabControl; $tabControl.Dock = 'Fill'
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel("Initializing...")
$statusStrip.Items.Add($statusLabel) | Out-Null
$toolTip = New-Object System.Windows.Forms.ToolTip
#endregion

#region --- All Helper Functions ---
function Draw-ShadowedText {
    param([System.Drawing.Graphics]$g, [string]$text, [System.Drawing.Font]$font, [System.Drawing.Rectangle]$rect, [System.Drawing.Color]$foreColor, [System.Drawing.StringFormat]$format)
    $shadowOffset = New-Object System.Drawing.Point(1, 1)
    $shadowRect = New-Object System.Drawing.Rectangle(($rect.X + $shadowOffset.X), ($rect.Y + $shadowOffset.Y), $rect.Width, $rect.Height)
    $shadowColor = [System.Drawing.Color]::FromArgb(128, 0, 0, 0)
    $shadowBrush = New-Object System.Drawing.SolidBrush($shadowColor)
    $foreBrush = New-Object System.Drawing.SolidBrush($foreColor)
    $shadowRectF = [System.Drawing.RectangleF]::new($shadowRect.X, $shadowRect.Y, $shadowRect.Width, $shadowRect.Height)
    $rectF = [System.Drawing.RectangleF]::new($rect.X, $rect.Y, $rect.Width, $rect.Height)
    $g.DrawString($text, $font, $shadowBrush, $shadowRectF, $format)
    $g.DrawString($text, $font, $foreBrush, $rectF, $format)
    $shadowBrush.Dispose(); $foreBrush.Dispose()
}

function Set-AeroButtonStyle {
    param([System.Windows.Forms.Button]$button, [System.Drawing.Color]$baseColor, [System.Drawing.Color]$highlightColor)
    $button.FlatStyle = 'Flat'; $button.FlatAppearance.BorderSize = 1; $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 90, 90, 90)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $button.ForeColor = [System.Drawing.Color]::White; $button.Padding = New-Object System.Windows.Forms.Padding(5)
    $button.add_Paint({
        param($sender, $e)
        $g = $e.Graphics; $g.SmoothingMode = 'AntiAlias'; $rect = $sender.ClientRectangle
        $startColor = $baseColor; $endColor = $highlightColor
        if ($sender.Tag -eq "Pressed") { $startColor = $highlightColor; $endColor = $baseColor }
        elseif ($sender.Tag -eq "Hover") { $startColor = [System.Windows.Forms.ControlPaint]::Light($baseColor, 0.2); $endColor = [System.Windows.Forms.ControlPaint]::Light($highlightColor, 0.2) }
        $rectF = [System.Drawing.RectangleF]::new($rect.X, $rect.Y, $rect.Width, $rect.Height)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rectF, $startColor, $endColor, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
        $g.FillRectangle($brush, $rect)
        $brush.Dispose()
        $textFormat = New-Object System.Drawing.StringFormat; $textFormat.Alignment = 'Center'; $textFormat.LineAlignment = 'Center'
        Draw-ShadowedText -g $g -text $sender.Text -font $sender.Font -rect $rect -foreColor $sender.ForeColor -format $textFormat
        $textFormat.Dispose()
    })
    $button.add_MouseEnter({ param($s, $e) $s.Tag = "Hover"; $s.Invalidate() })
    $button.add_MouseLeave({ param($s, $e) $s.Tag = ""; $s.Invalidate() })
    $button.add_MouseDown({ param($s, $e) $s.Tag = "Pressed"; $s.FlatAppearance.BorderColor = [System.Drawing.Color]::Black; $s.Invalidate() })
    $button.add_MouseUp({ param($s, $e) $s.Tag = "Hover"; $s.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 90, 90, 90); $s.Invalidate() })
}

function Load-Config {
    if (Test-Path $configFilePath) {
        try {
            $loadedConfig = Get-Content $configFilePath -Raw | ConvertFrom-Json -AsHashtable
            if ($loadedConfig.WebServers) { $Global:Config.WebServers = $loadedConfig.WebServers }
            if ($loadedConfig.FtpServers) { $Global:Config.FtpServers = $loadedConfig.FtpServers }
            if ($loadedConfig.ProxyServers) { $Global:Config.ProxyServers = $loadedConfig.ProxyServers }
            if ($loadedConfig.EmailServer) { $Global:Config.EmailServer = $loadedConfig.EmailServer }
            if ($loadedConfig.GlobalSettings) { $Global:Config.GlobalSettings = $loadedConfig.GlobalSettings }
        } catch { Write-Warning "Could not load or parse config file. A new one will be created." }
    }
}

function Save-Config {
    # Update global state before saving
    $Global:Config.GlobalSettings.KeepConsoleOpen = $Global:KeepConsoleOpen
    $Global:Config | ConvertTo-Json -Depth 5 | Set-Content -Path $configFilePath -Force
}

function Start-PythonProcess {
    param([string]$ScriptName, [array]$Arguments)
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "python.exe"
    $processInfo.Arguments = ("`"$((Join-Path $scriptDir $ScriptName))`"") + " " + ($Arguments -join " ")
    $processInfo.RedirectStandardOutput = $true; $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false; $processInfo.CreateNoWindow = $true
    return [System.Diagnostics.Process]::Start($processInfo)
}

function Test-PortInUse {
    param([int]$Port)
    try {
        return ($null -ne (Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue))
    } catch { return ($null -ne (netstat -ano | findstr ":$Port")) }
}

function Populate-IPComboBox {
    param([System.Windows.Forms.ComboBox]$comboBox)
    $comboBox.Items.Clear()
    try {
        $adapterLookup = @{}; Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { $adapterLookup[$_.InterfaceIndex] = $_.Name }
        Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $adapterLookup.ContainsKey($_.InterfaceIndex) } | ForEach-Object {
            $comboBox.Items.Add("$($_.IPAddress) ($($adapterLookup[$_.InterfaceIndex]))") | Out-Null
        }
    } catch { Write-Warning "Could not populate IP list: $_" }
    if ($comboBox.Items.Count -gt 0) { $comboBox.SelectedIndex = 0 }
}

function Write-Log {
    param([System.Windows.Forms.TextBox]$logControl, [string]$Message, [string]$Type = "Info")
    if ($logControl) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        if ($logControl.IsHandleCreated) {
            $logControl.BeginInvoke([Action[string]]{ param($text) $logControl.AppendText($text) }, "[$timestamp] [$Type] $Message`r`n")
        }
    }
}

function Load-HostsFile {
    param([System.Windows.Forms.ListView]$listView)
    $listView.Items.Clear()
    try {
        Get-Content $hostsFilePath | ForEach-Object {
            $line = $_.Trim()
            if ($line -and !$line.StartsWith("#")) {
                $parts = $line -split '\s+'; if ($parts.Count -ge 2) {
                    $item = New-Object System.Windows.Forms.ListViewItem($parts[0])
                    $item.SubItems.Add($parts[1..($parts.Count - 1)] -join ' ') | Out-Null
                    $listView.Items.Add($item) | Out-Null
                }
            }
        }
    } catch { $statusLabel.Text = "Error reading hosts file: $($_.Exception.Message)" }
}

function Save-HostsFile {
    param([System.Windows.Forms.ListView]$listView)
    try {
        Copy-Item -Path $hostsFilePath -Destination "$hostsFilePath.bak" -Force
        $originalContent = Get-Content $hostsFilePath
        $commentsAndBlanks = $originalContent | Where-Object { $_.Trim().StartsWith("#") -or $_.Trim() -eq "" }
        $newContent = @($commentsAndBlanks) + ($listView.Items | ForEach-Object { "$($_.SubItems[0].Text)`t$($_.SubItems[1].Text)" })
        Set-Content -Path $hostsFilePath -Value $newContent -Force
        $statusLabel.Text = "Hosts file saved successfully at $(Get-Date -Format T)"
    } catch { $statusLabel.Text = "Error saving hosts file: $($_.Exception.Message)" }
}

# Web Server Functions
function Update-WebSiteListView {
    param([System.Windows.Forms.ListView]$listView)
    $listView.Items.Clear()
    foreach ($siteName in $Global:Config.WebServers.Keys | Sort-Object) {
        $site = $Global:Config.WebServers[$siteName]
        $isRunning = ($site.Process -and -not $site.Process.HasExited)
        $status = if ($isRunning) { "Running" } else { "Stopped" }
        $protocol = if ($site.UseSSL) { "https" } else { "http" }
        $url = "{0}://{1}:{2}" -f $protocol, $site.BindIP, $site.HttpPort
        $authStatus = if ($site.UseAuth) { "Yes" } else { "No" }
        $item = New-Object System.Windows.Forms.ListViewItem($siteName)
        $item.Tag = $siteName
        $item.SubItems.AddRange(@($status, $url, $authStatus, $site.RootPath))
        if ($isRunning) { $item.ForeColor = [System.Drawing.Color]::DarkGreen }
        else { $item.ForeColor = [System.Drawing.Color]::Firebrick }
        $listView.Items.Add($item) | Out-Null
    }
}

function Start-WebServer {
    param([string]$SiteName)
    $site = $Global:Config.WebServers[$SiteName]
    if (!$site) { return }

    $scriptToRun = if ($site.UseAuth) { "auth_web_server_backend.py" } else { "web_server_backend.py" }
    $certPath = if ($site.CertPath) { "'$($site.CertPath)'" } else { "none" }
    $keyPath = if ($site.KeyPath) { "'$($site.KeyPath)'" } else { "none" }
    $custom404 = if ($Global:Config.GlobalSettings.Custom404Page) { "'$($Global:Config.GlobalSettings.Custom404Page)'" } else { "none" }
    $commonArgs = @("'$($site.BindIP)'", $site.HttpPort, "'$($site.RootPath)'", $site.UseSSL.ToString().ToLower(), $certPath, $keyPath)
    $authArgs = if ($site.UseAuth) { @("'$($site.Username)'", "'$($site.Password)'") } else { @($custom404) }
    $arguments = $commonArgs + $authArgs

    try {
        $process = Start-PythonProcess -ScriptName $scriptToRun -Arguments $arguments
        $Global:Config.WebServers[$SiteName].Process = $process
        Save-Config
        # Check if hosts file entry exists, if not, add it
        # ... logic to check and add hosts entry...
        $statusLabel.Text = "Server '$SiteName' started."
    } catch {
        $statusLabel.Text = "Failed to start server '$SiteName'."
        Write-Warning "Failed to start Python web server for '$SiteName': $_"
    }
    Update-WebSiteListView -listView $webSitesListView
}

function Stop-WebServer {
    param([string]$SiteName)
    $site = $Global:Config.WebServers[$SiteName]
    if (!$site -or !$site.Process -or $site.Process.HasExited) { return }
    try { $site.Process.Kill() } catch { Write-Warning "Could not stop process for '$SiteName'." }
    $Global:Config.WebServers[$SiteName].Process = $null
    Save-Config
    # Remove hosts file entry...
    $statusLabel.Text = "Server '$SiteName' stopped."
    Update-WebSiteListView -listView $webSitesListView
}

# FTP Server Functions
function Update-FtpSiteListView {
    param([System.Windows.Forms.ListView]$listView)
    $listView.Items.Clear()
    foreach ($ftpName in $Global:Config.FtpServers.Keys | Sort-Object) {
        $ftpSite = $Global:Config.FtpServers[$ftpName]
        $isRunning = ($ftpSite.Process -and -not $ftpSite.Process.HasExited)
        $status = if ($isRunning) { "Running" } else { "Stopped" }
        $address = "ftp://127.0.0.1:$($ftpSite.Port)"
        $item = New-Object System.Windows.Forms.ListViewItem($ftpName)
        $item.Tag = $ftpName
        $item.SubItems.AddRange(@($status, $address, $ftpSite.Username, $ftpSite.Path))
        if ($isRunning) { $item.ForeColor = [System.Drawing.Color]::DarkGreen } else { $item.ForeColor = [System.Drawing.Color]::Firebrick }
        $listView.Items.Add($item) | Out-Null
    }
}

function Start-FtpServer {
    param([string]$FtpName)
    $ftpSite = $Global:Config.FtpServers[$FtpName]
    if (!$ftpSite) { return }
    if(Test-PortInUse -Port $ftpSite.Port) { [System.Windows.Forms.MessageBox]::Show("Port $($ftpSite.Port) is already in use by another application. Please choose a different port.", "Port Conflict", "OK", "Error"); return }

    $arguments = @("'$($ftpSite.BindIP)'", $ftpSite.Port, "'$($ftpSite.Username)'", "'$($ftpSite.Password)'", "'$($ftpSite.Path)'")
    try {
        $process = Start-PythonProcess -ScriptName "ftp_server_backend.py" -Arguments $arguments
        $Global:Config.FtpServers[$FtpName].Process = $process
        Save-Config
        $statusLabel.Text = "FTP Server '$FtpName' started."
    } catch { 
        $statusLabel.Text = "Failed to start FTP Server '$FtpName'."
        Write-Warning "Failed to start Python FTP server for '$FtpName': $_"
    }
    Update-FtpSiteListView -listView $ftpSitesListView
}

function Stop-FtpServer {
    param([string]$FtpName)
    $ftpSite = $Global:Config.FtpServers[$FtpName]
    if (!$ftpSite -or !$ftpSite.Process -or $ftpSite.Process.HasExited) { return }
    try { $ftpSite.Process.Kill() } catch { Write-Warning "Could not stop process for '$FtpName'." }
    $Global:Config.FtpServers[$FtpName].Process = $null
    Save-Config
    $statusLabel.Text = "FTP Server '$FtpName' stopped."
    Update-FtpSiteListView -listView $ftpSitesListView
}

# Proxy Server Functions
function Update-ProxyServerListView {
    param([System.Windows.Forms.ListView]$listView)
    $listView.Items.Clear()
    foreach ($proxyName in $Global:Config.ProxyServers.Keys | Sort-Object) {
        $proxy = $Global:Config.ProxyServers[$proxyName]
        $isRunning = ($proxy.Process -and -not $proxy.Process.HasExited)
        $status = if ($isRunning) { "Running" } else { "Stopped" }
        $listening = "tcp://$($proxy.BindIP):$($proxy.ListenPort)"
        $forwarding = "tcp://$($proxy.TargetHost):$($proxy.TargetPort)"
        $item = New-Object System.Windows.Forms.ListViewItem($proxyName)
        $item.Tag = $proxyName
        $item.SubItems.AddRange(@($status, $listening, $forwarding))
        if ($isRunning) { $item.ForeColor = [System.Drawing.Color]::DarkGreen } else { $item.ForeColor = [System.Drawing.Color]::Firebrick }
        $listView.Items.Add($item) | Out-Null
    }
}

function Start-ProxyServer {
    param([string]$ProxyName)
    $proxy = $Global:Config.ProxyServers[$ProxyName]
    if (!$proxy) { return }
    if(Test-PortInUse -Port $proxy.ListenPort) { [System.Windows.Forms.MessageBox]::Show("Listen Port $($proxy.ListenPort) is already in use by another application. Please choose a different port.", "Port Conflict", "OK", "Error"); return }

    $arguments = @("'$($proxy.BindIP)'", $proxy.ListenPort, "'$($proxy.TargetHost)'", $proxy.TargetPort)
    try {
        $process = Start-PythonProcess -ScriptName "proxy_server_backend.py" -Arguments $arguments
        $Global:Config.ProxyServers[$ProxyName].Process = $process
        Save-Config
        $statusLabel.Text = "Proxy Server '$ProxyName' started."
    } catch {
        $statusLabel.Text = "Failed to start Proxy Server '$ProxyName'."
        Write-Warning "Failed to start Python Proxy server for '$ProxyName': $_"
    }
    Update-ProxyServerListView -listView $proxyServersListView
}

function Stop-ProxyServer {
    param([string]$ProxyName)
    $proxy = $Global:Config.ProxyServers[$ProxyName]
    if (!$proxy -or !$proxy.Process -or $proxy.Process.HasExited) { return }
    try { $proxy.Process.Kill() } catch { Write-Warning "Could not stop process for '$ProxyName'." }
    $Global:Config.ProxyServers[$ProxyName].Process = $null
    Save-Config
    $statusLabel.Text = "Proxy Server '$ProxyName' stopped."
    Update-ProxyServerListView -listView $proxyServersListView
}

# Email Server Functions
function Update-EmailServerStatus {
    if ($Global:Config.EmailServer.Process -and -not $Global:Config.EmailServer.Process.HasExited) {
        $lblEmailStatus.Text = "Status: Running on Port $($Global:Config.EmailServer.Port)"
        $lblEmailStatus.ForeColor = [System.Drawing.Color]::DarkGreen
        $btnStartStopEmail.Text = "Stop Mail Sink"
    } else {
        $lblEmailStatus.Text = "Status: Stopped"
        $lblEmailStatus.ForeColor = [System.Drawing.Color]::Firebrick
        $btnStartStopEmail.Text = "Start Mail Sink"
    }
}

function Start-EmailServer {
    if ($Global:Config.EmailServer.Process -and -not $Global:Config.EmailServer.Process.HasExited) { return }
    if(Test-PortInUse -Port $Global:Config.EmailServer.Port) { [System.Windows.Forms.MessageBox]::Show("Port $($Global:Config.EmailServer.Port) is already in use by another application. The mail sink cannot be started.", "Port Conflict", "OK", "Error"); return }

    $arguments = @("127.0.0.1", $Global:Config.EmailServer.Port, "'$emailStoragePath'")
    try {
        $process = Start-PythonProcess -ScriptName "email_server_backend.py" -Arguments $arguments
        $Global:Config.EmailServer.Process = $process
        Save-Config
        $statusLabel.Text = "Email Sink started."
        # Register event handler for this specific process
        $null = Register-ObjectEvent -InputObject $process -EventName "OutputDataReceived" -Action $emailDataReceived -SourceIdentifier "EmailOutput"
        $process.BeginOutputReadLine() # Start listening for output
    } catch { 
        $statusLabel.Text = "Failed to start Email Sink."
        Write-Warning "Failed to start Python Email server: $_"
    }
    Update-EmailServerStatus
}

function Stop-EmailServer {
    if (!$Global:Config.EmailServer.Process -or $Global:Config.EmailServer.Process.HasExited) { return }
    try {
        Unregister-Event -SourceIdentifier "EmailOutput" -ErrorAction SilentlyContinue
        $Global:Config.EmailServer.Process.Kill() 
    } catch { Write-Warning "Could not stop email server process." }
    $Global:Config.EmailServer.Process = $null
    Save-Config
    $statusLabel.Text = "Email Sink stopped."
    Update-EmailServerStatus
}

# Certificate Functions
function Write-CertLog { param ([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $certLogBox.AppendText("[$timestamp] [$Type] $Message`r`n")
}

function Load-CertificateForEditing {
    param ([System.Security.Cryptography.X509Certificates.X509Certificate2]$certToLoad)
    Write-CertLog -Message "Loading certificate '$($certToLoad.Subject)' for editing..."; $sanExtension = $certToLoad.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' }; if ($sanExtension) { $formattedData = $sanExtension.Format($true); $dnsNames = ($formattedData -split ', ') | Where-Object { $_ -like 'DNS Name=*' } | ForEach-Object { $_.Replace('DNS Name=', '') }; $textServerDns.Text = $dnsNames -join ', '; Write-CertLog "Loaded DNS Names: $($textServerDns.Text)" } else { $cn = $certToLoad.Subject -replace 'CN=', ''; $textServerDns.Text = $cn; Write-CertLog "Loaded Common Name (no SAN found): $cn" }; $lifespan = $certToLoad.NotAfter - $certToLoad.NotBefore; $years = [math]::Round($lifespan.TotalDays / 365); $numServerYears.Value = [math]::Max(1, $years); Write-CertLog "Loaded validity: $($numServerYears.Value) years."; [System.Windows.Forms.MessageBox]::Show("Certificate details loaded into Step 2 fields.", "Load Complete", "OK", "Information")
}

# Network Tools Functions
function Get-NetworkInfo {
    # Initialize StringBuilder objects for efficient string construction for each tab.
    $ipInfo = New-Object System.Text.StringBuilder
    $dnsInfo = New-Object System.Text.StringBuilder
    $adapterInfo = New-Object System.Text.StringBuilder

    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Sort-Object Description

    foreach ($adapter in $adapters) {
        $adapterName = $adapter.Description
        $ipInfo.AppendLine("--- Adapter: $($adapterName) ---")
        $dnsInfo.AppendLine("--- Adapter: $($adapterName) ---")
        $adapterInfo.AppendLine("--- Adapter: $($adapterName) ---")

        if ($adapter.IPAddress) {
            $ipInfo.AppendLine("  IP Address(es):")
            foreach ($ip in $adapter.IPAddress) { $ipInfo.AppendLine("    $ip") }
        } else { $ipInfo.AppendLine("  No IP Address configured.") }

        if ($adapter.IPSubnet) {
            $ipInfo.AppendLine("  Subnet Mask(s):")
            foreach ($subnet in $adapter.IPSubnet) { $ipInfo.AppendLine("    $subnet") }
        }
        if ($adapter.DefaultIPGateway) {
            $ipInfo.AppendLine("  Default Gateway(s):")
            foreach ($gateway in $adapter.DefaultIPGateway) { $ipInfo.AppendLine("    $gateway") }
        }
        if ($adapter.DHCPEnabled) {
            $ipInfo.AppendLine("  DHCP Enabled: True")
            $ipInfo.AppendLine("  DHCP Server: $($adapter.DHCPServer)")
            $ipInfo.AppendLine("  DHCP Lease Obtained: $($adapter.DHCPLeaseObtained)")
            $ipInfo.AppendLine("  DHCP Lease Expires: $($adapter.DHCPLeaseExpires)")
        } else { $ipInfo.AppendLine("  DHCP Enabled: False") }
        $ipInfo.AppendLine("")

        if ($adapter.DNSServerSearchOrder) {
            $dnsInfo.AppendLine("  DNS Server(s):")
            foreach ($dns in $adapter.DNSServerSearchOrder) { $dnsInfo.AppendLine("    $dns") }
        } else { $dnsInfo.AppendLine("  No DNS Servers configured.") }
        $dnsInfo.AppendLine("")

        $netAdapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
        if ($netAdapter) {
            $adapterInfo.AppendLine("  Description: $($netAdapter.InterfaceDescription)")
            $adapterInfo.AppendLine("  Status: $($netAdapter.Status)")
            $adapterInfo.AppendLine("  MAC Address: $($netAdapter.MacAddress)")
            $adapterInfo.AppendLine("  Link Speed: $($netAdapter.LinkSpeed)")
            $adapterInfo.AppendLine("  Media Connection State: $($netAdapter.MediaConnectionState)")
            $adapterInfo.AppendLine("  Driver Version: $($netAdapter.DriverVersion)")
            $adapterInfo.AppendLine("  Device Name: $($netAdapter.DeviceName)")
            $adapterInfo.AppendLine("  Interface Index: $($netAdapter.InterfaceIndex)")
        } else {
            $adapterInfo.AppendLine("  Description (WMI): $($adapter.Description)")
            $adapterInfo.AppendLine("  MAC Address (WMI): $($adapter.MACAddress)")
            $adapterInfo.AppendLine("  Service Name (WMI): $($adapter.ServiceName)")
            $adapterInfo.AppendLine("  Index (WMI): $($adapter.Index)")
        }
        $adapterInfo.AppendLine("")
    }
    
    $networkInfoTextBox.Text = $ipInfo.ToString()
    $dnsInfoTextBox.Text = $dnsInfo.ToString()
    $adapterDetailsTextBox.Text = $adapterInfo.ToString()
}

function Write-HotspotLog {
    param ([string]$Message, [string]$Type = "Info")
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $logMessage = "[$timestamp] [$Type] $Message"
    $hotspotLogBox.AppendText($logMessage + "`r`n")
    Write-Host $logMessage
}

function Is-ValidIpAddress {
    param ([string]$IPAddress)
    try { [System.Net.IPAddress]::Parse($IPAddress) | Out-Null; return $true } catch { return $false }
}

function Is-ValidSubnetMask {
    param ([string]$SubnetMask)
    return Is-ValidIpAddress -IPAddress $SubnetMask
}

function Test-IPConflict {
    param ([string]$TargetIP)
    Write-HotspotLog -Message "Testing for IP conflict for $TargetIP..." -Type "Info"
    try {
        $pingResult = Test-Connection -ComputerName $TargetIP -Count 1 -ErrorAction SilentlyContinue
        if ($pingResult) { Write-HotspotLog -Message "IP conflict detected: $TargetIP is already in use by $($pingResult.IPV4Address)." -Type "Error"; return $true }
        $localIPs = Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
        if ($localIPs -contains $TargetIP) { Write-HotspotLog -Message "IP conflict detected: $TargetIP is already assigned to a local adapter." -Type "Error"; return $true }
        return $false
    } catch {
        Write-HotspotLog -Message "Error during IP conflict detection: $($_.Exception.Message)" -Type "Error"
        return $false
    }
}
function Get-NetworkAdapters {
    $adapterListBox.Items.Clear()
    Write-HotspotLog -Message "Discovering network adapters..."
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceType -ne "Loopback" -and $_.Name -notlike "vEthernet*" -and $_.MacAddress -ne "" }
        if ($adapters.Count -gt 0) {
            foreach ($adapter in $adapters) {
                $ipInfo = (Get-NetIPAddress -InterfaceIndex $adapter.IfIndex -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) -join ", "
                if (-not $ipInfo) { $ipInfo = "No IP" }
                $adapterListBox.Items.Add("$($adapter.Name) ($($adapter.InterfaceDescription)) [IP: $ipInfo]")
            }
            Write-HotspotLog -Message "Found $($adapters.Count) network adapters."
        } else { Write-HotspotLog -Message "No active network adapters found for bridging." -Type "Warning" }
    } catch { Write-HotspotLog -Message "Error getting network adapters: $($_.Exception.Message)" -Type "Error" }
}

function Start-MyHotspot {
    $ssid = $hotspotSsidTextBox.Text.Trim()
    $password = $hotspotPasswordTextBox.Text.Trim()
    if ([string]::IsNullOrEmpty($ssid) -or [string]::IsNullOrEmpty($password)) { [System.Windows.Forms.MessageBox]::Show("SSID and Password cannot be empty.", "Input Error", "OK", "Warning"); Write-HotspotLog -Message "Hotspot start failed: SSID or Password missing." -Type "Warning"; return }
    if ($password.Length -lt 8) { [System.Windows.Forms.MessageBox]::Show("Password must be at least 8 characters long.", "Input Error", "OK", "Warning"); Write-HotspotLog -Message "Hotspot start failed: Password too short." -Type "Warning"; return }
    Write-HotspotLog -Message "Attempting to start mobile hotspot with SSID: '$ssid'..."
    try {
        netsh wlan set hostednetwork mode=allow ssid="$ssid" key="$password" keyUsage=persistent | Out-Null
        netsh wlan start hostednetwork | Out-Null
        Start-Sleep -Seconds 2
        $hotspotAdapter = Get-NetAdapter | Where-Object { $_.Name -like "Wi-Fi Direct Virtual Adapter*" -and $_.Status -eq "Up" } | Select-Object -First 1
        if ($hotspotAdapter) {
            $Global:hotspotAdapterName = $hotspotAdapter.Name; $Global:hotspotAdapterInterfaceAlias = $hotspotAdapter.InterfaceAlias
            Write-HotspotLog -Message "Mobile hotspot '$ssid' started successfully on adapter '$hotspotAdapterInterfaceAlias'." -Type "Info"
            $startHotspotButton.Enabled = $false; $stopHotspotButton.Enabled = $true; $bridgeSelectedButton.Enabled = $true
            Get-NetworkAdapters
        } else { Write-HotspotLog -Message "Failed to find the Wi-Fi Direct Virtual Adapter after starting hotspot." -Type "Error"; [System.Windows.Forms.MessageBox]::Show("Failed to start hotspot or find its adapter.", "Hotspot Error", "OK", "Error") }
    } catch { Write-HotspotLog -Message "Error starting hotspot: $($_.Exception.Message)" -Type "Error"; [System.Windows.Forms.MessageBox]::Show("An error occurred while starting the hotspot. Check logs.", "Hotspot Error", "OK", "Error") }
}

function Stop-MyHotspot {
    Write-HotspotLog -Message "Attempting to stop mobile hotspot..."
    try {
        netsh wlan stop hostednetwork | Out-Null
        $icsAdapters = Get-NetConnectionShare -ErrorAction SilentlyContinue | Where-Object { $_.SharingEnabled }
        foreach ($icsAdapter in $icsAdapters) { Set-NetConnectionShare -Name $icsAdapter.Name -SharingEnabled $false -ErrorAction SilentlyContinue }
        Remove-NetworkBridge
        $Global:hotspotAdapterName = ""; $Global:hotspotAdapterInterfaceAlias = ""
        Write-HotspotLog -Message "Mobile hotspot stopped successfully and ICS/bridge disabled." -Type "Info"
        $startHotspotButton.Enabled = $true; $stopHotspotButton.Enabled = $false; $bridgeSelectedButton.Enabled = $false; $unbridgeAllButton.Enabled = $false; $applyIPSettingsButton.Enabled = $false
        Get-NetworkAdapters
    } catch { Write-HotspotLog -Message "Error stopping hotspot: $($_.Exception.Message)" -Type "Error"; [System.Windows.Forms.MessageBox]::Show("An error occurred while stopping the hotspot. Check logs.", "Hotspot Error", "OK", "Error") }
}

function Create-NetworkBridge {
    if ([string]::IsNullOrEmpty($Global:hotspotAdapterName)) { [System.Windows.Forms.MessageBox]::Show("Please start the mobile hotspot first.", "Error", "OK", "Warning"); Write-HotspotLog -Message "Bridge creation failed: Hotspot not active." -Type "Warning"; return }
    if ($adapterListBox.SelectedItem -eq $null) { [System.Windows.Forms.MessageBox]::Show("Please select a network adapter to bridge.", "Error", "OK", "Warning"); Write-HotspotLog -Message "Bridge creation failed: No adapter selected." -Type "Warning"; return }
    $selectedAdapterText = $adapterListBox.SelectedItem.ToString(); $selectedAdapterName = ($selectedAdapterText -split '\(')[0].Trim()
    $Global:selectedNetworkAdapter = Get-NetAdapter -Name $selectedAdapterName -ErrorAction SilentlyContinue
    if (-not $Global:selectedNetworkAdapter) { [System.Windows.Forms.MessageBox]::Show("Could not find the selected network adapter. Please refresh and try again.", "Error", "OK", "Error"); Write-HotspotLog -Message "Bridge creation failed: Selected adapter '$selectedAdapterName' not found." -Type "Error"; return }
    Write-HotspotLog -Message "Attempting to create network bridge between '$($Global:hotspotAdapterName)' and '$($Global:selectedNetworkAdapter.Name)'..."
    try {
        Remove-NetworkBridge
        $hotspotAdapter = Get-NetAdapter -Name $Global:hotspotAdapterName -ErrorAction Stop
        $targetAdapter = Get-NetAdapter -Name $Global:selectedNetworkAdapter.Name -ErrorAction Stop
        Write-HotspotLog -Message "Disabling adapters '$($hotspotAdapter.Name)' and '$($targetAdapter.Name)' temporarily..."
        Disable-NetAdapter -Name $hotspotAdapter.Name -Confirm:$false -ErrorAction Stop
        Disable-NetAdapter -Name $targetAdapter.Name -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 1
        Write-HotspotLog -Message "Creating new network bridge..."
        $newBridge = New-NetLbfoTeam -Name "MyCustomHotspotBridge" -TeamMembers $hotspotAdapter.Name,$targetAdapter.Name -Confirm:$false -ErrorAction Stop
        $Global:activeBridgeName = $newBridge.Name
        Write-HotspotLog -Message "Network bridge '$($Global:activeBridgeName)' created successfully." -Type "Info"
        Write-HotspotLog -Message "Re-enabling adapters..."
        Enable-NetAdapter -Name $hotspotAdapter.Name -Confirm:$false -ErrorAction Stop
        Enable-NetAdapter -Name $targetAdapter.Name -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        $bridgeSelectedButton.Enabled = $false; $unbridgeAllButton.Enabled = $true; $applyIPSettingsButton.Enabled = $true
    } catch {
        Write-HotspotLog -Message "Error creating network bridge: $($_.Exception.Message)" -Type "Error"
        [System.Windows.Forms.MessageBox]::Show("An error occurred while creating the network bridge. Check logs.", "Bridge Error", "OK", "Error")
    }
}

function Remove-NetworkBridge {
    Write-HotspotLog -Message "Attempting to remove any existing network bridges..."
    try {
        $existingBridges = Get-NetLbfoTeam -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "MyCustomHotspotBridge*" }
        if ($existingBridges) {
            foreach ($bridge in $existingBridges) {
                Write-HotspotLog -Message "Removing bridge '$($bridge.Name)'..."
                Remove-NetLbfoTeam -Name $bridge.Name -Confirm:$false -ErrorAction Stop
                $Global:activeBridgeName = ""
                Write-HotspotLog -Message "Bridge '$($bridge.Name)' removed successfully." -Type "Info"
            }
        } else { Write-HotspotLog -Message "No active network bridges found to remove." -Type "Info" }
        $potentialAdapters = @($Global:hotspotAdapterName, $Global:selectedNetworkAdapter.Name) | Where-Object { $_ } | Select-Object -Unique
        foreach ($adapterName in $potentialAdapters) { try { $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue; if ($adapter -and $adapter.Status -eq "Disabled") { Write-HotspotLog -Message "Re-enabling adapter '$($adapter.Name)'..."; Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue } } catch { Write-HotspotLog -Message "Could not re-enable adapter '$adapterName': $($_.Exception.Message)" -Type "Warning" } }
        $unbridgeAllButton.Enabled = $false; $applyIPSettingsButton.Enabled = $false
        if (-not [string]::IsNullOrEmpty($Global:hotspotAdapterName)) { $bridgeSelectedButton.Enabled = $true }
        Get-NetworkAdapters
    } catch { Write-HotspotLog -Message "Error removing network bridge: $($_.Exception.Message)" -Type "Error"; [System.Windows.Forms.MessageBox]::Show("An error occurred while removing the network bridge. Check logs.", "Bridge Error", "OK", "Error") }
}

function Set-IPConfiguration {
    if ([string]::IsNullOrEmpty($Global:activeBridgeName)) { [System.Windows.Forms.MessageBox]::Show("Please create a network bridge first.", "Error", "OK", "Warning"); Write-HotspotLog -Message "IP configuration failed: No active bridge." -Type "Warning"; return }
    $bridgeAdapter = Get-NetAdapter -Name $Global:activeBridgeName -ErrorAction SilentlyContinue
    if (-not $bridgeAdapter) { [System.Windows.Forms.MessageBox]::Show("Could not find the active network bridge adapter.", "Error", "OK", "Error"); Write-HotspotLog -Message "IP configuration failed: Bridge adapter '$Global:activeBridgeName' not found." -Type "Error"; return }
    Write-HotspotLog -Message "Applying IP settings to bridge adapter '$($bridgeAdapter.Name)'..."
    try {
        Write-HotspotLog -Message "Clearing existing IP addresses and DNS on bridge adapter..."
        Get-NetIPAddress -InterfaceIndex $bridgeAdapter.IfIndex -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        Set-DnsClientServerAddress -InterfaceIndex $bridgeAdapter.IfIndex -ResetServerAddresses -ErrorAction SilentlyContinue
        if ($hotspotDhcpRadioButton.Checked) {
            Write-HotspotLog -Message "Setting bridge adapter to obtain IP address automatically (DHCP)..."
            Write-HotspotLog -Message "DHCP configuration applied (existing static IPs removed, will attempt DHCP)." -Type "Info"
        } else {
            $ipAddress = $hotspotIpAddressTextBox.Text.Trim(); $subnetMask = $hotspotSubnetMaskTextBox.Text.Trim(); $gateway = $hotspotGatewayTextBox.Text.Trim(); $dns1 = $hotspotDns1TextBox.Text.Trim(); $dns2 = $hotspotDns2TextBox.Text.Trim()
            if (-not (Is-ValidIpAddress -IPAddress $ipAddress)) { [System.Windows.Forms.MessageBox]::Show("Invalid IP Address.", "Input Error", "OK", "Warning"); Write-HotspotLog -Message "IP configuration failed: Invalid IP Address '$ipAddress'." -Type "Warning"; return }
            if (-not (Is-ValidSubnetMask -IPAddress $subnetMask)) { [System.Windows.Forms.MessageBox]::Show("Invalid Subnet Mask.", "Input Error", "OK", "Warning"); Write-HotspotLog -Message "IP configuration failed: Invalid Subnet Mask '$subnetMask'." -Type "Warning"; return }
            if (-not [string]::IsNullOrEmpty($gateway) -and -not (Is-ValidIpAddress -IPAddress $gateway)) { [System.Windows.Forms.MessageBox]::Show("Invalid Gateway IP Address.", "Input Error", "OK", "Warning"); Write-HotspotLog -Message "IP configuration failed: Invalid Gateway '$gateway'." -Type "Warning"; return }
            if (Test-IPConflict -TargetIP $ipAddress) { [System.Windows.Forms.MessageBox]::Show("The chosen IP Address '$ipAddress' conflicts with an existing device or local IP.", "IP Conflict", "OK", "Error"); Write-HotspotLog -Message "IP configuration aborted due to conflict." -Type "Error"; return }
            if (-not [string]::IsNullOrEmpty($gateway) -and (Test-IPConflict -TargetIP $gateway)) { [System.Windows.Forms.MessageBox]::Show("The chosen Gateway IP Address '$gateway' conflicts with an existing device or local IP.", "IP Conflict", "OK", "Error"); Write-HotspotLog -Message "IP configuration aborted due to gateway conflict." -Type "Error"; return }
            Write-HotspotLog -Message "Setting bridge adapter to static IP: $ipAddress/$subnetMask..."
            New-NetIPAddress -InterfaceIndex $bridgeAdapter.IfIndex -IPAddress $ipAddress -PrefixLength (([System.Net.IPAddress]::Parse($subnetMask).GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2) }).Where({$_ -eq '1'}).Count) -DefaultGateway $gateway -ErrorAction Stop
            $dnsServers = @(); if (Is-ValidIpAddress -IPAddress $dns1) { $dnsServers += $dns1 }; if (Is-ValidIpAddress -IPAddress $dns2) { $dnsServers += $dns2 }
            if ($dnsServers.Count -gt 0) { Write-HotspotLog -Message "Setting DNS servers: $($dnsServers -join ', ')..."; Set-DnsClientServerAddress -InterfaceIndex $bridgeAdapter.IfIndex -ServerAddresses ($dnsServers) -ErrorAction Stop } else { Write-HotspotLog -Message "No valid DNS servers provided. DNS will not be set." -Type "Warning" }
            Write-HotspotLog -Message "Static IP configuration applied successfully." -Type "Info"
        }
    } catch { Write-HotspotLog -Message "Error applying IP configuration: $($_.Exception.Message)" -Type "Error"; [System.Windows.Forms.MessageBox]::Show("An error occurred while applying IP settings. Check logs.", "IP Config Error", "OK", "Error") }
}

#endregion

#region --- Main Form Events & Final Assembly ---
$mainForm.Add_FormClosing({
    param($s, $e)
    Save-Config
    try {
        $uiState = @{
            Width = $mainForm.Size.Width
            Height = $mainForm.Size.Height
            WebServersListViewColWidths = $webSitesListView.Columns | Select-Object -ExpandProperty Width
            FtpServersListViewColWidths = $ftpSitesListView.Columns | Select-Object -ExpandProperty Width
            ProxyServersListViewColWidths = $proxyServersListView.Columns | Select-Object -ExpandProperty Width
            HostsListViewColWidths = $hostsListView.Columns | Select-Object -ExpandProperty Width
            NetworkInfoListViewColWidths = $networkInfoListView.Columns | Select-Object -ExpandProperty Width
            KeepConsoleOpen = $Global:KeepConsoleOpen
        }
        $uiState | ConvertTo-Json | Set-Content -Path $uiStateConfigPath -Force
    } catch { Write-Warning "Could not save UI state: $_" }

    if (-not $Global:forceExit -and $e.CloseReason -eq 'UserClosing') {
        $e.Cancel = $true; $mainForm.Hide(); $notifyIcon.Visible = $true
    }
})

$mainForm.Add_FormClosed({
    # Stop all running jobs before closing the form
    foreach ($serverName in $Global:Config.WebServers.Keys) { Stop-WebServer -SiteName $serverName }
    foreach ($ftpName in $Global:Config.FtpServers.Keys) { Stop-FtpServer -FtpName $ftpName }
    foreach ($proxyName in $Global:Config.ProxyServers.Keys) { Stop-ProxyServer -ProxyName $proxyName }
    Stop-EmailServer
    
    Get-Job | Remove-Job -Force
    $notifyIcon.Dispose()
})

$showTrayMenuItem.Add_Click({ $mainForm.Show(); $mainForm.WindowState = 'Normal'; $notifyIcon.Visible = $false })
$exitTrayMenuItem.Add_Click({ $Global:forceExit = $true; $mainForm.Close() })
$notifyIcon.Add_DoubleClick({ $showTrayMenuItem.PerformClick() })

#endregion

#region --- Build All UI Tabs ---
# This region is now responsible for creating ALL UI elements and adding them to the tabs.
# This ensures everything is defined before the form is shown.

# --- Dashboard Tab Controls ---
$dashboardTab = New-Object System.Windows.Forms.TabPage("Dashboard")
$dashboardPanel = New-Object System.Windows.Forms.Panel; $dashboardPanel.Dock = 'Fill'
$dashboardTab.Controls.Add($dashboardPanel)

# Placeholder for Dashboard content (e.g., summary of running services)
$dashboardTitleLabel = New-Object System.Windows.Forms.Label; $dashboardTitleLabel.Text = "Dashboard"; $dashboardTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $dashboardTitleLabel.Location = '10, 10'; $dashboardTitleLabel.AutoSize = $true
$dashboardPanel.Controls.Add($dashboardTitleLabel)

# --- Web Servers Tab Controls ---
$webServersTab = New-Object System.Windows.Forms.TabPage("Web Servers")
$webSitesListView = New-Object System.Windows.Forms.ListView; $webSitesListView.Dock = 'Fill'; $webSitesListView.View = 'Details'; $webSitesListView.FullRowSelect = $true; $webSitesListView.GridLines = $true; $webSitesListView.MultiSelect = $false
$webSitesListView.Columns.Add("Site Name", 150); $webSitesListView.Columns.Add("Status", 80); $webSitesListView.Columns.Add("URL", 250); $webSitesListView.Columns.Add("Auth", 50); $webSitesListView.Columns.Add("Path", 450)
$webServersTab.Controls.Add($webSitesListView)
$webButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $webButtonPanel.Dock = 'Bottom'; $webButtonPanel.Height = 40; $webButtonPanel.Padding = '5, 5, 0, 0'
$webServersTab.Controls.Add($webButtonPanel)
$btnAddSite = New-Object System.Windows.Forms.Button; $btnAddSite.Text = "Add New Site..."; $btnAddSite.AutoSize = $true
$btnRemoveSite = New-Object System.Windows.Forms.Button; $btnRemoveSite.Text = "Remove Site"; $btnRemoveSite.Enabled = $false; $btnRemoveSite.AutoSize = $true
$btnStartStopSite = New-Object System.Windows.Forms.Button; $btnStartStopSite.Text = "Start/Stop"; $btnStartStopSite.Enabled = $false; $btnStartStopSite.AutoSize = $true
$webButtonPanel.Controls.AddRange(@($btnAddSite, $btnRemoveSite, $btnStartStopSite))

# --- FTP Servers Tab Controls ---
$ftpServersTab = New-Object System.Windows.Forms.TabPage("FTP Servers")
$ftpSitesListView = New-Object System.Windows.Forms.ListView; $ftpSitesListView.Dock = 'Fill'; $ftpSitesListView.View = 'Details'; $ftpSitesListView.FullRowSelect = $true; $ftpSitesListView.GridLines = $true; $ftpSitesListView.MultiSelect = $false
$ftpSitesListView.Columns.Add("FTP Site Name", 150); $ftpSitesListView.Columns.Add("Status", 80); $ftpSitesListView.Columns.Add("Address", 200); $ftpSitesListView.Columns.Add("User", 100); $ftpSitesListView.Columns.Add("Path", 450)
$ftpServersTab.Controls.Add($ftpSitesListView)
$ftpButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $ftpButtonPanel.Dock = 'Bottom'; $ftpButtonPanel.Height = 40; $ftpButtonPanel.Padding = '5, 5, 0, 0'
$ftpServersTab.Controls.Add($ftpButtonPanel)
$btnAddFtp = New-Object System.Windows.Forms.Button; $btnAddFtp.Text = "Add FTP Site..."; $btnAddFtp.AutoSize = $true
$btnRemoveFtp = New-Object System.Windows.Forms.Button; $btnRemoveFtp.Text = "Remove FTP Site"; $btnRemoveFtp.Enabled = $false; $btnRemoveFtp.AutoSize = $true
$btnStartStopFtp = New-Object System.Windows.Forms.Button; $btnStartStopFtp.Text = "Start/Stop"; $btnStartStopFtp.Enabled = $false; $btnStartStopFtp.AutoSize = $true
$ftpButtonPanel.Controls.AddRange(@($btnAddFtp, $btnRemoveFtp, $btnStartStopFtp))

# --- Proxy Servers Tab Controls ---
$proxyServersTab = New-Object System.Windows.Forms.TabPage("Proxy Servers")
$proxyServersListView = New-Object System.Windows.Forms.ListView; $proxyServersListView.Dock = 'Fill'; $proxyServersListView.View = 'Details'; $proxyServersListView.FullRowSelect = $true; $proxyServersListView.GridLines = $true; $proxyServersListView.MultiSelect = $false
$proxyServersListView.Columns.Add("Proxy Name", 150); $proxyServersListView.Columns.Add("Status", 80); $proxyServersListView.Columns.Add("Listening On", 200); $proxyServersListView.Columns.Add("Forwarding To", 450)
$proxyServersTab.Controls.Add($proxyServersListView)
$proxyButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $proxyButtonPanel.Dock = 'Bottom'; $proxyButtonPanel.Height = 40; $proxyButtonPanel.Padding = '5, 5, 0, 0'
$proxyServersTab.Controls.Add($proxyButtonPanel)
$btnAddProxy = New-Object System.Windows.Forms.Button; $btnAddProxy.Text = "Add Proxy..."; $btnAddProxy.AutoSize = $true
$btnRemoveProxy = New-Object System.Windows.Forms.Button; $btnRemoveProxy.Text = "Remove Proxy"; $btnRemoveProxy.Enabled = $false; $btnRemoveProxy.AutoSize = $true
$btnStartStopProxy = New-Object System.Windows.Forms.Button; $btnStartStopProxy.Text = "Start/Stop"; $btnStartStopProxy.Enabled = $false; $btnStartStopProxy.AutoSize = $true
$proxyButtonPanel.Controls.AddRange(@($btnAddProxy, $btnRemoveProxy, $btnStartStopProxy))

# --- Email Sink Tab Controls ---
$emailSinkTab = New-Object System.Windows.Forms.TabPage("Email Sink")
$emailPanel = New-Object System.Windows.Forms.Panel; $emailPanel.Dock = 'Fill'; $emailPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$emailSinkTab.Controls.Add($emailPanel)
$emailHeaderPanel = New-Object System.Windows.Forms.Panel; $emailHeaderPanel.Dock = 'Top'; $emailHeaderPanel.Height = 40
$emailPanel.Controls.Add($emailHeaderPanel)
$btnStartStopEmail = New-Object System.Windows.Forms.Button; $btnStartStopEmail.Text = "Start Mail Sink"; $btnStartStopEmail.Location = New-Object System.Drawing.Point(0,0); $btnStartStopEmail.Width = 150
$lblEmailStatus = New-Object System.Windows.Forms.Label; $lblEmailStatus.Text = "Status: Stopped"; $lblEmailStatus.Location = New-Object System.Drawing.Point(160, 5); $lblEmailStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $lblEmailStatus.ForeColor = [System.Drawing.Color]::Firebrick; $lblEmailStatus.AutoSize = $true
$lblEmailInfo = New-Object System.Windows.Forms.Label; $lblEmailInfo.Text = "Address: 127.0.0.1, Port: 25. Catches all emails sent to this address."; $lblEmailInfo.Location = New-Object System.Drawing.Point(350, 5); $lblEmailInfo.AutoSize = $true
$btnViewEmails = New-Object System.Windows.Forms.Button; $btnViewEmails.Text = "View Saved Emails..."; $btnViewEmails.Location = New-Object System.Drawing.Point(700, 0); $btnViewEmails.Width = 150
$btnClearLog = New-Object System.Windows.Forms.Button; $btnClearLog.Text = "Clear Log"; $btnClearLog.Location = New-Object System.Drawing.Point(860, 0);
$emailHeaderPanel.Controls.AddRange(@($btnStartStopEmail, $lblEmailStatus, $lblEmailInfo, $btnViewEmails, $btnClearLog))
$emailLogBox = New-Object System.Windows.Forms.TextBox; $emailLogBox.Dock = 'Fill'; $emailLogBox.Multiline = $true; $emailLogBox.ScrollBars = "Vertical"; $emailLogBox.ReadOnly = $true; $emailLogBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$emailPanel.Controls.Add($emailLogBox)
$emailLogBox.BringToFront()

# --- Certificate Authority Tab Controls ---
$certTab = New-Object System.Windows.Forms.TabPage("Certificate Authority")
$certMainPanel = New-Object System.Windows.Forms.Panel; $certMainPanel.Dock = 'Fill'
$certMainPanel.add_Paint({
    param($s, $e)
    $g = $e.Graphics; $rect = $s.ClientRectangle
    $startColor = [System.Drawing.ColorTranslator]::FromHtml("#00c6ff")
    $endColor = [System.Drawing.ColorTranslator]::FromHtml("#4f46e5")
    $rectF = [System.Drawing.RectangleF]::new($rect.X, $rect.Y, $rect.Width, $rect.Height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rectF, $startColor, $endColor, [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
})
$certLogBox = New-Object System.Windows.Forms.TextBox; $certLogBox.Multiline = $true; $certLogBox.ReadOnly = $true; $certLogBox.Dock = 'Bottom'; $certLogBox.Height = 150; $certLogBox.Location = '0, 500' # Adjusted location
$rootGroup = New-Object System.Windows.Forms.GroupBox; $rootGroup.Text = "Root Certificate Authority"; $rootGroup.Size = '580, 120'; $rootGroup.Location = '10, 10'; $rootGroup.ForeColor = 'White'; $rootGroup.BackColor = 'Transparent'
$rootLabel = New-Object System.Windows.Forms.Label; $rootLabel.Text = "Root CA Status:"; $rootLabel.Location = '10, 25'; $rootLabel.Size = '100, 20'; $rootLabel.ForeColor = 'White'; $rootLabel.BackColor = 'Transparent'
$rootStatus = New-Object System.Windows.Forms.Label; $rootStatus.Text = "Not created."; $rootStatus.Location = '120, 25'; $rootStatus.Size = '400, 20'; $rootStatus.ForeColor = 'White'; $rootStatus.BackColor = 'Transparent'
$createRootButton = New-Object System.Windows.Forms.Button; $createRootButton.Text = "Create Root CA"; $createRootButton.Location = '10, 55'; $createRootButton.Size = '140, 30'
$installRootButton = New-Object System.Windows.Forms.Button; $installRootButton.Text = "Install Root CA"; $installRootButton.Location = '160, 55'; $installRootButton.Size = '140, 30'
Set-AeroButtonStyle -button $createRootButton -baseColor '#581c87' -highlightColor '#a5b4fc'
Set-AeroButtonStyle -button $installRootButton -baseColor '#1d4ed8' -highlightColor '#a5b4fc'
$rootGroup.Controls.AddRange(@($rootLabel, $rootStatus, $createRootButton, $installRootButton))
$certMainPanel.Controls.AddRange(@($rootGroup, $certLogBox))
$certTab.Controls.Add($certMainPanel)

# --- Hosts File Manager Tab Controls ---
$hostsTabPage = New-Object System.Windows.Forms.TabPage("Hosts File Manager")
$hostsListView = New-Object System.Windows.Forms.ListView; $hostsListView.View = 'Details'; $hostsListView.FullRowSelect = $true; $hostsListView.GridLines = $true; $hostsListView.Dock = 'Fill'
$hostsListView.Columns.Add("IP Address", 150) | Out-Null
$hostsListView.Columns.Add("Hostnames", 550) | Out-Null
$hostsTabPage.Controls.Add($hostsListView)

# --- Network Tools Tab Controls ---
$netToolsTab = New-Object System.Windows.Forms.TabPage("Network Tools")
$networkInfoTabControl = New-Object System.Windows.Forms.TabControl; $networkInfoTabControl.Dock = 'Fill'
$netToolsTab.Controls.Add($networkInfoTabControl)

$networkInfoTabPageIP = New-Object System.Windows.Forms.TabPage("IP Address"); $networkInfoTabControl.Controls.Add($networkInfoTabPageIP)
$networkInfoTextBox = New-Object System.Windows.Forms.RichTextBox; $networkInfoTextBox.Dock = 'Fill'; $networkInfoTextBox.ReadOnly = $true; $networkInfoTextBox.Multiline = $true; $networkInfoTextBox.ScrollBars = "Vertical"; $networkInfoTextBox.Font = New-Object System.Drawing.Font("Consolas", 10); $networkInfoTabPageIP.Controls.Add($networkInfoTextBox)
$networkInfoTabPageDNS = New-Object System.Windows.Forms.TabPage("DNS Configuration"); $networkInfoTabControl.Controls.Add($networkInfoTabPageDNS)
$dnsInfoTextBox = New-Object System.Windows.Forms.RichTextBox; $dnsInfoTextBox.Dock = 'Fill'; $dnsInfoTextBox.ReadOnly = $true; $dnsInfoTextBox.Multiline = $true; $dnsInfoTextBox.ScrollBars = "Vertical"; $dnsInfoTextBox.Font = New-Object System.Drawing.Font("Consolas", 10); $networkInfoTabPageDNS.Controls.Add($dnsInfoTextBox)
$networkInfoTabPageAdapter = New-Object System.Windows.Forms.TabPage("Adapter Details"); $networkInfoTabControl.Controls.Add($networkInfoTabPageAdapter)
$adapterDetailsTextBox = New-Object System.Windows.Forms.RichTextBox; $adapterDetailsTextBox.Dock = 'Fill'; $adapterDetailsTextBox.ReadOnly = $true; $adapterDetailsTextBox.Multiline = $true; $adapterDetailsTextBox.ScrollBars = "Vertical"; $adapterDetailsTextBox.Font = New-Object System.Drawing.Font("Consolas", 10); $networkInfoTabPageAdapter.Controls.Add($adapterDetailsTextBox)

$networkToolsPanel = New-Object System.Windows.Forms.Panel; $networkToolsPanel.Dock = 'Bottom'; $networkToolsPanel.Height = 150
$hotspotGroupBox = New-Object System.Windows.Forms.GroupBox; $hotspotGroupBox.Text = "Mobile Hotspot & Bridging"; $hotspotGroupBox.Location = '10, 10'; $hotspotGroupBox.Size = '450, 130'
$hotspotSsidLabel = New-Object System.Windows.Forms.Label; $hotspotSsidLabel.Text = "SSID:"; $hotspotSsidLabel.Location = '10, 25'; $hotspotSsidLabel.AutoSize = $true; $hotspotGroupBox.Controls.Add($hotspotSsidLabel)
$hotspotSsidTextBox = New-Object System.Windows.Forms.TextBox; $hotspotSsidTextBox.Text = "MyHotspot"; $hotspotSsidTextBox.Location = '80, 22'; $hotspotSsidTextBox.Width = 150; $hotspotGroupBox.Controls.Add($hotspotSsidTextBox)
$hotspotPasswordLabel = New-Object System.Windows.Forms.Label; $hotspotPasswordLabel.Text = "Password:"; $hotspotPasswordLabel.Location = '10, 55'; $hotspotPasswordLabel.AutoSize = $true; $hotspotGroupBox.Controls.Add($hotspotPasswordLabel)
$hotspotPasswordTextBox = New-Object System.Windows.Forms.TextBox; $hotspotPasswordTextBox.Text = "P@ssword123"; $hotspotPasswordTextBox.Location = '80, 52'; $hotspotPasswordTextBox.Width = 150; $hotspotGroupBox.Controls.Add($hotspotPasswordTextBox)
$startHotspotButton = New-Object System.Windows.Forms.Button; $startHotspotButton.Text = "Start Hotspot"; $startHotspotButton.Location = '240, 20'; $startHotspotButton.Size = '100, 30'; $hotspotGroupBox.Controls.Add($startHotspotButton)
$stopHotspotButton = New-Object System.Windows.Forms.Button; $stopHotspotButton.Text = "Stop Hotspot"; $stopHotspotButton.Location = '345, 20'; $stopHotspotButton.Size = '100, 30'; $hotspotGroupBox.Controls.Add($stopHotspotButton)
$adapterListBox = New-Object System.Windows.Forms.ListBox; $adapterListBox.Location = '10, 80'; $adapterListBox.Size = '220, 50'; $hotspotGroupBox.Controls.Add($adapterListBox)
$bridgeSelectedButton = New-Object System.Windows.Forms.Button; $bridgeSelectedButton.Text = "Bridge Selected"; $bridgeSelectedButton.Location = '240, 80'; $bridgeSelectedButton.Size = '100, 30'; $hotspotGroupBox.Controls.Add($bridgeSelectedButton)
$unbridgeAllButton = New-Object System.Windows.Forms.Button; $unbridgeAllButton.Text = "Unbridge All"; $unbridgeAllButton.Location = '345, 80'; $unbridgeAllButton.Size = '100, 30'; $hotspotGroupBox.Controls.Add($unbridgeAllButton)

$networkToolsPanel.Controls.Add($hotspotGroupBox)
$netToolsTab.Controls.Add($networkToolsPanel)

# --- Global Settings Tab Controls ---
$settingsTab = New-Object System.Windows.Forms.TabPage("Global Settings")
$settingsPanel = New-Object System.Windows.Forms.Panel; $settingsPanel.Dock = 'Fill'; $settingsPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$settingsTab.Controls.Add($settingsPanel)

$lblCustom404 = New-Object System.Windows.Forms.Label; $lblCustom404.Text = "Custom 404 Error Page:"; $lblCustom404.Location = New-Object System.Drawing.Point(10, 15); $lblCustom404.AutoSize = $true
$txtCustom404 = New-Object System.Windows.Forms.TextBox; $txtCustom404.Location = New-Object System.Drawing.Point(10, 40); $txtCustom404.Width = 400
$btnBrowse404 = New-Object System.Windows.Forms.Button; $btnBrowse404.Text = "Browse..."; $btnBrowse404.Location = New-Object System.Drawing.Point(420, 38)
$chkKeepConsoleOpen = New-Object System.Windows.Forms.CheckBox; $chkKeepConsoleOpen.Text = "Keep Console Open on Exit"; $chkKeepConsoleOpen.Location = New-Object System.Drawing.Point(10, 80); $chkKeepConsoleOpen.AutoSize = $true; $chkKeepConsoleOpen.Checked = $Global:Config.GlobalSettings.KeepConsoleOpen

$settingsPanel.Controls.AddRange(@($lblCustom404, $txtCustom404, $btnBrowse404, $chkKeepConsoleOpen))


# --- Add all tabs to the TabControl ---
$tabControl.Controls.AddRange(@(
    $dashboardTab,
    $webServersTab,
    $ftpServersTab,
    $proxyServersTab,
    $emailSinkTab,
    $certTab,
    $hostsTabPage,
    $netToolsTab,
    $settingsTab
))
#endregion

#region --- Event Handlers and Final Form Assembly & Show ---

# Web Server Handlers
$webSitesListView.Add_SelectedIndexChanged({
    $enable = $webSitesListView.SelectedItems.Count -gt 0
    $btnRemoveSite.Enabled = $enable; $btnStartStopSite.Enabled = $enable
})
$btnAddSite.Add_Click({ Show-AddEditSiteDialog })
$btnRemoveSite.Add_Click({
    $selected = $webSitesListView.SelectedItems[0]; if (!$selected) { return }
    $siteName = $selected.Tag
    if ([System.Windows.Forms.MessageBox]::Show("Are you sure you want to remove '$siteName'?", "Confirm Removal", "YesNo", "Warning") -eq "Yes") {
        Stop-WebServer -SiteName $siteName
        $Global:Config.WebServers.Remove($siteName)
        Save-Config
        Update-WebSiteListView -listView $webSitesListView
    }
})
$btnStartStopSite.Add_Click({
    $selected = $webSitesListView.SelectedItems[0]; if (!$selected) { return }
    $site = $Global:Config.WebServers[$selected.Tag]
    if ($site.Process -and -not $site.Process.HasExited) { Stop-WebServer -SiteName $selected.Tag } else { Start-WebServer -SiteName $selected.Tag }
})

# FTP Server Handlers
$ftpSitesListView.Add_SelectedIndexChanged({
    $enable = $ftpSitesListView.SelectedItems.Count -gt 0
    $btnRemoveFtp.Enabled = $enable; $btnStartStopFtp.Enabled = $enable
})
$btnAddFtp.Add_Click({ Show-AddFtpDialog })
$btnRemoveFtp.Add_Click({
    $selected = $ftpSitesListView.SelectedItems[0]; if (!$selected) { return }
    $ftpName = $selected.Tag
    if ([System.Windows.Forms.MessageBox]::Show("Are you sure you want to remove FTP site '$ftpName'?", "Confirm Removal", "YesNo", "Warning") -eq "Yes") {
        Stop-FtpServer -FtpName $ftpName
        $Global:Config.FtpServers.Remove($ftpName)
        Save-Config
        Update-FtpSiteListView -listView $ftpSitesListView
    }
})
$btnStartStopFtp.Add_Click({
    $selected = $ftpSitesListView.SelectedItems[0]; if (!$selected) { return }
    $ftpSite = $Global:Config.FtpServers[$selected.Tag]
    if ($ftpSite.Process -and -not $ftpSite.Process.HasExited) { Stop-FtpServer -FtpName $selected.Tag } else { Start-FtpServer -FtpName $selected.Tag }
})

# Proxy Server Handlers
$proxyServersListView.Add_SelectedIndexChanged({
    $enable = $proxyServersListView.SelectedItems.Count -gt 0
    $btnRemoveProxy.Enabled = $enable; $btnStartStopProxy.Enabled = $enable
})
$btnAddProxy.Add_Click({ Show-AddProxyDialog })
$btnRemoveProxy.Add_Click({
    $selected = $proxyServersListView.SelectedItems[0]; if (!$selected) { return }
    $proxyName = $selected.Tag
    if ([System.Windows.Forms.MessageBox]::Show("Are you sure you want to remove proxy '$proxyName'?", "Confirm Removal", "YesNo", "Warning") -eq "Yes") {
        Stop-ProxyServer -ProxyName $proxyName
        $Global:Config.ProxyServers.Remove($proxyName)
        Save-Config
        Update-ProxyServerListView -listView $proxyServersListView
    }
})
$btnStartStopProxy.Add_Click({
    $selected = $proxyServersListView.SelectedItems[0]; if (!$selected) { return }
    $proxy = $Global:Config.ProxyServers[$selected.Tag]
    if ($proxy.Process -and -not $proxy.Process.HasExited) { Stop-ProxyServer -ProxyName $selected.Tag } else { Start-ProxyServer -ProxyName $selected.Tag }
})

# Email Server Handlers
$btnStartStopEmail.Add_Click({
    if ($Global:Config.EmailServer.Process -and -not $Global:Config.EmailServer.Process.HasExited) { Stop-EmailServer } else { Start-EmailServer }
})
$emailDataReceived = {
    param($sender, $e)
    if (-not [string]::IsNullOrEmpty($e.Data)) {
        # Use Invoke to safely update UI from another thread
        $mainForm.Invoke([Action[string]]{ param($data) $emailLogBox.AppendText($data + "`r`n") }, $e.Data)
    }
}
$btnViewEmails.Add_Click({ try { Invoke-Item $emailStoragePath } catch { [System.Windows.Forms.MessageBox]::Show("Could not open folder: $emailStoragePath", "Error", "OK", "Error") } })
$btnClearLog.Add_Click({ $emailLogBox.Clear() })


# Certificate Authority Handlers
$createRootButton.Add_Click({
    try {
        Write-CertLog -Message "Starting Root CA creation...";
        $caName = "EliteSoftware Corp. Limited Root CA"; # Hardcoded for now
        $validityYears = 10;
        $notAfter = (Get-Date).AddYears($validityYears);
        $rootParams = @{ Type = 'Custom'; Subject = "CN=$caName"; CertStoreLocation = 'Cert:\CurrentUser\My'; KeyAlgorithm = 'RSA'; KeyLength = 2048; KeyUsage = @('CertSign', 'CrlSign'); NotAfter = $notAfter; TextExtension = @('2.5.29.19={critical}{text}ca=true') };
        $Global:rootCACert = New-SelfSignedCertificate @rootParams -ErrorAction Stop;
        Write-CertLog -Message "SUCCESS: Root CA '$caName' created.";
        Write-CertLog -Message "Thumbprint: $($Global:rootCACert.Thumbprint)";
        $rootStatus.Text = "Created: $($Global:rootCACert.Thumbprint)"
        [System.Windows.Forms.MessageBox]::Show("Root CA '$caName' was created successfully!", "Success", "OK", "Information")
    } catch {
        Write-CertLog -Message "ERROR: Failed to create Root CA.";
        Write-CertLog -Message $_.Exception.Message;
        [System.Windows.Forms.MessageBox]::Show("An error occurred while creating the Root CA.`n`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
})
$installRootButton.Add_Click({
    try {
        if ($null -eq $Global:rootCACert) { [System.Windows.Forms.MessageBox]::Show("You must create a Root CA first.", "Error", "OK", "Error"); return };
        Write-CertLog -Message "Installing Root CA to Trusted Root Certification Authorities stores...";
        Import-Certificate -Cert $Global:rootCACert -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction Stop;
        Write-CertLog -Message "SUCCESS: Installed to Local Machine store.";
        Import-Certificate -Cert $Global:rootCACert -CertStoreLocation 'Cert:\CurrentUser\Root' -ErrorAction Stop;
        Write-CertLog -Message "SUCCESS: Installed to Current User store.";
        [System.Windows.Forms.MessageBox]::Show("Root CA was installed to the system's trusted stores successfully!", "Installation Complete", "OK", "Information")
    } catch {
        Write-CertLog -Message "ERROR: Failed to install Root CA.";
        Write-CertLog -Message $_.Exception.Message;
        [System.Windows.Forms.MessageBox]::Show("An error occurred during installation.`n`n$($_.Exception.Message)`n`nEnsure the script is running as an Administrator.", "Error", "OK", "Error")
    }
})

# Hosts File Manager Handlers
$hostsListView.Add_SelectedIndexChanged({
    if ($hostsListView.SelectedItems.Count -gt 0) {
        $selectedItem = $hostsListView.SelectedItems[0]
        $hostsIpTextBox.Text = $selectedItem.SubItems[0].Text
        $hostsHostnamesTextBox.Text = $selectedItem.SubItems[1].Text
    }
})
$hostsAddUpdateButton.Add_Click({
    $ip = $hostsIpTextBox.Text.Trim(); $hosts = $hostsHostnamesTextBox.Text.Trim()
    if (-not $ip -or -not $hosts) { return }
    $existingItems = $hostsListView.Items | Where-Object { $_.SubItems[0].Text -eq $ip }
    if ($existingItems.Count -gt 0) { $existingItems[0].SubItems[1].Text = $hosts }
    else {
        $newItem = New-Object System.Windows.Forms.ListViewItem($ip)
        $newItem.SubItems.Add($hosts) | Out-Null
        $hostsListView.Items.Add($newItem) | Out-Null
    }
    Save-HostsFile -listView $hostsListView
    $hostsIpTextBox.Clear(); $hostsHostnamesTextBox.Clear()
})
$hostsRemoveButton.Add_Click({
    if ($hostsListView.SelectedItems.Count -gt 0) {
        $hostsListView.Items.Remove($hostsListView.SelectedItems[0])
        Save-HostsFile -listView $hostsListView
        $hostsIpTextBox.Clear(); $hostsHostnamesTextBox.Clear()
    }
})

# Network Tools Handlers
$refreshInfoButton.Add_Click({ Get-NetworkInfo })
$startHotspotButton.Add_Click({ Start-MyHotspot })
$stopHotspotButton.Add_Click({ Stop-MyHotspot })
$bridgeSelectedButton.Add_Click({ Create-NetworkBridge })
$unbridgeAllButton.Add_Click({ Remove-NetworkBridge })

# Settings Handlers
$chkKeepConsoleOpen.Add_CheckedChanged({ $Global:KeepConsoleOpen = $chkKeepConsoleOpen.Checked; Save-Config })
$btnBrowse404.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog; $fileDialog.Title = "Select Custom 404 Page"; $fileDialog.Filter = "HTML Files (*.html)|*.html|All Files (*.*)|*.*"
    if ($fileDialog.ShowDialog() -eq "OK") { $Global:Config.GlobalSettings.Custom404Page = $fileDialog.FileName; $txtCustom404.Text = $fileDialog.FileName; Save-Config }
})


# Add all top-level controls to the main form at the very end.
$mainForm.Controls.AddRange(@($tabControl, $menuStrip, $statusStrip))

# --- Initial Load & Population ---
Load-Config
if (Test-Path $uiStateConfigPath) {
    try {
        $uiState = Get-Content $uiStateConfigPath | ConvertFrom-Json
        $mainForm.Size = New-Object System.Drawing.Size($uiState.Width, $uiState.Height)
        # Apply column widths from saved state if they exist
        if ($uiState.WebServersListViewColWidths) { for($i=0; $i -lt $uiState.WebServersListViewColWidths.Count; $i++) { $webSitesListView.Columns[$i].Width = $uiState.WebServersListViewColWidths[$i] } }
        if ($uiState.FtpServersListViewColWidths) { for($i=0; $i -lt $uiState.FtpServersListViewColWidths.Count; $i++) { $ftpSitesListView.Columns[$i].Width = $uiState.FtpServersListViewColWidths[$i] } }
        if ($uiState.ProxyServersListViewColWidths) { for($i=0; $i -lt $uiState.ProxyServersListViewColWidths.Count; $i++) { $proxyServersListView.Columns[$i].Width = $uiState.ProxyServersListViewColWidths[$i] } }
        if ($uiState.HostsListViewColWidths) { for($i=0; $i -lt $uiState.HostsListViewColWidths.Count; $i++) { $hostsListView.Columns[$i].Width = $uiState.HostsListViewColWidths[$i] } }
        if ($uiState.NetworkInfoListViewColWidths) { for($i=0; $i -lt $uiState.NetworkInfoListViewColWidths.Count; $i++) { $networkInfoListView.Columns[$i].Width = $uiState.NetworkInfoListViewColWidths[$i] } }
        $Global:KeepConsoleOpen = $uiState.KeepConsoleOpen
        $chkKeepConsoleOpen.Checked = $Global:KeepConsoleOpen
    } catch { Write-Warning "Could not apply saved UI state." }
}
Update-WebSiteListView -listView $webSitesListView
Update-FtpSiteListView -listView $ftpSitesListView
Update-ProxyServerListView -listView $proxyServersListView
Load-HostsFile -listView $hostsListView
Get-NetworkAdapters # Populate adapter list box on the network tools tab
Get-NetworkInfo # Populate initial network info on the network tools tab

$statusLabel.Text = "Ready."

# --- Show Form ---
[void]$mainForm.ShowDialog()

if ($Global:KeepConsoleOpen -or $LASTEXITCODE -ne 0) {
    if ($LASTEXITCODE -ne 0) { Write-Error "The script encountered an error." }
    Read-Host "Press Enter to close the console."
}
#endregion

#region --- DIALOGS (Moved here for clarity) ---
function Show-AddEditSiteDialog {
    param([string]$SiteName)
    $isEditMode = -not [string]::IsNullOrEmpty($SiteName)
    $site = if ($isEditMode) { $Global:Config.WebServers[$SiteName] } else { $null }

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = if ($isEditMode) { "Edit Site '$SiteName'" } else { "Add New Web Site" }
    $dialog.Size = New-Object System.Drawing.Size(450, 300); $dialog.StartPosition = "CenterParent"; $dialog.FormBorderStyle = "FixedDialog"

    # Controls
    $lblSiteName = New-Object System.Windows.Forms.Label; $lblSiteName.Text = "Site Name:"; $lblSiteName.Location = New-Object System.Drawing.Point(20, 23)
    $txtSiteName = New-Object System.Windows.Forms.TextBox; $txtSiteName.Location = New-Object System.Drawing.Point(150, 20); $txtSiteName.Width = 250; if ($isEditMode) { $txtSiteName.Text = $site.Name; $txtSiteName.Enabled = $false }
    
    $lblSiteFolder = New-Object System.Windows.Forms.Label; $lblSiteFolder.Text = "Website Folder:"; $lblSiteFolder.Location = New-Object System.Drawing.Point(20, 53)
    $txtSiteFolder = New-Object System.Windows.Forms.TextBox; $txtSiteFolder.Location = New-Object System.Drawing.Point(150, 50); $txtSiteFolder.Width = 160; if ($isEditMode) { $txtSiteFolder.Text = $site.RootPath; $txtSiteFolder.Enabled = $false }
    $btnBrowseFolder = New-Object System.Windows.Forms.Button; $btnBrowseFolder.Text = "Browse..."; $btnBrowseFolder.Location = New-Object System.Drawing.Point(320, 48); if ($isEditMode) { $btnBrowseFolder.Enabled = $false }
    
    $lblBindIP = New-Object System.Windows.Forms.Label; $lblBindIP.Text = "Bind to IP:"; $lblBindIP.Location = New-Object System.Drawing.Point(20, 83)
    $cboBindIP = New-Object System.Windows.Forms.ComboBox; $cboBindIP.Location = New-Object System.Drawing.Point(150, 80); $cboBindIP.Width = 250; $cboBindIP.DropDownStyle = 'DropDownList'
    Populate-IPComboBox -comboBox $cboBindIP
    if ($isEditMode) { $cboBindIP.SelectedIndex = $cboBindIP.Items.IndexOf("$($site.BindIP) ($($site.InterfaceAlias))") }
    
    $lblPort = New-Object System.Windows.Forms.Label; $lblPort.Text = "Port:"; $lblPort.Location = New-Object System.Drawing.Point(20, 113)
    $numPort = New-Object System.Windows.Forms.NumericUpDown; $numPort.Location = New-Object System.Drawing.Point(150, 110); $numPort.Width = 100; $numPort.Minimum = 1025; $numPort.Maximum = 65535; $numPort.Value = if ($isEditMode) { $site.HttpPort } else { 8080 }

    $chkUseSSL = New-Object System.Windows.Forms.CheckBox; $chkUseSSL.Text = "Use HTTPS/SSL"; $chkUseSSL.Location = New-Object System.Drawing.Point(150, 140); if ($isEditMode) { $chkUseSSL.Checked = $site.UseSSL }

    $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = "OK"; $btnOK.Location = New-Object System.Drawing.Point(150, 200); $btnOK.DialogResult = "OK"
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancel"; $btnCancel.Location = New-Object System.Drawing.Point(240, 200); $btnCancel.DialogResult = "Cancel"

    $dialog.Controls.AddRange(@($lblSiteName, $txtSiteName, $lblSiteFolder, $txtSiteFolder, $btnBrowseFolder, $lblBindIP, $cboBindIP, $lblPort, $numPort, $chkUseSSL, $btnOK, $btnCancel))
    $dialog.AcceptButton = $btnOK; $dialog.CancelButton = $btnCancel

    $btnBrowseFolder.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; $folderBrowser.Description = "Select the root folder of your website"
        if ($folderBrowser.ShowDialog() -eq "OK") { $txtSiteFolder.Text = $folderBrowser.SelectedPath }
    })

    if ($dialog.ShowDialog($mainForm) -eq "OK") {
        if ([string]::IsNullOrWhiteSpace($txtSiteName.Text) -or ($isEditMode -eq $false -and [string]::IsNullOrWhiteSpace($txtSiteFolder.Text)) -or [string]::IsNullOrWhiteSpace($cboBindIP.SelectedItem)) {
            [System.Windows.Forms.MessageBox]::Show("Site Name, Folder, and IP Address are required.", "Validation Error", "OK", "Error"); return
        }
        $portToCheck = $numPort.Value
        if(Test-PortInUse -Port $portToCheck) {
            [System.Windows.Forms.MessageBox]::Show("Port $portToCheck is already in use by another application. Please choose a different port.", "Port Conflict", "OK", "Error"); return
        }
        
        $bindIp = ($cboBindIP.SelectedItem -split ' ')[0]
        
        if ($isEditMode) {
            Stop-WebServer -SiteName $SiteName
            $site.BindIP = $bindIp; $site.HttpPort = $numPort.Value; $site.UseSSL = $chkUseSSL.Checked
            [System.Windows.Forms.MessageBox]::Show("Site updated. Please start it to apply changes.", "Update Complete", "OK", "Information")
        } else {
            $newSiteName = $txtSiteName.Text
            if ($Global:Config.WebServers.ContainsKey($newSiteName)) { [System.Windows.Forms.MessageBox]::Show("A site with that name already exists.", "Validation Error", "OK", "Error"); return }
            $destinationPath = Join-Path $webHostingBasePath $newSiteName
            try { Copy-Item -Path $txtSiteFolder.Text -Destination $destinationPath -Recurse -Force }
            catch { [System.Windows.Forms.MessageBox]::Show("Failed to copy website files: $($_.Exception.Message)", "File Error", "OK", "Error"); return }
            
            $newSite = [pscustomobject]@{ Name = $newSiteName; RootPath = $destinationPath; BindIP = $bindIp; HttpPort = $numPort.Value; UseSSL = $chkUseSSL.Checked; Process = $null; CertPath = ""; KeyPath = ""; UseAuth = $false; Username = ""; Password = "" }
            $Global:Config.WebServers.Add($newSiteName, $newSite)
        }
        Save-Config
        Update-WebSiteListView -listView $webSitesListView
    }
    $dialog.Dispose()
}

function Show-AddFtpDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Add New FTP Site"; $dialog.Size = New-Object System.Drawing.Size(450, 280); $dialog.StartPosition = "CenterParent"; $dialog.FormBorderStyle = "FixedDialog"

    # Controls
    $lblFtpName = New-Object System.Windows.Forms.Label; $lblFtpName.Text = "FTP Site Name:"; $lblFtpName.Location = New-Object System.Drawing.Point(20, 23)
    $txtFtpName = New-Object System.Windows.Forms.TextBox; $txtFtpName.Location = New-Object System.Drawing.Point(150, 20); $txtFtpName.Width = 250
    
    $lblFtpFolder = New-Object System.Windows.Forms.Label; $lblFtpFolder.Text = "FTP Root Folder:"; $lblFtpFolder.Location = New-Object System.Drawing.Point(20, 53)
    $txtFtpFolder = New-Object System.Windows.Forms.TextBox; $txtFtpFolder.Location = New-Object System.Drawing.Point(150, 50); $txtFtpFolder.Width = 160
    $btnBrowseFolder = New-Object System.Windows.Forms.Button; $btnBrowseFolder.Text = "Browse..."; $btnBrowseFolder.Location = New-Object System.Drawing.Point(320, 48)

    $lblUser = New-Object System.Windows.Forms.Label; $lblUser.Text = "Username:"; $lblUser.Location = New-Object System.Drawing.Point(20, 83)
    $txtUser = New-Object System.Windows.Forms.TextBox; $txtUser.Location = New-Object System.Drawing.Point(150, 80); $txtUser.Width = 250
    
    $lblPass = New-Object System.Windows.Forms.Label; $lblPass.Text = "Password:"; $lblPass.Location = New-Object System.Drawing.Point(20, 113)
    $txtPass = New-Object System.Windows.Forms.TextBox; $txtPass.Location = New-Object System.Drawing.Point(150, 110); $txtPass.Width = 250; $txtPass.PasswordChar = "*"
    
    $lblPort = New-Object System.Windows.Forms.Label; $lblPort.Text = "Port:"; $lblPort.Location = New-Object System.Drawing.Point(20, 143)
    $numPort = New-Object System.Windows.Forms.NumericUpDown; $numPort.Location = New-Object System.Drawing.Point(150, 140); $numPort.Width = 100; $numPort.Minimum = 1025; $numPort.Maximum = 65535; $numPort.Value = 2121
    
    $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = "OK"; $btnOK.Location = New-Object System.Drawing.Point(150, 200); $btnOK.DialogResult = "OK"
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancel"; $btnCancel.Location = New-Object System.Drawing.Point(240, 200); $btnCancel.DialogResult = "Cancel"

    $dialog.Controls.AddRange(@($lblFtpName, $txtFtpName, $lblFtpFolder, $txtFtpFolder, $btnBrowseFolder, $lblUser, $txtUser, $lblPass, $txtPass, $lblPort, $numPort, $btnOK, $btnCancel))
    $dialog.AcceptButton = $btnOK; $dialog.CancelButton = $btnCancel

    $btnBrowseFolder.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; $folderBrowser.Description = "Select the root folder for the FTP user"
        if ($folderBrowser.ShowDialog() -eq "OK") { $txtFtpFolder.Text = $folderBrowser.SelectedPath }
    })

    if ($dialog.ShowDialog($mainForm) -eq "OK") {
        if ([string]::IsNullOrWhiteSpace($txtFtpName.Text) -or [string]::IsNullOrWhiteSpace($txtFtpFolder.Text) -or [string]::IsNullOrWhiteSpace($txtUser.Text) -or [string]::IsNullOrWhiteSpace($txtPass.Text)) {
            [System.Windows.Forms.MessageBox]::Show("All fields are required.", "Validation Error", "OK", "Error"); return
        }
        $portToCheck = $numPort.Value
        if(Test-PortInUse -Port $portToCheck) {
            [System.Windows.Forms.MessageBox]::Show("Port $portToCheck is already in use by another application. Please choose a different port.", "Port Conflict", "OK", "Error"); return
        }
        $newFtpName = $txtFtpName.Text
        if ($Global:Config.FtpServers.ContainsKey($newFtpName)) { [System.Windows.Forms.MessageBox]::Show("An FTP site with that name already exists.", "Validation Error", "OK", "Error"); return }
        
        $newFtpSite = [pscustomobject]@{ Name = $newFtpName; RootPath = $txtFtpFolder.Text; Port = $numPort.Value; Username = $txtUser.Text; Password = $txtPass.Text; Process = $null; BindIP = "0.0.0.0" }
        $Global:Config.FtpServers.Add($newFtpName, $newFtpSite)
        Save-Config
        Update-FtpSiteListView -listView $ftpSitesListView
    }
    $dialog.Dispose()
}

function Show-AddProxyDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Add New Proxy Server"; $dialog.Size = New-Object System.Drawing.Size(450, 250); $dialog.StartPosition = "CenterParent"; $dialog.FormBorderStyle = "FixedDialog"

    # Controls
    $lblProxyName = New-Object System.Windows.Forms.Label; $lblProxyName.Text = "Proxy Name:"; $lblProxyName.Location = New-Object System.Drawing.Point(20, 23)
    $txtProxyName = New-Object System.Windows.Forms.TextBox; $txtProxyName.Location = New-Object System.Drawing.Point(150, 20); $txtProxyName.Width = 250
    
    $lblListenPort = New-Object System.Windows.Forms.Label; $lblListenPort.Text = "Listen Port:"; $lblListenPort.Location = New-Object System.Drawing.Point(20, 53)
    $numListenPort = New-Object System.Windows.Forms.NumericUpDown; $numListenPort.Location = New-Object System.Drawing.Point(150, 50); $numListenPort.Width = 100; $numListenPort.Minimum = 1025; $numListenPort.Maximum = 65535; $numListenPort.Value = 8888
    
    $lblTargetHost = New-Object System.Windows.Forms.Label; $lblTargetHost.Text = "Target Host:"; $lblTargetHost.Location = New-Object System.Drawing.Point(20, 83)
    $txtTargetHost = New-Object System.Windows.Forms.TextBox; $txtTargetHost.Location = New-Object System.Drawing.Point(150, 80); $txtTargetHost.Width = 250; $txtTargetHost.Text = "127.0.0.1"
    
    $lblTargetPort = New-Object System.Windows.Forms.Label; $lblTargetPort.Text = "Target Port:"; $lblTargetPort.Location = New-Object System.Drawing.Point(20, 113)
    $numTargetPort = New-Object System.Windows.Forms.NumericUpDown; $numTargetPort.Location = New-Object System.Drawing.Point(150, 110); $numTargetPort.Width = 100; $numTargetPort.Minimum = 1; $numTargetPort.Maximum = 65535; $numTargetPort.Value = 80

    $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = "OK"; $btnOK.Location = New-Object System.Drawing.Point(150, 170); $btnOK.DialogResult = "OK"
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancel"; $btnCancel.Location = New-Object System.Drawing.Point(240, 170); $btnCancel.DialogResult = "Cancel"

    $dialog.Controls.AddRange(@($lblProxyName, $txtProxyName, $lblListenPort, $numListenPort, $lblTargetHost, $txtTargetHost, $lblTargetPort, $numTargetPort, $btnOK, $btnCancel))
    $dialog.AcceptButton = $btnOK; $dialog.CancelButton = $btnCancel

    if ($dialog.ShowDialog($mainForm) -eq "OK") {
        if ([string]::IsNullOrWhiteSpace($txtProxyName.Text) -or [string]::IsNullOrWhiteSpace($txtTargetHost.Text)) {
            [System.Windows.Forms.MessageBox]::Show("All fields are required.", "Validation Error", "OK", "Error"); return
        }
        $portToCheck = $numListenPort.Value
        if(Test-PortInUse -Port $portToCheck) {
            [System.Windows.Forms.MessageBox]::Show("Port $portToCheck is already in use by another application. Please choose a different port.", "Port Conflict", "OK", "Error"); return
        }
        $newProxyName = $txtProxyName.Text
        if ($Global:Config.ProxyServers.ContainsKey($newProxyName)) { [System.Windows.Forms.MessageBox]::Show("A proxy with that name already exists.", "Validation Error", "OK", "Error"); return }
        
        $newProxy = [pscustomobject]@{ Name = $newProxyName; BindIP = "0.0.0.0"; ListenPort = $numListenPort.Value; TargetHost = $txtTargetHost.Text; TargetPort = $numTargetPort.Value; Process = $null }
        $Global:Config.ProxyServers.Add($newProxyName, $newProxy)
        Save-Config
        Update-ProxyServerListView -listView $proxyServersListView
    }
    $dialog.Dispose()
}
#endregion
