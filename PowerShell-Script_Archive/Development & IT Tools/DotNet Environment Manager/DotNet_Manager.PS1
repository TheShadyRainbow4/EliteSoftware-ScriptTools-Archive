#Requires -Version 5.1
<#
.SYNOPSIS
    A GUI-based tool to manage and diagnose .NET installations on Windows.
.DESCRIPTION
    This PowerShell script provides a Windows Forms interface to view installed .NET SDKs and Runtimes,
    check for available downloadable versions, and run diagnostics to troubleshoot common issues,
    such as incorrect PATH environment variables. This version includes enhanced stability, asynchronous
    network operations to prevent UI freezing, and more robust error handling.
.NOTES
    .NET Management Utility v1.0.5 - Created by: Zachary Whiteman & Google Gemini AI. 2025-07-13 - 2:31 PM
    Author: Google Gemini AI
    Version: 1.0.5
    For: Zachary Whiteman
    Company Affiliations: ComputerCare Co. (ComputerCC), TheShadyRainbow Enterprises LLC, EliteSoftware Corp. Limited, ValianTech Repairs, and Zach’s Tech Shop.
#>

# --- Minimize Console Window on Start ---
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("User32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int cmdShow);
'
try {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    # 6 = SW_MINIMIZE
    [Console.Window]::ShowWindow($consolePtr, 6)
}
catch {
    Write-Warning "Could not minimize the console window."
}


# --- Assembly & UI Setup ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# --- Main Form ---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = ".NET Management Utility"
$mainForm.Size = New-Object System.Drawing.Size(800, 600)
$mainForm.MinimumSize = New-Object System.Drawing.Size(700, 500)
$mainForm.StartPosition = 'CenterScreen'
$mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command "powershell.exe").Path)

# --- Status Bar ---
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"
$mainForm.Controls.Add($statusBar)

# --- Tab Control ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = 'Fill'
$mainForm.Controls.Add($tabControl)

# --- ================================================================== ---
# --- TAB 1: INSTALLED VERSIONS                                          ---
# --- ================================================================== ---
$tabInstalled = New-Object System.Windows.Forms.TabPage
$tabInstalled.Text = "Installed Versions"
$tabControl.Controls.Add($tabInstalled)

$installedLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$installedLayoutPanel.Dock = 'Fill'
$installedLayoutPanel.ColumnCount = 1
$installedLayoutPanel.RowCount = 3
$installedLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null
$installedLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$installedLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null
$tabInstalled.Controls.Add($installedLayoutPanel)

$installedHeaderLabel = New-Object System.Windows.Forms.Label
$installedHeaderLabel.Text = "Detected .NET Runtimes and SDKs on this system."
$installedHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$installedHeaderLabel.Dock = 'Fill'
$installedHeaderLabel.TextAlign = 'MiddleCenter'
$installedLayoutPanel.Controls.Add($installedHeaderLabel, 0, 0)

$installedTreeView = New-Object System.Windows.Forms.TreeView
$installedTreeView.Dock = 'Fill'
$installedTreeView.Font = New-Object System.Drawing.Font("Consolas", 10)
$installedTreeView.Padding = New-Object System.Windows.Forms.Padding(5)
$installedLayoutPanel.Controls.Add($installedTreeView, 0, 1)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh List"
$refreshButton.Anchor = 'None'
$refreshButton.AutoSize = $true
$refreshButton.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$installedLayoutPanel.Controls.Add($refreshButton, 0, 2)
$installedLayoutPanel.SetColumnSpan($refreshButton, 1)


# --- ================================================================== ---
# --- TAB 2: DIAGNOSTICS & REPAIR                                        ---
# --- ================================================================== ---
$tabDiagnostics = New-Object System.Windows.Forms.TabPage
$tabDiagnostics.Text = "Diagnostics & Repair"
$tabControl.Controls.Add($tabDiagnostics)

$diagLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$diagLayoutPanel.Dock = 'Fill'
$diagLayoutPanel.ColumnCount = 1
$diagLayoutPanel.RowCount = 3
$diagLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null
$diagLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$diagLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 50))) | Out-Null
$tabDiagnostics.Controls.Add($diagLayoutPanel)

$diagHeaderLabel = New-Object System.Windows.Forms.Label
$diagHeaderLabel.Text = "Run diagnostics to check for common SDK and environment issues."
$diagHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$diagHeaderLabel.Dock = 'Fill'
$diagHeaderLabel.TextAlign = 'MiddleCenter'
$diagLayoutPanel.Controls.Add($diagHeaderLabel, 0, 0)

