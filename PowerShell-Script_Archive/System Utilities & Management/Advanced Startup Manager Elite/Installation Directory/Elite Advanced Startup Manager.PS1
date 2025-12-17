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
    2.3.9.2
#>

# Start logging for debugging purposes
$LogFile = Join-Path $PSScriptRoot "log.txt"
Start-Transcript -Path $LogFile -Append

#region P/Invoke Definitions
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Shell32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct SHFILEINFO {
        public IntPtr hIcon;
        public int iIcon;
        public uint dwAttributes;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string szDisplayName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]
        public string szTypeName;
    };

    [Flags]
    public enum FileInfoFlags : uint {
        SHGFI_ICON = 0x000000100,     // get icon
        SHGFI_DISPLAYNAME = 0x000000200,     // get display name
        SHGFI_TYPENAME = 0x000000400,     // get type name
        SHGFI_ATTRIBUTES = 0x000000800,     // get attributes
        SHGFI_ICONLOCATION = 0x000001000,     // get icon location
        SHGFI_EXETYPE = 0x000002000,     // return exe type
        SHGFI_SYSICONINDEX = 0x000004000,     // get system icon index
        SHGFI_LINKOVERLAY = 0x000008000,     // put a link overlay on icon
        SHGFI_SELECTED = 0x000010000,     // show icon in selected state
        SHGFI_ATTR_SPECIFIED = 0x000020000,     // get only specified attributes
        SHGFI_LARGEICON = 0x000000000,     // get large icon
        SHGFI_SMALLICON = 0x000000001,     // get small icon
        SHGFI_OPENICON = 0x000000002,     // get open icon
        SHGFI_SHELLICONSIZE = 0x000000004,     // get shell size icon
        SHGFI_PIDL = 0x000000008,     // pszPath is a pidl
        SHGFI_USEFILEATTRIBUTES = 0x000000010     // use passed dwFileAttribute
    }

    [DllImport("shell32.dll")]
    public static extern IntPtr SHGetFileInfo(string pszPath, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbFileInfo, FileInfoFlags uFlags);
}

public static class User32 {
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool DestroyIcon(IntPtr hIcon);
}
"@
#endregion

