<#
.SYNOPSIS
    IconManager - A tool for browsing and compiling .ico files into a resource-only DLL.
    Version: 1.0.0.0
.DESCRIPTION
    Provides a graphical user interface to:
    - Add and remove icon files from a build list.
    - Specify an output DLL name.
    - Compile the selected icons into a resource-only DLL using the MinGW toolchain.
#>

# --- Initial Setup and Configuration ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- [BEGIN] Enhanced Logging Module from gemini.md ---

# 1. --- PORTABLE PATH & CONFIGURATION ---
$ScriptBaseDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ConfigDirName = "IcoHolder_Config"
$ConfigDir = [System.IO.Path]::Combine($ScriptBaseDir, $ConfigDirName)
$LogFilesDir = [System.IO.Path]::Combine($ConfigDir, "Log Files")
$ErrorLogDir = [System.IO.Path]::Combine($LogFilesDir, "Error Logs")
$HistoricalLogDir = [System.IO.Path]::Combine($LogFilesDir, "Historical Logs")
$HistoricalErrorLogDir = [System.IO.Path]::Combine($ErrorLogDir, "Historical Logs")
$Global:LiveLogFile = [System.IO.Path]::Combine($LogFilesDir, "LiveLog.json")

# 2. --- AUTOMATIC DIRECTORY CREATION ---
@($ConfigDir, $LogFilesDir, $ErrorLogDir, $HistoricalLogDir, $HistoricalErrorLogDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# 3. --- LOGGING FUNCTIONS ---
function Archive-OldLogs {
    if (Test-Path $Global:LiveLogFile) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $destination = [System.IO.Path]::Combine($HistoricalLogDir, "LiveLog-$timestamp.json")
            Move-Item -Path $Global:LiveLogFile -Destination $destination -Force
        } catch {
            Write-Warning "Could not archive old LiveLog.json: $($_.Exception.Message)"
        }
    }
    $oldErrorLogs = Get-ChildItem -Path $ErrorLogDir -Filter "*.json"
    foreach ($log in $oldErrorLogs) {
        try {
            $destination = [System.IO.Path]::Combine($HistoricalErrorLogDir, $log.Name)
            Move-Item -Path $log.FullName -Destination $destination -Force
        } catch {
            Write-Warning "Could not archive error log $($log.Name): $($_.Exception.Message)"
        }
    }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL")]
        [string]$Severity = "INFO"
    )
    if ($Severity -eq "WARN") { Write-Warning $Message }
    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Severity  = $Severity
        Message   = $Message
    }
    try {
        $logEntry | ConvertTo-Json | Add-Content -Path $Global:LiveLogFile
    } catch {
        Write-Warning "Failed to write to LiveLog: $($_.Exception.Message)"
    }
}

function Write-ErrorLog {
    param(
        [string]$ContextMessage,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Write-Error -ErrorRecord $ErrorRecord
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $fileNameTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $errorDetails = @{
        Timestamp      = $timestamp
        Context        = $ContextMessage
        Exception_Type = $ErrorRecord.Exception.GetType().FullName
        Exception_Msg  = $ErrorRecord.Exception.Message
        StackTrace     = $ErrorRecord.Exception.StackTrace
        Script_Line    = $ErrorRecord.InvocationInfo.ScriptLineNumber
        Line_Content   = $ErrorRecord.InvocationInfo.Line
    }
    try {
        $errorJson = $errorDetails | ConvertTo-Json -Depth 5
        $destination = [System.IO.Path]::Combine($ErrorLogDir, "ErrorLog-$fileNameTimestamp.json")
        $errorJson | Out-File -FilePath $destination -Encoding UTF8
        Write-Log -Message "An error occurred. Details in ErrorLog-$fileNameTimestamp.json. Context: $ContextMessage" -Severity "ERROR"
    } catch {
        Write-Warning "Could not write to error log: $($_.Exception.Message)"
    }
}

# 4. --- RUN AT STARTUP ---
Archive-OldLogs
Write-Log -Message "Script started. Logging system initialized."

# --- [END] Enhanced Logging Module ---

# --- WinForms GUI Definition ---

[System.Windows.Forms.Application]::EnableVisualStyles()

# Main Window
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Icon DLL Builder v1.1"
$mainForm.Size = New-Object System.Drawing.Size(550, 500)
$mainForm.MinimumSize = New-Object System.Drawing.Size(400, 400)
$mainForm.StartPosition = "CenterScreen"

# Status Strip
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.SizingGrip = $false
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusStrip.Items.Add($statusLabel)
$mainForm.Controls.Add($statusStrip)

# Main Table Layout
$mainTable = New-Object System.Windows.Forms.TableLayoutPanel
$mainTable.Dock = "Fill"
$mainTable.Padding = New-Object System.Windows.Forms.Padding(10)
$mainTable.ColumnCount = 1
$mainTable.RowCount = 3
$mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle "Percent", 100))
$mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle "AutoSize"))
$mainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle "AutoSize"))
$mainForm.Controls.Add($mainTable)
$mainTable.BringToFront()

