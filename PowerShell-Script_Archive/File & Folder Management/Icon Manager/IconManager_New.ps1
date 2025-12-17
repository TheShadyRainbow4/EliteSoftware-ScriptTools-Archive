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

# ListBox for Icons
$iconListBox = New-Object System.Windows.Forms.ListBox
$iconListBox.Dock = "Fill"
$iconListBox.SelectionMode = "MultiExtended"
$iconListGroup.Controls.Add($iconListBox)

# FlowLayoutPanel for Action Buttons
$actionButtonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$actionButtonPanel.Dock = "Fill"
$actionButtonPanel.FlowDirection = "LeftToRight"
$actionButtonPanel.AutoSize = $true
$mainTable.Controls.Add($actionButtonPanel, 0, 1)

# Button: Add Icons
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Add Icons..."
$btnAdd.AutoSize = $true
$actionButtonPanel.Controls.Add($btnAdd)

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

# Button: Add Icons
$btnAdd.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select Icon Files"
    $openFileDialog.Filter = "Icon files (*.ico)|*.ico|All files (*.*)|*.*"
    $openFileDialog.Multiselect = $True
    
    if ($openFileDialog.ShowDialog() -eq "OK") {
        foreach ($file in $openFileDialog.FileNames) {
            if (-not $iconListBox.Items.Contains($file)) {
                $iconListBox.Items.Add($file) | Out-Null
            }
        }
        Update-Status "Added $($openFileDialog.FileNames.Count) icon(s) to the list."
    }
})

# Button: Remove Selected
$btnRemove.Add_Click({
    $removedCount = 0
    for ($i = $iconListBox.SelectedItems.Count - 1; $i -ge 0; $i--) {
        $iconListBox.Items.Remove($iconListBox.SelectedItems[$i])
        $removedCount++
    }
    Update-Status "Removed $removedCount icon(s) from the list."
})

# Button: Clear List
$btnClear.Add_Click({
    $iconListBox.Items.Clear()
    Update-Status "Icon list cleared."
})

# Button: Build DLL
$btnBuild.Add_Click({
    try {
        $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $mainForm.Refresh()

        # --- VALIDATION ---
        Update-Status "Validating inputs..."
        if ($iconListBox.Items.Count -eq 0) {
            throw "Build failed: The icon list cannot be empty. Please add at least one icon."
        }
        if ([string]::IsNullOrWhiteSpace($txtDllName.Text)) {
            throw "Build failed: The output DLL name cannot be empty."
        }
        $windresPath = Join-Path -Path $ScriptBaseDir -ChildPath "MinGW\bin\windres.exe"
        if (-not (Test-Path $windresPath)) {
            throw "Build failed: windres.exe not found at '$windresPath'."
        }
        $gppPath = Join-Path -Path $ScriptBaseDir -ChildPath "MinGW\bin\g++.exe"
        if (-not (Test-Path $gppPath)) {
            throw "Build failed: g++.exe not found at '$gppPath'."
        }

        # --- SETUP PATHS ---
        $iconsToBuild = $iconListBox.Items
        $outputDllName = $txtDllName.Text
        $dllOutputPath = [System.IO.Path]::Combine($ScriptBaseDir, $outputDllName)
        $tempDir = [System.IO.Path]::Combine($ScriptBaseDir, "temp")
        if (-not (Test-Path $tempDir)) {
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        }
        $tempRcPath = [System.IO.Path]::Combine($tempDir, "icons.rc")
        $tempResPath = [System.IO.Path]::Combine($tempDir, "icons.res")

        # --- 1. GENERATE .RC FILE ---
        Update-Status "Step 1/3: Generating resource script..."
        $rcContent = @()
        foreach ($iconPath in $iconsToBuild) {
            $iconName = [System.IO.Path]::GetFileNameWithoutExtension($iconPath)
            # Resource names with spaces or special characters should be quoted.
            $rcContent += "`"$iconName`" ICON `"$iconPath`""
        }
        Set-Content -Path $tempRcPath -Value $rcContent -Encoding Ascii

        # --- 2. COMPILE .RC TO .RES ---
        Update-Status "Step 2/3: Compiling resource script with windres..."
        $windresCommand = "& `"$windresPath`" -i `"$tempRcPath`" -o `"$tempResPath`""
        $fullCommand = "pwsh.exe -NoProfile -Command `"`$env:Path = '$($ScriptBaseDir)\MinGW\bin;' + `$env:Path; $windresCommand`""
        Invoke-Expression $fullCommand | Out-Null
        
        if (-not (Test-Path $tempResPath)) {
            throw "Build failed: windres.exe failed to create the .res file."
        }

        # --- 3. LINK .RES TO DLL ---
        Update-Status "Step 3/3: Linking resource file to DLL with g++..."
        $gppCommand = "& `"$gppPath`" -shared -o `"$dllOutputPath`" `"$tempResPath`""
        $fullCommand = "pwsh.exe -NoProfile -Command `"`$env:Path = '$($ScriptBaseDir)\MinGW\bin;' + `$env:Path; $gppCommand`""
        Invoke-Expression $fullCommand | Out-Null
        
        if (-not (Test-Path $dllOutputPath)) {
            throw "Build failed: g++.exe failed to create the DLL."
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