#region Administrative Rights Check
# This section ensures the script is run with administrator privileges.
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    try {
        $currentExe = (Get-Process -Id $PID).Path
        $arguments = "-NoProfile -File `"$($myinvocation.mycommand.definition)`""
        Start-Process -FilePath $currentExe -Verb runAs -ArgumentList $arguments
    } catch {
        # Fallback for environments where the above might fail
        $arguments = "& '" + $myinvocation.mycommand.definition + "'"
        Start-Process powershell -Verb runAs -ArgumentList $arguments
    }
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
        ResizeMode="CanResizeWithGrip"
        Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}">
    <Window.Resources>
        <LinearGradientBrush x:Key="GlassyButtonBrush" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#55FFFFFF" Offset="0.0"/>
            <GradientStop Color="#22000000" Offset="1.0"/>
        </LinearGradientBrush>
        
        <Style x:Key="GlassyButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource GlassyButtonBrush}"/>
            <Setter Property="BorderBrush" Value="#FFD7D7D7"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        
        <Menu Grid.Row="0" VerticalAlignment="Top">
            <MenuItem Header="_File" ToolTip="File operations">
                <MenuItem x:Name="MenuItem_BackupRestore" Header="_Backup &amp; Restore..." ToolTip="Open the Backup &amp; Restore window"/>
                <Separator/>
                <MenuItem x:Name="MenuItem_Exit" Header="E_xit" ToolTip="Exit the application"/>
            </MenuItem>
            <MenuItem Header="_Help" ToolTip="Get help and application information">
                <MenuItem x:Name="MenuItem_ViewChangelog" Header="View _Changelog" ToolTip="View the application's version history"/>
            </MenuItem>
        </Menu>
        
        <TabControl x:Name="TabControl_Main" Grid.Row="1">
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
                            <Button x:Name="Button_ViewList" Content="List" Margin="5,0" Padding="5,2" ToolTip="Display startup items in a detailed list" Style="{StaticResource GlassyButtonStyle}"/>
                            <Button x:Name="Button_ViewIcons" Content="Icons" Margin="0,0,20,0" Padding="5,2" ToolTip="Display startup items as large icons" Style="{StaticResource GlassyButtonStyle}"/>
                            <Label Content="Group by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_GroupStartup" Width="120" Margin="5,0,20,0" ToolTip="Group the list by the selected criteria">
                                <ComboBoxItem Content="(None)"/>
                                <ComboBoxItem Content="Status"/>
                                <ComboBoxItem Content="Location Type"/>
                            </ComboBox>
                            <Label Content="Sort by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_SortStartup" Width="120" Margin="5,0" ToolTip="Sort the list by the selected criteria">
                                <ComboBoxItem Content="Name"/>
                                <ComboBoxItem Content="Location"/>
                                <ComboBoxItem Content="Status"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    
                    <DataGrid x:Name="DataGrid_StartupApps" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended" Visibility="Visible"
                              AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"
                              GridLinesVisibility="All" HorizontalGridLinesBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" VerticalGridLinesBrush="{DynamicResource {x:Static SystemColors.GrayTextBrushKey}}">
                        <DataGrid.ContextMenu>
                            <ContextMenu>
                                <MenuItem x:Name="CM_Startup_OpenFileLocation" Header="Open File Location"/>
                                <MenuItem x:Name="CM_Startup_OpenRegLocation" Header="Open Registry Location"/>
                            </ContextMenu>
                        </DataGrid.ContextMenu>
                        <DataGrid.GroupStyle>
                            <GroupStyle><GroupStyle.ContainerStyle><Style TargetType="{x:Type GroupItem}"><Setter Property="Template"><Setter.Value><ControlTemplate><Expander IsExpanded="True"><Expander.Header><StackPanel Orientation="Horizontal"><TextBlock FontWeight="Bold" Text="{Binding Name}" Margin="5,0"/><TextBlock Text="{Binding ItemCount, StringFormat='({0} items)'}"/></StackPanel></Expander.Header><ItemsPresenter /></Expander></ControlTemplate></Setter.Value></Setter></Style></GroupStyle.ContainerStyle></GroupStyle>
                        </DataGrid.GroupStyle>
                        <DataGrid.Columns>
                            <DataGridTemplateColumn><DataGridTemplateColumn.Header><CheckBox x:Name="CheckBox_SelectAllStartup" ToolTip="Select or deselect all items in the list"/></DataGridTemplateColumn.Header><DataGridTemplateColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn>
                            <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="200" />
                            <DataGridTextColumn Header="Command / Path" Binding="{Binding Command}" Width="*" />
                            <DataGridTextColumn Header="Location" Binding="{Binding Location}" Width="250" />
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100" />
                        </DataGrid.Columns>
                    </DataGrid>

                    <ListView x:Name="ListView_StartupApps" Grid.Row="1" Visibility="Collapsed" SelectionMode="Extended" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListView.GroupStyle><GroupStyle><GroupStyle.HeaderTemplate><DataTemplate><TextBlock FontWeight="Bold" FontSize="14" Text="{Binding Name}" Margin="0,5"/></DataTemplate></GroupStyle.HeaderTemplate></GroupStyle></ListView.GroupStyle>
                        <ListView.ItemTemplate><DataTemplate><Border Margin="5" Padding="5" BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" BorderThickness="1" Width="350"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="48"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Image Grid.Column="0" Source="{Binding Icon}" Width="32" Height="32" VerticalAlignment="Center"/><StackPanel Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Center"><TextBlock Text="{Binding Name}" FontWeight="Bold" TextTrimming="CharacterEllipsis"/><TextBlock Text="{Binding Status}" FontStyle="Italic"/></StackPanel></Grid></Border></DataTemplate></ListView.ItemTemplate>
                    </ListView>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshStartup" Content="Refresh" Width="100" Margin="0,0,5,0" ToolTip="Reloads the list of all startup applications" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_ToggleStartup" Content="Enable/Disable Selected" Width="180" Margin="0,0,5,0" ToolTip="Enables or disables the selected startup items (Registry only)" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_DeleteStartup" Content="Delete Selected" Width="120" Margin="0,0,5,0" ToolTip="Permanently deletes the selected startup items" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_AddStartup" Content="Add New..." Width="100" Margin="0,0,5,0" ToolTip="Add a new startup item to the registry" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_BackupStartup" Content="Backup to JSON..." Width="130" ToolTip="Save the current list of startup items to a JSON file" Style="{StaticResource GlassyButtonStyle}"/>
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
                            <ComboBox x:Name="ComboBox_GroupTasks" Width="120" Margin="5,0,20,0" ToolTip="Group the list by the selected criteria">
                                <ComboBoxItem Content="(None)"/>
                                <ComboBoxItem Content="State"/>
                            </ComboBox>
                            <Label Content="Sort by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_SortTasks" Width="120" Margin="5,0" ToolTip="Sort the list by the selected criteria">
                                <ComboBoxItem Content="Task Name"/>
                                <ComboBoxItem Content="Task Path"/>
                                <ComboBoxItem Content="State"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    <DataGrid x:Name="DataGrid_ScheduledTasks" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single"
                              AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"
                              GridLinesVisibility="All" HorizontalGridLinesBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" VerticalGridLinesBrush="{DynamicResource {x:Static SystemColors.GrayTextBrushKey}}">
                        <DataGrid.ContextMenu>
                            <ContextMenu>
                                <MenuItem x:Name="CM_Tasks_OpenScheduler" Header="Open Task Scheduler"/>
                            </ContextMenu>
                        </DataGrid.ContextMenu>
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
                        <Button x:Name="Button_RefreshTasks" Content="Refresh" Width="100" Margin="0,0,5,0" ToolTip="Reloads the list of all scheduled tasks" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_ToggleTask" Content="Enable/Disable" Width="120" Margin="0,0,5,0" ToolTip="Enables or disables the selected task" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_DeleteTask" Content="Delete Task" Width="100" Margin="0,0,5,0" ToolTip="Permanently deletes the selected task" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_RunTask" Content="Run Now" Width="100" Margin="0,0,5,0" ToolTip="Runs the selected task immediately" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_BackupTasks" Content="Backup to JSON..." Width="130" ToolTip="Save the current list of scheduled tasks to a JSON file" Style="{StaticResource GlassyButtonStyle}"/>
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
                            <ComboBox x:Name="ComboBox_GroupServices" Width="120" Margin="5,0,20,0" ToolTip="Group the list by the selected criteria">
                                <ComboBoxItem Content="(None)"/>
                                <ComboBoxItem Content="Status"/>
                                <ComboBoxItem Content="Startup Type"/>
                            </ComboBox>
                            <Label Content="Sort by:" VerticalAlignment="Center"/>
                            <ComboBox x:Name="ComboBox_SortServices" Width="120" Margin="5,0" ToolTip="Sort the list by the selected criteria">
                                <ComboBoxItem Content="Display Name"/>
                                <ComboBoxItem Content="Service Name"/>
                                <ComboBoxItem Content="Status"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>
                    <DataGrid x:Name="DataGrid_Services" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single"
                              AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"
                              GridLinesVisibility="All" HorizontalGridLinesBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" VerticalGridLinesBrush="{DynamicResource {x:Static SystemColors.GrayTextBrushKey}}">
                        <DataGrid.ContextMenu>
                            <ContextMenu>
                                <MenuItem x:Name="CM_Services_OpenManager" Header="Open Services Manager"/>
                            </ContextMenu>
                        </DataGrid.ContextMenu>
                        <DataGrid.GroupStyle><GroupStyle><GroupStyle.ContainerStyle><Style TargetType="{x:Type GroupItem}"><Setter Property="Template"><Setter.Value><ControlTemplate><Expander IsExpanded="True"><Expander.Header><StackPanel Orientation="Horizontal"><TextBlock FontWeight="Bold" Text="{Binding Name}" Margin="5,0"/><TextBlock Text="{Binding ItemCount, StringFormat='({0} items)'}"/></StackPanel></Expander.Header><ItemsPresenter /></Expander></ControlTemplate></Setter.Value></Setter></Style></GroupStyle.ContainerStyle></GroupStyle></DataGrid.GroupStyle>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Display Name" Binding="{Binding DisplayName}" Width="*" />
                            <DataGridTextColumn Header="Service Name" Binding="{Binding Name}" Width="250" />
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100" />
                            <DataGridTextColumn Header="Startup Type" Binding="{Binding StartType}" Width="120" />
                        </DataGrid.Columns>
                    </DataGrid>
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="Button_RefreshServices" Content="Refresh" Width="100" Margin="0,0,5,0" ToolTip="Reloads the list of all services" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_StartService" Content="Start" Width="100" Margin="0,0,5,0" ToolTip="Starts the selected service" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_StopService" Content="Stop" Width="100" Margin="0,0,5,0" ToolTip="Stops the selected service" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_SetServiceAuto" Content="Set to Automatic" Width="130" Margin="0,0,5,0" ToolTip="Sets the selected service's startup type to Automatic" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_SetServiceManual" Content="Set to Manual" Width="120" Margin="0,0,5,0" ToolTip="Sets the selected service's startup type to Manual" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_SetServiceDisabled" Content="Set to Disabled" Width="120" Padding="5" Margin="0,0,5,0" ToolTip="Disables the selected service" Style="{StaticResource GlassyButtonStyle}"/>
                        <Button x:Name="Button_BackupServices" Content="Backup to JSON..." Width="130" ToolTip="Save the current list of services to a JSON file" Style="{StaticResource GlassyButtonStyle}"/>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>
        
        <StatusBar Grid.Row="2" Margin="0,10,0,0">
            <StatusBarItem>
                <TextBlock x:Name="TextBlock_Status" Text="Ready. Select a tab to begin." />
            </StatusBarItem>
            <Separator/>
            <StatusBarItem>
                <TextBlock x:Name="TextBlock_Version" />
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

# Add event handlers for menu items
$WPF_MenuItem_Exit.Add_Click({ $Window.Close() })
$WPF_MenuItem_ViewChangelog.Add_Click({ Show-ChangelogWindow })
$WPF_MenuItem_BackupRestore.Add_Click({ Show-BackupRestoreWindow })
#endregion

#region Helper Functions
# This will hold the placeholder icon so we only load it once.
$Global:PlaceholderIcon = $null

$Global:PreferencesFile = Join-Path $PSScriptRoot "Preferences.json"

# This function converts a System.Drawing.Icon into a WPF-compatible ImageSource.
Function ConvertTo-ImageSource {
    param ([System.Drawing.Icon]$icon)
    if ($icon -eq $null) { return $null }
    try {
        $memoryStream = New-Object System.IO.MemoryStream
        $icon.ToBitmap().Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
        [void]$memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin)
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

Function Load-Preferences {
    if (-not (Test-Path $Global:PreferencesFile)) { return }
    try {
        $prefs = Get-Content -Path $Global:PreferencesFile | ConvertFrom-Json
        
        # Startup Tab
        $WPF_ComboBox_GroupStartup.SelectedIndex = $prefs.Startup.Grouping
        $WPF_ComboBox_SortStartup.SelectedIndex = $prefs.Startup.Sorting
        if ($prefs.Startup.View -eq 'List') { $WPF_Button_ViewList.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent))) }
        else { $WPF_Button_ViewIcons.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent))) }

        # Scheduled Tasks Tab
        $WPF_ComboBox_GroupTasks.SelectedIndex = $prefs.Tasks.Grouping
        $WPF_ComboBox_SortTasks.SelectedIndex = $prefs.Tasks.Sorting

        # Services Tab
        $WPF_ComboBox_GroupServices.SelectedIndex = $prefs.Services.Grouping
        $WPF_ComboBox_SortServices.SelectedIndex = $prefs.Services.Sorting

    } catch {
        Write-Warning "Could not load preferences: $_"
    }
}

Function Save-Preferences {
    $prefs = @{
        Startup = @{
            Grouping = $WPF_ComboBox_GroupStartup.SelectedIndex
            Sorting = $WPF_ComboBox_SortStartup.SelectedIndex
            View = if ($WPF_DataGrid_StartupApps.Visibility -eq 'Visible') { 'List' } else { 'Icons' }
        }
        Tasks = @{
            Grouping = $WPF_ComboBox_GroupTasks.SelectedIndex
            Sorting = $WPF_ComboBox_SortTasks.SelectedIndex
        }
        Services = @{
            Grouping = $WPF_ComboBox_GroupServices.SelectedIndex
            Sorting = $WPF_ComboBox_SortServices.SelectedIndex
        }
    }
    try {
        $prefs | ConvertTo-Json | Out-File -FilePath $Global:PreferencesFile -Encoding utf8
    } catch {
        Write-Warning "Could not save preferences: $_"
    }
}


Function Get-PlaceholderIcon {
    # If the icon is already created and cached, return it.
    if ($Global:PlaceholderIcon -ne $null) {
        return $Global:PlaceholderIcon
    }
    
    $placeholderPath = Join-Path $PSScriptRoot "..\Icons\Currently Unused\Missing_icon.ico"
    try {
        if (-not (Test-Path $placeholderPath)) { throw "Placeholder icon not found at '$placeholderPath'" }
        $icon = New-Object System.Drawing.Icon -ArgumentList $placeholderPath
        $Global:PlaceholderIcon = ConvertTo-ImageSource -icon $icon
        return $Global:PlaceholderIcon
    } catch {
        Write-Warning "Could not load the placeholder icon. Error: $_"
        # As a final fallback, try to get a system generic icon.
        $genericPath = Join-Path $env:SystemRoot "System32\imageres.dll"
        try {
            $genericIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($genericPath)
            return ConvertTo-ImageSource -icon $genericIcon
        } catch { return $null }
    }
}

Function Show-Message ($Title, $Text, $Button = 'OK', $Icon = 'Information') {
    [System.Windows.MessageBox]::Show($Window, $Text, $Title, $Button, $Icon) | Out-Null
}

Function Show-InRegedit {

    param(

        [string]$KeyPath,

        [string]$ValueName

    )

    try {

        # Regedit opens to the key stored in the 'LastKey' value.

        # The path needs to be converted from the PowerShell format (e.g., HKCU:\) to the regedit format (e.g., HKEY_CURRENT_USER\)

        $regeditPath = $KeyPath -replace "HKCU:","HKEY_CURRENT_USER" -replace "HKLM:","HKEY_LOCAL_MACHINE"

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" -Name "LastKey" -Value $regeditPath -Force

        Start-Process regedit.exe -ArgumentList "/v `"$ValueName`""

    } catch {

        Show-Message "Error" "Failed to open Registry Editor: $_" "Error"

    }

}



