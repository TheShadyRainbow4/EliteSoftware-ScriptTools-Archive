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

## Local Group Policy Manager

`Local Group Policy Manager` is a PowerShell script that provides a graphical user interface (GUI) for backing up, restoring, and managing the Local Group Policy (LGP) on a Windows computer. It simplifies the process of saving and restoring policy settings, which is useful for system administrators and power users.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides essential tools for managing your Local Group Policy.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Pro, Enterprise, or Education editions that include the Group Policy Editor).
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script must be run as an administrator to access and modify the Group Policy files.

## 💽 Installation & Execution
1.  **Download:** Download the `LocalGroupPolicyBackup-Inator.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell" or execute it from a PowerShell console that is running as an administrator.
    ```powershell
    .\LocalGroupPolicyBackup-Inator.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a straightforward interface for managing your Local Group Policy.

*   **Backup/Restore Path:**
    *   Specify the root directory where your Local Group Policy backups will be stored.
*   **Actions:**
    *   **Backup Local GPO:** Creates a timestamped backup of your current Local Group Policy settings in the specified directory.
    *   **Restore Local GPO:** Allows you to browse for and select a previously created backup folder to restore your policy settings.
    *   **Restore Local GPO Defaults:** Deletes the current policy settings, effectively resetting your Local Group Policy to its default state.
    *   **Open Local Group Policy Editor:** Launches the `gpedit.msc` console.
    *   **View Current Policy Files:** Opens the system folders containing the Local Group Policy files in Windows Explorer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI for Policy Management:** Simplifies the process of backing up and restoring Local Group Policy settings.
*   **Timestamped Backups:** Creates uniquely named backup folders with a timestamp for easy identification.
*   **One-Click Restore:** Easily restore from a previously created backup.
*   **Reset to Defaults:** Provides a safe way to reset all local policies to their original state.
*   **Integrated Tools:** Includes shortcuts to launch the Group Policy Editor and view the underlying policy files.
*   **Automatic Policy Refresh:** Automatically runs `gpupdate /force` after a restore or reset to ensure changes are applied immediately.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Interacts directly with the file system by copying, deleting, and restoring the policy files located in `C:\Windows\System32\GroupPolicy` and `C:\Windows\System32\GroupPolicyUsers`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Local Group Policy Manager` directly manages the files that constitute the Local Group Policy.

*   **Administrator Privileges:** This script requires administrator access to read and write to the system's Group Policy folders.
*   **File-Based Operation:** The backup and restore process is based on copying and replacing files and folders. This is a standard method for managing Local Group Policy.
*   **`gpedit.msc` Requirement:** The "Open Local Group Policy Editor" button will only work on editions of Windows that include `gpedit.msc` (e.g., Pro, Enterprise).

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
