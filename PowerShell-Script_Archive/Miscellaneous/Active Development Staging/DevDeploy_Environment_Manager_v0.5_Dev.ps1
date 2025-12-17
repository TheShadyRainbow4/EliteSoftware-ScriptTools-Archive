#<
.SYNOPSIS
    Dev-Deploy Environment Manager v0.5
    Created by: Zachary Whiteman & Google Gemini
    Date: 7/14/2025 - 1:06 PM (Original) / 5/20/2024 (Refactored)

.DESCRIPTION
    A comprehensive utility for discovering, installing, and managing Python and .NET environments.
    This tool provides a graphical user interface to simplify development environment setup.
    
v0.5 Update (Major Refactoring & Feature Implementation):
    - Fixed critical bug in Start-Job argument passing for installation/uninstallation tasks.
    - Enhanced Python discovery: Prioritizes `py.exe` (Python Launcher), then PATH, then common install locations.
      Also attempts to link installed Python to Winget IDs for more robust uninstallation.
    - Enhanced .NET discovery: Parses `dotnet --list-sdks` and `dotnet --list-runtimes` into structured objects,
      and attempts to link them to Winget IDs for better uninstallation capabilities.
    - Implemented Python uninstallation (via Winget if linked, or direct folder removal with warning).
    - Implemented .NET uninstallation (via Winget if linked, or dotnet CLI commands).
    - Implemented Pip package management for selected Python installations:
        - List installed packages (`pip list --format json`).
        - Uninstall selected Pip package (`pip uninstall`).
    - Added a 'Launch Terminal' button for selected Python installations.
    - Improved error handling and logging, providing more informative messages in the Activity Log.
    - General code quality improvements, including type safety and consistency.
#>

# --- PowerShell Environment Setup ---

# Minimize Console Window (Non-critical, best-effort)
try {
    $psWindow = (Get-Process -Id $PID).MainWindowHandle
    if ($psWindow) {
        Add-Type -Name Window -Namespace Console -MemberDefinition '
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        '
        [Console.Window]::ShowWindow($psWindow, 6) # 6 corresponds to SW_MINIMIZE
    }
}
catch { Write-Warning "Could not minimize the console window. $($_.Exception.Message)" }

# Add Required .NET Assemblies for WPF GUI
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Enable Visual Styles (Theming) - Robust Method using P/Invoke
# This C# code uses P/Invoke to directly initialize Common Controls v6, which provides
# the modern visual styles. This is the most reliable method for PowerShell scripts.
$cSharpCode = @"
using System;
using System.Runtime.InteropServices;

public class VisualStylesInitializer {
    [StructLayout(LayoutKind.Sequential)]
    public struct INITCOMMONCONTROLSEX {
        public int dwSize;
        public int dwICC;
    }

    [DllImport("comctl32.dll")]
    public static extern bool InitCommonControlsEx(ref INITCOMMONCONTROLSEX iccex);

    public static void Enable() {
        INITCOMMONCONTROLSEX iccex = new INITCOMMONCONTROLSEX();
        iccex.dwSize = Marshal.SizeOf(typeof(INITCOMMONCONTROLSEX));
        // Init all common controls (ICC_BARS | ICC_LISTVIEW_CLASSES | ICC_PROGRESS_CLASS | ICC_TAB_CLASSES | ICC_UPDOWN_CLASS | ICC_TREEVIEW_CLASSES | ICC_WIN95_CLASSES) = 0x40FF
        iccex.dwICC = 0x40FF;
        InitCommonControlsEx(ref iccex);
    }
}
"@
Add-Type -TypeDefinition $cSharpCode
[VisualStylesInitializer]::Enable()

# --- WPF Namespaces for Cleaner XAML Interaction ---
using namespace System.Windows
using namespace System.Windows.Controls
using namespace System.Windows.Data
using namespace System.Windows.Markup
using namespace System.Windows.Media