Function Set-WindowIcon {



    try {



        $iconPath = Join-Path $PSScriptRoot "Advanced Startup Manager Elite.ico"



        if (Test-Path $iconPath) {



            $icon = New-Object System.Drawing.Icon -ArgumentList $iconPath



            $Window.Icon = ConvertTo-ImageSource -icon $icon



        }



    } catch {



        Write-Warning "Could not load the application icon. Error: $_"



    }



}







Function Get-IconFromPathByApi {



    param ($path)



    $hIcon = $null



    try {



        $shfi = New-Object Shell32+SHFILEINFO



        $flags = [Shell32+FileInfoFlags]::SHGFI_ICON -bor [Shell32+FileInfoFlags]::SHGFI_LARGEICON



        $result = [Shell32]::SHGetFileInfo($path, 0, [ref]$shfi, [System.Runtime.InteropServices.Marshal]::SizeOf($shfi), $flags)







        if ($result -eq [System.IntPtr]::Zero) {



            # Failed to get icon handle



            return $null



        }



        $hIcon = $shfi.hIcon



        $icon = [System.Drawing.Icon]::FromHandle($hIcon)



        return ConvertTo-ImageSource -icon $icon.Clone() # Clone to avoid handle issues



    }



    catch {



        Write-Warning "P/Invoke icon extraction failed for '$path': $_"



        return $null



    }



    finally {



        if ($hIcon -ne $null) {



            [User32]::DestroyIcon($hIcon) | Out-Null



        }



    }



}







