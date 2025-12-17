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

## Aero Resurrector (Legacy Resolution Control Panel)

`Aero Resurrector` is a specialized PowerShell utility designed to restore the classic, full-featured "Screen Resolution" control panel found in Windows 7 and 8.1, replacing the modern "Settings" app page in newer versions of Windows. This tool automates the complex process of harvesting the necessary legacy files, backing up your current system state, and injecting the old components and registry settings to bring back the classic interface.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is a system modification tool that replaces core operating system files. Proceed with caution.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 7 (`pwsh.exe`):** This script is written for PowerShell Core and requires `pwsh.exe` to be installed and in your PATH.
*   **NSudo:** The `NSudo.exe` utility must be present in the same directory or accessible. The script uses this to gain "TrustedInstaller" privileges, which are required to modify protected system files in `System32`.
*   **Administrator Privileges:** You must be an administrator to launch the tool.

## 💽 Installation & Execution
1.  **Download:** Download the `Restore-Legacy-Resolution-Control-Panel.PS1` script file.
2.  **Dependencies:** Ensure `NSudo.exe` is in the same folder.
3.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
4.  **Run:** Execute the script. It will automatically detect if it needs higher privileges and use `NSudo` to relaunch itself as TrustedInstaller.
    ```powershell
    .\Restore-Legacy-Resolution-Control-Panel.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The tool operates in three distinct phases:

### 1. Harvest Files (Donor PC)
Use this section to gather the necessary legacy files (`desk.cpl`, `display.dll`, etc.) and registry keys.
*   **Harvest Files:** Creates a "Source" folder in the script's directory containing copies of the required system files and registry exports from the *current* machine. This is typically done on an older version of Windows or a machine that still has the legacy components intact.

### 2. Installation (Target PC)
Use this section on the machine where you want to restore the classic panel.
*   **Backup Target System:** **CRITICAL STEP.** Click this button first to create a full backup of your current system files and registry keys. This allows you to revert changes if something goes wrong.
*   **Install Files & Import Registry:** This button stops Explorer, overwrites the system files with the harvested versions, imports the registry settings to redirect the Control Panel, and restarts Explorer.

### 3. Emergency Restore
*   **Restore:** If you encounter issues, select a timestamped backup from the dropdown menu and click "Restore." The tool will revert your system files and registry settings to their previous state.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automated Harvesting:** Identifies and copies the exact files needed for the restoration (`desk.cpl`, `display.dll`, `deskmon.dll`, `themeui.dll` and their MUI files).
*   **TrustedInstaller Access:** Built-in integration with `NSudo` ensures the script has the permissions needed to overwrite protected system files.
*   **Safety Backup:** Forces a backup of existing files before applying any changes.
*   **Registry Redirection:** Handles the complex CLSID and NameSpace registry modifications required to make the classic panel appear in the Control Panel and context menus.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 7 (`pwsh`).
*   **Elevation:** `NSudo` (External Dependency) for TrustedInstaller access.
*   **GUI:** .NET Windows Forms (WinForms).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **System File Replacement:** This script replaces core Windows files. While it includes a backup mechanism, there is inherent risk in modifying `System32` files.
*   **TrustedInstaller:** The script runs with the highest possible privileges on the local machine. Ensure you trust the source of the harvested files.

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