#================================================================================================
#  XAML DEFINITION FOR THE GUI
#================================================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Dev-Deploy Environment Manager v0.5" Height="600" Width="800"
        WindowStartupLocation="CenterScreen" MinHeight="500" MinWidth="700">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <TabControl x:Name="MainTabControl" Grid.Row="0">
            <!-- Python Environment Tab -->
            <TabItem Header="Python Environment">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,10" Grid.Row="0">
                        <Button x:Name="RefreshPython" Content="Refresh All" Width="120" Margin="0,0,10,0"/>
                        <Label Content="Status:" VerticalAlignment="Center"/>
                        <TextBlock x:Name="PythonStatus" Text="Ready." VerticalAlignment="Center" FontWeight="Bold"/>
                    </StackPanel>
                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="5"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <GroupBox Header="Installed Python Versions" Grid.Column="0">
                            <StackPanel>
                                <ListBox x:Name="InstalledPythonList" Height="Auto" MinHeight="100" MaxHeight="250" />
                                <Button x:Name="UninstallPython" Content="Uninstall Selected Python" Margin="0,5,0,0" Padding="5" IsEnabled="False"/>
                                <Button x:Name="LaunchPythonTerminal" Content="Launch Terminal for Selected Python" Margin="0,5,0,0" Padding="5" IsEnabled="False"/>
                            </StackPanel>
                        </GroupBox>
                        <GridSplitter Grid.Column="1" Width="5" HorizontalAlignment="Stretch" />
                        <GroupBox Header="Available via Winget" Grid.Column="2">
                            <ListBox x:Name="AvailablePythonList" />
                        </GroupBox>
                    </Grid>
                    <StackPanel Grid.Row="2" Orientation="Vertical" Margin="0,10,0,0">
                         <GroupBox Header="Manage Packages (pip) for Selected Installation">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <StackPanel Orientation="Horizontal" Grid.Row="0">
                                    <TextBox x:Name="PipPackageName" Grid.Column="0" Margin="5" VerticalContentAlignment="Center" Width="*"/>
                                    <Button x:Name="InstallPipPackage" Content="Install Package" Grid.Column="1" Margin="5" Padding="10,5" IsEnabled="False"/>
                                </StackPanel>
                                <GroupBox Header="Installed Pip Packages" Grid.Row="1" Margin="0,10,0,0">
                                    <ListBox x:Name="InstalledPipPackagesList" Height="150"/>
                                </GroupBox>
                                <StackPanel Orientation="Horizontal" Grid.Row="2" Margin="0,10,0,0">
                                    <Button x:Name="ListPipPackages" Content="List Packages" Width="120" Margin="0,0,10,0" IsEnabled="False"/>
                                    <Button x:Name="UninstallPipPackage" Content="Uninstall Selected Package" Width="200" IsEnabled="False"/>
                                </StackPanel>
                            </Grid>
                        </GroupBox>
                        <Button x:Name="InstallPython" Content="Install Selected Python Version" Margin="0,10,0,0" Padding="5" IsEnabled="False"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <!-- .NET Environment Tab -->
            <TabItem Header=".NET Environment">
                 <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,10">
                        <Button x:Name="RefreshDotNet" Content="Refresh All" Width="120" Margin="0,0,10,0"/>
                        <Label Content="Status:" VerticalAlignment="Center"/>
                        <TextBlock x:Name="DotNetStatus" Text="Ready." VerticalAlignment="Center" FontWeight="Bold"/>
                    </StackPanel>
                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="5"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <GroupBox Header="Installed .NET SDKs &amp; Runtimes" Grid.Column="0">
                            <StackPanel>
                                <ListBox x:Name="InstalledDotNetList" />
                                <Button x:Name="UninstallDotNet" Content="Uninstall Selected .NET Component" Margin="0,5,0,0" Padding="5" IsEnabled="False"/>
                            </StackPanel>
                        </GroupBox>
                        <GridSplitter Grid.Column="1" Width="5" HorizontalAlignment="Stretch" />
                        <GroupBox Header="Available via Winget" Grid.Column="2">
                             <ListBox x:Name="AvailableDotNetList" />
                        </GroupBox>
                    </Grid>
                    <Button Grid.Row="2" x:Name="InstallDotNet" Content="Install Selected .NET Version" Margin="0,10,0,0" Padding="5" IsEnabled="False"/>
                </Grid>
            </TabItem>
            
            <!-- Activity Log Tab -->
            <TabItem Header="Activity Log">
                <Grid Margin="5">
                    <TextBox x:Name="LogOutput" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" FontFamily="Consolas"/>
                </Grid>
            </TabItem>
        </TabControl>

        <StatusBar Grid.Row="1">
            <StatusBarItem>
                <TextBlock x:Name="MainStatusBar" Text="Welcome to Dev-Deploy!"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

#================================================================================================
#  GUI SETUP AND VARIABLE INITIALIZATION
#================================================================================================
# Load the XAML and get the main window object
$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

