# --- EliteUtility - Main.ps1 ---
# Developer: Zach (with your trusty AI Dev Team)
# Version: 0.8.1 (AI Assistant Layout Fix)
# --- DESCRIPTION ---
# Fixed a critical layout bug in the AI Assistant Snap-in Panel where the
# input controls were hidden. The control docking order has been corrected.
# --- MAIN ---

# 1.) ASSEMBLY AND FORM CREATION
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =============================================================================
# --- APPLET CREATION FUNCTIONS ---
# =============================================================================

function Create-PackageManagerPanel {
    $panel = New-Object System.Windows.Forms.Panel; $panel.Dock = "Fill"; $panel.BackColor = [System.Drawing.Color]::White; $panel.Name = "packageManagerPanel"
    $label = New-Object System.Windows.Forms.Label; $label.Text = "This Snap-in Panel will launch the Winget UI in a separate window."; $label.Font = New-Object System.Drawing.Font("Segoe UI", 12); $label.Dock = "Fill"; $label.TextAlign = "MiddleCenter"; $panel.Controls.Add($label)
    $launchButton = New-Object System.Windows.Forms.Button; $launchButton.Text = "Launch Package Manager"; $launchButton.Font = New-Object System.Drawing.Font("Segoe UI", 10); $launchButton.Size = New-Object System.Drawing.Size(220, 40);
    $panel.Controls.Add($launchButton)
    $panel.Add_Resize({ $launchButton.Location = New-Object System.Drawing.Point( ($panel.ClientSize.Width - $launchButton.Width) / 2, 200) })
    $launchButton.Add_Click({
        try { $scriptPath = "H:\Zachary Whiteman\Desktop\EliteUtility\wingetsearch.ps1"; if (Test-Path $scriptPath) { Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$scriptPath`"" } else { throw "File not found." } }
        catch { [System.Windows.Forms.MessageBox]::Show("Could not find wingetsearch.ps1!", "Error", "OK", "Error") }
    })
    return $panel
}

function Create-AIAssistantPanel {
    # --- Create the main panel for this Snap-in ---
    $panel = New-Object System.Windows.Forms.Panel; $panel.Dock = "Fill"; $panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#333333"); $panel.Name = "aiAssistantPanel"
    
    # --- Create UI Controls (Styled to match the new design) ---
    $outputBox = New-Object System.Windows.Forms.RichTextBox; $outputBox.Dock = "Fill"; $outputBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E"); $outputBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D4D4D4"); $outputBox.Font = New-Object System.Drawing.Font("Consolas", 10); $outputBox.ReadOnly = $true; $outputBox.BorderStyle = "None"; $outputBox.Text = "AI Assistant ready. Select a model and ask a question."
    $promptBox = New-Object System.Windows.Forms.RichTextBox; $promptBox.Dock = "Bottom"; $promptBox.Font = New-Object System.Drawing.Font("Segoe UI", 11); $promptBox.Height = 50; $promptBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D2D"); $promptBox.ForeColor = [System.Drawing.Color]::White;
    $actionBar = New-Object System.Windows.Forms.Panel; $actionBar.Dock = "Bottom"; $actionBar.Height = 40; $actionBar.Padding = New-Object System.Windows.Forms.Padding(5);
    $sendButton = New-Object System.Windows.Forms.Button; $sendButton.Dock = "Right"; $sendButton.Text = "Send"; $sendButton.Width = 100
    $modelSelectorLabel = New-Object System.Windows.Forms.Label; $modelSelectorLabel.Text = "Model:"; $modelSelectorLabel.Dock = "Left"; $modelSelectorLabel.AutoSize = $false; $modelSelectorLabel.Width = 50; $modelSelectorLabel.TextAlign = "MiddleRight"; $modelSelectorLabel.ForeColor = [System.Drawing.Color]::White
    $modelComboBox = New-Object System.Windows.Forms.ComboBox; $modelComboBox.Dock = "Fill"; $modelComboBox.DropDownStyle = "DropDownList"; $modelComboBox.Width = 200;
    $modelComboBox.Items.Add("google/gemma-3-12b") | Out-Null; $modelComboBox.Items.Add("lm-4b") | Out-Null; $modelComboBox.SelectedIndex = 0
    
    # Add controls to the action bar
    $actionBar.Controls.Add($sendButton); $actionBar.Controls.Add($modelComboBox); $actionBar.Controls.Add($modelSelectorLabel)
    
    # --- BUGFIX: Add controls in the correct order for Docking ---
    # Edge-docked controls (Bottom, Top) MUST be added BEFORE Fill controls.
    $panel.Controls.Add($actionBar)
    $panel.Controls.Add($promptBox)
    $panel.Controls.Add($outputBox) # The Fill control is added LAST.

    # --- Event Handlers ---
    $sendButton.Add_Click({
        $userPrompt = $promptBox.Text; if ([string]::IsNullOrWhiteSpace($userPrompt)) { return }
        $outputBox.SelectionColor = "Cyan"; $outputBox.AppendText("`n`nUSER: `n"); $outputBox.SelectionColor = $outputBox.ForeColor; $outputBox.AppendText($userPrompt)
        $outputBox.SelectionColor = "Lime"; $outputBox.AppendText("`n`nAI: `nThinking..."); $outputBox.SelectionColor = $outputBox.ForeColor
        $outputBox.ScrollToCaret(); $panel.Update(); $sendButton.Enabled = $false
        
        $selectedModel = $modelComboBox.SelectedItem.ToString()
        $apiUrl = "http://192.168.10.100:1234/v1/chat/completions"
        $headers = @{ "Content-Type" = "application/json" }
        $body = @{ model = $selectedModel; messages = @( @{ role = "system"; content = "You are a helpful assistant." }, @{ role = "user"; content = $userPrompt }) } | ConvertTo-Json -Depth 5
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -TimeoutSec 300
            $aiMessage = $response.choices[0].message.content
            $outputBox.Text = $outputBox.Text.Substring(0, $outputBox.Text.LastIndexOf("Thinking..."))
            $outputBox.AppendText($aiMessage)
        } catch { $outputBox.AppendText("`n`nERROR: Could not reach the AI model. Is the LM Studio server running?") }
        finally { $promptBox.Clear(); $outputBox.ScrollToCaret(); $sendButton.Enabled = $true }
    })
    $promptBox.Add_KeyDown({ if ($_.KeyCode -eq "Enter" -and !$_.ShiftKey) { $_.SuppressKeyPress = $true; $sendButton.PerformClick() } })

    return $panel
}

# =============================================================================
# --- FORM AND MAIN LAYOUT SETUP ---
# =============================================================================

$mainForm = New-Object System.Windows.Forms.Form; $mainForm.Text = "EliteUtility"; $mainForm.Size = New-Object System.Drawing.Size(950, 720); $mainForm.StartPosition = "CenterScreen"; $mainForm.MinimumSize = New-Object System.Drawing.Size(700, 500)
$utilityBar = New-Object System.Windows.Forms.MenuStrip; $utilityBar.Dock = "Top"; $fileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("File"); $exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Exit"); $exitMenuItem.add_Click({$mainForm.Close()}); $fileMenuItem.DropDownItems.Add($exitMenuItem); $utilityBar.Items.Add($fileMenuItem); $mainForm.Controls.Add($utilityBar)
$statusStrip = New-Object System.Windows.Forms.StatusStrip; $statusStrip.Dock = "Bottom"; $statusStrip.Name = "statusStrip"; $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $statusLabel.Text = "Welcome to EliteUtility!"; $statusStrip.Items.Add($statusLabel); $mainForm.Controls.Add($statusStrip)
$splitContainer = New-Object System.Windows.Forms.SplitContainer; $splitContainer.Dock = "Fill"; $splitContainer.SplitterDistance = 280; $splitContainer.FixedPanel = "Panel1"; $mainForm.Controls.Add($splitContainer)

# =============================================================================
# --- LEFT PANE - TREEVIEW NAVIGATION ---
# =============================================================================

$imageList = New-Object System.Windows.Forms.ImageList
$systemRoot = $env:SystemRoot
try {
    $imageresPath = Join-Path -Path $systemRoot -ChildPath "System32\imageres.dll"; $shell32Path = Join-Path -Path $systemRoot -ChildPath "System32\shell32.dll"
    $imageList.Images.Add("home", (New-Object System.Drawing.Icon((Get-Item $imageresPath), 32, 32))); $imageList.Images.Add("folder", (New-Object System.Drawing.Icon((Get-Item $shell32Path), 32, 32))); $imageList.Images.Add("tweak", (New-Object System.Drawing.Icon((Get-Item $imageresPath), 32, 32))); $imageList.Images.Add("software", (New-Object System.Drawing.Icon((Get-Item $imageresPath), 32, 32))); $imageList.Images.Add("ai", (New-Object System.Drawing.Icon((Get-Item $imageresPath), 32, 32)))
} catch { Write-Warning "Could not load all system icons." }

$treeView = New-Object System.Windows.Forms.TreeView; $treeView.Dock = "Fill"; $treeView.ImageList = $imageList; $treeView.Font = New-Object System.Drawing.Font("Segoe UI", 9.5); $treeView.ItemHeight = 22; $treeView.ShowLines = $false
$splitContainer.Panel1.Controls.Add($treeView)

function Add-Node { param($parent, $name, $text, $imageKey); $node = New-Object System.Windows.Forms.TreeNode($text); $node.Name = $name; $node.ImageKey = $imageKey; $node.SelectedImageKey = $imageKey; if ($parent) { $parent.Nodes.Add($node) | Out-Null } else { $treeView.Nodes.Add($node) | Out-Null }; return $node }

$welcomeNode = Add-Node -parent $null -name "homeDashBoard" -text "Home DashBoard" -imageKey "home"
$fileUtilsNode = Add-Node -parent $null -name "fileUtils" -text "File & Icon Utilities" -imageKey "folder"
Add-Node -parent $fileUtilsNode -name "iconExtractor" -text "DLL Icon Extractor" -imageKey "tweak"
Add-Node -parent $fileUtilsNode -name "aiIconOrganizer" -text "AI Icon Organizer" -imageKey "tweak"
$sysMgmtNode = Add-Node -parent $null -name "sysMgmt" -text "System Management" -imageKey "tweak"
Add-Node -parent $sysMgmtNode -name "startupApps" -text "Startup Apps Manager" -imageKey "tweak"
Add-Node -parent $sysMgmtNode -name "serviceManager" -text "Services Manager" -imageKey "tweak"
$softwareNode = Add-Node -parent $null -name "software" -text "Software" -imageKey "software"
Add-Node -parent $softwareNode -name "packageManager" -text "Package Manager" -imageKey "software"
$aiToolsNode = Add-Node -parent $null -name "aiTools" -text "AI Tools" -imageKey "ai"
Add-Node -parent $aiToolsNode -name "aiAssistant" -text "AI Assistant" -imageKey "ai"

# =============================================================================
# --- RIGHT PANE - DYNAMIC APPLET PANELS ---
# =============================================================================

function New-PlaceholderPanel { param ($name); $panel = New-Object System.Windows.Forms.Panel; $panel.Dock = "Fill"; $panel.BackColor = [System.Drawing.Color]::White; $panel.Visible = $false; $label = New-Object System.Windows.Forms.Label; $label.Text = "Placeholder for the '$name' Snap-in Panel."; $label.Font = New-Object System.Drawing.Font("Segoe UI", 12); $label.Dock = "Fill"; $label.TextAlign = "MiddleCenter"; $panel.Controls.Add($label); return $panel }

$AllPanels = @{
    "homeDashBoard" = (New-PlaceholderPanel -name "Home DashBoard")
    "iconExtractor" = (New-PlaceholderPanel -name "DLL Icon Extractor")
    "aiIconOrganizer" = (New-PlaceholderPanel -name "AI Icon Organizer")
    "startupApps" = (New-PlaceholderPanel -name "Startup Apps Manager")
    "serviceManager" = (New-PlaceholderPanel -name "Services Manager")
    "packageManager" = (Create-PackageManagerPanel)
    "aiAssistant" = (Create-AIAssistantPanel)
}

foreach($panel in $AllPanels.Values){ $splitContainer.Panel2.Controls.Add($panel) }

# =============================================================================
# --- CORE LOGIC & STARTUP ---
# =============================================================================

$treeView.Add_AfterSelect({
    foreach($panel in $AllPanels.Values) { if ($panel.Parent -eq $splitContainer.Panel2) {$panel.Visible = $false} }
    $selectedNodeName = $treeView.SelectedNode.Name
    $statusLabel.Text = "Current Section: " + $treeView.SelectedNode.Text
    if ($AllPanels.ContainsKey($selectedNodeName)) {
        if ($AllPanels[$selectedNodeName].Parent -eq $splitContainer.Panel2) { $AllPanels[$selectedNodeName].Visible = $true } 
        else { $statusLabel.Text = "The '" + $treeView.SelectedNode.Text + "' Snap-in Panel is currently in a separate window." }
    }
})

$treeView.ExpandAll()
$treeView.SelectedNode = $welcomeNode
$AllPanels["homeDashBoard"].Visible = $true

$mainForm.ShowDialog()