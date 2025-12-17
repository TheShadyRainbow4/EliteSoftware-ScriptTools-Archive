<#
.SYNOPSIS
    A comprehensive GUI tool for managing Windows startup items, scheduled tasks, and services.
.DESCRIPTION
    This PowerShell script provides a WPF-based graphical user interface to view, manage, and control
    various auto-starting applications and processes on a Windows system. It allows for enabling, disabling,
    deleting, and manually adding entries. Includes multiple view modes, sorting, grouping, and JSON export.
    The tool requires administrative privileges for full functionality.
.AUTHOR
    Generated for Zach
.VERSION
    2.2
#>

#region Administrative Rights Check
# This section ensures the script is run with administrator privileges.
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}
#endregion

#region WPF and XAML UI Definition
# Add the necessary .NET assemblies for creating a WPF GUI.
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Advanced Startup Manager" Height="700" Width="950" WindowStartupLocation="CenterScreen"
        Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        
        <TabControl x:Name="TabControl_Main">
            <!-- Startup Apps Tab -->
            <TabItem Header="Startup Apps (Registry &amp; Folders)">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Margin="0,0,0,5" Padding="5" BorderThickness="1" BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}">
                        <StackPanel Orientation="Horizontal">
                            <Label Content="View:" VerticalAlignment="Center"/>
                            <Button x:Name="Button_ViewList" Content="List" Margin="5,0" Padding="5,2"/>
                            <Button x:Name="Button_ViewIcons" Content="Icons" Margin="0,0,20,0" Padding="5,2"/>
                            <Label Content="Group by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_GroupStartup" Width="120" Margin="5,0,20,0">
                                <ComboBoxItem Content="(None)"/>
                                <ComboBoxItem Content="Status"/>
                                <ComboBoxItem Content="Location Type"/>
                            </ComboBox>
                            <Label Content="Sort by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_SortStartup" Width="120" Margin="5,0">
                                <ComboBoxItem Content="Name"/>
                                <ComboBoxItem Content="Location"/>
                                <ComboBoxItem Content="Status"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    
                    <DataGrid x:Name="DataGrid_StartupApps" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended" Visibility="Visible"
                              AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}">
                        <DataGrid.GroupStyle>
                            <GroupStyle><GroupStyle.ContainerStyle><Style TargetType="{x:Type GroupItem}"><Setter Property="Template"><Setter.Value><ControlTemplate><Expander IsExpanded="True"><Expander.Header><StackPanel Orientation="Horizontal"><TextBlock FontWeight="Bold" Text="{Binding Name}" Margin="5,0"/><TextBlock Text="{Binding ItemCount, StringFormat='({0} items)'}"/></StackPanel></Expander.Header><ItemsPresenter /></Expander></ControlTemplate></Setter.Value></Setter></Style></GroupStyle.ContainerStyle></GroupStyle>
                        </DataGrid.GroupStyle>
                        <DataGrid.Columns>
                            <DataGridTemplateColumn><DataGridTemplateColumn.Header><CheckBox x:Name="CheckBox_SelectAllStartup"/></DataGridTemplateColumn.Header><DataGridTemplateColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
                            <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="200" />
                            <DataGridTextColumn Header="Command / Path" Binding="{Binding Command}" Width="*" />
                            <DataGridTextColumn Header="Location" Binding="{Binding Location}" Width="250" />
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100" />
                        </DataGrid.Columns>
                    </DataGrid>

                    <ListView x:Name="ListView_StartupApps" Grid.Row="1" Visibility="Collapsed" SelectionMode="Extended" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListView.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ListView.ItemsPanel>
                        <ListView.GroupStyle><GroupStyle><GroupStyle.HeaderTemplate><DataTemplate><TextBlock FontWeight="Bold" FontSize="14" Text="{Binding Name}" Margin="0,5"/></DataTemplate></GroupStyle.HeaderTemplate></GroupStyle></ListView.GroupStyle>
                        <ListView.ItemTemplate><DataTemplate><Border Margin="5" Padding="5" BorderBrush="LightGray" BorderThickness="1" Width="350"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="48"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Image Grid.Column="0" Source="{Binding Icon}" Width="32" Height="32" VerticalAlignment="Center"/><StackPanel Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Center"><TextBlock Text="{Binding Name}" FontWeight="Bold" TextTrimming="CharacterEllipsis"/><TextBlock Text="{Binding Status}" FontStyle="Italic"/></StackPanel></Grid></Border></DataTemplate></ListView.ItemTemplate>
                    </ListView>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshStartup" Content="Refresh" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_ToggleStartup" Content="Enable/Disable Selected" Width="180" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_DeleteStartup" Content="Delete Selected" Width="120" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_AddStartup" Content="Add New..." Width="100" Padding="5" Margin="0,0,5,0"/>
                        <Button x:Name="Button_BackupStartup" Content="Backup to JSON..." Width="130" Padding="5"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <!-- Scheduled Tasks Tab -->
            <TabItem Header="Scheduled Tasks">
                 <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                     <Border Grid.Row="0" Margin="0,0,0,5" Padding="5" BorderThickness="1" BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}">
                        <StackPanel Orientation="Horizontal">
                            <Label Content="Group by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_GroupTasks" Width="120" Margin="5,0,20,0">
                                <ComboBoxItem Content="(None)"/>
                                <ComboBoxItem Content="State"/>
                            </ComboBox>
                            <Label Content="Sort by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_SortTasks" Width="120" Margin="5,0">
                                <ComboBoxItem Content="Task Name"/>
                                <ComboBoxItem Content="Task Path"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    <DataGrid x:Name="DataGrid_ScheduledTasks" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}">
                         <DataGrid.GroupStyle><GroupStyle><GroupStyle.ContainerStyle><Style TargetType="{x:Type GroupItem}"><Setter Property="Template"><Setter.Value><ControlTemplate><Expander IsExpanded="True"><Expander.Header><StackPanel Orientation="Horizontal"><TextBlock FontWeight="Bold" Text="{Binding Name}" Margin="5,0"/><TextBlock Text="{Binding ItemCount, StringFormat='({0} items)'}"/></StackPanel></Expander.Header><ItemsPresenter /></Expander></ControlTemplate></Setter.Value></Setter></Style></GroupStyle.ContainerStyle></GroupStyle></DataGrid.GroupStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Task Name" Binding="{Binding TaskName}" Width="*" />
                            <DataGridTextColumn Header="Task Path" Binding="{Binding TaskPath}" Width="300" />
                            <DataGridTextColumn Header="State" Binding="{Binding State}" Width="100" />
                            <DataGridTextColumn Header="Last Run Time" Binding="{Binding LastRunTime}" Width="150" />
                            <DataGridTextColumn Header="Next Run Time" Binding="{Binding NextRunTime}" Width="150" />
                        </DataGrid.Columns>
                    </DataGrid>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshTasks" Content="Refresh" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_ToggleTask" Content="Enable/Disable" Width="120" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_DeleteTask" Content="Delete Task" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_RunTask" Content="Run Now" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_BackupTasks" Content="Backup to JSON..." Width="130" Padding="5"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <!-- Services Tab -->
            <TabItem Header="Services">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                     <Border Grid.Row="0" Margin="0,0,0,5" Padding="5" BorderThickness="1" BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}">
                        <StackPanel Orientation="Horizontal">
                            <Label Content="Group by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_GroupServices" Width="120" Margin="5,0,20,0">
                                <ComboBoxItem Content="(None)"/>
                                <ComboBoxItem Content="Status"/>
                                <ComboBoxItem Content="Startup Type"/>
                            </ComboBox>
                            <Label Content="Sort by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_SortServices" Width="120" Margin="5,0">
                                <ComboBoxItem Content="Display Name"/>
                                <ComboBoxItem Content="Service Name"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    <DataGrid x:Name="DataGrid_Services" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}">
                        <DataGrid.GroupStyle><GroupStyle><GroupStyle.ContainerStyle><Style TargetType="{x:Type GroupItem}"><Setter Property="Template"><Setter.Value><ControlTemplate><Expander IsExpanded="True"><Expander.Header><StackPanel Orientation="Horizontal"><TextBlock FontWeight="Bold" Text="{Binding Name}" Margin="5,0"/><TextBlock Text="{Binding ItemCount, StringFormat='({0} items)'}"/></StackPanel></Expander.Header><ItemsPresenter /></Expander></ControlTemplate></Setter.Value></Setter></Style></GroupStyle.ContainerStyle></GroupStyle></DataGrid.GroupStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Display Name" Binding="{Binding DisplayName}" Width="*" />
                            <DataGridTextColumn Header="Service Name" Binding="{Binding Name}" Width="250" />
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100" />
                            <DataGridTextColumn Header="Startup Type" Binding="{Binding StartType}" Width="120" />
                        </DataGrid.Columns>
                    </DataGrid>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshServices" Content="Refresh" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_StartService" Content="Start" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_StopService" Content="Stop" Width="100" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_SetServiceAuto" Content="Set to Automatic" Width="130" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_SetServiceManual" Content="Set to Manual" Width="120" Margin="0,0,5,0" Padding="5"/>
                        <Button x:Name="Button_SetServiceDisabled" Content="Set to Disabled" Width="120" Padding="5" Margin="0,0,5,0"/>
                        <Button x:Name="Button_BackupServices" Content="Backup to JSON..." Width="130" Padding="5"/>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>
        
        <StatusBar Grid.Row="1" Margin="0,10,0,0">
            <StatusBarItem>
                <TextBlock x:Name="TextBlock_Status" Text="Ready. Select a tab to begin." />
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# Create a PowerShell variable container for the WPF window's named elements.
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $Window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Write-Error "Error parsing XAML: $_"
    exit
}