Function Get-FileIcon ($command) {







    if ([string]::IsNullOrWhiteSpace($command)) { return (Get-PlaceholderIcon) }















    try {







        $expandedCommand = [System.Environment]::ExpandEnvironmentVariables($command)







        # Extract the base command/executable name (e.g., "chrome.exe" from "chrome.exe --incognito")







        $match = [regex]::Match($expandedCommand, '(?:"([^"]+?)"|([^\s]+))')







        if (-not $match.Success) { return (Get-PlaceholderIcon) }







        







        $baseCommand = $match.Value.Trim('"')







        $exeName = [System.IO.Path]::GetFileName($baseCommand)







        $resolvedPath = $null















        # 1. (PRIMARY) Try to find the program in the 'App Paths' registry key. This is the most reliable method.







        $appPathKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"







        if (Test-Path $appPathKey) {







            $resolvedPath = Get-ItemProperty -Path $appPathKey -Name "(Default)" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "(Default)"







        }















        # 2. (FALLBACK 1) If not in App Paths, check if the command was already a full path.







        if (-not $resolvedPath -and (Test-Path $baseCommand -PathType Leaf -ErrorAction SilentlyContinue)) {







            $resolvedPath = $baseCommand







        }







        







        # 3. (FALLBACK 2) If still not found, try to resolve it using the system PATH environment variable.







        if (-not $resolvedPath) {







            $foundCmd = Get-Command $baseCommand -CommandType Application, ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1







            if ($foundCmd) {







                $resolvedPath = $foundCmd.Source







            }







        }







        







        # 4. If we have a path, try to get the icon.







        if (-not ([string]::IsNullOrWhiteSpace($resolvedPath))) {







            # If it's a shortcut, resolve it







            if ($resolvedPath.ToLower().EndsWith(".lnk")) {







                 try {







                    $shell = New-Object -ComObject WScript.Shell







                    $shortcut = $shell.CreateShortcut($resolvedPath)







                    $targetPath = $shortcut.TargetPath







                    if (-not ([string]::IsNullOrWhiteSpace($targetPath))) {







                        $expandedTarget = [System.Environment]::ExpandEnvironmentVariables($targetPath)







                        if (Test-Path $expandedTarget -ErrorAction SilentlyContinue) {







                            $resolvedPath = $expandedTarget







                        }







                    }







                 } catch {







                    Write-Warning "Could not resolve shortcut '$resolvedPath': $_"







                 }







            }







            







            $iconSource = Get-IconFromPathByApi -path $resolvedPath







            if ($iconSource -ne $null) {







                return $iconSource







            }







        }







    }







    catch {







        Write-Warning "Top-level icon retrieval failed for '$command': $_"







    }







    







    # Final fallback if all methods fail







    return (Get-PlaceholderIcon)







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

                        $exportList | ConvertTo-Json | Out-File -FilePath $saveFileDialog.FileName -Encoding utf8

                        Show-Message "Export Successful" "The list was successfully backed up to:`n$($saveFileDialog.FileName)" "Okay" "Information"

                    } catch {

                        Show-Message "Export Failed" "An error occurred while saving the file:`n$($_.Exception.Message)" "Okay" "Error"

                    }

                }

            }

            

            Function Export-ListToJson-Auto {

                param(

                    [System.Collections.IList]$List,

                    [string]$FilePath

                )

                if ($List.Count -eq 0) { return } # Don't save empty backups

            

                try {

                    $exportList = $List | Select-Object * -ExcludeProperty Icon, IsSelected

                    $exportList | ConvertTo-Json | Out-File -FilePath $FilePath -Encoding utf8

                } catch {

                    Write-Warning "Auto-backup failed for '$FilePath'. Error: $_"

                }

            }



