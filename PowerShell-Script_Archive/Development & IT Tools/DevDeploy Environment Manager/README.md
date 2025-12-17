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

## Dev-Deploy Environment Manager

**Note:** This file (`Untitled (2).PS1`) is the **Dev-Deploy Environment Manager** (v0.5).

`Dev-Deploy` is a comprehensive utility for discovering, installing, and managing Python and .NET development environments on Windows. It provides a clean, tabbed graphical user interface (GUI) to simplify the setup and maintenance of your coding tools.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool helps you manage your programming runtimes and SDKs.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms/WPF GUI.
*   **Winget:** The Windows Package Manager is used for searching and installing new versions of Python and .NET.

## 💽 Installation & Execution
1.  **Download:** Download the script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ."\Untitled (2).PS1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features

### Python Environment Management
*   **Discovery:** Automatically finds installed Python versions using multiple methods:
    *   Querying the Python Launcher (`py.exe`).
    *   Scanning the system `PATH`.
    *   Checking common installation directories.
    *   Cross-referencing with `winget` to enable uninstallation.
*   **Installation:** Search for and install new Python versions directly from `winget`.
*   **Package Management:** Manage `pip` packages for any selected Python installation:
    *   List installed packages.
    *   Install new packages by name.
    *   Uninstall existing packages.
*   **Terminal Launch:** Quickly open a command prompt environment configured for a specific Python version.

### .NET Environment Management
*   **Discovery:** Lists all installed .NET SDKs and Runtimes by parsing the output of the `dotnet` CLI.
*   **Installation:** Search for and install .NET SDKs and Runtimes via `winget`.
*   **Uninstallation:** Remove specific .NET components.

### General Features
*   **Activity Log:** A dedicated tab tracks all actions, command outputs, and errors for troubleshooting.
*   **Background Jobs:** Long-running tasks (like installations) run in the background to keep the UI responsive.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** WPF (Windows Presentation Foundation) via XAML.
*   **Backend Tools:** `winget`, `dotnet`, `py.exe`, `pip`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Privileges:** Installing or uninstalling software typically requires Administrator privileges. While the script doesn't force a UAC prompt on launch, operations may fail or prompt for elevation if you are not running as Admin.
*   **Winget Integration:** The script acts as a wrapper around `winget`. Ensure `winget` is correctly configured on your system.

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