# Store references to all the named controls in a hash table for easy access.
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
    Set-Variable -Name "WPF_$($_.Name)" -Value $Window.FindName($_.Name)
}
#endregion

#region Helper Functions
# This will hold the generic icon so we only load it once.
$Global:GenericIcon = $null

# This function converts a System.Drawing.Icon into a WPF-compatible ImageSource.
Function ConvertTo-ImageSource {
    param ([System.Drawing.Icon]$icon)
    if ($icon -eq $null) { return $null }
    try {
        $memoryStream = New-Object System.IO.MemoryStream
        $icon.ToBitmap().Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin)
        $bitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmapImage.BeginInit()
        $bitmapImage.StreamSource = $memoryStream
        $bitmapImage.EndInit()
        $bitmapImage.Freeze() # Prevents cross-thread issues
        return $bitmapImage
    }
    catch {
        Write-Warning "Could not convert icon to ImageSource. Error: $_"
        return $null
    }
}

Function Get-GenericIcon {
    # If the icon is already created and cached, return it.
    if ($Global:GenericIcon -ne $null) {
        return $Global:GenericIcon
    }
    
    # Use a well-known system icon as the generic fallback.
    $genericPath = Join-Path $env:SystemRoot "System32\imageres.dll"
    try {
        # Icon index 11 from imageres.dll is a generic application icon.
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($genericPath)
        $Global:GenericIcon = ConvertTo-ImageSource -icon $icon
        return $Global:GenericIcon
    } catch {
        Write-Warning "Could not load the generic system icon from imageres.dll."
        return $null
    }
}

