<#
.SYNOPSIS
    A comprehensive and enhanced GUI tool for managing Windows startup items, scheduled tasks, and services.
.DESCRIPTION
    This PowerShell script provides an advanced WPF-based graphical user interface to view, analyze, and manage
    auto-starting applications, scheduled tasks, and system services. It allows for enabling, disabling, deleting,
    and manually adding entries. 
    
    Version 3.3 Enhancements:
    - CRITICAL FIX: Resolved a startup crash by re-architecting the initial loading sequence to prevent race conditions.
    - LOGIC FIX: Corrected the detection logic for disabled HKCU startup items.
    - Implemented a proper Enable/Disable function for HKCU startup items using the modern 'StartupApproved' registry method.
    - Revamped UI with modern styling, improved fonts, and system-aware colors.
    - Added dedicated search functionality and powerful right-click context menus.
.AUTHOR
    Enhanced by Gemini for Zach
.VERSION
    3.3
#>

#region Administrative Rights Check & Assembly Loading
# This section ensures the script is run with administrator privileges, which is required for full functionality.
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

# Add the necessary .NET assemblies for creating a WPF GUI and for Forms integration (for visual styles).
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms
#endregion

#region WPF and XAML UI Definition
# Calling EnableVisualStyles() improves the look of dialog boxes to match the system theme.
[System.Windows.Forms.Application]::EnableVisualStyles()

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Advanced Startup Manager v3.3" Height="750" Width="1100" WindowStartupLocation="CenterScreen"
        Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}"
        Foreground="{DynamicResource {x:Static SystemColors.WindowTextBrushKey}}">
    <Window.Resources>
        <!-- Global font settings for a more polished look -->
        <Style TargetType="{x:Type Control}">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="{x:Type TextBlock}">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>

        <!-- Style for all Buttons to give them a consistent, modern look -->
        <Style TargetType="Button">
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="0,0,5,0"/>
            <Setter Property="Background" Value="{DynamicResource {x:Static SystemColors.ControlLightLightBrushKey}}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Foreground" Value="{DynamicResource {x:Static SystemColors.ControlTextBrushKey}}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"/>
                    <Setter Property="BorderBrush" Value="{DynamicResource {x:Static SystemColors.HighlightBrushKey}}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Style for the DataGrids for a cleaner appearance -->
        <Style TargetType="DataGrid">
            <Setter Property="AlternatingRowBackground" Value="#F7F7F7"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="HorizontalGridLinesBrush" Value="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"/>
            <Setter Property="VerticalGridLinesBrush" Value="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <!-- Custom Expander Style for Grouping -->
        <Style x:Key="GroupHeaderExpanderStyle" TargetType="{x:Type GroupItem}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type GroupItem}">
                        <Expander IsExpanded="True" 
                                  BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" 
                                  BorderThickness="0,0,0,1">
                            <Expander.Header>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontWeight="SemiBold" FontSize="14" Text="{Binding Name}" Margin="5,0"/>
                                    <TextBlock FontSize="14" Text="{Binding ItemCount, StringFormat='({0} items)'}" Foreground="Gray"/>
                                </StackPanel>
                            </Expander.Header>
                            <ItemsPresenter />
                        </Expander>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    
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
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Orientation="Horizontal">
                                <Label Content="View:" VerticalAlignment="Center"/>
                                <Button x:Name="Button_ViewList" Content="List" Margin="5,0" Padding="5,2"/>
                                <Button x:Name="Button_ViewIcons" Content="Icons" Margin="0,0,20,0" Padding="5,2"/>
                                <Label Content="Group by:" VerticalAlignment="Center"/>
                                <ComboBox x:Name="ComboBox_GroupStartup" Width="120" Margin="5,0,20,0"/>
                                <Label Content="Sort by:" VerticalAlignment="Center"/>
                                <ComboBox x:Name="ComboBox_SortStartup" Width="120" Margin="5,0"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
                                <Label Content="Search:" VerticalAlignment="Center"/>
                                <TextBox x:Name="TextBox_SearchStartup" Width="250" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <DataGrid x:Name="DataGrid_StartupApps" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended" Visibility="Visible">
                        <DataGrid.GroupStyle><GroupStyle ContainerStyle="{StaticResource GroupHeaderExpanderStyle}"/></DataGrid.GroupStyle>
                        <DataGrid.ContextMenu>
                            <ContextMenu x:Name="ContextMenu_StartupApps"/>
                        </DataGrid.ContextMenu>
                        <DataGrid.Columns>
                            <DataGridTemplateColumn><DataGridTemplateColumn.Header><CheckBox x:Name="CheckBox_SelectAllStartup"/></DataGridTemplateColumn.Header><DataGridTemplateColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
                            <DataGridTemplateColumn Header=" " Width="Auto"><DataGridTemplateColumn.CellTemplate><DataTemplate><Image Source="{Binding Icon}" Width="16" Height="16"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
                            <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="200" ElementStyle="{StaticResource SemiBoldStyle}"/>
                            <DataGridTextColumn Header="Command / Path" Binding="{Binding Command}" Width="*" />
                            <DataGridTextColumn Header="Location" Binding="{Binding Location}" Width="250" />
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100" />
                            <DataGridTextColumn Header="Publisher" Binding="{Binding Publisher}" Width="180"/>
                        </DataGrid.Columns>
                    </DataGrid>

                    <ListView x:Name="ListView_StartupApps" Grid.Row="1" Visibility="Collapsed" SelectionMode="Extended" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListView.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ListView.ItemsPanel>
                        <ListView.GroupStyle><GroupStyle><GroupStyle.HeaderTemplate><DataTemplate><TextBlock FontWeight="SemiBold" FontSize="14" Text="{Binding Name}" Margin="0,5"/></DataTemplate></GroupStyle.HeaderTemplate></GroupStyle></ListView.GroupStyle>
                        <ListView.ItemTemplate><DataTemplate><Border Margin="5" Padding="5" BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" BorderThickness="1" Width="350"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="48"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Image Grid.Column="0" Source="{Binding Icon}" Width="32" Height="32" VerticalAlignment="Center"/><StackPanel Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Center"><TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/><TextBlock Text="{Binding Publisher}" Foreground="Gray"/><TextBlock Text="{Binding Status}" FontStyle="Italic"/></StackPanel></Grid></Border></DataTemplate></ListView.ItemTemplate>
                    </ListView>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshStartup" Content="Refresh"/>
                        <Button x:Name="Button_ToggleStartup" Content="Enable/Disable Selected"/>
                        <Button x:Name="Button_DeleteStartup" Content="Delete Selected"/>
                        <Button x:Name="Button_AddStartup" Content="Add New..."/>
                        <Button x:Name="Button_BackupStartup" Content="Backup to JSON..."/>
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
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Orientation="Horizontal">
                                <Label Content="Group by:" VerticalAlignment="Center"/>
                                <ComboBox x:Name="ComboBox_GroupTasks" Width="120" Margin="5,0,20,0"/>
                                <Label Content="Sort by:" VerticalAlignment="Center"/>
                                <ComboBox x:Name="ComboBox_SortTasks" Width="120" Margin="5,0"/>
                            </StackPanel>
                             <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
                                <Label Content="Search:" VerticalAlignment="Center"/>
                                <TextBox x:Name="TextBox_SearchTasks" Width="250" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    <DataGrid x:Name="DataGrid_Tasks" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended">
                         <DataGrid.GroupStyle><GroupStyle ContainerStyle="{StaticResource GroupHeaderExpanderStyle}"/></DataGrid.GroupStyle>
                         <DataGrid.ContextMenu>
                            <ContextMenu x:Name="ContextMenu_Tasks"/>
                         </DataGrid.ContextMenu>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Task Name" Binding="{Binding TaskName}" Width="*" ElementStyle="{StaticResource SemiBoldStyle}" />
                            <DataGridTextColumn Header="Task Path" Binding="{Binding TaskPath}" Width="300" />
                            <DataGridTextColumn Header="State" Binding="{Binding State}" Width="100" />
                            <DataGridTextColumn Header="Last Run Time" Binding="{Binding LastRunTime}" Width="150" />
                            <DataGridTextColumn Header="Next Run Time" Binding="{Binding NextRunTime}" Width="150" />
                        </DataGrid.Columns>
                    </DataGrid>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshTasks" Content="Refresh"/>
                        <Button x:Name="Button_ToggleTask" Content="Enable/Disable Selected"/>
                        <Button x:Name="Button_DeleteTask" Content="Delete Selected"/>
                        <Button x:Name="Button_RunTask" Content="Run Selected"/>
                        <Button x:Name="Button_BackupTasks" Content="Backup to JSON..."/>
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
                        <Grid>
                             <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Orientation="Horizontal">
                                <Label Content="Group by:" VerticalAlignment="Center"/>
                                <ComboBox x:Name="ComboBox_GroupServices" Width="120" Margin="5,0,20,0"/>
                                <Label Content="Sort by:" VerticalAlignment="Center"/>
                                <ComboBox x:Name="ComboBox_SortServices" Width="120" Margin="5,0"/>
                            </StackPanel>
                             <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
                                <Label Content="Search:" VerticalAlignment="Center"/>
                                <TextBox x:Name="TextBox_SearchServices" Width="250" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    <DataGrid x:Name="DataGrid_Services" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended">
                        <DataGrid.GroupStyle><GroupStyle ContainerStyle="{StaticResource GroupHeaderExpanderStyle}"/></DataGrid.GroupStyle>
                         <DataGrid.ContextMenu>
                            <ContextMenu x:Name="ContextMenu_Services"/>
                         </DataGrid.ContextMenu>
                        <DataGrid.RowStyle>
                            <Style TargetType="DataGridRow">
                                <Setter Property="ToolTip">
                                    <Setter.Value>
                                        <ToolTip>
                                            <StackPanel>
                                                <TextBlock Text="{Binding Description}" FontWeight="Bold" MaxWidth="400" TextWrapping="Wrap"/>
                                                <TextBlock Text="{Binding PathName}" FontStyle="Italic" MaxWidth="400" TextWrapping="Wrap"/>
                                            </StackPanel>
                                        </ToolTip>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </DataGrid.RowStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Display Name" Binding="{Binding DisplayName}" Width="*" ElementStyle="{StaticResource SemiBoldStyle}"/>
                            <DataGridTextColumn Header="Service Name" Binding="{Binding Name}" Width="250" />
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100" />
                            <DataGridTextColumn Header="Startup Type" Binding="{Binding StartType}" Width="120" />
                            <DataGridTextColumn Header="Path" Binding="{Binding PathName}" Width="300" />
                        </DataGrid.Columns>
                    </DataGrid>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshServices" Content="Refresh"/>
                        <Button x:Name="Button_StartService" Content="Start Selected"/>
                        <Button x:Name="Button_StopService" Content="Stop Selected"/>
                        <Button x:Name="Button_SetServiceAuto" Content="Set to Automatic"/>
                        <Button x:Name="Button_SetServiceManual" Content="Set to Manual"/>
                        <Button x:Name="Button_SetServiceDisabled" Content="Set to Disabled"/>
                        <Button x:Name="Button_BackupServices" Content="Backup to JSON..."/>
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
    $varName = $_.Name
    Set-Variable -Name "WPF_$($varName)" -Value $Window.FindName($_.Name)
}