# Automatically set PowerShell variables for named XAML elements
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
    Set-Variable -Name $_.Name -Value $window.FindName($_.Name)
}

# Store the path to the selected python installation for use with pip and terminal launch
$SelectedPythonPath = $null

#================================================================================================
#  CORE LOGIC AND FUNCTIONS
#================================================================================================

# --- Logging Function ---
function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry # Output to console as well
    $LogOutput.Dispatcher.InvokeAsync({ # Ensure UI update happens on the UI thread
        $LogOutput.AppendText("$logEntry`n"); 
        $LogOutput.ScrollToEnd()
    }) | Out-Null
}

# --- Generic Background Job Installer/Task Runner ---
function Start-InstallerJob {
    param(
        [Parameter(Mandatory=$true)] [scriptblock]$InstallerScriptBlock,
        [Parameter(Mandatory=$true)] [string]$SoftwareName,
        [Parameter()] [array]$JobArguments = @()
    )
    
    Write-Log "Starting background task for $SoftwareName..."
    $MainStatusBar.Dispatcher.InvokeAsync({ $MainStatusBar.Text = "Running task for $SoftwareName..." }) | Out-Null
    
    $job = Start-Job -ScriptBlock $InstallerScriptBlock -ArgumentList $JobArguments
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        # Access job state and results within the event handler's runspace
        if ($job.State -eq 'Completed' -or $job.State -eq 'Failed' -or $job.State -eq 'Stopped') {
            $result = Receive-Job $job -Keep # Keep the job to allow logging if needed, then remove.
            
            # Invoke on UI thread to update GUI elements
            $window.Dispatcher.InvokeAsync({
                Write-Log "--- Task Log for $SoftwareName ---"
                if ($result.Log) {
                    $result.Log | ForEach-Object { Write-Log $_ }
                }
                Write-Log "--- End Log for $SoftwareName ---"

                if ($result.Success) {
                    Write-Log "Successfully completed task for $SoftwareName." "SUCCESS"
                    $MainStatusBar.Text = "Task for $SoftwareName complete."
                } else {
                    Write-Log "Task for $SoftwareName failed. Check logs for details." "ERROR"
                    $MainStatusBar.Text = "Task for $SoftwareName failed."
                }

                # Always refresh relevant lists after an install/uninstall task completes
                if ($SoftwareName -like "*Python*") {
                    Find-InstalledPython
                    # Find-AvailableSoftware -SearchTerm "Python.Python.3" -TargetListBox $AvailablePythonList -StatusTextBlock $PythonStatus # Not strictly needed here, but good for consistency
                } elseif ($SoftwareName -like "*.NET*") {
                    Find-InstalledDotNet
                    # Find-AvailableSoftware -SearchTerm "Microsoft.DotNet" -TargetListBox $AvailableDotNetList -StatusTextBlock $DotNetStatus
                }
                # For pip operations, refresh the pip list after completion
                if ($SelectedPythonPath -and ($SoftwareName -like "*Pip Package*")) {
                    List-PipPackages -PythonPath $SelectedPythonPath
                }

            }) | Out-Null
            
            Remove-Job $job -Force # Clean up the job
            Unregister-Event -SourceIdentifier $job.id
        }
    } | Out-Null
}