$diagResultsBox = New-Object System.Windows.Forms.RichTextBox
$diagResultsBox.Dock = 'Fill'
$diagResultsBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$diagResultsBox.ReadOnly = $true
$diagResultsBox.WordWrap = $false
$diagResultsBox.Text = "Click 'Run Diagnostics' to begin..."
$diagLayoutPanel.Controls.Add($diagResultsBox, 0, 1)

$diagButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$diagButtonPanel.Dock = 'Fill'
$diagButtonPanel.FlowDirection = 'LeftToRight'
$diagButtonPanel.Anchor = 'None'
$diagLayoutPanel.Controls.Add($diagButtonPanel, 0, 2)

$runDiagButton = New-Object System.Windows.Forms.Button
$runDiagButton.Text = "Run Diagnostics"
$runDiagButton.AutoSize = $true
$runDiagButton.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$diagButtonPanel.Controls.Add($runDiagButton)

$fixPathButton = New-Object System.Windows.Forms.Button
$fixPathButton.Text = "Attempt to Fix PATH Variable"
$fixPathButton.AutoSize = $true
$fixPathButton.Enabled = $false
$fixPathButton.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$diagButtonPanel.Controls.Add($fixPathButton)

# --- ================================================================== ---
# --- TAB 3: AVAILABLE FOR DOWNLOAD                                      ---
# --- ================================================================== ---
$tabAvailable = New-Object System.Windows.Forms.TabPage
$tabAvailable.Text = "Available for Download"
$tabControl.Controls.Add($tabAvailable)

$availableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
$availableLayoutPanel.Dock = 'Fill'
$availableLayoutPanel.ColumnCount = 1
$availableLayoutPanel.RowCount = 3
$availableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null
$availableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$availableLayoutPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40))) | Out-Null
$tabAvailable.Controls.Add($availableLayoutPanel)

$availableHeaderLabel = New-Object System.Windows.Forms.Label
$availableHeaderLabel.Text = "Fetching available .NET versions from Microsoft... Please wait."
$availableHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$availableHeaderLabel.Dock = 'Fill'
$availableHeaderLabel.TextAlign = 'MiddleCenter'
$availableLayoutPanel.Controls.Add($availableHeaderLabel, 0, 0)

$availableDataGridView = New-Object System.Windows.Forms.DataGridView
$availableDataGridView.Dock = 'Fill'
$availableDataGridView.ReadOnly = $true
$availableDataGridView.AllowUserToAddRows = $false
$availableDataGridView.AllowUserToDeleteRows = $false
$availableDataGridView.AutoSizeColumnsMode = 'Fill'
$availableDataGridView.SelectionMode = 'FullRowSelect'
$availableDataGridView.MultiSelect = $false
$availableLayoutPanel.Controls.Add($availableDataGridView, 0, 1)

$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = "Open Download Page for Selected Version"
$downloadButton.Anchor = 'None'
$downloadButton.AutoSize = $true
$downloadButton.Enabled = $false
$downloadButton.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$availableLayoutPanel.Controls.Add($downloadButton, 0, 2)


# --- ================================================================== ---
# --- SCRIPT LOGIC & FUNCTIONS                                           ---
# --- ================================================================== ---

