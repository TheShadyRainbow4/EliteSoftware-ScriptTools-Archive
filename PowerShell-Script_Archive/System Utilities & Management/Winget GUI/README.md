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

## PowerShell Winget User Interface

The `PowerShell Winget User Interface` is a versatile script that provides a modern, user-friendly frontend for the Windows Package Manager (`winget`). It allows users to choose between a feature-rich Graphical User Interface (GUI) or a classic, menu-driven command-line interface (Shell Mode).

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool simplifies software management on Windows by wrapping the powerful `winget` command-line tool.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 10 Version 1709 or later).
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the GUI mode.
*   **Windows Package Manager (`winget`):** Must be installed. It is usually included with the "App Installer" from the Microsoft Store. The script checks for this dependency on launch.

## 💽 Installation & Execution
1.  **Download:** Download the `WinGet_GUI_07-2025.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\WinGet_GUI_07-2025.ps1
    ```
4.  **Select Mode:** Upon launch, you will be prompted to choose between **GUI Mode [1]** or **Shell Mode [2]**.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features

### GUI Mode
The Graphical User Interface offers a familiar, application-like experience:
*   **Search & Install:** Easily search the `winget` repository and install applications.
*   **Visual Management:** View installed packages with their icons and installation dates.
*   **Batch Operations:** Select multiple packages to install, upgrade, or uninstall at once.
*   **Updates:** Quickly check for and apply updates to all your installed software.
*   **Details:** View detailed manifest information for any package.
*   **Launch:** Double-click an installed application in the list to launch it (if the path can be determined).

### Shell Mode
The Shell Mode provides a robust text-based menu for quick operations:
*   **Menu-Driven:** Navigate options using simple number keys.
*   **Core Functions:** Search, list, upgrade, and uninstall packages directly from the console.
*   **Formatted Output:** Displays results in clean, readable tables.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend:** Windows Package Manager (`winget.exe`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Wrapper:** This script acts as a frontend wrapper. All actual package management operations are performed by the official `winget` tool.
*   **Configuration:** The GUI mode saves settings (like custom icons and window title) to `%APPDATA%\PowerShellWingetUI\config.json`.

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