Function Invoke-AutoBackup {



    $WPF_TextBlock_Status.Text = "Performing automatic backup..."



    $backupRoot = Join-Path $PSScriptRoot "..\Backups" # Assumes Backups folder is one level up from Installation Directory



    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"







    # Scheduled Tasks Backup



    $tasksBackupDir = Join-Path $backupRoot "Scheduled Tasks"



    if (-not (Test-Path $tasksBackupDir)) { New-Item -Path $tasksBackupDir -ItemType Directory -Force | Out-Null }



    if ($Global:ScheduledTasksList.Count -gt 0) {



        $simplifiedTasks = $Global:ScheduledTasksList | Select-Object TaskName, TaskPath, State, Description, Author, Actions, Triggers



        Export-ListToJson-Auto -List $simplifiedTasks -FilePath (Join-Path $tasksBackupDir "ScheduledTasks_Backup_$timestamp.json")



    }







    # Services Backup



    $servicesBackupDir = Join-Path $backupRoot "Services"



    if (-not (Test-Path $servicesBackupDir)) { New-Item -Path $servicesBackupDir -ItemType Directory -Force | Out-Null }



    if ($Global:ServicesList.Count -gt 0) {



        $simplifiedServices = $Global:ServicesList | Select-Object DisplayName, Name, Status, StartType



        Export-ListToJson-Auto -List $simplifiedServices -FilePath (Join-Path $servicesBackupDir "Services_Backup_$timestamp.json")



    }







    # Startup Items Backup (already simple objects)



    $startupBackupDir = Join-Path $backupRoot "Startup Items"



    if (-not (Test-Path $startupBackupDir)) { New-Item -Path $startupBackupDir -ItemType Directory -Force | Out-Null }



    if ($Global:StartupItemsList.Count -gt 0) {



        Export-ListToJson-Auto -List $Global:StartupItemsList -FilePath (Join-Path $startupBackupDir "StartupItems_Backup_$timestamp.json")



    }



    $WPF_TextBlock_Status.Text = "Automatic backup completed."



}

#endregion



#region Startup Apps Logic



$Global:StartupItemsList = [System.Collections.Generic.List[psobject]]::new()



Function Get-StartupApps {

    $WPF_TextBlock_Status.Text = "Loading startup applications..."

    $Global:StartupItemsList.Clear()

    # Pre-load the placeholder icon to ensure it's available.

    Get-PlaceholderIcon | Out-Null



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

                        Location   = $folder # Use the actual folder path

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

                Remove-Item -Path (Join-Path $selected.Location $selected.Name) -Force -ErrorAction Stop

            }

        } catch { Show-Message "Error" "Failed to delete item '$($selected.Name)': $_" "OK" "Error" }

    }

    Show-Message "Success" "Deletion complete."

    Get-StartupApps

})



# --- UI Event Handlers ---

$WPF_Button_RefreshStartup.Add_Click({ Get-StartupApps; $WPF_ComboBox_GroupStartup.SelectedIndex = 0; $WPF_ComboBox_SortStartup.SelectedIndex = 0 })

$WPF_Button_BackupStartup.Add_Click({ Export-ListToJson -List $Global:StartupItemsList -DefaultFileName "StartupApps_Backup.json" })

$WPF_Button_ViewList.Add_Click({ $WPF_DataGrid_StartupApps.Visibility = 'Visible'; $WPF_ListView_StartupApps.Visibility = 'Collapsed'; Save-Preferences })

$WPF_Button_ViewIcons.Add_Click({ $WPF_DataGrid_StartupApps.Visibility = 'Collapsed'; $WPF_ListView_StartupApps.Visibility = 'Visible'; Save-Preferences })

$WPF_CheckBox_SelectAllStartup.Add_Click({ $isChecked = $WPF_CheckBox_SelectAllStartup.IsChecked; $Global:StartupItemsList | ForEach-Object { $_.IsSelected = $isChecked }; $WPF_DataGrid_StartupApps.ItemsSource.Refresh() })