# --- Function to populate the 'Installed Versions' TreeView ---
function Get-InstalledDotNetVersions {
    $statusBar.Text = "Scanning for installed .NET versions..."
    $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $installedTreeView.Nodes.Clear()

    # --- .NET (Core / 5+) ---
    $dotNetNode = $installedTreeView.Nodes.Add(".NET (Core, 5+)")
    try {
        $sdkOutput = (dotnet --list-sdks 2>&1 | Out-String).Trim()
        $runtimeOutput = (dotnet --list-runtimes 2>&1 | Out-String).Trim()

        if ($sdkOutput -and $sdkOutput -notmatch "No SDKs were found") {
            $sdkNode = $dotNetNode.Nodes.Add("SDKs")
            $sdkOutput.Split([Environment]::NewLine) | ForEach-Object { $sdkNode.Nodes.Add($_) }
        }
        else {
            $dotNetNode.Nodes.Add("No .NET SDKs found.")
        }

        if ($runtimeOutput -and $runtimeOutput -notmatch "No runtimes were found") {
            $runtimeNode = $dotNetNode.Nodes.Add("Runtimes")
            $runtimeOutput.Split([Environment]::NewLine) | ForEach-Object { $runtimeNode.Nodes.Add($_) }
        }
        else {
            $dotNetNode.Nodes.Add("No .NET Runtimes found.")
        }
    }
    catch {
        $dotNetNode.Nodes.Add("Error running 'dotnet' command. Is it in your PATH?")
    }

    # --- .NET Framework (Revised for stability) ---
    $frameworkNode = $installedTreeView.Nodes.Add(".NET Framework")
    $baseKey = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP"
    try {
        # Recursively find all installed framework versions from the registry
        $frameworkKeys = Get-ChildItem -Path $baseKey -Recurse -ErrorAction Stop | ForEach-Object {
            $props = Get-ItemProperty -Path $_.PSPath -Name "Version", "Release", "Install" -ErrorAction SilentlyContinue
            # We only care about keys that signify a full installation
            if ($props.Install -eq 1 -and $props.Version) {
                [PSCustomObject]@{
                    KeyName = $_.PSChildName
                    Version = $props.Version
                    Release = $props.Release
                }
            }
        } | Sort-Object -Property @{ Expression = { [version]$_.Version } } -Unique

        if ($frameworkKeys) {
            foreach ($key in $frameworkKeys) {
                $displayVersion = Get-FrameworkVersionFromRelease -releaseId $key.Release
                $nodeText = ".NET Framework $($key.Version)"
                if ($displayVersion -ne "Unknown Version" -and $displayVersion -ne "Older than 4.5") {
                    $nodeText += " ($displayVersion)"
                }
                if ($key.Release) {
                    $nodeText += " [Release: $($key.Release)]"
                }
                $frameworkNode.Nodes.Add($nodeText)
            }
        }
        else {
            $frameworkNode.Nodes.Add("No .NET Framework versions found in the registry.")
        }
    }
    catch {
        $frameworkNode.Nodes.Add("Error accessing registry. (Did you Run as Admin?)")
        $frameworkNode.Nodes.Add($_.Exception.Message)
    }


    $installedTreeView.ExpandAll()
    $statusBar.Text = "Scan complete."
    $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
}

# Helper to convert .NET Framework release ID to version string
function Get-FrameworkVersionFromRelease {
    param($releaseId)
    if (-not $releaseId) { return "Unknown Version" }
    switch ($releaseId) {
        { $_ -ge 533320 } { return "4.8.1" }
        { $_ -ge 528040 } { return "4.8" }
        { $_ -ge 461808 } { return "4.7.2" }
        { $_ -ge 461308 } { return "4.7.1" }
        { $_ -ge 460798 } { return "4.7" }
        { $_ -ge 394802 } { return "4.6.2" }
        { $_ -ge 394254 } { return "4.6.1" }
        { $_ -ge 393295 } { return "4.6" }
        { $_ -ge 379893 } { return "4.5.2" }
        { $_ -ge 378675 } { return "4.5.1" }
        { $_ -ge 378389 } { return "4.5" }
        default { return "Older than 4.5" }
    }
}

# --- Function to run diagnostics ---
$global:dotNetInfo = $null # Store dotnet --info output globally for the fix function
function Run-Diagnostics {
    $statusBar.Text = "Running diagnostics..."
    $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $fixPathButton.Enabled = $false
    $sb = New-Object System.Text.StringBuilder

    $sb.AppendLine("--- .NET Diagnostics Report ---") | Out-Null
    $sb.AppendLine("Timestamp: $(Get-Date)") | Out-Null
    $sb.AppendLine("=" * 30) | Out-Null

    # 1. Run dotnet --info
    $sb.AppendLine("1. Running 'dotnet --info':") | Out-Null
    try {
        $global:dotNetInfo = dotnet --info 2>&1 | Out-String
        $sb.AppendLine($global:dotNetInfo) | Out-Null
    }
    catch {
        $sb.AppendLine("  ERROR: The 'dotnet' command failed to run.") | Out-Null
        $sb.AppendLine("  This is the primary issue. The .NET SDK is likely not in your PATH environment variable.") | Out-Null
        $global:dotNetInfo = $null
    }

    # 2. Check Environment Variables
    $sb.AppendLine("=" * 30) | Out-Null
    $sb.AppendLine("2. Checking Environment Variables:") | Out-Null
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $dotNetRoot = [Environment]::GetEnvironmentVariable("DOTNET_ROOT", "Process") # Process includes User and Machine

    $sb.AppendLine("  DOTNET_ROOT: $($dotNetRoot)") | Out-Null
    $sb.AppendLine("  --- User PATH ---") | Out-Null
    $sb.AppendLine($userPath) | Out-Null
    $sb.AppendLine("  --- Machine PATH ---") | Out-Null
    $sb.AppendLine($machinePath) | Out-Null

    # 3. Analyze PATH
    $sb.AppendLine("=" * 30) | Out-Null
    $sb.AppendLine("3. PATH Analysis:") | Out-Null
    if ($global:dotNetInfo) {
        $basePath = ($global:dotNetInfo -split '\n' | Where-Object { $_ -like "*Base Path:*" } | Select-Object -First 1) -replace ".*Base Path:\s*", ""
        $sb.AppendLine("  Detected .NET Base Path: $basePath") | Out-Null

        if ($userPath -like "*$basePath*" -or $machinePath -like "*$basePath*") {
            $sb.AppendLine("  [OK] .NET base path appears to be in the system or user PATH.") | Out-Null
        }
        else {
            $sb.AppendLine("  [!! PROBLEM !!] The .NET base path was NOT found in your user or system PATH variable.") | Out-Null
            $sb.AppendLine("  This is the most common reason for 'SDK not found' errors.") | Out-Null
            $sb.AppendLine("  The 'Attempt to Fix PATH' button has been enabled. Run this as an Administrator.") | Out-Null
            $fixPathButton.Enabled = $true
        }
    }
    else {
        $sb.AppendLine("  [!! PROBLEM !!] Could not run 'dotnet --info', so cannot determine the correct path to check.") | Out-Null
        $sb.AppendLine("  Try reinstalling the .NET SDK from the 'Available for Download' tab.") | Out-Null
    }

    $diagResultsBox.Text = $sb.ToString()
    $statusBar.Text = "Diagnostics complete."
    $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
}

