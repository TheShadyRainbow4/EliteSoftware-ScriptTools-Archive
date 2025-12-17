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

## Registry Backup-Inator

`Registry Backup-Inator` is a PowerShell script with a graphical user interface (GUI) for backing up and restoring the Windows Registry. It allows users to selectively back up `HKEY_CURRENT_USER` and `HKEY_LOCAL_MACHINE` hives to `.reg` files and restore them when needed.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script simplifies the process of backing up and restoring the Windows Registry.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's capabilities for GUI development.
*   **Administrator Privileges:** The script requires administrator privileges to back up and restore the registry.

## 💽 Installation & Execution
1.  **Download:** Download the `RegistryBackup_Inator.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console. It is recommended to run PowerShell as an administrator.
    ```powershell
    .\RegistryBackup_Inator.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a straightforward interface for registry operations.

*   **Backup/Restore Path:**
    *   Specify the directory where registry backups will be saved or from where they will be restored. The default is `Documents\Registry_Backups`.
*   **Backup Options:**
    *   Select the registry hives (`HKEY_CURRENT_USER` and/or `HKEY_LOCAL_MACHINE`) to include in the backup.
*   **Actions:**
    *   **Backup Registry Hives:** Creates a backup of the selected hives in the specified directory.
    *   **Restore Registry (.reg):** Restores the registry from a selected `.reg` file.
    *   **Restore System Defaults (Advisory):** Provides advice on using Windows System Restore for system-wide rollbacks.
    *   **Open Registry Editor:** Launches the Windows Registry Editor (`regedit.exe`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI for Registry Management:** Provides a user-friendly interface for backing up and restoring the registry.
*   **Selective Hive Backup:** Allows users to choose which registry hives to back up.
*   **Custom Backup Path:** Users can specify a custom directory for saving backup files.
*   **Direct Registry Editor Access:** Includes a button to quickly open `regedit.exe`.
*   **Administrator Check:** The script will show an error if not run with administrator privileges.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, integrating with several key technologies:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Registry Operations:** `reg.exe` for exporting and importing registry hives.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Registry Backup-Inator` operates by interacting with the Windows Registry.

*   **Administrator Privileges:** The script requires administrator privileges to function correctly.
*   **Registry Modification:** Modifying the registry can cause system instability. Use this tool with caution and only restore from trusted backup files.
*   **System Restore Advisory:** The "Restore System Defaults" button does not perform any action but advises the user to use the Windows System Restore feature for a safe rollback.

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
