<#
.SYNOPSIS
    A PowerShell script with a Windows Forms GUI to chat with a local AI model via the LM Studio API.
.DESCRIPTION
    This script provides a graphical user interface for interacting with an AI model
    hosted by LM Studio. It allows the user to:
    - Specify the LM Studio server address.
    - Fetch and select from a list of available models on the server.
    - Set a custom system prompt to define the AI's behavior.
    - Engage in a back-and-forth conversation with the selected model.
    - The chat history is maintained for conversational context.
.NOTES
    Author: Gemini
    Version: 1.4
    Requirements: PowerShell 5.1 or later.
    Changes: Re-architected the script to move event handler logic into separate, dedicated
             functions for improved stability. Added more detailed startup logging and a
             fallback for the log file path if $PSScriptRoot is not available. This is the
             most robust version for debugging instant-crash scenarios.
#>

# ---[ Logging Setup ]---
# This is the very first block of code to run.

# Determine the script's directory. If it's not available (e.g., running in ISE),
# fall back to the user's temporary directory.
if ($PSScriptRoot) {
    $ScriptPath = $PSScriptRoot
} else {
    $ScriptPath = $env:TEMP
}
$Logfile = Join-Path -Path $ScriptPath -ChildPath "LMChatGUI.log"

# Define a robust logging function.
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$($Level.ToUpper())] $Message"
    try {
        Add-Content -Path $Logfile -Value $LogEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "CRITICAL: Could not write to log file at '$Logfile'. Error: $_"
    }
    # Also write to the console for immediate feedback.
    Write-Host $LogEntry
}

# ---[ Main Execution Block ]---
# This is the entry point of the script.
Write-Log "----------------------------------------------------"
Write-Log "Script execution started."
Write-Log "Log file location is: $Logfile"