Function Show-Message ($Title, $Text, $Button = 'OK', $Icon = 'Information') {
    [System.Windows.MessageBox]::Show($Window, $Text, $Title, $Button, $Icon) | Out-Null
}

Function Get-FileIcon ($command) {
    if ([string]::IsNullOrWhiteSpace($command)) { 
        return (Get-GenericIcon) 
    }

    try {
        # Improved regex to find a file path. It prioritizes quoted paths.
        $match = [regex]::Match($command, '(?:"([^"]+\.exe)"|([^\s]+\.exe))')
        if (-not $match.Success) { return (Get-GenericIcon) }
        
        $cleanPath = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($cleanPath)
        
        if (-not (Test-Path $expandedPath -PathType Leaf)) { return (Get-GenericIcon) }

        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($expandedPath)
        
        if ($icon -eq $null) { return (Get-GenericIcon) }

        return (ConvertTo-ImageSource -icon $icon)
    } catch {
        # Any failure in this block will result in the generic icon being used.
        return (Get-GenericIcon)
    }
}

Function Export-ListToJson {
    param(
        [System.Collections.IList]$List,
        [string]$DefaultFileName
    )
    if ($List.Count -eq 0) {
        Show-Message "Export" "There is nothing to export." "OK" "Information"
        return
    }

    $saveFileDialog = New-Object Microsoft.Win32.SaveFileDialog
    $saveFileDialog.Filter = "JSON Files (*.json)|*.json|All files (*.*)|*.*"
    $saveFileDialog.FileName = $DefaultFileName
    $saveFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')

    if ($saveFileDialog.ShowDialog($Window) -eq $true) {
        try {
            # Create a clean list for export, removing the UI-only Icon property
            $exportList = $List | Select-Object * -ExcludeProperty Icon
            $exportList | ConvertTo-Json -Depth 5 | Out-File -FilePath $saveFileDialog.FileName -Encoding utf8
            Show-Message "Export Successful" "The list was successfully backed up to:`n$($saveFileDialog.FileName)" "OK" "Information"
        } catch {
            Show-Message "Export Failed" "An error occurred while saving the file:`n$($_.Exception.Message)" "OK" "Error"
        }
    }
}
#endregion

