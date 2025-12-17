<a id="readme-top"></a>

<!-- EliteSoftware Co. LOGO -->

<br />
<div align="center">
<!-- <a href="Logo"> -->
<!-- <img src="https://i.postimg.cc/85MDTcrJ/Elite-Software-LOGO-Mocup2.png" alt="Logo" width="256" height="256"> -->
<!-- </a> -->
</div>

<!-- ABOUT THE PROJECT -->

# 💾 About The Project <div align="center">
## Screenshot may be slightly outdated. Sorry in advance! :)  
<br />
<div align="center">
<!-- <a href="Screenshot"> -->
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720"> -->
<!-- </a> -->
</div>

## EliteSoftware Manager v3.7.2

EliteSoftware Manager is a powerful and versatile PowerShell interface for the Windows Package Manager (`winget`). It offers users the flexibility of both a classic text-based shell mode and a modern, feature-rich graphical user interface (GUI) to streamline software discovery, installation, upgrade, and uninstallation processes. Version 3.7.2 focuses on enhanced stability, UI responsiveness, and robust handling of `winget` operations.

Built by: Zachary Whiteman & Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script designed to manage your system's software packages via `winget`.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** (PowerShell Core is supported).
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing`, `Microsoft.VisualBasic` (included with modern Windows installations).
*   **`winget`:** The Windows Package Manager (`winget`) must be installed and accessible in your system's PATH. You can install it from the Microsoft Store ("App Installer").

## 💽 Installation & Execution
1.  **Download:** Download the `EliteSoftware_Manager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\EliteSoftware_Manager.PS1
    ```
    Upon launch, you will be prompted to choose between GUI mode (1) or Shell mode (2).

The application's configuration files (e.g., `config.json` for custom title/icon) are stored in:
`%APPDATA%\PowerShellWingetUI`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
### GUI Mode
The GUI mode provides a visual interface for all `winget` operations:

*   **Search for Package:** Enter a search term in the text box and click "Search" to find packages.
*   **List All Installed:** Click "List All Installed" to display all packages currently on your system.
*   **Check for Upgrades:** Click "Check for Upgrades" to see packages with available updates.
*   **Upgrade All:** Click "Upgrade All" to update all installed packages with available upgrades.
*   **Install/Upgrade/Uninstall/Details:** Select a package from the list and use the respective buttons to perform actions.
*   **Context Menu:** Right-click on the list view to access sorting and grouping options.
*   **Double-Click to Launch:** For installed applications, double-click an item in the list to attempt to launch it.
*   **File Menu (`&File`):**
    *   **Rename Utility:** Change the application's display title.
    *   **Set Custom Icon:** Assign a custom `.ico` file as the application icon.
    *   **Export Installed Packages:** Save a list of package IDs to a text file.
    *   **Import & Install from List:** Batch install packages from a previously exported list.
*   **Advanced Menu (`&Advanced`):**
    *   **View Package Manifest:** View the detailed manifest for a selected package.
    *   **Reset Winget Sources:** Reset `winget` sources to their default configuration.

### Shell Mode
The shell mode offers a text-based, menu-driven interface for quick `winget` interactions. Navigate through options by entering the corresponding number.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Dual-Mode Interface:** Seamlessly switch between a full-featured graphical UI (WinForms) and a classic text-based shell mode for `winget` management.
*   **Comprehensive `winget` Operations:** Perform package search, list installed software, check for upgrades, install, upgrade (individual or all), and uninstall packages.
*   **Advanced ListView Functionality:** The GUI features sorting by various columns (Name, ID, Version, Available, Date Installed) and grouping capabilities, enhancing data organization.
*   **Application Launching:** Double-click installed packages in the GUI to directly launch the associated application.
*   **Flexible Import/Export:** Export installed package lists to a text file and perform batch installations from such lists.
*   **Customizable Interface:** Personalize the application by renaming the utility and setting a custom icon, with these preferences persisting across sessions.
*   **Detailed Package Information:** View full `winget` manifests for selected packages directly within the GUI.
*   **Responsive UI:** `winget` commands are executed efficiently to maintain UI responsiveness, especially during searches and listings.
*   **Robust Error Handling:** Includes logging within the GUI and informative message boxes for operational feedback.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The entire application is a self-contained PowerShell script, utilizing:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Package Management:** Integrates directly with `winget` (Windows Package Manager).
*   **UI Enhancements:**
    *   `Microsoft.VisualBasic.Interaction.InputBox` for user input dialogs.
    *   C# P/Invoke for advanced console window management (minimization).
    *   Custom PowerShell class (`ListViewItemComparer`) for robust ListView sorting and grouping logic.
*   **Data Persistence:** JSON for saving and loading application configuration (`config.json`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
EliteSoftware Manager operates locally to interface with your system's package manager.

*   **Local Execution:** All core operations are performed directly on your local Windows system.
*   **`winget` Dependency:** The application's functionality is entirely reliant on the presence and correct configuration of the `winget` command-line tool.
*   **Direct Process Invocation:** `winget` commands are executed using `Start-Process`, often in new, visible terminal windows, which provides transparency regarding the commands being run and their output.
*   **Registry Interaction:** The script accesses standard Windows Registry paths (`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall`, etc.) to gather information about installed applications, such as icons and install dates, for display in the GUI.
*   **Configuration Storage:** Application settings, including custom names and icon paths, are stored in a `config.json` file within the user's `%APPDATA%\PowerShellWingetUI` directory.
*   **No Telemetry:** The application does not collect or transmit any user data or telemetry.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🪪 License
Distributed under the MIT License. See LICENSE.txt for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ☎️ Contact
Zach Whiteman - elitesoftwarecolimited@gmail.com

HuggingFace - https://huggingface.co/EliteSoftware

HuggingFace (Personal) - https://huggingface.co/TheShadyRainbow

LinkTree - https://linktr.ee/zachrainbow

Patreon - https://www.patreon.com/c/EliteSoftwareCo

<p align="right">(<a href="#readme-top">back to top</a>)</p>
