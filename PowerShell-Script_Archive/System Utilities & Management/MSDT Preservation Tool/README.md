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

## MSDT Preservation Tool

The `MSDT Preservation Tool` is a PowerShell script with a graphical user interface (GUI) designed to manage the behavior of the Microsoft Support Diagnostic Tool (MSDT). As Microsoft transitions away from legacy troubleshooters to its "Get Help" application, this tool allows users to preserve and continue using the classic MSDT engine. It also provides functionality to back up the necessary troubleshooter files.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script helps you retain access to legacy Windows troubleshooters.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 10 or 11).
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script requires administrator privileges to modify the registry and will attempt to self-elevate.

## 💽 Installation & Execution
1.  **Download:** Download the `MSDT-Preservation-Tool.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it. The script will automatically request administrator elevation.
    ```powershell
    .\MSDT-Preservation-Tool.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a simple interface with a status log that gives feedback on all operations.

*   **Actions:**
    *   **Enable Legacy Troubleshooters:** Modifies the Windows Registry to prevent `msdt.exe` from redirecting to the "Get Help" app. This allows you to use the classic troubleshooters.
    *   **Use 'Get Help' App (Default):** Reverts the registry changes, restoring the system's default behavior of using the "Get Help" app.
    *   **Backup All Troubleshooters:** Creates a comprehensive, timestamped backup of `msdt.exe`, related diagnostic DLLs, and the entire `C:\Windows\diagnostics` folder onto your desktop.
    *   **Copy Troubleshooter Path:** A convenience button that copies the path `C:\Windows\diagnostics` to your clipboard.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI for Easy Management:** Provides a user-friendly interface to manage complex registry settings and file operations.
*   **Automatic Administrator Elevation:** The script checks for and requests administrator privileges automatically.
*   **One-Click Legacy Mode:** Enables or disables the classic MSDT troubleshooters with a single button click.
*   **Comprehensive Backup:** Creates a full, structured backup of all essential troubleshooter files and DLLs.
*   **Real-time Status Logging:** A log panel within the GUI provides clear feedback on the success or failure of each operation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **System Interaction:** Uses PowerShell cmdlets to modify the Windows Registry and perform file system operations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`MSDT Preservation Tool` interacts with core system settings and files.

*   **Administrator Privileges:** This script requires administrator access to function. It is designed to self-elevate.
*   **Registry Modification:** The script modifies keys in `HKEY_LOCAL_MACHINE` to control the behavior of `msdt.exe`. It backs up the original registry key before making changes.
*   **File System Backup:** The backup function copies system files to a folder on your desktop. It does not modify or delete the original files.

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
