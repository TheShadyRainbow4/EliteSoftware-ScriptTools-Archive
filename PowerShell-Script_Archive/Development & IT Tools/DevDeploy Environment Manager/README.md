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

## Dev-Deploy Environment Manager v0.4

Dev-Deploy Environment Manager is a comprehensive PowerShell GUI utility, crafted with WPF/XAML, designed to streamline the setup and management of Python and .NET development environments. It provides an intuitive interface for discovering installed software, searching for available versions via `winget`, and facilitating installations (including `pip` package management for Python). Version 0.4 introduces robust UI theming, efficient background operations, and reliable parsing of `winget` results.

Built by: Zachary Whiteman & Google Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script designed to simplify your development environment setup.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** (PowerShell Core is supported).
*   **Required .NET Assemblies:** `PresentationFramework`, `PresentationCore`, `WindowsBase`, `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **`winget`:** The Windows Package Manager (`winget`) must be installed and accessible in your system's PATH.
*   **Python:** While the tool helps manage Python, some `pip` functionalities assume Python is generally available for selected installations.

## 💽 Installation & Execution
1.  **Download:** Download the `DevDeploy Envirnment Manager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\DevDeploy Envirnment Manager.PS1
    ```
    The PowerShell console window will automatically minimize upon launch for a cleaner GUI experience.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application features a tabbed interface for managing different development environments:

*   **Python Environment Tab:**
    *   **"Refresh All"**: Scans for installed Python versions and lists available ones via `winget`.
    *   **"Installed Python Versions"**: Displays detected Python installations.
    *   **"Available via Winget"**: Shows Python versions available for installation. Select an item and click "Install Selected Python Version".
    *   **"Manage Packages (pip) for Selected Installation"**: After selecting an installed Python version, enter a package name and click "Install Package" to install it via `pip`.
*   **.NET Environment Tab:**
    *   **"Refresh All"**: Scans for installed .NET SDKs/Runtimes and lists available ones via `winget`.
    *   **"Installed .NET SDKs & Runtimes"**: Displays detected .NET installations.
    *   **"Available via Winget"**: Shows .NET versions available for installation. Select an item and click "Install Selected .NET Version".
*   **Activity Log Tab:** Provides a real-time log of all actions performed by the application, including `winget` searches and installation outputs.

All `winget` searches and installations are performed in the background, ensuring the GUI remains responsive.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-based Environment Management:** Intuitive WPF/XAML graphical user interface for easy interaction.
*   **Python Environment Control:** Discover installed Python versions, search for new ones via `winget`, and install Python packages using `pip`.
*   **.NET Environment Control:** Discover installed .NET SDKs/Runtimes, and install new versions via `winget`.
*   **Asynchronous Operations:** `winget` searches and installations run as background PowerShell jobs, preventing UI freezes.
*   **Robust `winget` Parsing:** Utilizes regular expressions to reliably extract and display information from `winget` search results.
*   **Modern UI Theming:** Implements P/Invoke methods to ensure the GUI uses native Windows visual styles for a polished look.
*   **Integrated Activity Log:** Provides real-time feedback and detailed logs of all operations directly within the application.
*   **Console Minimization:** Automatically minimizes the PowerShell console window on startup, providing a cleaner, application-like experience.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The application is a self-contained PowerShell script, leveraging:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** WPF (Windows Presentation Foundation) using XAML for rich graphical user interfaces.
*   **Package Management:** `winget` (Windows Package Manager) for system-level software discovery and installation.
*   **Python Package Management:** `pip` for installing Python libraries.
*   **Operating System Integration:** P/Invoke (Platform Invoke) for direct calls to Windows API functions for advanced UI control and theming.
*   **Concurrency:** PowerShell Jobs (`Start-Job`) for non-blocking background operations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
Dev-Deploy Environment Manager operates by orchestrating local system commands and services.

*   **Local Execution:** All operations are performed locally on your machine. No external network services are directly accessed by the script itself beyond what `winget` or `pip` might do to fetch packages.
*   **Dependency on `winget` and Python:** Relies on the proper functioning and security of `winget` for package installations and Python for environment management.
*   **Administrator Privileges (for winget/pip):** While the script attempts to minimize the console, `winget` and `pip` commands often require elevated privileges for system-wide installations or modifications.
*   **P/Invoke for UI:** Uses P/Invoke for direct Windows API calls for UI rendering, which is a standard and secure practice for custom UI in PowerShell.
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