# Add a style resource for SemiBold text to be used in DataGrid columns
$semiBoldStyle = New-Object System.Windows.Style -ArgumentList ([System.Windows.Controls.TextBlock])
$semiBoldStyle.Setters.Add((New-Object System.Windows.Setter -ArgumentList @([System.Windows.Controls.TextBlock]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)))
$Window.Resources.Add("SemiBoldStyle", $semiBoldStyle)

#endregion

#region Helper Functions
$Global:GenericIcon = $null
$Global:FileDetailCache = @{} # Cache for publisher info and signature status

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
        $bitmapImage.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
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
    if ($Global:GenericIcon -ne $null) { return $Global:GenericIcon }
    
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

Function Get-CleanPathFromCommand($command) {
    if ([string]::IsNullOrWhiteSpace($command)) { return $null }
    
    # Improved regex to find a file path. It prioritizes quoted paths.
    $match = [regex]::Match($command, '(?:"([^"]+\.(?:exe|dll|sys))"|([^\s]+\.(?:exe|dll|sys)))')
    if (-not $match.Success) { return $null }
    
    $cleanPath = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
    
    try {
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($cleanPath)
        return $expandedPath
    } catch {
        return $cleanPath # Fallback if expansion fails
    }
}

Function Get-FileIcon ($command) {
    $expandedPath = Get-CleanPathFromCommand -command $command
    if ([string]::IsNullOrWhiteSpace($expandedPath) -or -not (Test-Path $expandedPath -PathType Leaf)) {
        return (Get-GenericIcon)
    }

    try {
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($expandedPath)
        if ($icon -eq $null) { return (Get-GenericIcon) }
        return (ConvertTo-ImageSource -icon $icon)
    } catch {
        return (Get-GenericIcon)
    }
}