#region Startup Apps Logic

$Global:StartupItemsList = [System.Collections.Generic.List[psobject]]::new()

Function Get-StartupApps {
    $WPF_TextBlock_Status.Text = "Loading startup applications..."
    $Global:StartupItemsList.Clear()
    # Pre-load the generic icon to ensure it's available.
    Get-GenericIcon | Out-Null

    $locations = @{
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" = "Enabled";
        "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" = "Enabled";
        "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" = "Enabled";
        "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" = "Enabled";
        "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" = "Enabled";
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Run_Disabled" = "Disabled";
        "HKLM\Software\Microsoft\Windows\CurrentVersion\Run_Disabled" = "Disabled";
        "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run_Disabled" = "Disabled";
    }
    
    foreach ($path in $locations.Keys) {
        if (Test-Path "Registry::$path") {
            $properties = Get-ItemProperty -Path "Registry::$path" -ErrorAction SilentlyContinue
            if ($properties) {
                $properties.psobject.Properties | ForEach-Object {
                    if ($_.Name -ne "(default)") {
                        $Global:StartupItemsList.Add([pscustomobject]@{
                            Name       = $_.Name
                            Command    = $_.Value
                            Location   = $path
                            Status     = $locations[$path]
                            Type       = "Registry"
                            Icon       = Get-FileIcon -command $_.Value
                            IsSelected = $false
                        })
                    }
                }
            }
        }
    }
    
    $startupFolders = @{
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" = "User Startup";
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup" = "Common Startup";
    }

    foreach ($folder in $startupFolders.Keys) {
        if (Test-Path $folder) {
            Get-ChildItem -Path $folder -Filter "*.lnk" | ForEach-Object {
                try {
                    $shell = New-Object -ComObject WScript.Shell
                    $shortcut = $shell.CreateShortcut($_.FullName)
                    if ([string]::IsNullOrWhiteSpace($shortcut.TargetPath)) { throw "Empty target path for shortcut '$($_.Name)'" }
                    
                    $Global:StartupItemsList.Add([pscustomobject]@{
                        Name       = $_.Name
                        Command    = $shortcut.TargetPath
                        Location   = $startupFolders[$folder]
                        Status     = "Enabled"
                        Type       = "Folder"
                        Icon       = Get-FileIcon -command $shortcut.TargetPath
                        IsSelected = $false
                    })
                } catch {
                    Write-Warning "Could not resolve shortcut: $($_.Exception.Message)"
                }
            }
        }
    }
    
    $cvs = [System.Windows.Data.CollectionViewSource]::new()
    $cvs.Source = $Global:StartupItemsList
    $WPF_DataGrid_StartupApps.ItemsSource = $cvs.View
    $WPF_ListView_StartupApps.ItemsSource = $cvs.View

    $WPF_TextBlock_Status.Text = "Found $($Global:StartupItemsList.Count) startup items."
}