# --- Function to Fix PATH Variable ---
function Fix-DotNetPath {
    # Check for Admin rights
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        [System.Windows.Forms.MessageBox]::Show("This action requires administrative privileges. Please re-run this script as an Administrator.", "Administrator Required", "OK", "Warning")
        return
    }

    if (-not $global:dotNetInfo) {
        [System.Windows.Forms.MessageBox]::Show("Cannot attempt a fix because the initial 'dotnet --info' command failed. Please run diagnostics again.", "Error", "OK", "Error")
        return
    }

    $basePath = ($global:dotNetInfo -split '\n' | Where-Object { $_ -like "*Base Path:*" } | Select-Object -First 1) -replace ".*Base Path:\s*", ""
    if (-not [System.IO.Directory]::Exists($basePath)) {
        [System.Windows.Forms.MessageBox]::Show("The detected base path '$basePath' does not exist. Cannot proceed.", "Error", "OK", "Error")
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -like "*$basePath*") {
        [System.Windows.Forms.MessageBox]::Show("The .NET path is already in your User PATH variable. No changes needed.", "Information", "OK", "Information")
        return
    }

    $confirmation = [System.Windows.Forms.MessageBox]::Show("This will add the following path to your USER environment PATH variable:`n`n$basePath`n`nDo you want to continue?", "Confirm PATH Change", "YesNo", "Question")
    if ($confirmation -eq 'No') { return }

    try {
        $newPath = if ([string]::IsNullOrEmpty($userPath)) { $basePath } else { "$($userPath.TrimEnd(';'));$basePath" }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        [System.Windows.Forms.MessageBox]::Show("Successfully updated the User PATH variable.`n`nPlease RESTART PowerShell or any open terminal windows for the changes to take effect.", "Success", "OK", "Information")
        # Re-run diagnostics to show the fix
        Run-Diagnostics
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while setting the environment variable: $($_.Exception.Message)", "Error", "OK", "Error")
    }
}