try {
    # ---[ Load Assemblies First ]---
    # If this fails, the GUI cannot run. It's done outside the main function
    # to catch the earliest possible point of failure.
    Write-Log "Attempting to load required .NET Assemblies..."
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Write-Log ".NET Assemblies loaded successfully."

    # ---[ Define Functions ]---
    # The script now defines all functions before attempting to create the GUI.

    # Function to handle fetching models from the server
    function Get-LMStudioModels {
        param($form, $serverTextBox, $modelComboBox, $systemPromptTextBox, $userInputBox, $sendButton, $statusBar)
        
        $statusBar.Text = "Connecting..."
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        $serverUrl = $serverTextBox.Text
        $modelsEndpoint = "$serverUrl/v1/models"
        Write-Log "Attempting to fetch models from: $modelsEndpoint"

        try {
            $response = Invoke-RestMethod -Uri $modelsEndpoint -Method Get -TimeoutSec 10 -ErrorAction Stop
            $modelComboBox.Items.Clear()
            if ($response.data) {
                $response.data | ForEach-Object { $modelComboBox.Items.Add($_.id) }
                if ($modelComboBox.Items.Count -gt 0) { $modelComboBox.SelectedIndex = 0 }

                $modelComboBox.Enabled = $true
                $systemPromptTextBox.Enabled = $true
                $userInputBox.Enabled = $true
                $sendButton.Enabled = $true
                
                $statusBar.Text = "Success! Found $($modelComboBox.Items.Count) models. Ready."
                Write-Log "Successfully fetched $($modelComboBox.Items.Count) models."
            } else {
                [System.Windows.Forms.MessageBox]::Show("Could not find any loaded models. Please load a model in LM Studio first.", "No Models Found", "OK", "Warning")
                $statusBar.Text = "Connection successful, but no models found."
                Write-Log "Connection OK, but no models were loaded on the server."
            }
        }
        catch {
            $errorMessage = $_.Exception.GetBaseException().Message
            [System.Windows.Forms.MessageBox]::Show("Failed to connect to LM Studio at '$serverUrl'.`n`nError: $errorMessage`n`nPlease ensure LM Studio is running and the server is enabled.", "Connection Error", "OK", "Error")
            $statusBar.Text = "Connection failed."
            Write-Log "Connection to LM Studio failed. Error: $errorMessage" "ERROR"
        }
        finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }

    # Function to handle sending a message and receiving a response
    function Send-LMChatMessage {
        param($form, $serverTextBox, $modelComboBox, $systemPromptTextBox, $userInputBox, $sendButton, $chatHistoryBox, $statusBar)

        $userMessage = $userInputBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($userMessage)) { return }
    
        $statusBar.Text = "Thinking..."
        $sendButton.Enabled = $false; $userInputBox.Enabled = $false
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        Add-TextToChatBox -Role 'You' -Content $userMessage -chatHistoryBox $chatHistoryBox
        
        # Rebuild the chat history for the API call
        $messages = [System.Collections.Generic.List[object]]::new()
        $messages.Add([PSCustomObject]@{role = 'system'; content = $systemPromptTextBox.Text })
        $lines = $chatHistoryBox.Text.Split([string[]]"`n`n", [System.StringSplitOptions]::RemoveEmptyEntries)
        foreach ($line in $lines) {
            if ($line -match '^(You|AI): (.*)') {
                $role = if ($Matches[1] -eq 'You') { 'user' } else { 'assistant' }
                $content = $Matches[2]
                $messages.Add([PSCustomObject]@{role = $role; content = $content})
            }
        }

        $payload = @{
            model = $modelComboBox.SelectedItem
            messages = $messages
            temperature = 0.7
            stream = $false
        } | ConvertTo-Json -Depth 5

        $serverUrl = $serverTextBox.Text
        $chatEndpoint = "$serverUrl/v1/chat/completions"
        Write-Log "Sending payload to $chatEndpoint"

        try {
            $response = Invoke-RestMethod -Uri $chatEndpoint -Method Post -Body $payload -ContentType "application/json" -ErrorAction Stop
            $aiMessage = $response.choices[0].message.content.Trim()
            Add-TextToChatBox -Role 'AI' -Content $aiMessage -chatHistoryBox $chatHistoryBox
            $statusBar.Text = "Ready."
        }
        catch {
            $errorMessage = $_.Exception.GetBaseException().Message
            [System.Windows.Forms.MessageBox]::Show("An error occurred communicating with the model.`n`nError: $errorMessage", "API Error", "OK", "Error")
            $statusBar.Text = "Error receiving response."
            Write-Log "API Error: $errorMessage" "ERROR"
        }
        finally {
            $userInputBox.Clear(); $userInputBox.Focus()
            $sendButton.Enabled = $true; $userInputBox.Enabled = $true
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }

    # Helper function to format text in the chat box
    function Add-TextToChatBox {
        param([string]$Role, [string]$Content, $chatHistoryBox)
        $color = if ($Role -eq 'You') { [System.Drawing.Color]::Blue } else { [System.Drawing.Color]::DarkGreen }
        $chatHistoryBox.SelectionStart = $chatHistoryBox.TextLength; $chatHistoryBox.SelectionLength = 0
        $chatHistoryBox.SelectionFont = New-Object System.Drawing.Font($chatHistoryBox.Font, [System.Drawing.FontStyle]::Bold)
        $chatHistoryBox.SelectionColor = $color; $chatHistoryBox.AppendText("$Role: ")
        $chatHistoryBox.SelectionStart = $chatHistoryBox.TextLength; $chatHistoryBox.SelectionLength = 0
        $chatHistoryBox.SelectionFont = New-Object System.Drawing.Font($chatHistoryBox.Font, [System.Drawing.FontStyle]::Regular)
        $chatHistoryBox.SelectionColor = [System.Drawing.Color]::Black; $chatHistoryBox.AppendText($Content + "`n`n")
        $chatHistoryBox.ScrollToCaret()
    }
    
    # Main function to build and show the GUI
    function Start-LMChatGui {
        Write-Log "Initializing GUI function."
        
        # --- GUI Element Creation ---
        Write-Log "Creating main form..."
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "PowerShell LM Studio Chat"
        $form.Size = New-Object System.Drawing.Size(600, 720)
        $form.MinimumSize = New-Object System.Drawing.Size(500, 600)
        $form.StartPosition = 'CenterScreen'
        $form.FormBorderStyle = 'Sizable'

        try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$PSHOME\powershell.exe") } catch { Write-Log "Could not load PowerShell icon." "WARN" }

        # --- Create Controls ---
        $serverLabel = New-Object System.Windows.Forms.Label; $serverLabel.Text = "LM Studio Address:"; $serverLabel.Location = New-Object System.Drawing.Point(10, 15); $serverLabel.AutoSize = $true
        $serverTextBox = New-Object System.Windows.Forms.TextBox; $serverTextBox.Text = "http://192.168.10.100:1234"; $serverTextBox.Location = New-Object System.Drawing.Point(140, 12); $serverTextBox.Size = New-Object System.Drawing.Size(270, 20); $serverTextBox.Anchor = 'Top, Left, Right'
        $fetchModelsButton = New-Object System.Windows.Forms.Button; $fetchModelsButton.Text = "Connect"; $fetchModelsButton.Location = New-Object System.Drawing.Point(420, 10); $fetchModelsButton.Size = New-Object System.Drawing.Size(150, 25); $fetchModelsButton.Anchor = 'Top, Right'
        $modelLabel = New-Object System.Windows.Forms.Label; $modelLabel.Text = "Select Model:"; $modelLabel.Location = New-Object System.Drawing.Point(10, 45); $modelLabel.AutoSize = $true
        $modelComboBox = New-Object System.Windows.Forms.ComboBox; $modelComboBox.Location = New-Object System.Drawing.Point(140, 42); $modelComboBox.Size = New-Object System.Drawing.Size(430, 20); $modelComboBox.DropDownStyle = 'DropDownList'; $modelComboBox.Enabled = $false; $modelComboBox.Anchor = 'Top, Left, Right'
        $systemPromptLabel = New-Object System.Windows.Forms.Label; $systemPromptLabel.Text = "System Prompt:"; $systemPromptLabel.Location = New-Object System.Drawing.Point(10, 75); $systemPromptLabel.AutoSize = $true
        $systemPromptTextBox = New-Object System.Windows.Forms.TextBox; $systemPromptTextBox.Text = "You are a helpful assistant."; $systemPromptTextBox.Location = New-Object System.Drawing.Point(140, 72); $systemPromptTextBox.Size = New-Object System.Drawing.Size(430, 60); $systemPromptTextBox.Multiline = $true; $systemPromptTextBox.ScrollBars = 'Vertical'; $systemPromptTextBox.Enabled = $false; $systemPromptTextBox.Anchor = 'Top, Left, Right'
        $chatHistoryBox = New-Object System.Windows.Forms.RichTextBox; $chatHistoryBox.Location = New-Object System.Drawing.Point(10, 145); $chatHistoryBox.Size = New-Object System.Drawing.Size(560, 420); $chatHistoryBox.ReadOnly = $true; $chatHistoryBox.Font = New-Object System.Drawing.Font("Segoe UI", 10); $chatHistoryBox.ScrollBars = 'Vertical'; $chatHistoryBox.Anchor = 'Top, Bottom, Left, Right'
        $userInputBox = New-Object System.Windows.Forms.TextBox; $userInputBox.Location = New-Object System.Drawing.Point(10, 575); $userInputBox.Size = New-Object System.Drawing.Size(450, 20); $userInputBox.Enabled = $false; $userInputBox.Anchor = 'Bottom, Left, Right'
        $sendButton = New-Object System.Windows.Forms.Button; $sendButton.Text = "Send"; $sendButton.Location = New-Object System.Drawing.Point(470, 573); $sendButton.Size = New-Object System.Drawing.Size(100, 25); $sendButton.Enabled = $false; $sendButton.Anchor = 'Bottom, Right'
        $statusBar = New-Object System.Windows.Forms.StatusBar; $statusBar.Text = "Ready. Please connect to the LM Studio server."
        
        $form.Controls.AddRange(@($serverLabel, $serverTextBox, $fetchModelsButton, $modelLabel, $modelComboBox, $systemPromptLabel, $systemPromptTextBox, $chatHistoryBox, $userInputBox, $sendButton, $statusBar))
        Write-Log "All GUI controls created and added."

        # --- Attach Event Handlers ---
        $fetchModelsButton.Add_Click({ Get-LMStudioModels -form $form -serverTextBox $serverTextBox -modelComboBox $modelComboBox -systemPromptTextBox $systemPromptTextBox -userInputBox $userInputBox -sendButton $sendButton -statusBar $statusBar })
        $sendButton.Add_Click({ Send-LMChatMessage -form $form -serverTextBox $serverTextBox -modelComboBox $modelComboBox -systemPromptTextBox $systemPromptTextBox -userInputBox $userInputBox -sendButton $sendButton -chatHistoryBox $chatHistoryBox -statusBar $statusBar })
        $form.Add_KeyDown({ if ($_.KeyCode -eq 'Enter' -and $form.ActiveControl -eq $userInputBox) { $sendButton.PerformClick(); $_.SuppressKeyPress = $true } })
        $form.KeyPreview = $true
        Write-Log "Event handlers attached."

        # --- Show Form ---
        try {
            Write-Log "Initialization complete. Displaying form."
            $form.ShowDialog()
            Write-Log "Form was closed by the user."
        }
        finally {
            Write-Log "Disposing of form object."
            $form.Dispose()
        }
    }

    # ---[ Call the Main GUI Function ]---
    Start-LMChatGui

}
catch {
    # This block will run if any unhandled error occurs during the script's execution.
    $errorMessage = "FATAL SCRIPT ERROR: The script could not start or has crashed.`n"
    $errorMessage += "Error details: $($_.ToString())`n"
    $errorMessage += "Script Stack Trace: $($_.ScriptStackTrace)"
    
    # Log the fatal error to the file.
    Write-Log -Message $errorMessage -Level "FATAL"
    
    # Also write to the console for immediate visibility.
    Write-Host "`n" + ("-"*80) -ForegroundColor Red
    Write-Host $errorMessage -ForegroundColor Red
    Write-Host ("-"*80) + "`n" -ForegroundColor Red
    Read-Host "A fatal error occurred. Please check the LMChatGUI.log file for details. Press Enter to exit."
}
finally {
    Write-Log "Script execution finished."
    Write-Log "----------------------------------------------------`n"
}