# GroupBox for Icon List
$iconListGroup = New-Object System.Windows.Forms.GroupBox
$iconListGroup.Text = "Icons to Compile"
$iconListGroup.Dock = "Fill"
$iconListGroup.Padding = New-Object System.Windows.Forms.Padding(10)
$mainTable.Controls.Add($iconListGroup, 0, 0)

# TreeView for Icons
$iconTreeView = New-Object System.Windows.Forms.TreeView
$iconTreeView.Dock = "Fill"
$iconListGroup.Controls.Add($iconTreeView)

# FlowLayoutPanel for Action Buttons
$actionButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$actionButtonPanel.Dock = "Fill"
$actionButtonPanel.FlowDirection = "LeftToRight"
$actionButtonPanel.AutoSize = $true
$mainTable.Controls.Add($actionButtonPanel, 0, 1)

# Button: Add Folder
$btnAddFolder = New-Object System.Windows.Forms.Button
$btnAddFolder.Text = "Add Folder..."
$btnAddFolder.AutoSize = $true
$actionButtonPanel.Controls.Add($btnAddFolder)

# Button: Remove Selected
$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove Selected"
$btnRemove.AutoSize = $true
$actionButtonPanel.Controls.Add($btnRemove)

# Button: Clear List
$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear List"
$btnClear.AutoSize = $true
$actionButtonPanel.Controls.Add($btnClear)

# GroupBox for Build Action
$buildGroup = New-Object System.Windows.Forms.GroupBox
$buildGroup.Text = "Output"
$buildGroup.Dock = "Fill"
$buildGroup.Padding = New-Object System.Windows.Forms.Padding(10)
$mainTable.Controls.Add($buildGroup, 0, 2)

# TableLayoutPanel for Build controls
$buildTable = New-Object System.Windows.Forms.TableLayoutPanel
$buildTable.Dock = "Fill"
$buildTable.ColumnCount = 3
$buildTable.RowCount = 1
$buildTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle "AutoSize"))
$buildTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle "Percent", 100))
$buildTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle "AutoSize"))
$buildGroup.Controls.Add($buildTable)

# Label for DLL Name
$labelDllName = New-Object System.Windows.Forms.Label
$labelDllName.Text = "File Name:"
$labelDllName.Anchor = "Left"
$labelDllName.TextAlign = "MiddleLeft"
$labelDllName.Dock = "Fill"
$buildTable.Controls.Add($labelDllName, 0, 0)

# TextBox for DLL Name
$txtDllName = New-Object System.Windows.Forms.TextBox
$txtDllName.Dock = "Fill"
$txtDllName.Text = "IcoHolder.dll"
$buildTable.Controls.Add($txtDllName, 1, 0)

# Button: Build DLL
$btnBuild = New-Object System.Windows.Forms.Button
$btnBuild.Text = "Build DLL"
$btnBuild.Width = 120
$btnBuild.Anchor = "Right"
$buildTable.Controls.Add($btnBuild, 2, 0)
$mainForm.AcceptButton = $btnBuild


# --- Function to Update Status Bar ---
function Update-Status ($message, $isError=$false) {
    $statusLabel.Text = $message
    if ($isError) {
        Write-Log -Message $message -Severity "ERROR"
    } else {
        Write-Log -Message $message -Severity "INFO"
    }
}


# --- Event Handlers ---

# Helper function to recursively add folders and files to the TreeView
function Add-DirectoryNodes {
    param(
        [System.Windows.Forms.TreeNodeCollection]$parentNode,
        [System.IO.DirectoryInfo]$directoryInfo
    )

    $node = $parentNode.Add($directoryInfo.Name)
    $node.Tag = $directoryInfo.FullName

    foreach ($directory in $directoryInfo.GetDirectories()) {
        Add-DirectoryNodes -parentNode $node.Nodes -directoryInfo $directory
    }

    foreach ($file in $directoryInfo.GetFiles("*.ico")) {
        $fileNode = $node.Nodes.Add($file.Name)
        $fileNode.Tag = $file.FullName
    }
}

