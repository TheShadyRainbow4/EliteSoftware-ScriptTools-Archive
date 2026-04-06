<a id="readme-top"></a>

<!-- EliteSoftware Co. LOGO -->

<br />
<div align="center">
<a href="Logo">
<img src="https://i.postimg.cc/85MDTcrJ/Elite-Software-LOGO-Mocup2.png" alt="Logo" width="256" height="256">
</a>
</div>

<!-- ABOUT THE PROJECT -->

# 💾 About The Project <div align="center">

WingetSearch-Tool is a PowerShell script that provides a user-friendly interface for the Windows Package Manager (winget). It offers both a graphical user interface (GUI) built with Windows Forms and a traditional command-line shell mode.

This tool simplifies package management on Windows by allowing users to easily search, install, upgrade, and uninstall applications. The GUI provides a rich experience with features like sorting, grouping, and context menus, making it accessible for users of all levels.

Built by: Zachary Whiteman & Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script and does not require a complex installation process.

## 🕰️ Prerequisites
To run this script, you need:

*   Windows Operating System (Windows 10 or later).
*   PowerShell 5.1 or newer.
*   Windows Package Manager (`winget`) installed. It is included by default in modern versions of Windows 10 and 11.

## 💽 Installation & Execution
1.  **Download**: Download the `wgsearch.PS1` script file.
2.  **Unblock**: If you downloaded the script from the internet, right-click the file, go to **Properties**, and click **Unblock**.
3.  **Run**: Execute the script from a PowerShell console:
    ```powershell
    .\wgsearch.PS1
    ```
    The script will prompt you to choose between GUI mode and Shell mode.

The application's configuration files are stored in:
`C:\Users\<YourUser>\AppData\Roaming\PowerShellWingetUI`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application can be used in two modes:

### GUI Mode
The GUI provides a full-featured visual interface for `winget`.
*   **Search**: Enter a package name and click "Search".
*   **Manage Packages**: Select a package from the list to install, upgrade, or uninstall it using the buttons at the bottom.
*   **List Packages**: Use the buttons on the right to list all installed packages or check for available upgrades.
*   **Sorting & Grouping**: Right-click the results list to access sorting and grouping options to organize the packages.

### Shell Mode
For users who prefer the command line, the shell mode offers a menu-driven interface to perform common `winget` operations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Dual Mode**: Choose between a modern GUI and a classic shell interface.
*   **Full Package Management**: Search, install, upgrade, and uninstall packages.
*   **Advanced List Controls**: In GUI mode, sort results by any column and group them by name, ID, or version.
*   **Configuration Persistence**: The application saves its window title and custom icon settings.
*   **Package List Export/Import**: Export a list of your installed packages to a file and import it later to batch-install them.
*   **Advanced Winget Operations**: Access advanced features like viewing package manifests and resetting `winget` sources.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language**: PowerShell (5.1+)
*   **GUI Framework**: .NET Windows Forms (WinForms)
*   **Core Package Manager**: `winget.exe`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

## 🪪 License
Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## ☎️ Contact
Zach Whiteman - elitesoftwarecolimited@gmail.com

HuggingFace - https://huggingface.co/EliteSoftware

HuggingFace (Personal) - https://huggingface.co/TheShadyRainbow

LinkTree - https://linktr.ee/zachrainbow

Patreon - https://www.patreon.com/c/EliteSoftwareCo

<p align="right">(<a href="#readme-top">back to top</a>)</p>
