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

## Application Shortcut Creator v2.1

The `Application Shortcut Creator` is a sophisticated PowerShell script featuring a WPF (Windows Presentation Foundation) graphical user interface. It is designed to simplify the task of finding installed applications on your Windows system and creating convenient desktop shortcuts (.lnk files) for them. This tool goes beyond standard shortcuts by enabling discovery of applications registered in the Windows Registry, portable applications across all connected drives, and executables within any user-specified folder, ensuring you can easily create shortcuts for all your software.

Built by: Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a powerful GUI for managing application shortcuts.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's integration with WPF for its GUI.
*   **Required .NET Assemblies:** `PresentationFramework`, `PresentationCore`, `WindowsBase`, `System.Windows.Forms` (included with modern Windows installations).

## 💽 Installation & Execution
1.  **Download:** Download the `Create Installed Application Shortcuts.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Create Installed Application Shortcuts.PS1
    ```
    While creating shortcuts on the desktop typically does not require administrator privileges, performing a comprehensive scan of system-protected directories might. If a scan operation fails, try running PowerShell as Administrator.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application features a tabbed interface for discovering applications and a section for creating shortcuts:

### 1. Discover Applications

*   **"User Installed Apps" Tab:**
    *   Click **"Scan Registry"** to list applications officially registered in the Windows Registry.
*   **"All Drive Apps" Tab:**
    *   Click **"Deep Scan All Drives"** to scan "Program Files" and "Program Files (x86)" folders on all connected drives for executables. This may take some time.
*   **"System Apps" Tab:**
    *   This tab automatically populates with a list of common built-in Windows system applications (e.g., Notepad, Calculator).
*   **"Manual Scan" Tab:**
    *   Click **"Choose Folder to Scan..."** to select any specific folder or drive. The grid will then populate with all `.exe` files found within that location (and its subfolders).

### 2. Create Shortcut

1.  **Select an Application:** From any of the tabs (User Installed Apps, All Drive Apps, System Apps, Manual Scan), select the application for which you want to create a shortcut by clicking its row in the data grid. The executable path will appear in the "Shortcut Path" text box.
2.  **Choose Destination Folder:**
    *   Click the **"Browse..."** button next to the "Shortcut Path" text box to select a folder where the shortcut (`.lnk` file) will be created (e.g., your Desktop).
3.  **Create Shortcut:**
    *   Click the **"Create Shortcut"** button. The script will create a `.lnk` file for the selected application in your chosen destination folder. A success message will appear.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Intuitive WPF GUI:** A modern and responsive graphical user interface built with Windows Presentation Foundation.
*   **Comprehensive Application Discovery:** Combines multiple scanning methods to find a wide range of applications:
    *   **Registry Scan:** Identifies traditionally installed software.
    *   **Deep Drive Scan:** Locates portable or non-registered applications across all hard drives.
    *   **Manual Folder Scan:** Allows users to specify any directory for executable file discovery.
    *   **System Apps List:** Provides quick access to common Windows utilities.
*   **One-Click Shortcut Creation:** Generate desktop shortcuts (.lnk files) with ease for any discovered application.
*   **Real-time Status Feedback:** Displays clear status messages and a progress indicator during scanning operations.
*   **Robust Executable Path Resolution:** Intelligent logic to accurately determine the executable path for various types of installed applications.
*   **Customizable UI Styles:** Uses WPF styling for a polished and consistent user experience.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging its powerful .NET integrations:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** WPF (Windows Presentation Foundation) using XAML for the rich graphical user interface.
*   **System Interaction:**
    *   Windows Registry Access: For querying installed application information.
    *   File System Operations: `Get-ChildItem` for scanning directories.
    *   COM Objects: `WScript.Shell` for programmatic creation of `.lnk` shortcut files.
*   **Data Binding:** WPF's data binding capabilities are utilized to display application lists in the `DataGrid` controls.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `Application Shortcut Creator` interacts with your system's core components to discover and manage applications.

*   **Local System Interaction:** All operations are performed strictly on your local machine, interacting with the Windows Registry and file system.
*   **File System Scanning:** The "Deep Scan All Drives" and "Manual Scan" features involve extensive file system traversal, which can be time-consuming depending on your system's storage size.
*   **COM Object Usage:** The script utilizes the `WScript.Shell` COM object to create shortcuts. This is a standard and secure method for shortcut creation within Windows scripting environments.
*   **Privilege Considerations:** While creating shortcuts on the desktop typically does not require elevated privileges, full scans of system-protected folders or certain registry keys might benefit from running the script as Administrator.
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