Function Get-FileDetails($command) {
    $path = Get-CleanPathFromCommand -command $command
    if (-not $path -or -not (Test-Path $path -PathType Leaf)) { return [pscustomobject]@{ Publisher = 'N/A'; IsSigned = 'N/A' } }

    if ($Global:FileDetailCache.ContainsKey($path)) { return $Global:FileDetailCache[$path] }

    try {
        $versionInfo = Get-Item $path | Select-Object -ExpandProperty VersionInfo
        $publisher = if ([string]::IsNullOrWhiteSpace($versionInfo.CompanyName)) { 'N/A' } else { $versionInfo.CompanyName }

        $signature = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
        $isSigned = if ($signature -and $signature.Status -eq 'Valid') { "Signed ($($signature.SignerCertificate.SubjectName.Name))" } else { 'Not Signed' }

        $details = [pscustomobject]@{ Publisher = $publisher; IsSigned = $isSigned }
        $Global:FileDetailCache[$path] = $details
        return $details
    } catch {
        return [pscustomobject]@{ Publisher = 'Error'; IsSigned = 'Error' }
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
            $exportList = $List | Select-Object * -ExcludeProperty Icon, IsSelected
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
    $Global:FileDetailCache.Clear()
    Get-GenericIcon | Out-Null # Pre-load

    $locations = @{
        "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" = "Enabled";
        "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" = "Enabled";
        "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" = "Enabled";
        "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" = "Enabled";
        "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" = "Enabled";
    }
    
    foreach ($path in $locations.Keys) {
        if (Test-Path "Registry::$path") {
            Get-ItemProperty -Path "Registry::$path" -ErrorAction SilentlyContinue | ForEach-Object {
                $_.psobject.Properties | ForEach-Object {
                    if ($_.Name -ne "(default)") {
                        $fileDetails = Get-FileDetails -command $_.Value
                        $Global:StartupItemsList.Add([pscustomobject]@{
                            Name       = $_.Name; Command    = $_.Value; Location   = $path; Status     = $locations[$path]
                            Type       = "Registry"; Icon = Get-FileIcon -command $_.Value; Publisher  = $fileDetails.Publisher
                            IsSigned   = $fileDetails.IsSigned; IsSelected = $false
                        })
                    }
                }
            }
        }
    }
    
    # Check for disabled startup items using the modern StartupApproved method
    $approvedKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    if (Test-Path "Registry::$approvedKey") {
        $approvedProps = Get-ItemProperty -Path "Registry::$approvedKey" -ErrorAction SilentlyContinue
        if ($approvedProps) {
            $approvedProps.psobject.Properties | ForEach-Object {
                $prop = $_ # Capture the current property object
                if ($prop.Name -eq '(default)') { return } # 'return' acts as 'continue' in ForEach-Object
                $itemValue = $prop.Value
                
                # A value starting with 0x03 indicates disabled.
                if ($itemValue -is [byte[]] -and $itemValue.Count -gt 0 -and $itemValue[0] -eq 3) {
                    $itemToUpdate = $Global:StartupItemsList | Where-Object { $_.Name -eq $prop.Name -and $_.Location -like 'HKCU*' }
                    if ($itemToUpdate) { $itemToUpdate.Status = 'Disabled' }
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
            Get-ChildItem -Path $folder -Filter "*.lnk" -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $shell = New-Object -ComObject WScript.Shell
                    $shortcut = $shell.CreateShortcut($_.FullName)
                    if ([string]::IsNullOrWhiteSpace($shortcut.TargetPath)) { throw "Empty target path for shortcut '$($_.Name)'" }
                    
                    $fileDetails = Get-FileDetails -command $shortcut.TargetPath
                    $Global:StartupItemsList.Add([pscustomobject]@{
                        Name       = $_.Name; Command    = $shortcut.TargetPath; Location   = $startupFolders[$folder]; Status     = "Enabled"
                        Type       = "Folder"; Icon = Get-FileIcon -command $shortcut.TargetPath; Publisher  = $fileDetails.Publisher
                        IsSigned   = $fileDetails.IsSigned; IsSelected = $false
                    })
                } catch { Write-Warning "Could not resolve shortcut: $($_.Exception.Message)" }
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
    $selectedItems = $Global:StartupItemsList.Where({$_.IsSelected -eq $true})
    if ($selectedItems.Count -eq 0) { $selectedItems = @($WPF_DataGrid_StartupApps.SelectedItems) }
    if ($selectedItems.Count -eq 0) { Show-Message "Selection Error" "Please select one or more startup items to enable or disable."; return }

    $approvedKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    if (-not(Test-Path $approvedKey)) { New-Item -Path $approvedKey -Force | Out-Null }
    
    $itemsChanged = 0
    foreach ($item in $selectedItems) {
        # This method is only applicable for Current User registry run items.
        if ($item.Location -ne "HKCU\Software\Microsoft\Windows\CurrentVersion\Run") {
            Write-Warning "Skipping '$($item.Name)': Only items in the main HKCU Run key can be toggled with this method."
            continue
        }
        
        try {
            if ($item.Status -eq "Enabled") {
                # Value for DISABLED starts with 03. The rest of the bytes are a timestamp.
                $val = [byte[]](0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
                Set-ItemProperty -Path $approvedKey -Name $item.Name -Value $val -Type Binary -Force -ErrorAction Stop
                $itemsChanged++
            } else { # Item is Disabled
                # Value for ENABLED starts with 02.
                $val = [byte[]](0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
                Set-ItemProperty -Path $approvedKey -Name $item.Name -Value $val -Type Binary -Force -ErrorAction Stop
                $itemsChanged++
            }
        } catch {
            Show-Message "Error" "Failed to toggle status for '$($item.Name)':`n$($_.Exception.Message)" "OK" "Error"
        }
    }

    if ($itemsChanged -gt 0) {
        Show-Message "Success" "Successfully toggled the state for $itemsChanged item(s)."
        Get-StartupApps
    }
})

$WPF_Button_DeleteStartup.Add_Click({
    $selectedItems = $Global:StartupItemsList.Where({$_.IsSelected -eq $true})
    if ($selectedItems.Count -eq 0) {
        if ($WPF_DataGrid_StartupApps.Visibility -eq 'Visible') { $selectedItems = @($WPF_DataGrid_StartupApps.SelectedItems) }
        else { $selectedItems = @($WPF_ListView_StartupApps.SelectedItems) }
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
$WPF_Button_RefreshStartup.Add_Click({ Get-StartupApps })
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
    param($ItemsSource, [string]$SortProperty, [string]$GroupProperty, [string]$SearchText, [string[]]$SearchProperties)
    if (-not $ItemsSource) { return }
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($ItemsSource)
    
    # Apply Filtering
    if (-not [string]::IsNullOrWhiteSpace($SearchText)) {
        $view.Filter = {
            param($item)
            foreach ($prop in $SearchProperties) {
                if ("$($item.$prop)" -like "*$SearchText*") { return $true }
            }
            return $false
        }
    } else {
        $view.Filter = $null
    }

    # Apply Grouping and Sorting
    $view.SortDescriptions.Clear()
    $view.GroupDescriptions.Clear()
    if ($SortProperty) { $view.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription -ArgumentList $SortProperty, "Ascending")) }
    if ($GroupProperty) { $view.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription -ArgumentList $GroupProperty)) }
}

$ApplyStartupFilter = {
    $sortProp = $WPF_ComboBox_SortStartup.SelectedItem
    $groupPropRaw = $WPF_ComboBox_GroupStartup.SelectedItem
    $groupProp = if ($groupPropRaw -eq '(None)') { $null } else { $groupPropRaw }
    Update-View -ItemsSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp -SearchText $WPF_TextBox_SearchStartup.Text -SearchProperties @('Name', 'Command', 'Publisher')
}
$WPF_ComboBox_SortStartup.Add_SelectionChanged($ApplyStartupFilter)
$WPF_ComboBox_GroupStartup.Add_SelectionChanged($ApplyStartupFilter)
$WPF_TextBox_SearchStartup.Add_TextChanged($ApplyStartupFilter)

#endregion

#region Scheduled Tasks Logic
$Global:ScheduledTasksList = [System.Collections.Generic.List[psobject]]::new()
Function Get-ScheduledTasks {
    $WPF_TextBlock_Status.Text = "Loading scheduled tasks..."; 
    $Global:ScheduledTasksList.Clear()
    Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object {
        $Global:ScheduledTasksList.Add($_)
    }
    $WPF_DataGrid_Tasks.ItemsSource = $Global:ScheduledTasksList
    $WPF_TextBlock_Status.Text = "Found $($Global:ScheduledTasksList.Count) scheduled tasks."
}

$ApplyTaskFilter = {
    $sortProp = $WPF_ComboBox_SortTasks.SelectedItem
    $groupPropRaw = $WPF_ComboBox_GroupTasks.SelectedItem
    $groupProp = if ($groupPropRaw -eq '(None)') { $null } else { $groupPropRaw }
    Update-View -ItemsSource $WPF_DataGrid_Tasks.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp -SearchText $WPF_TextBox_SearchTasks.Text -SearchProperties @('TaskName', 'TaskPath')
}
$WPF_Button_RefreshTasks.Add_Click({ Get-ScheduledTasks })
$WPF_Button_BackupTasks.Add_Click({ Export-ListToJson -List @($WPF_DataGrid_Tasks.ItemsSource) -DefaultFileName "ScheduledTasks_Backup.json" })
$WPF_Button_ToggleTask.Add_Click({ 
    $selectedItems = @($WPF_DataGrid_Tasks.SelectedItems)
    if ($selectedItems.Count -eq 0) { Show-Message "Error" "Please select at least one task."; return }
    foreach ($selected in $selectedItems) {
        try { 
            if ($selected.State -eq "Ready" -or $selected.State -eq "Running") { Disable-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop } 
            else { Enable-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop }
        } catch { Show-Message "Error" "Failed to change state for task '$($selected.TaskName)': $_" "OK" "Error" }
    }
    Start-Sleep -milliseconds 500; Get-ScheduledTasks
})
$WPF_Button_DeleteTask.Add_Click({ 
    $selectedItems = @($WPF_DataGrid_Tasks.SelectedItems)
    if ($selectedItems.Count -eq 0) { Show-Message "Error" "Please select at least one task to delete."; return }
    $confirm = Show-Message "Confirm Deletion" "Are you sure you want to permanently delete $($selectedItems.Count) task(s)?" "YesNo" "Warning"
    if ($confirm -ne "Yes") { return }
    foreach ($selected in $selectedItems) {
        try { Unregister-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -Confirm:$false -ErrorAction Stop } 
        catch { Show-Message "Error" "Failed to delete task '$($selected.TaskName)': $_" "OK" "Error" }
    }
    Show-Message "Success" "$($selectedItems.Count) task(s) have been deleted."; Get-ScheduledTasks
})
$WPF_Button_RunTask.Add_Click({
    $selectedItems = @($WPF_DataGrid_Tasks.SelectedItems)
    if ($selectedItems.Count -eq 0) { Show-Message "Error" "Please select at least one task to run."; return }
    foreach ($selected in $selectedItems) {
        if ($selected.State -eq "Disabled") { Write-Warning "Cannot run disabled task '$($selected.TaskName)'."; continue }
        try { Start-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop } 
        catch { Show-Message "Error" "Failed to start task '$($selected.TaskName)': $_" "OK" "Error" }
    }
    Show-Message "Success" "Attempted to start selected task(s)."; Start-Sleep -Seconds 2; Get-ScheduledTasks
})
$WPF_ComboBox_SortTasks.Add_SelectionChanged($ApplyTaskFilter)
$WPF_ComboBox_GroupTasks.Add_SelectionChanged($ApplyTaskFilter)
$WPF_TextBox_SearchTasks.Add_TextChanged($ApplyTaskFilter)
#endregion

#region Services Logic
$Global:ServicesList = [System.Collections.Generic.List[psobject]]::new()
Function Get-Services { 
    $WPF_TextBlock_Status.Text = "Loading services..."; 
    $Global:ServicesList.Clear()
    $servicesRaw = Get-CimInstance -ClassName Win32_Service | Select-Object DisplayName, Name, State, StartMode, PathName, Description
    foreach($service in $servicesRaw) {
        $Global:ServicesList.Add([pscustomobject]@{
            DisplayName = $service.DisplayName; Name = $service.Name; Status = $service.State
            StartType = $service.StartMode; PathName = $service.PathName; Description = $service.Description
        })
    }
    $WPF_DataGrid_Services.ItemsSource = $Global:ServicesList
    $WPF_TextBlock_Status.Text = "Found $($Global:ServicesList.Count) services." 
}
Function Set-ServiceAction($Action, [string[]]$ServiceNames) {
    if ($ServiceNames.Count -eq 0) { Show-Message "Error" "Please select at least one service."; return }
    
    foreach ($name in $ServiceNames) {
        $WPF_TextBlock_Status.Text = "Performing action on service '$($name)'..."
        try { 
            switch ($Action) {
                "Start"    { Start-Service -Name $name -ErrorAction Stop }
                "Stop"     { Stop-Service -Name $name -Force -ErrorAction Stop }
                "Auto"     { Set-Service -Name $name -StartupType Automatic -ErrorAction Stop }
                "Manual"   { Set-Service -Name $name -StartupType Manual -ErrorAction Stop }
                "Disabled" { Set-Service -Name $name -StartupType Disabled -ErrorAction Stop }
            }
        } catch { Show-Message "Error" "Failed to perform action '$Action' on service '$($name)': $_" "OK" "Error" }
    }
    $WPF_TextBlock_Status.Text = "Action completed for selected service(s)."; Start-Sleep -milliseconds 500; Get-Services
}

$ApplyServiceFilter = {
    $sortProp = $WPF_ComboBox_SortServices.SelectedItem
    $groupPropRaw = $WPF_ComboBox_GroupServices.SelectedItem
    $groupProp = switch($groupPropRaw) {
        "(None)" { $null }
        "Startup Type" { "StartType" }
        default { $groupPropRaw }
    }
    Update-View -ItemsSource $WPF_DataGrid_Services.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp -SearchText $WPF_TextBox_SearchServices.Text -SearchProperties @('DisplayName', 'Name', 'PathName')
}
$WPF_Button_RefreshServices.Add_Click({ Get-Services })
$WPF_Button_BackupServices.Add_Click({ Export-ListToJson -List @($WPF_DataGrid_Services.ItemsSource) -DefaultFileName "Services_Backup.json" })
$WPF_Button_StartService.Add_Click({ Set-ServiceAction -Action "Start" -ServiceNames ($WPF_DataGrid_Services.SelectedItems | ForEach-Object Name) })
$WPF_Button_StopService.Add_Click({ Set-ServiceAction -Action "Stop" -ServiceNames ($WPF_DataGrid_Services.SelectedItems | ForEach-Object Name) })
$WPF_Button_SetServiceAuto.Add_Click({ Set-ServiceAction -Action "Auto" -ServiceNames ($WPF_DataGrid_Services.SelectedItems | ForEach-Object Name) })
$WPF_Button_SetServiceManual.Add_Click({ Set-ServiceAction -Action "Manual" -ServiceNames ($WPF_DataGrid_Services.SelectedItems | ForEach-Object Name) })
$WPF_Button_SetServiceDisabled.Add_Click({ Set-ServiceAction -Action "Disabled" -ServiceNames ($WPF_DataGrid_Services.SelectedItems | ForEach-Object Name) })
$WPF_ComboBox_SortServices.Add_SelectionChanged($ApplyServiceFilter)
$WPF_ComboBox_GroupServices.Add_SelectionChanged($ApplyServiceFilter)
$WPF_TextBox_SearchServices.Add_TextChanged($ApplyServiceFilter)
#endregion

#region Context Menu Logic
Function Create-ContextMenu {
    param($TabName)
    $menu = Get-Variable "WPF_ContextMenu_$($TabName)" -ValueOnly
    $grid = Get-Variable "WPF_DataGrid_$($TabName)" -ValueOnly
    $menu.Items.Clear()

    if ($grid.SelectedItems.Count -ne 1) { # Only show context menu for a single selected item
        $mi = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Select a single item to see options"; IsEnabled = $false }
        $menu.Items.Add($mi)
        return
    }
    $selectedItem = $grid.SelectedItem

    $path = $null
    if ($TabName -eq "StartupApps") { $path = Get-CleanPathFromCommand -command $selectedItem.Command }
    if ($TabName -eq "Services") { $path = Get-CleanPathFromCommand -command $selectedItem.PathName }

    # --- File-based actions ---
    if ($path -and (Test-Path $path)) {
        $miOpenLocation = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Open File Location" }
        $miOpenLocation.Add_Click({ Invoke-Item (Split-Path $path) })
        $menu.Items.Add($miOpenLocation)

        $miProperties = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Properties" }
        $miProperties.Add_Click({ $shell = New-Object -ComObject Shell.Application; $shell.Namespace((Split-Path $path)).ParseName((Split-Path $path -Leaf)).InvokeVerb("properties") })
        $menu.Items.Add($miProperties)

        $miSignature = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Verify Digital Signature..." }
        $miSignature.Add_Click({ Show-Message "Signature Status" $selectedItem.IsSigned "OK" "Information" })
        $menu.Items.Add($miSignature)

        $miVirusTotal = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Check on VirusTotal" }
        $miVirusTotal.Add_Click({ 
            try { 
                $hash = (Get-FileHash $path -Algorithm SHA256).Hash
                Start-Process "https://www.virustotal.com/gui/file/$($hash)/detection"
            } catch { Show-Message "Error" "Could not get file hash for '$path'." "OK" "Error" }
        })
        $menu.Items.Add($miVirusTotal)

        $menu.Items.Add((New-Object System.Windows.Controls.Separator))
    }

    # --- Registry/Task specific actions ---
    if ($TabName -eq "StartupApps" -and $selectedItem.Type -eq 'Registry') {
        $miOpenReg = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Open in Registry Editor" }
        $miOpenReg.Add_Click({ 
            $regPath = $selectedItem.Location -replace "HKCU", "HKEY_CURRENT_USER" -replace "HKLM", "HKEY_LOCAL_MACHINE"
            Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" -Name "LastKey" -Value $regPath
            Start-Process regedit -ErrorAction SilentlyContinue
        })
        $menu.Items.Add($miOpenReg)
    }
     if ($TabName -eq "Tasks") {
        $miOpenTaskSchd = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Open Task Scheduler" }
        $miOpenTaskSchd.Add_Click({ Start-Process taskschd.msc })
        $menu.Items.Add($miOpenTaskSchd)
    }

    # --- Generic actions ---
    $itemName = if ($selectedItem.Name) { $selectedItem.Name } elseif ($selectedItem.TaskName) { $selectedItem.TaskName } else { $selectedItem.DisplayName }
    $miSearchOnline = New-Object System.Windows.Controls.MenuItem -Property @{ Header = "Search Online for '$itemName'..." }
    $miSearchOnline.Add_Click({ Start-Process "https://www.google.com/search?q=$([uri]::EscapeDataString($itemName))" })
    $menu.Items.Add($miSearchOnline)
}
$WPF_DataGrid_StartupApps.Add_ContextMenuOpening({ Create-ContextMenu -TabName "StartupApps" })
$WPF_DataGrid_Services.Add_ContextMenuOpening({ Create-ContextMenu -TabName "Services" })
$WPF_DataGrid_Tasks.Add_ContextMenuOpening({ Create-ContextMenu -TabName "Tasks" })
#endregion

#region Main Application Logic

Function Initialize-UI-Defaults {
    # Startup Apps Tab
    $WPF_ComboBox_GroupStartup.ItemsSource = @("(None)", "Status", "Type")
    $WPF_ComboBox_SortStartup.ItemsSource = @("Name", "Location", "Status", "Publisher")
    $WPF_ComboBox_GroupStartup.SelectedItem = "Status"
    $WPF_ComboBox_SortStartup.SelectedItem = "Name"
    
    # Scheduled Tasks Tab
    $WPF_ComboBox_GroupTasks.ItemsSource = @("(None)", "State")
    $WPF_ComboBox_SortTasks.ItemsSource = @("TaskName", "TaskPath")
    $WPF_ComboBox_GroupTasks.SelectedItem = "State"
    $WPF_ComboBox_SortTasks.SelectedItem = "TaskName"

    # Services Tab
    $WPF_ComboBox_GroupServices.ItemsSource = @("(None)", "Status", "Startup Type")
    $WPF_ComboBox_SortServices.ItemsSource = @("DisplayName", "Service Name")
    $WPF_ComboBox_GroupServices.SelectedItem = "Startup Type"
    $WPF_ComboBox_SortServices.SelectedItem = "DisplayName"
}

# Main window load event
$Window.Add_Loaded({
    # Using the dispatcher ensures that the UI is fully loaded and ready before we manipulate data collections.
    # This prevents race conditions that can cause startup crashes.
    $Window.Dispatcher.InvokeAsync({
        try {
            Initialize-UI-Defaults
            Get-StartupApps
            $ApplyStartupFilter.Invoke()
        } catch {
            Show-Message "Fatal Error on Load" "An unexpected error occurred while loading the application:`n`n$($_.Exception.Message)" "OK" "Error"
            $Window.Close()
        }
    })
})

# Load data when a tab is changed by the user
$WPF_TabControl_Main_SelectionChanged = {
    # Don't run this logic during the initial window loading phase
    if (-not $Window.IsLoaded) { return }

    $selectedTab = $WPF_TabControl_Main.SelectedItem.Header
    switch ($selectedTab) {
        # The 'if count is 0' logic efficiently loads data only on the first visit to a tab
        "Startup Apps (Registry & Folders)" { if ($Global:StartupItemsList.Count -eq 0) { Get-StartupApps; $ApplyStartupFilter.Invoke() } }
        "Scheduled Tasks" { if ($Global:ScheduledTasksList.Count -eq 0) { Get-ScheduledTasks; $ApplyTaskFilter.Invoke() } }
        "Services" { if ($Global:ServicesList.Count -eq 0) { Get-Services; $ApplyServiceFilter.Invoke() } }
    }
}
$WPF_TabControl_Main.Add_SelectionChanged($WPF_TabControl_Main_SelectionChanged)


# Display the window to the user
$Window.ShowDialog() | Out-Null

#endregion