# --- Function to get available versions asynchronously ---
function Get-AvailableDotNetVersions-Async {
    # Set the UI to a loading state immediately
    $statusBar.Text = "Fetching available versions from Microsoft..."
    $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $availableHeaderLabel.Text = "Fetching available .NET versions... Please wait."
    $downloadButton.Enabled = $false
    
    # This is the work that will be done in the background.
    # It avoids freezing the UI.
    $scriptBlock = {
        $releasesIndexUrl = "https://raw.githubusercontent.com/dotnet/core/main/release-notes/releases-index.json"
        $allReleases = @()
        try {
            # Invoke-RestMethod performs the network request.
            $indexData = Invoke-RestMethod -Uri $releasesIndexUrl -TimeoutSec 15
            
            foreach ($release in $indexData.'releases-index') {
                # We only care about major releases with SDKs that are not End-of-Life (eol)
                if ($release.'channel-version' -and $release.'support-phase' -ne 'eol' -and $release.'releases.json') {
                    $obj = [PSCustomObject]@{
                        Version       = $release.'channel-version'
                        LatestSDK     = $release.'latest-sdk'
                        LatestRuntime = $release.'latest-runtime'
                        Support       = $release.'support-phase'.ToUpper()
                        ReleaseDate   = try { [datetime]$release.'release-date' } catch { $release.'release-date' }
                        DownloadURL   = $release.'releases.json'.Replace('releases.json', 'index.html') # Create a direct link to the download page
                    }
                    $allReleases += $obj
                }
            }
            # Return a hashtable indicating success and the data
            return @{ Success = $true; Data = $allReleases }
        }
        catch {
            # On error, return a hashtable indicating failure and the error message
            return @{ Success = $false; ErrorMessage = $_.Exception.Message }
        }
    }

    # A PowerShell job runs the scriptblock in a separate thread.
    $job = Start-Job -ScriptBlock $scriptBlock

    # We register an event that will fire when the job's state changes (e.g., finishes).
    # This is the callback that will update the UI.
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        param($sender, $eventArgs)

        # Check if the job is finished
        if ($sender.State -eq 'Completed') {
            $result = Receive-Job -Job $sender

            # CRITICAL: UI elements must be updated from the main UI thread.
            # $mainForm.Invoke() marshals the code back to the correct thread.
            $mainForm.Invoke([Action[object]] {
                param($res) # The result from the background job

                if ($res.Success) {
                    $availableHeaderLabel.Text = "Available .NET Versions (from Microsoft)"
                    $availableDataGridView.DataSource = $res.Data
                    $availableDataGridView.Columns['DownloadURL'].Visible = $false
                    $downloadButton.Enabled = $true
                } else {
                    $availableHeaderLabel.Text = "Error fetching data. Check internet connection."
                    [System.Windows.Forms.MessageBox]::Show("Failed to fetch release data from Microsoft: $($res.ErrorMessage)", "Network Error", "OK", "Error")
                }
                # Reset the UI from its loading state
                $statusBar.Text = "Ready."
                $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default

            }, $result) # Pass the result to the Invoke block

            # Clean up the event subscription and the job itself to free resources
            Unregister-Event -SubscriptionId $eventArgs.SourceIdentifier
            Remove-Job -Job $sender
        }
        elseif ($sender.State -in 'Failed', 'Stopped') {
            # Handle cases where the job itself fails to run
             $mainForm.Invoke([Action]{
                $availableHeaderLabel.Text = "A critical error occurred while fetching data."
                $statusBar.Text = "Ready."
                $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
             })
             Unregister-Event -SubscriptionId $eventArgs.SourceIdentifier
             Remove-Job -Job $sender
        }
    } | Out-Null # Pipe to Out-Null to suppress output from Register-ObjectEvent
}


# --- ================================================================== ---
# --- EVENT HANDLERS                                                     ---
# --- ================================================================== ---
$mainForm.Add_Shown({
    # Initial population of data
    Get-InstalledDotNetVersions
    Get-AvailableDotNetVersions-Async # Call the new asynchronous function
})

$refreshButton.Add_Click({
    Get-InstalledDotNetVersions
})

$runDiagButton.Add_Click({
    Run-Diagnostics
})

$fixPathButton.Add_Click({
    Fix-DotNetPath
})

$downloadButton.Add_Click({
    if ($availableDataGridView.SelectedRows.Count -gt 0) {
        $selectedRow = $availableDataGridView.SelectedRows[0].DataBoundItem
        $url = $selectedRow.DownloadURL
        if ($url) {
            try {
                # Use Start-Process for URLs for better handling
                Start-Process $url
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Could not open the URL: $url", "Error", "OK", "Error")
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a version from the list first.", "No Selection", "OK", "Information")
    }
})


# --- ================================================================== ---
# --- MAIN EXECUTION & CLEANUP                                           ---
# --- ================================================================== ---
try {
    # Show the form and wait for it to be closed. This is the main event loop.
    [void]$mainForm.ShowDialog()
}
catch {
    # This block will catch any terminating errors that occur while the form is running.
    Write-Host "A critical error occurred during form execution:" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "StackTrace: $($_.Exception.StackTrace)" -ForegroundColor Gray
    # Keep the console open briefly to see the error
    Start-Sleep -Seconds 15
}
finally {
    # This block runs regardless of whether an error occurred or not.
    
    # Safely dispose of the form to release its resources.
    if ($mainForm -and -not $mainForm.IsDisposed) {
        $mainForm.Dispose()
    }
    
    # Clean up any lingering background jobs on exit
    Get-Job | Remove-Job -Force
    
    Write-Host "`nScript finished. Exiting." -ForegroundColor Green
}