$WPF_CM_Startup_OpenFileLocation.Add_Click({

    if ($WPF_DataGrid_StartupApps.SelectedItem -eq $null) { return }

    $selected = $WPF_DataGrid_StartupApps.SelectedItem

    $path = $null

    if ($selected.Type -eq 'Folder') {

        $path = Join-Path $selected.Location $selected.Name

    } else {

        $match = [regex]::Match($selected.Command, '(?:"([^"]+?)"|([^\s]+))')

        if ($match.Success) {

            $path = [System.Environment]::ExpandEnvironmentVariables($match.Value.Trim('"'))

        }

    }



    if ($path -and (Test-Path $path)) {

        Start-Process explorer.exe -ArgumentList "/select,`"$path`""

    } else {

        Show-Message "Error" "Could not determine a valid file path to open." "OK" "Error"

    }

})



$WPF_CM_Startup_OpenRegLocation.Add_Click({

    if ($WPF_DataGrid_StartupApps.SelectedItem -eq $null) { return }

    $selected = $WPF_DataGrid_StartupApps.SelectedItem

    Show-InRegedit -KeyPath $selected.Location -ValueName $selected.Name

})



$WPF_DataGrid_StartupApps.Add_ContextMenuOpening({

    if ($WPF_DataGrid_StartupApps.SelectedItem -eq $null) {

        $WPF_CM_Startup_OpenFileLocation.IsEnabled = $false

        $WPF_CM_Startup_OpenRegLocation.IsEnabled = $false

        return

    }

    $selected = $WPF_DataGrid_StartupApps.SelectedItem

    $WPF_CM_Startup_OpenFileLocation.IsEnabled = ($selected.Type -eq 'Folder' -or $selected.Command -match '(\.exe|\.bat|\.cmd|\.ps1|\.lnk)')

    $WPF_CM_Startup_OpenRegLocation.IsEnabled = ($selected.Type -eq 'Registry')

})



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

                <Button x:Name="Button_OK" Content="Okay" Width="80" Margin="0,0,5,0" IsDefault="True"/>

                <Button x:Name="Button_Cancel" Content="Cancel" Width="80" IsCancel="True"/>

            </StackPanel>

        </Grid>

    </Window>

"@

        $addReader = (New-Object System.Xml.XmlNodeReader $addDialogXaml)

        $addDialog = [Windows.Markup.XamlReader]::Load($addReader)

        $addDialog.Owner = $Window

        $addDialog.Icon = $Window.Icon

    

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
$WPF_ComboBox_SortStartup.Add_SelectionChanged({ $sortProp = switch($WPF_ComboBox_SortStartup.SelectedItem.Content) { "Name" { "Name" } "Location" { "Location" } "Status" { "Status" } default { "Name" } }; $groupProp = if ($WPF_DataGrid_StartupApps.ItemsSource.GroupDescriptions.Count -gt 0) { $WPF_DataGrid_StartupApps.ItemsSource.GroupDescriptions[0].PropertyName } else { $null }; Update-View -ViewSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp; Save-Preferences })
$WPF_ComboBox_GroupStartup.Add_SelectionChanged({ $groupProp = switch($WPF_ComboBox_GroupStartup.SelectedItem.Content) { "Status" { "Status" } "Location Type" { "Type" } default { $null } }; $sortProp = if ($WPF_DataGrid_StartupApps.ItemsSource.SortDescriptions.Count -gt 0) { $WPF_DataGrid_StartupApps.ItemsSource.SortDescriptions[0].PropertyName } else { "Name" }; Update-View -ViewSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp; Save-Preferences })
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
$WPF_Button_BackupTasks.Add_Click({ 
    $simplifiedTasks = $Global:ScheduledTasksList | Select-Object TaskName, TaskPath, State, Description, Author, Actions, Triggers
    Export-ListToJson -List $simplifiedTasks -DefaultFileName "ScheduledTasks_Backup.json" 
})
$WPF_Button_ToggleTask.Add_Click({ $selected = $WPF_DataGrid_ScheduledTasks.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a task first."; return }; try { if ($selected.State -eq "Ready" -or $selected.State -eq "Running") { Disable-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop; } else { Enable-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop; }; Start-Sleep -milliseconds 500; Get-ScheduledTasks } catch { Show-Message "Error" "Failed to change task state: $_" "OK" "Error" } })
$WPF_Button_DeleteTask.Add_Click({ $selected = $WPF_DataGrid_ScheduledTasks.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a task first."; return }; $confirm = Show-Message "Confirm Deletion" "Are you sure you want to permanently delete task '$($selected.TaskName)'?" "YesNo" "Warning"; if ($confirm -ne "Yes") { return }; try { Unregister-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -Confirm:$false -ErrorAction Stop; Show-Message "Success" "Task '$($selected.TaskName)' has been deleted."; Get-ScheduledTasks } catch { Show-Message "Error" "Failed to delete task: $_" "OK" "Error" } })
$WPF_Button_RunTask.Add_Click({ $selected = $WPF_DataGrid_ScheduledTasks.SelectedItem; if (-not $selected) { Show-Message "Error" "Please select a task first."; return }; if ($selected.State -eq "Disabled") { Show-Message "Error" "Cannot run a disabled task. Please enable it first."; return }; try { Start-ScheduledTask -TaskName $selected.TaskName -TaskPath $selected.TaskPath -ErrorAction Stop; Show-Message "Success" "Task '$($selected.TaskName)' has been started."; Start-Sleep -Seconds 2; Get-ScheduledTasks } catch { Show-Message "Error" "Failed to start task: $_" "OK" "Error" } })
$WPF_ComboBox_SortTasks.Add_SelectionChanged({ $sortProp = switch($WPF_ComboBox_SortTasks.SelectedItem.Content) { "Task Name" { "TaskName" } "Task Path" { "TaskPath" } "State" { "State" } default { "TaskName" } }; $groupProp = if ($WPF_DataGrid_ScheduledTasks.ItemsSource.GroupDescriptions.Count -gt 0) { $WPF_DataGrid_ScheduledTasks.ItemsSource.GroupDescriptions[0].PropertyName } else { $null }; Update-View -ViewSource $WPF_DataGrid_ScheduledTasks.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp; Save-Preferences })
$WPF_ComboBox_GroupTasks.Add_SelectionChanged({ $groupProp = switch($WPF_ComboBox_GroupTasks.SelectedItem.Content) { "State" { "State" } default { $null } }; $sortProp = if ($WPF_DataGrid_ScheduledTasks.ItemsSource.SortDescriptions.Count -gt 0) { $WPF_DataGrid_ScheduledTasks.ItemsSource.SortDescriptions[0].PropertyName } else { "TaskName" }; Update-View -ViewSource $WPF_DataGrid_ScheduledTasks.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp; Save-Preferences })
$WPF_CM_Tasks_OpenScheduler.Add_Click({ Start-Process taskschd.msc })
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
$WPF_Button_BackupServices.Add_Click({ 
    $simplifiedServices = $Global:ServicesList | Select-Object DisplayName, Name, Status, StartType
    Export-ListToJson -List $simplifiedServices -DefaultFileName "Services_Backup.json" 
})
$WPF_Button_StartService.Add_Click({ Set-ServiceAction -Action "Start" })
$WPF_Button_StopService.Add_Click({ Set-ServiceAction -Action "Stop" })
$WPF_Button_SetServiceAuto.Add_Click({ Set-ServiceAction -Action "Auto" })
$WPF_Button_SetServiceManual.Add_Click({ Set-ServiceAction -Action "Manual" })
$WPF_Button_SetServiceDisabled.Add_Click({ Set-ServiceAction -Action "Disabled" })
$WPF_ComboBox_SortServices.Add_SelectionChanged({ $sortProp = switch($WPF_ComboBox_SortServices.SelectedItem.Content) { "Display Name" { "DisplayName" } "Service Name" { "Name" } "Status" { "Status" } default { "DisplayName" } }; $groupProp = if ($WPF_DataGrid_Services.ItemsSource.GroupDescriptions.Count -gt 0) { $WPF_DataGrid_Services.ItemsSource.GroupDescriptions[0].PropertyName } else { $null }; Update-View -ViewSource $WPF_DataGrid_Services.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp; Save-Preferences })
$WPF_ComboBox_GroupServices.Add_SelectionChanged({ $groupProp = switch($WPF_ComboBox_GroupServices.SelectedItem.Content) { "Status" { "Status" } "Startup Type" { "StartType" } default { $null } }; $sortProp = if ($WPF_DataGrid_Services.ItemsSource.SortDescriptions.Count -gt 0) { $WPF_DataGrid_Services.ItemsSource.SortDescriptions[0].PropertyName } else { "DisplayName" }; Update-View -ViewSource $WPF_DataGrid_Services.ItemsSource -SortProperty $sortProp -GroupProperty $groupProp; Save-Preferences })
$WPF_CM_Services_OpenManager.Add_Click({ Start-Process services.msc })
#endregion

#region Main Application Logic

Function Show-BackupRestoreWindow {
    [xml]$brDialogXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Backup &amp; Restore" Height="600" Width="800" WindowStartupLocation="CenterOwner"
            Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}" ShowInTaskbar="False">
        <Grid Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
            </Grid.RowDefinitions>
            
            <TabControl x:Name="TabControl_BackupType">
                <TabItem Header="Startup Items" x:Name="Tab_Startup">
                    <Grid Margin="5">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="250"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                        <Label Grid.Row="0" Grid.Column="0" Content="Available Backups:" FontWeight="Bold"/>
                        <ListBox x:Name="ListBox_StartupBackups" Grid.Row="1" Grid.Column="0" Margin="0,0,5,0">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Name}" ToolTip="{Binding FullName}"/>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                        <DataGrid x:Name="DataGrid_StartupBackupContent" Grid.Row="1" Grid.Column="1" IsReadOnly="True" AutoGenerateColumns="False">
                             <DataGrid.Columns>
                                <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="150" />
                                <DataGridTextColumn Header="Command" Binding="{Binding Command}" Width="*" />
                                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="80" />
                            </DataGrid.Columns>
                        </DataGrid>
                    </Grid>
                </TabItem>
                <TabItem Header="Services" x:Name="Tab_Services">
                     <Grid Margin="5">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="250"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                        <Label Grid.Row="0" Grid.Column="0" Content="Available Backups:" FontWeight="Bold"/>
                        <ListBox x:Name="ListBox_ServicesBackups" Grid.Row="1" Grid.Column="0" Margin="0,0,5,0">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Name}" ToolTip="{Binding FullName}"/>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                        <DataGrid x:Name="DataGrid_ServicesBackupContent" Grid.Row="1" Grid.Column="1" IsReadOnly="True" AutoGenerateColumns="False">
                            <DataGrid.Columns>
                                <DataGridTextColumn Header="Display Name" Binding="{Binding DisplayName}" Width="*" />
                                <DataGridTextColumn Header="Service Name" Binding="{Binding Name}" Width="150" />
                                <DataGridTextColumn Header="Startup Type" Binding="{Binding StartType}" Width="100" />
                            </DataGrid.Columns>
                        </DataGrid>
                    </Grid>
                </TabItem>
                <TabItem Header="Scheduled Tasks" x:Name="Tab_Tasks">
                     <Grid Margin="5">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="250"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                        <Label Grid.Row="0" Grid.Column="0" Content="Available Backups:" FontWeight="Bold"/>
                        <ListBox x:Name="ListBox_TasksBackups" Grid.Row="1" Grid.Column="0" Margin="0,0,5,0">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Name}" ToolTip="{Binding FullName}"/>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                        <DataGrid x:Name="DataGrid_TasksBackupContent" Grid.Row="1" Grid.Column="1" IsReadOnly="True" AutoGenerateColumns="False">
                            <DataGrid.Columns>
                                <DataGridTextColumn Header="Task Name" Binding="{Binding TaskName}" Width="*" />
                                <DataGridTextColumn Header="Task Path" Binding="{Binding TaskPath}" Width="200" />
                                <DataGridTextColumn Header="State" Binding="{Binding State}" Width="80" />
                            </DataGrid.Columns>
                        </DataGrid>
                    </Grid>
                </TabItem>
            </TabControl>

            <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
                <Button x:Name="Button_Compare" Content="Compare..." Width="100" Margin="0,0,5,0" IsEnabled="False"/>
                <Button x:Name="Button_Restore" Content="Restore" Width="100" Margin="0,0,5,0" IsEnabled="False"/>
                <Button x:Name="Button_Done" Content="Done" Width="100" IsDefault="True"/>
            </StackPanel>
        </Grid>
    </Window>
"@
    $brReader = (New-Object System.Xml.XmlNodeReader $brDialogXaml)
    $brDialog = [Windows.Markup.XamlReader]::Load($brReader)
    $brDialog.Owner = $Window
    $brDialog.Icon = $Window.Icon

    # --- Control References ---
    # Manually find each control to avoid issues with GetVisualChildObjects helper
    $ListBox_StartupBackups = $brDialog.FindName("ListBox_StartupBackups")
    $DataGrid_StartupBackupContent = $brDialog.FindName("DataGrid_StartupBackupContent")
    $ListBox_ServicesBackups = $brDialog.FindName("ListBox_ServicesBackups")
    $DataGrid_ServicesBackupContent = $brDialog.FindName("DataGrid_ServicesBackupContent")
    $ListBox_TasksBackups = $brDialog.FindName("ListBox_TasksBackups")
    $DataGrid_TasksBackupContent = $brDialog.FindName("DataGrid_TasksBackupContent")
    
    $Button_Done = $brDialog.FindName("Button_Done")
    $TabControl_BackupType = $brDialog.FindName("TabControl_BackupType")

    # --- Functions ---
    $backupRoot = Join-Path $PSScriptRoot "..\Backups"
    
    Function Get-BackupsForType($backupType, $listBox) {
        $backupDir = Join-Path $backupRoot $backupType
        $backups = Get-ChildItem -Path $backupDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        $listBox.ItemsSource = $backups
        if ($backups.Count -gt 0) {
            $listBox.SelectedIndex = 0
        }
    }

    Function Show-BackupContent($listBox, $dataGrid, $backupType) {
        if ($listBox.SelectedItem -eq $null) { $dataGrid.ItemsSource = $null; return }
        $backupFile = Join-Path $backupRoot $backupType ($listBox.SelectedItem.Name)
        try {
            $dataGrid.ItemsSource = Get-Content -Path $backupFile | ConvertFrom-Json
        } catch {
            Show-Message "Error" "Could not read or parse backup file '$($listBox.SelectedItem.Name)'."
        }
    }

    # --- Event Handlers ---
    $Button_Done.Add_Click({ $brDialog.Close() })
    
    $TabControl_BackupType.Add_SelectionChanged({
        $selectedTab = $TabControl_BackupType.SelectedItem
        switch ($selectedTab.Name) {
            "Tab_Startup" { Get-BackupsForType "Startup Items" $ListBox_StartupBackups }
            "Tab_Services" { Get-BackupsForType "Services" $ListBox_ServicesBackups }
            "Tab_Tasks" { Get-BackupsForType "Scheduled Tasks" $ListBox_TasksBackups }
        }
    })

    $ListBox_StartupBackups.Add_SelectionChanged({ Show-BackupContent $ListBox_StartupBackups $DataGrid_StartupBackupContent "Startup Items" })
    $ListBox_ServicesBackups.Add_SelectionChanged({ Show-BackupContent $ListBox_ServicesBackups $DataGrid_ServicesBackupContent "Services" })
    $ListBox_TasksBackups.Add_SelectionChanged({ Show-BackupContent $ListBox_TasksBackups $DataGrid_TasksBackupContent "Scheduled Tasks" })

    # --- Initial Load ---
    Get-BackupsForType "Startup Items" $ListBox_StartupBackups

    $brDialog.ShowDialog() | Out-Null
}

Function Show-ChangelogWindow {
    [xml]$changelogDialogXaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Changelog" Height="500" Width="600" WindowStartupLocation="CenterOwner"
            Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}" ShowInTaskbar="False">
        <Grid Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
            </Grid.RowDefinitions>
            
            <DataGrid x:Name="DataGrid_Changelog" Grid.Row="0" AutoGenerateColumns="False" IsReadOnly="True"
                      AlternatingRowBackground="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}"
                      HeadersVisibility="Column" GridLinesVisibility="All" HorizontalGridLinesBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" VerticalGridLinesBrush="{DynamicResource {x:Static SystemColors.GrayTextBrushKey}}"
                      ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Columns>
                    <DataGridTextColumn Header="Version" Binding="{Binding version}" Width="100" />
                    <DataGridTextColumn Header="Date" Binding="{Binding date}" Width="100" />
                    <DataGridTemplateColumn Header="Changes" Width="*">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate>
                                <TextBlock Text="{Binding changes}" TextWrapping="Wrap" Margin="5"/>
                            </DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                </DataGrid.Columns>
            </DataGrid>

            <Button x:Name="Button_Okay" Grid.Row="1" Content="Okay" Width="100" Margin="0,10,0,0" Padding="5" HorizontalAlignment="Center" IsDefault="True"/>
        </Grid>
    </Window>
"@
    $changelogReader = (New-Object System.Xml.XmlNodeReader $changelogDialogXaml)
    $changelogDialog = [Windows.Markup.XamlReader]::Load($changelogReader)
    $changelogDialog.Owner = $Window
    $changelogDialog.Icon = $Window.Icon
    
    $DataGrid_Changelog = $changelogDialog.FindName("DataGrid_Changelog")
    $changelogDialog.FindName("Button_Okay").Add_Click({ $changelogDialog.Close() })
    
    try {
        $changelogFile = Join-Path $PSScriptRoot "changelog.json"
        if (Test-Path $changelogFile) {
            $changelogData = Get-Content -Path $changelogFile | ConvertFrom-Json
            # The JSON contains an array of objects, where each object has a 'changes' array.
            # We need to flatten this for the DataGrid.
            $flattenedLogs = $changelogData | ForEach-Object {
                $version = $_.version
                $date = $_.date
                [pscustomobject]@{
                    version = $version
                    date = $date
                    changes = $_.changes -join [Environment]::NewLine # Join array of changes into a multi-line string
                }
            }
            $DataGrid_Changelog.ItemsSource = $flattenedLogs
        } else {
            $DataGrid_Changelog.ItemsSource = @([pscustomobject]@{version="Error"; date=""; changes="changelog.json not found."})
        }
    } catch {
        Show-Message "Changelog Error" "Could not read or parse changelog.json: $_" "OK" "Error"
    }
    
    $changelogDialog.ShowDialog() | Out-Null
}

# Main window load event
$Window.Add_Loaded({
    try {
        # Set Version in Status Bar
        try {
            $changelogFile = Join-Path $PSScriptRoot "changelog.json"
            if (Test-Path $changelogFile) {
                $latestVersion = (Get-Content -Path $changelogFile | ConvertFrom-Json)[0].version
                $WPF_TextBlock_Version.Text = "Version: $latestVersion"
            }
        } catch {
            $WPF_TextBlock_Version.Text = "Version: Unknown"
        }

        # Force-load all data for a complete backup
        Get-StartupApps
        Get-ScheduledTasks
        Get-Services

        # Perform the automatic backup
        Invoke-AutoBackup

        # Load user preferences
        Load-Preferences

        # Update the views based on loaded preferences without reloading data
        Update-View -ViewSource $WPF_DataGrid_StartupApps.ItemsSource -SortProperty ($WPF_DataGrid_StartupApps.ItemsSource.SortDescriptions[0].PropertyName) -GroupProperty ($WPF_DataGrid_StartupApps.ItemsSource.GroupDescriptions[0].PropertyName)
        Update-View -ViewSource $WPF_DataGrid_ScheduledTasks.ItemsSource -SortProperty ($WPF_DataGrid_ScheduledTasks.ItemsSource.SortDescriptions[0].PropertyName) -GroupProperty ($WPF_DataGrid_ScheduledTasks.ItemsSource.GroupDescriptions[0].PropertyName)
        Update-View -ViewSource $WPF_DataGrid_Services.ItemsSource -SortProperty ($WPF_DataGrid_Services.ItemsSource.SortDescriptions[0].PropertyName) -GroupProperty ($WPF_DataGrid_Services.ItemsSource.GroupDescriptions[0].PropertyName)

    } catch {
        Show-Message "Fatal Error on Load" "An unexpected error occurred while loading the application:`n`n$($_.Exception.Message)" "OK" "Error"
        $Window.Close()
    }
})

# Load data when a tab is changed (now only re-loads if cleared or forced)
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
Set-WindowIcon
$Window.ShowDialog() | Out-Null

# Stop logging
Stop-Transcript

#endregion
