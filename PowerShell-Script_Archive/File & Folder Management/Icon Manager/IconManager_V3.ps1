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
$iconTreeView.AllowDrop = $true
$iconListGroup.Controls.Add($iconTreeView)

$iconTreeView.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})

$iconTreeView.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach ($file in $files) {
        if ((Get-Item $file).PSIsContainer) {
            $rootDir = New-Object System.IO.DirectoryInfo($file)
            Add-DirectoryNodes -parentNode $iconTreeView.Nodes -directoryInfo $rootDir -imgList $imageList
            $iconTreeView.ExpandAll()
            Update-Status "Added folder $file"
        }
    }
})

$imageList = New-Object System.Windows.Forms.ImageList
$iconTreeView.ImageList = $imageList

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

$buildButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buildButtonPanel.Dock = "Fill"
$buildButtonPanel.FlowDirection = "RightToLeft"
$buildButtonPanel.AutoSize = $true
$buildTable.Controls.Add($buildButtonPanel, 2, 0)

# Button: Build DLL
$btnBuild = New-Object System.Windows.Forms.Button
$btnBuild.Text = "Build DLL"
$btnBuild.Width = 120
$btnBuild.Anchor = "Right"
$buildButtonPanel.Controls.Add($btnBuild)

# Button: Build RC/RES Only
$btnBuildRes = New-Object System.Windows.Forms.Button
$btnBuildRes.Text = "Build RC/RES Only"
$btnBuildRes.Width = 120
$btnBuildRes.Anchor = "Right"
$buildButtonPanel.Controls.Add($btnBuildRes)

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
        [System.IO.DirectoryInfo]$directoryInfo,
        [System.Windows.Forms.ImageList]$imgList
    )

    $node = $parentNode.Add($directoryInfo.Name)
    $node.Tag = $directoryInfo.FullName

    foreach ($directory in $directoryInfo.GetDirectories()) {
        Add-DirectoryNodes -parentNode $node.Nodes -directoryInfo $directory -imgList $imgList
    }

    foreach ($file in $directoryInfo.GetFiles("*.ico")) {
        try {
            $icon = New-Object System.Drawing.Icon($file.FullName)
            $imgList.Images.Add($icon)
            $fileNode = $node.Nodes.Add($file.Name)
            $fileNode.Tag = $file.FullName
            $fileNode.ImageIndex = $imgList.Images.Count - 1
            $fileNode.SelectedImageIndex = $imgList.Images.Count - 1
        } catch {
            Write-Log -Message "Failed to load icon: $($file.FullName)" -Severity "WARN"
        }
    }
}

# Button: Add Folder
$btnAddFolder.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = "Select a folder containing icons"
    
    if ($folderBrowserDialog.ShowDialog() -eq "OK") {
        $rootDir = New-Object System.IO.DirectoryInfo($folderBrowserDialog.SelectedPath)
        Add-DirectoryNodes -parentNode $iconTreeView.Nodes -directoryInfo $rootDir -imgList $imageList
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
function Get-IconNodes($nodes, $currentPath) {
    $pairs = @()
    foreach($node in $nodes) {
        $item = Get-Item -LiteralPath $node.Tag
        if ($item.PSIsContainer) {
            $pairs += Get-IconNodes -nodes $node.Nodes -currentPath "$currentPath\$($node.Text)"
        } else {
            $iconName = [System.IO.Path]::GetFileNameWithoutExtension($node.Text)
            $resName = "$currentPath\$iconName".TrimStart('\')
            $pairs += "`"$resName=$($node.Tag)`""
        }
    }
    return $pairs
}

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
        $iconPairs = Get-IconNodes -nodes $iconTreeView.Nodes -currentPath ""

        if ($iconPairs.Count -eq 0) {
            throw "Build failed: No icons found in the specified folders."
        }

        # --- BUILD DLL ---
        Update-Status "Building DLL with ico2dll_named.py engine..."
        $pythonArgs = "`"$pyScriptPath`" -o `"$dllOutputPath`" $($iconPairs -join ' ')"
        
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

function Get-IconNodesForRc($nodes, $currentPath) {
    $content = @()
    foreach($node in $nodes) {
        $item = Get-Item -LiteralPath $node.Tag
        if ($item.PSIsContainer) {
            $content += Get-IconNodesForRc -nodes $node.Nodes -currentPath "$currentPath\$($node.Text)"
        } else {
            $iconName = [System.IO.Path]::GetFileNameWithoutExtension($node.Text)
            $resName = "$currentPath\$iconName".TrimStart('\')
            $content += "`"$resName`" ICON `"$($node.Tag)`""
        }
    }
    return $content
}

$btnBuildRes.Add_Click({
    try {
        $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $mainForm.Refresh()

        # --- VALIDATION ---
        Update-Status "Validating inputs..."
        if ($iconTreeView.Nodes.Count -eq 0) {
            throw "Build failed: The icon tree cannot be empty. Please add at least one folder."
        }
        $resourceHackerPath = Join-Path -Path $ScriptBaseDir -ChildPath "ResourceHacker.exe"
        if (-not (Test-Path $resourceHackerPath)) {
            throw "Build failed: ResourceHacker.exe not found at '$resourceHackerPath'."
        }

        # --- SETUP PATHS ---
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($txtDllName.Text)
        $rcPath = [System.IO.Path]::Combine($ScriptBaseDir, "$outputName.rc")
        $resPath = [System.IO.Path]::Combine($ScriptBaseDir, "$outputName.res")
        
        # --- GATHER ICONS ---
        $rcContent = Get-IconNodesForRc -nodes $iconTreeView.Nodes -currentPath ""
        
        if ($rcContent.Count -eq 0) {
            throw "Build failed: No icons found in the specified folders."
        }
        
        Set-Content -Path $rcPath -Value $rcContent -Encoding Ascii

        # --- COMPILE .RC TO .RES ---
        Update-Status "Compiling resource script with ResourceHacker..."
        $rhArgs = "-open `"$rcPath`" -save `"$resPath`" -action compile"
        $process = Start-Process -FilePath $resourceHackerPath -ArgumentList $rhArgs -WorkingDirectory $ScriptBaseDir -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Build failed: ResourceHacker.exe failed to compile the .rc file. Exit code: $($process.ExitCode)"
        }

        # --- SUCCESS ---
        Update-Status "Success! RC and RES files created at '$ScriptBaseDir'"

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