# Button: Add Folder
$btnAddFolder.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = "Select a folder containing icons"
    
    if ($folderBrowserDialog.ShowDialog() -eq "OK") {
        $iconTreeView.Nodes.Clear()
        $rootDir = New-Object System.IO.DirectoryInfo($folderBrowserDialog.SelectedPath)
        Add-DirectoryNodes -parentNode $iconTreeView.Nodes -directoryInfo $rootDir
        $iconTreeView.ExpandAll()
        Update-Status "Added folder $($folderBrowserDialog.SelectedPath)"
    }
})

# Button: Remove Selected
$btnRemove.Add_Click({
    if ($iconTreeView.SelectedNode) {
        $iconTreeView.Nodes.Remove($iconTreeView.SelectedNode)
        Update-Status "Removed selected node."
    }
})

# Button: Clear List
$btnClear.Add_Click({
    $iconTreeView.Nodes.Clear()
    Update-Status "Icon tree cleared."
})

# Button: Build DLL
$btnBuild.Add_Click({
    try {
        $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $mainForm.Refresh()

        # --- VALIDATION ---
        Update-Status "Validating inputs..."
        if ($iconTreeView.Nodes.Count -eq 0) {
            throw "Build failed: The icon tree cannot be empty. Please add at least one folder."
        }
        if ([string]::IsNullOrWhiteSpace($txtDllName.Text)) {
            throw "Build failed: The output DLL name cannot be empty."
        }
        $pythonPath = Get-Command python.exe -ErrorAction SilentlyContinue
        if (-not $pythonPath) {
            throw "Build failed: python.exe not found in your system's PATH."
        }
        $pyScriptPath = [System.IO.Path]::Combine($ScriptBaseDir, "ico2dll_named.py")
        if (-not (Test-Path $pyScriptPath)) {
            throw "Build failed: ico2dll_named.py not found."
        }

        # --- SETUP PATHS ---
        $outputDllName = $txtDllName.Text
        $dllOutputPath = [System.IO.Path]::Combine($ScriptBaseDir, $outputDllName)
        
        # --- GATHER ICONS ---
        $iconPairs = @()
        function Get-IconNodes {
            param(
                [System.Windows.Forms.TreeNodeCollection]$nodes,
                [string]$currentPath
            )
            foreach($node in $nodes) {
                if ($node.Nodes.Count -gt 0) {
                    Get-IconNodes -nodes $node.Nodes -currentPath "$currentPath\$($node.Text)"
                } else {
                    $iconName = [System.IO.Path]::GetFileNameWithoutExtension($node.Text)
                    $resName = "$currentPath\$iconName".TrimStart('\')
                    $iconPairs += "`"$resName=$($node.Tag)`""
                }
            }
        }
        Get-IconNodes -nodes $iconTreeView.Nodes -currentPath ""

        if ($iconPairs.Count -eq 0) {
            throw "Build failed: No icons found in the specified folders."
        }

        # --- BUILD DLL ---
        Update-Status "Building DLL with ico2dll_named.py engine..."
        $pythonArgs = "-o `"$dllOutputPath`" $($iconPairs -join ' ')"
        
        $process = Start-Process -FilePath $pythonPath.Source -ArgumentList $pythonArgs -WorkingDirectory $ScriptBaseDir -Wait -PassThru -NoNewWindow -RedirectStandardError "$ScriptBaseDir\py_stderr.log"
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = Get-Content "$ScriptBaseDir\py_stderr.log" -Raw
            throw "Build failed: ico2dll_named.py exited with code $($process.ExitCode). Error: $errorOutput"
        }

        # --- SUCCESS ---
        Update-Status "Success! DLL created at '$dllOutputPath'"

    } catch {
        Update-Status "ERROR: $($_.Exception.Message)" $true
        Write-ErrorLog -ContextMessage "Build process failed." -ErrorRecord $_
    } finally {
        $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})


# --- Show the Form ---
Write-Log -Message "GUI is ready. Showing main form."
$mainForm.ShowDialog() | Out-Null
Write-Log -Message "Script finished."
