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

## Winget Repair Tool

The `Winget Repair Tool` is a targeted PowerShell script designed to fix common issues with the Windows Package Manager (`winget`). If you are encountering errors like "winget is not recognized" or profile loading errors related to `winget.exe`, this script performs a clean re-installation of the App Installer package to resolve them.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a repair utility for the Windows Package Manager.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script requires administrator access to uninstall and reinstall AppX packages for all users.
*   **Internet Connection:** Required to download the latest installer from the official GitHub repository.

## 💽 Installation & Execution
1.  **Download:** Download the `Winget-Repair-Tool.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell". Ensure you run it from an elevated context.
    ```powershell
    .\Winget-Repair-Tool.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script runs automatically once launched as an administrator. It performs the following steps:

1.  **Uninstall:** It attempts to remove the existing "Microsoft.DesktopAppInstaller" package to clear out any corrupted files.
2.  **Download:** It downloads the latest stable `winget` release bundle (`.msixbundle`) directly from the official Microsoft GitHub repository.
3.  **Install:** It installs the downloaded package using `Add-AppxPackage`.
4.  **Path Verification:** It checks your User environment variables to ensure the `Microsoft\WindowsApps` directory is in your `PATH`. If missing, it adds it, ensuring you can run `winget` from any command prompt.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Clean Reinstall:** Removes potentially broken installations before applying the new one.
*   **Official Source:** Downloads directly from the official `microsoft/winget-cli` GitHub releases.
*   **Environment Fix:** Automatically corrects `PATH` variable issues that prevent `winget` from being recognized.
*   **Automated Cleanup:** Deletes the temporary installer file after the operation is complete.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **Core Cmdlets:** `Get-AppxPackage`, `Remove-AppxPackage`, `Add-AppxPackage` for managing the application.
*   **Environment:** .NET `[Environment]` class for modifying user variables.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Administrator Required:** This script must be run as an administrator to manage system packages.
*   **System Change:** It modifies the installed AppX packages and User Environment variables.
*   **Restart Required:** After running, you typically need to close and reopen your terminal windows (PowerShell, CMD) for the `PATH` changes to take effect.

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