$WPF_Button_ToggleStartup.Add_Click({
    $itemsToToggle = $Global:StartupItemsList.Where({$_.IsSelected -eq $true})
    if ($itemsToToggle.Count -eq 0) {
        if ($WPF_DataGrid_StartupApps.Visibility -eq 'Visible') { $itemsToToggle = $WPF_DataGrid_StartupApps.SelectedItems }
        else { $itemsToToggle = $WPF_ListView_StartupApps.SelectedItems }
    }
    if ($itemsToToggle.Count -eq 0) { Show-Message "Error" "Please select at least one item."; return }

    foreach ($selected in $itemsToToggle) {
        if ($selected.Type -ne "Registry") { Write-Warning "Skipping '$($selected.Name)': Only registry entries can be toggled."; continue }
        if ($selected.Location -like "*RunOnce*") { Write-Warning "Skipping '$($selected.Name)': 'RunOnce' entries cannot be disabled."; continue }

        $newKeyPath = $selected.Location -replace '(?i)\\Run(?!_)', '\Run_Disabled'
        $originalKeyPath = $selected.Location -replace '(?i)\\Run_Disabled', '\Run'

        if ($selected.Status -eq "Enabled") {
            if (-not (Test-Path "Registry::$newKeyPath")) { New-Item -Path "Registry::$newKeyPath" -Force | Out-Null }
            Move-ItemProperty -Path "Registry::$($selected.Location)" -Name $selected.Name -Destination "Registry::$newKeyPath" -Force
        } else {
            if (-not (Test-Path "Registry::$originalKeyPath")) { New-Item -Path "Registry::$originalKeyPath" -Force | Out-Null }
            Move-ItemProperty -Path "Registry::$($selected.Location)" -Name $selected.Name -Destination "Registry::$originalKeyPath" -Force
        }
    }
    Show-Message "Success" "Toggle operation completed for selected items."
    Get-StartupApps
})

$WPF_Button_DeleteStartup.Add_Click({
    $selectedItems = $Global:StartupItemsList.Where({$_.IsSelected -eq $true})
    if ($selectedItems.Count -eq 0) {
        if ($WPF_DataGrid_StartupApps.Visibility -eq 'Visible') { $selectedItems = $WPF_DataGrid_StartupApps.SelectedItems }
        else { $selectedItems = $WPF_ListView_StartupApps.SelectedItems }
    }
    if ($selectedItems.Count -eq 0) { Show-Message "Error" "Please select at least one item to delete."; return }
    
    $confirm = Show-Message "Confirm Deletion" "Are you sure you want to permanently delete $($selectedItems.Count) item(s)?" "YesNo" "Warning"
    if ($confirm -ne "Yes") { return }

    foreach($selected in $selectedItems) {
        try {
            if ($selected.Type -eq "Registry") { Remove-ItemProperty -Path "Registry::$($selected.Location)" -Name $selected.Name -Force -ErrorAction Stop } 
            elseif ($selected.Type -eq "Folder") { 
                $folderPath = if ($selected.Location -eq "User Startup") { "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" } else { "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup" }
                Remove-Item -Path (Join-Path $folderPath $selected.Name) -Force -ErrorAction Stop
            }
        } catch { Show-Message "Error" "Failed to delete item '$($selected.Name)': $_" "OK" "Error" }
    }
    Show-Message "Success" "Deletion complete."
    Get-StartupApps
})