# --- Functions to Find Available Software (Winget) ---
function Find-AvailableSoftware {
    param(
        [Parameter(Mandatory=$true)] [string]$SearchTerm,
        [Parameter(Mandatory=$true)] [System.Windows.Controls.ListBox]$TargetListBox,
        [Parameter(Mandatory=$true)] [System.Windows.Controls.TextBlock]$StatusTextBlock
    )
    
    $StatusTextBlock.Dispatcher.InvokeAsync({ $StatusTextBlock.Text = "Searching winget..." }) | Out-Null
    $TargetListBox.Dispatcher.InvokeAsync({ $TargetListBox.Items.Clear() }) | Out-Null
    
    $scriptBlock = {
        param($term)
        $log = @()
        $items = [System.Collections.Generic.List[PSCustomObject]]::new()
        try {
            $log += "Executing: winget search $term --accept-source-agreements"
            # Capturing winget output directly can be tricky. Pipe to Out-String.
            $results = winget search $term --accept-source-agreements 2>&1 | Out-String
            
            # Robust parsing using RegEx to split by 2 or more spaces
            $resultsLines = $results -split "`n" | Select-Object -Skip 2 | Where-Object { $_ -match "\S" }
            
            foreach ($line in $resultsLines) {
                # Example format: Name                Id                      Version         Match         Source
                #                Python 3.10         Python.Python.3.10      3.10.11.0       Tag           winget
                # Regex to capture Name, ID, Version, and Source reliably
                if ($line -match "^\s*(?<name>.+?)\s{2,}(?<id>[^\s]+)\s{2,}(?<version>[^\s]+)\s{2,}(?<match>.*?[^\s])?\s{2,}(?<source>[^\s]+)\s*$") {
                    $name = $Matches['name'].Trim()
                    $id = $Matches['id'].Trim()
                    $version = $Matches['version'].Trim()
                    $source = $Matches['source'].Trim()
                    
                    # Filter based on Winget ID starts with search term to ensure relevance
                    if ($id -like "$term*") {
                        $items.Add([PSCustomObject]@{ 
                            DisplayName = "$name $version ($source)"
                            WingetId    = $id
                            Version     = $version
                            Source      = $source
                        })
                    }
                }
            }
            $log += "Found $($items.Count) items for '$term'."
            return [PSCustomObject]@{ Success = $true; Items = $items; Log = $log }
        } catch {
            $log += "ERROR: Failed to execute winget search for '$term'. Is winget installed and in your PATH? Error: $($_.Exception.Message)"
            return [PSCustomObject]@{ Success = $false; Items = $null; Log = $log }
        }
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $SearchTerm
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($job.State -eq 'Completed') {
            $result = Receive-Job $job -Keep
            $window.Dispatcher.InvokeAsync({
                $result.Log | ForEach-Object { Write-Log $_ }
                if ($result.Success) {
                    $result.Items | ForEach-Object { $TargetListBox.Items.Add($_) }
                    $StatusTextBlock.Text = "Found $($TargetListBox.Items.Count) versions."
                } else {
                    $StatusTextBlock.Text = "Winget search failed."
                }
            }) | Out-Null
            Remove-Job $job -Force
            Unregister-Event -SourceIdentifier $job.id
        }
    } | Out-Null
}