# --- UI Event Handlers ---
$WPF_Button_RefreshStartup.Add_Click({ Get-StartupApps; $WPF_ComboBox_GroupStartup.SelectedIndex = 0; $WPF_ComboBox_SortStartup.SelectedIndex = 0 })
$WPF_Button_BackupStartup.Add_Click({ Export-ListToJson -List $Global:StartupItemsList -DefaultFileName "StartupApps_Backup.json" })
$WPF_Button_ViewList.Add_Click({ $WPF_DataGrid_StartupApps.Visibility = 'Visible'; $WPF_ListView_StartupApps.Visibility = 'Collapsed' })
$WPF_Button_ViewIcons.Add_Click({ $WPF_DataGrid_StartupApps.Visibility = 'Collapsed'; $WPF_ListView_StartupApps.Visibility = 'Visible' })
$WPF_CheckBox_SelectAllStartup.Add_Click({ $isChecked = $WPF_CheckBox_SelectAllStartup.IsChecked; $Global:StartupItemsList | ForEach-Object { $_.IsSelected = $isChecked }; $WPF_DataGrid_StartupApps.ItemsSource.Refresh() })
$WPF_Button_AddStartup.Add_Click({
    [xml]$addDialogXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Add New Startup Item" SizeToContent="WidthAndHeight" WindowStartupLocation="CenterOwner"
            Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}" ResizeMode="NoResize" ShowInTaskbar="False">
        <Grid Margin="15">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="350"/></Grid.ColumnDefinitions>
            <Label Grid.Row="0" Grid.Column="0" Content="Entry Name:" VerticalAlignment="Center"/>
            <TextBox x:Name="TextBox_Name" Grid.Row="0" Grid.Column="1" Margin="5"/>
            <Label Grid.Row="1" Grid.Column="0" Content="Command:" VerticalAlignment="Center"/>
            <TextBox x:Name="TextBox_Command" Grid.Row="1" Grid.Column="1" Margin="5"/>
            <Label Grid.Row="2" Grid.Column="0" Content="Add For:" VerticalAlignment="Center"/>
            <ComboBox x:Name="ComboBox_Scope" Grid.Row="2" Grid.Column="1" Margin="5" SelectedIndex="0">
                <ComboBoxItem Content="Current User (HKCU)"/><ComboBoxItem Content="All Users (HKLM)"/>
            </ComboBox>
            <StackPanel Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,15,0,0">
                <Button x:Name="Button_OK" Content="OK" Width="80" Margin="0,0,5,0" IsDefault="True"/>
                <Button x:Name="Button_Cancel" Content="Cancel" Width="80" IsCancel="True"/>
            </StackPanel>
        </Grid>
    </Window>
"@
    $addReader = (New-Object System.Xml.XmlNodeReader $addDialogXaml)
    $addDialog = [Windows.Markup.XamlReader]::Load($addReader)
    $addDialog.Owner = $Window
    
    $TextBox_Name = $addDialog.FindName("TextBox_Name")
    $TextBox_Command = $addDialog.FindName("TextBox_Command")
    $ComboBox_Scope = $addDialog.FindName("ComboBox_Scope")
    $addDialog.FindName("Button_OK").Add_Click({
        if ([string]::IsNullOrWhiteSpace($TextBox_Name.Text) -or [string]::IsNullOrWhiteSpace($TextBox_Command.Text)) {
            Show-Message "Input Error" "Name and Command fields cannot be empty." "OK" "Warning"; return
        }
        $regPath = if ($ComboBox_Scope.SelectedIndex -eq 0) { "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" } else { "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" }
        try {
            $commandValue = if ($TextBox_Command.Text.Contains(" ") -and -not $TextBox_Command.Text.StartsWith('"')) { "`"$($TextBox_Command.Text)`"" } else { $TextBox_Command.Text }
            New-ItemProperty -Path "Registry::$regPath" -Name $TextBox_Name.Text -Value $commandValue -PropertyType String -Force -ErrorAction Stop
            Show-Message "Success" "Startup item '$($TextBox_Name.Text)' was added successfully."
            $addDialog.DialogResult = $true
        } catch { Show-Message "Error" "Failed to add registry entry: $_" "OK" "Error" }
    })

    if ($addDialog.ShowDialog()) { Get-StartupApps }
})

Function Update-View {
    param($ViewSource, $SortProperty, $GroupProperty)
    if (-not $ViewSource) { return }
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($ViewSource)
    $view.SortDescriptions.Clear()
    $view.GroupDescriptions.Clear()

    if ($SortProperty) { $view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription -ArgumentList $SortProperty, "Ascending")) }
    if ($GroupProperty) { $view.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription -ArgumentList $GroupProperty)) }
}
$WPF_ComboBox_SortStartup.Add_SelectionChanged({ $sortProp = switch($WPF_ComboBox_SortStartup.SelectedItem.Content) { "Name" { "Name" } "Location" { "Location" } "Status" { "Status" } default { "Name" } }; $groupProp = if ($WPF_DataGrid_StartupApps.ItemsSource.GroupDescriptions.Count -gt 0) { $WPF_DataGrid_StartupApps.ItemsSource.GroupDescriptions[0].PropertyName } else { $null }; Update-View -ViewSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp })
$WPF_ComboBox_GroupStartup.Add_SelectionChanged({ $groupProp = switch($WPF_ComboBox_GroupStartup.SelectedItem.Content) { "Status" { "Status" } "Location Type" { "Type" } default { $null } }; $sortProp = if ($WPF_DataGrid_StartupApps.ItemsSource.SortDescriptions.Count -gt 0) { $WPF_DataGrid_StartupApps.ItemsSource.SortDescriptions[0].PropertyName } else { "Name" }; Update-View -ViewSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp })
#endregion

#region Scheduled Tasks Logic
$Global:ScheduledTasksList = [System.Collections.Generic.List[psobject]]::new()
Function Get-ScheduledTasks {
    $WPF_TextBlock_Status.Text = "Loading scheduled tasks..."; 
    $Global:ScheduledTasksList.Clear()
    Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object {
        $Global:ScheduledTasksList.Add($_)
    }
    
    $cvs = [System.Windows.Data.CollectionViewSource]::new()
    $cvs.Source = $Global:ScheduledTasksList
    $WPF_DataGrid_ScheduledTasks.ItemsSource = $cvs.View
    
    $WPF_TextBlock_Status.Text = "Found $($Global:ScheduledTasksList.Count) scheduled tasks."
}
$WPF_Button_RefreshTasks.Add_Click({ Get-ScheduledTasks; $WPF_ComboBox_GroupTasks.SelectedIndex = 0; $WPF_ComboBox_SortTasks.SelectedIndex = 0 })
$WPF_Button_BackupTasks.Add_Click({ Export-ListToJson -List $Global:ScheduledTasksList -DefaultFileName "ScheduledTasks_Backup.json" })
$WPF_Button_ToggleTask.Add_Click({ $selected = $WPF_DataGrid_ScheduledTasks.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a task first."; return }; try { if ($selected.State -eq "Ready" -or $selected.State -eq "Running") { Disable-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop; } else { Enable-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop; }; Start-Sleep -milliseconds 500; Get-ScheduledTasks } catch { Show-Message "Error" "Failed to change task state: $_" "OK" "Error" } })
$WPF_Button_DeleteTask.Add_Click({ $selected = $WPF_DataGrid_ScheduledTasks.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a task first."; return }; $confirm = Show-Message "Confirm Deletion" "Are you sure you want to permanently delete task '$($selected.TaskName)'?" "YesNo" "Warning"; if ($confirm -ne "Yes") { return }; try { Unregister-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -Confirm:$false -ErrorAction Stop; Show-Message "Success" "Task '$($selected.TaskName)' has been deleted."; Get-ScheduledTasks } catch { Show-Message "Error" "Failed to delete task: $_" "OK" "Error" } })
$WPF_Button_RunTask.Add_Click({ $selected = $WPF_DataGrid_ScheduledTasks.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a task first."; return }; if ($selected.State -eq "Disabled") { Show-Message "Error" "Cannot run a disabled task. Please enable it first."; return }; try { Start-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop; Show-Message "Success" "Task '$($selected.TaskName)' has been started."; Start-Sleep -Seconds 2; Get-ScheduledTasks } catch { Show-Message "Error" "Failed to start task: $_" "OK" "Error" } })
$WPF_ComboBox_SortTasks.Add_SelectionChanged({ $sortProp = switch($WPF_ComboBox_SortTasks.SelectedItem.Content) { "Task Name" { "TaskName" } "Task Path" { "TaskPath" } default { "TaskName" } }; $groupProp = if ($WPF_DataGrid_ScheduledTasks.ItemsSource.GroupDescriptions.Count -gt 0) { $WPF_DataGrid_ScheduledTasks.ItemsSource.GroupDescriptions[0].PropertyName } else { $null }; Update-View -ViewSource $WPF_DataGrid_ScheduledTasks.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp })
$WPF_ComboBox_GroupTasks.Add_SelectionChanged({ $groupProp = switch($WPF_ComboBox_GroupTasks.SelectedItem.Content) { "State" { "State" } default { $null } }; $sortProp = if ($WPF_DataGrid_ScheduledTasks.ItemsSource.SortDescriptions.Count -gt 0) { $WPF_DataGrid_ScheduledTasks.ItemsSource.SortDescriptions[0].PropertyName } else { "TaskName" }; Update-View -ViewSource $WPF_DataGrid_ScheduledTasks.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp })
#endregion

#region Services Logic
$Global:ServicesList = [System.Collections.Generic.List[psobject]]::new()
Function Get-Services { 
    $WPF_TextBlock_Status.Text = "Loading services..."; 
    $Global:ServicesList.Clear()
    $servicesRaw = Get-CimInstance -ClassName Win32_Service | Select-Object DisplayName, Name, State, StartMode
    foreach($service in $servicesRaw) {
        $Global:ServicesList.Add([pscustomobject]@{
            DisplayName = $service.DisplayName
            Name = $service.Name
            Status = $service.State
            StartType = $service.StartMode
        })
    }
    
    $cvs = [System.Windows.Data.CollectionViewSource]::new()
    $cvs.Source = $Global:ServicesList
    $WPF_DataGrid_Services.ItemsSource = $cvs.View
    
    $WPF_TextBlock_Status.Text = "Found $($Global:ServicesList.Count) services." 
}
Function Set-ServiceAction($Action) { $selected = $WPF_DataGrid_Services.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a service first."; return }; $WPF_TextBlock_Status.Text = "Performing action on service '$($selected.Name)'..."; try { switch ($Action) { "Start" { Start-Service -Name $selected.Name -ErrorAction Stop } "Stop" { Stop-Service -Name $selected.Name -Force -ErrorAction Stop } "Auto" { Set-Service -Name $selected.Name -StartupType Automatic -ErrorAction Stop } "Manual" { Set-Service -Name $selected.Name -StartupType Manual -ErrorAction Stop } "Disabled"{ Set-Service -Name $selected.Name -StartupType Disabled -ErrorAction Stop } }; Start-Sleep -Milliseconds 500; Get-Services } catch { Show-Message "Error" "Failed to perform action '$Action' on service: $_" "OK" "Error"; $WPF_TextBlock_Status.Text = "Action failed." } }
$WPF_Button_RefreshServices.Add_Click({ Get-Services; $WPF_ComboBox_GroupServices.SelectedIndex = 0; $WPF_ComboBox_SortServices.SelectedIndex = 0 })
$WPF_Button_BackupServices.Add_Click({ Export-ListToJson -List $Global:ServicesList -DefaultFileName "Services_Backup.json" })
$WPF_Button_StartService.Add_Click({ Set-ServiceAction -Action "Start" })
$WPF_Button_StopService.Add_Click({ Set-ServiceAction -Action "Stop" })
$WPF_Button_SetServiceAuto.Add_Click({ Set-ServiceAction -Action "Auto" })
$WPF_Button_SetServiceManual.Add_Click({ Set-ServiceAction -Action "Manual" })
$WPF_Button_SetServiceDisabled.Add_Click({ Set-ServiceAction -Action "Disabled" })
$WPF_ComboBox_SortServices.Add_SelectionChanged({ $sortProp = switch($WPF_ComboBox_SortServices.SelectedItem.Content) { "Display Name" { "DisplayName" } "Service Name" { "Name" } default { "DisplayName" } }; $groupProp = if ($WPF_DataGrid_Services.ItemsSource.GroupDescriptions.Count -gt 0) { $WPF_DataGrid_Services.ItemsSource.GroupDescriptions[0].PropertyName } else { $null }; Update-View -ViewSource $WPF_DataGrid_Services.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp })
$WPF_ComboBox_GroupServices.Add_SelectionChanged({ $groupProp = switch($WPF_ComboBox_GroupServices.SelectedItem.Content) { "Status" { "Status" } "Startup Type" { "StartType" } default { $null } }; $sortProp = if ($WPF_DataGrid_Services.ItemsSource.SortDescriptions.Count -gt 0) { $WPF_DataGrid_Services.ItemsSource.SortDescriptions[0].PropertyName } else { "DisplayName" }; Update-View -ViewSource $WPF_DataGrid_Services.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp })
#endregion

#region Main Application Logic

# Main window load event
$Window.Add_Loaded({
    try {
        # Trigger the SelectionChanged event for the initially selected tab to load its data.
        $WPF_TabControl_Main_SelectionChanged.Invoke($null, $null)
    } catch {
        Show-Message "Fatal Error on Load" "An unexpected error occurred while loading the application:`n`n$($_.Exception.Message)" "OK" "Error"
        $Window.Close()
    }
})

# Load data when a tab is changed
$WPF_TabControl_Main_SelectionChanged = {
    $selectedTab = $WPF_TabControl_Main.SelectedItem.Header
    switch ($selectedTab) {
        "Startup Apps (Registry & Folders)" { if ($Global:StartupItemsList.Count -eq 0) { Get-StartupApps; Update-View -ViewSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty "Name" -GroupProperty $null } }
        "Scheduled Tasks" { if ($Global:ScheduledTasksList.Count -eq 0) { Get-ScheduledTasks; Update-View -ViewSource $WPF_DataGrid_ScheduledTasks.ItemsSource -SortProperty "TaskName" -GroupProperty $null } }
        "Services" { if ($Global:ServicesList.Count -eq 0) { Get-Services; Update-View -ViewSource $WPF_DataGrid_Services.ItemsSource -SortProperty "DisplayName" -GroupProperty $null } }
    }
}
$WPF_TabControl_Main.Add_SelectionChanged($WPF_TabControl_Main_SelectionChanged)


# Display the window to the user
$Window.ShowDialog() | Out-Null

#endregion