# --- Functions to Find Installed Software ---
function Find-InstalledPython {
    Write-Log "Scanning for existing Python installations..."
    $InstalledPythonList.Dispatcher.InvokeAsync({ $InstalledPythonList.Items.Clear() }) | Out-Null
    $InstalledPipPackagesList.Dispatcher.InvokeAsync({ $InstalledPipPackagesList.Items.Clear() }) | Out-Null
    
    # Use a background job to avoid freezing the UI during the scan
    $job = Start-Job -ScriptBlock {
        $foundPythons = [System.Collections.Generic.List[PSCustomObject]]::new()
        $log = @()
        $processedPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        # Helper function to add a Python entry, check for uniqueness, and link WingetId
        function Add-PythonEntry {
            param(
                [string]$Path,
                [string]$SourceLabel,
                [System.Collections.Generic.List[PSCustomObject]]$AllPythonsList,
                [System.Collections.Generic.HashSet[string]]$ProcessedPathsSet,
                [System.Collections.Hashtable]$InstalledFromWingetDict,
                [System.Collections.Generic.List[string]]$LogList
            )
            $pythonExe = Join-Path $Path "python.exe"
            if (Test-Path $pythonExe -and -not $ProcessedPathsSet.Contains($Path)) {
                try {
                    $versionOutput = (& $pythonExe --version 2>&1) | Out-String
                    if ($versionOutput -match "Python\s+(\d+\.\d+\.\d+)") {
                        $version = $Matches[1]
                        $psobject = [PSCustomObject]@{ 
                            DisplayName = "Python $version ($SourceLabel)"
                            Path = $Path
                            WingetId = $null
                            Version = $version
                        }
                        $versionMajorMinor = ($version -split '\.')[0..1] -join '.' # e.g., "3.9"
                        # Attempt to link with Winget ID based on version
                        $wingetCandidateVersion = "Python $versionMajorMinor"
                        if ($InstalledFromWingetDict.ContainsKey($wingetCandidateVersion)) {
                            $psobject.WingetId = $InstalledFromWingetDict[$wingetCandidateVersion]
                            $psobject.DisplayName += " (Winget linked)"
                        }
                        $AllPythonsList.Add($psobject)
                        $ProcessedPathsSet.Add($Path)
                        $LogList += "Found Python $version at $Path ($SourceLabel)"
                    }
                } catch {
                    $LogList += "Could not get version for $pythonExe: $($_.Exception.Message)"
                }
            }
        }

        # 1. Discover Winget-installed Pythons first to build a lookup table
        $installedFromWinget = [System.Collections.Hashtable]::new([StringComparer]::OrdinalIgnoreCase)
        try {
            $log += "Searching installed Winget packages for Python..."
            $wingetResults = winget list --query "Python" --accept-source-agreements 2>&1 | Out-String
            $wingetLines = $wingetResults -split "`n" | Select-Object -Skip 2 | Where-Object { $_ -match "\S" }
            
            foreach ($line in $wingetLines) {
                if ($line -match "^\s*(?<name>.+?)\s{2,}(?<id>[^\s]+)\s{2,}(?<version>[^\s]+)\s{2,}(?<match>.*?[^\s])?\s{2,}(?<source>[^\s]+)\s*$") {
                    $wingetName = $Matches['name'].Trim()
                    $wingetId = $Matches['id'].Trim()
                    $wingetVersion = $Matches['version'].Trim()
                    
                    if ($wingetName -match "Python\s+(\d+\.\d+(\.\d+)?)") {
                         $versionKey = $Matches[1] # e.g. "3.9" or "3.9.13"
                         $installedFromWinget["Python $versionKey"] = $wingetId
                    }
                    $log += "Discovered Winget Python: $wingetName (ID: $wingetId, Version: $wingetVersion)"
                }
            }
        } catch {
            $log += "Error during winget list for Python: $($_.Exception.Message)"
        }

        # 2. Check Python Launcher (py.exe)
        try {
            $pyExePath = (Get-Command py.exe -ErrorAction SilentlyContinue)?.Path
            if ($pyExePath) {
                $log += "Using 'py.exe' to discover Python installations."
                $pyOutput = & $pyExePath -0p 2>&1 | Out-String # Capture all output
                $pyOutputLines = $pyOutput -split "`n" | Where-Object { $_ -match "^\s*(\d+\.\d+)(-64)?\s*(.*)$" }
                
                foreach ($line in $pyOutputLines) {
                    if ($line -match "^\s*(\d+\.\d+)(-64)?\s*(.*)$") {
                        $version = $Matches[1]
                        $path = $Matches[3].Trim()
                        Add-PythonEntry -Path $path -SourceLabel "via py.exe" -AllPythonsList $foundPythons -ProcessedPathsSet $processedPaths -InstalledFromWingetDict $installedFromWinget -LogList $log
                    }
                }
            } else {
                $log += "py.exe not found, skipping Python Launcher discovery."
            }
        } catch {
            $log += "Error during py.exe discovery: $($_.Exception.Message)"
        }

        # 3. Check PATH environment variable
        try {
            $pathEntries = ($env:Path -split ';') | Where-Object { $_ -ne "" } | Select-Object -Unique
            foreach ($entry in $pathEntries) {
                Add-PythonEntry -Path $entry -SourceLabel "via PATH" -AllPythonsList $foundPythons -ProcessedPathsSet $processedPaths -InstalledFromWingetDict $installedFromWinget -LogList $log
            }
        } catch {
            $log += "Error during PATH scan: $($_.Exception.Message)"
        }

        # 4. Check common installation directories (fallback)
        $commonInstallRoots = @(
            "$env:ProgramFiles\Python*",
            "$env:ProgramFiles(x86)\Python*",
            (Join-Path $env:LOCALAPPDATA "Programs\Python"),
            (Join-Path $env:APPDATA "Python")
        )
        foreach ($root in $commonInstallRoots) {
            try {
                Get-ChildItem -Path $root -Directory -Depth 2 -ErrorAction SilentlyContinue | ForEach-Object {
                    Add-PythonEntry -Path $_.FullName -SourceLabel "manual scan" -AllPythonsList $foundPythons -ProcessedPathsSet $processedPaths -InstalledFromWingetDict $installedFromWinget -LogList $log
                }
            } catch {
                $log += "Error during common install root scan ($root): $($_.Exception.Message)"
            }
        }
        
        # Final unique selection and sorting
        $uniqueFoundPythons = $foundPythons | Select-Object -Unique -Property Path | Sort-Object { [version]$_.Version } -Descending

        return [PSCustomObject]@{ FoundPythons = $uniqueFoundPythons; Log = $log }
    }
    
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($job.State -eq 'Completed') {
            $result = Receive-Job $job -Keep
            $window.Dispatcher.InvokeAsync({
                $result.Log | ForEach-Object { Write-Log $_ }
                if ($result.FoundPythons.Count -eq 0) {
                    Write-Log "No Python installations found." "WARN"
                    $PythonStatus.Text = "No local Python found."
                } else {
                    $result.FoundPythons | ForEach-Object { $InstalledPythonList.Items.Add($_) }
                    Write-Log "Found $($result.FoundPythons.Count) Python installation(s)." "INFO"
                    $PythonStatus.Text = "Found $($result.FoundPythons.Count) Python installation(s)."
                }
            }) | Out-Null
            Remove-Job $job -Force
            Unregister-Event -SourceIdentifier $job.id
        }
    } | Out-Null
}

function Find-InstalledDotNet {
    Write-Log "Scanning for .NET SDKs and Runtimes..."
    $InstalledDotNetList.Dispatcher.InvokeAsync({ $InstalledDotNetList.Items.Clear() }) | Out-Null
    
    $job = Start-Job -ScriptBlock {
        $foundDotNets = [System.Collections.Generic.List[PSCustomObject]]::new()
        $log = @()

        # 1. Discover via 'dotnet --list-sdks'
        try {
            $log += "Listing .NET SDKs..."
            $sdksOutput = & dotnet --list-sdks 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0 -and $sdksOutput -notmatch "^\s*\d+\.\d+\.\d+\s*\[.*?\]$") {
                $log += "'dotnet --list-sdks' failed or returned unexpected output. Error: $sdksOutput" "ERROR"
            } else {
                $sdksOutput -split "`n" | Where-Object { $_ -match "^\s*(\d+\.\d+\.\d+)\s*\[(.*)\]$" } | ForEach-Object {
                    $version = $Matches[1].Trim()
                    $path = $Matches[2].Trim()
                    $foundDotNets.Add([PSCustomObject]@{ 
                        DisplayName = "SDK: $version"
                        Type = "SDK"
                        Version = $version
                        Path = $path
                        WingetId = $null
                    })
                    $log += "Found SDK: $version at $path"
                }
            }
        } catch {
            $log += "Error listing .NET SDKs: $($_.Exception.Message)" "ERROR"
            $log += "Please ensure 'dotnet' CLI is installed and in your PATH."
        }

        # 2. Discover via 'dotnet --list-runtimes'
        try {
            $log += "Listing .NET Runtimes..."
            $runtimesOutput = & dotnet --list-runtimes 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0 -and $runtimesOutput -notmatch "^\s*[^\s]+\s*\d+\.\d+\.\d+\s*\[.*?\]$") {
                 $log += "'dotnet --list-runtimes' failed or returned unexpected output. Error: $runtimesOutput" "ERROR"
            } else {
                $runtimesOutput -split "`n" | Where-Object { $_ -match "^\s*([^\s]+)\s*(\d+\.\d+\.\d+)\s*\[(.*)\]$" } | ForEach-Object {
                    $runtimeName = $Matches[1].Trim() # e.g., Microsoft.AspNetCore.App
                    $version = $Matches[2].Trim()
                    $path = $Matches[3].Trim()
                    $foundDotNets.Add([PSCustomObject]@{ 
                        DisplayName = "Runtime: $runtimeName $version"
                        Type = "Runtime"
                        RuntimeName = $runtimeName
                        Version = $version
                        Path = $path
                        WingetId = $null
                    })
                    $log += "Found Runtime: $runtimeName $version at $path"
                }
            }
        } catch {
            $log += "Error listing .NET Runtimes: $($_.Exception.Message)" "ERROR"
        }
        
        # 3. Discover via 'winget list --query Microsoft.DotNet' to find Winget IDs and link them
        try {
            $log += "Searching installed Winget packages for .NET components..."
            $wingetResults = winget list --query "Microsoft.DotNet" --accept-source-agreements 2>&1 | Out-String
            $wingetLines = $wingetResults -split "`n" | Select-Object -Skip 2 | Where-Object { $_ -match "\S" }
            
            foreach ($line in $wingetLines) {
                 if ($line -match "^\s*(?<name>.+?)\s{2,}(?<id>[^\s]+)\s{2,}(?<version>[^\s]+)\s{2,}(?<match>.*?[^\s])?\s{2,}(?<source>[^\s]+)\s*$") {
                    $wingetName = $Matches['name'].Trim()
                    $wingetId = $Matches['id'].Trim()
                    $wingetVersion = $Matches['version'].Trim()

                    $linked = $false
                    foreach ($item in $foundDotNets) {
                        # Link SDKs: 