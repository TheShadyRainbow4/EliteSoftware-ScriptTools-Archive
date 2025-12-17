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

## Adobe Genuine Service Remover

The `Adobe Genuine Service Remover` is a specialized PowerShell utility designed to forcefully stop and remove the Adobe Genuine Service (AGS) and its related background processes. This tool provides a simple graphical user interface (GUI) to automate the cleanup of these persistent services, which can sometimes cause performance issues or unwanted notifications.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool is designed to forcefully remove specific system services. Use with understanding of its function.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script requires full administrator access to stop processes and delete system services/files. It will automatically attempt to self-elevate.

## 💽 Installation & Execution
1.  **Download:** Download the `Adobe Genuine Service Remover - Utility Script.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    ".\Adobe Genuine Service Remover - Utility Script.ps1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a "Kill & Nuke" button to initiate the cleaning process.

1.  **Launch:** Open the tool. The status label will indicate "Ready for process termination...".
2.  **Execute:** Click the **Kill & Nuke** button.
3.  **Process:** The tool will perform the following actions:
    *   **Hunt Processes:** Actively searches for and terminates known Adobe background processes like `AdobeIPCBroker`, `CCXProcess`, `CoreSync`, and others.
    *   **Delete Services:** Attempts to delete the `AGSService` and `AGMService` from the Windows Service Control Manager.
    *   **Remove Files:** Deletes the installation directory for the Adobe Genuine Client (`C:\Program Files (x86)\Common Files\Adobe\AdobeGCClient`).
4.  **Log:** The output box will display a real-time log of every action taken, including successes and any errors encountered.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Pre-emptive Process Killing:** Actively hunts down and stops related Adobe background processes that might prevent file deletion.
*   **Service Removal:** Uses the `sc.exe` command to permanently delete the target services.
*   **File Cleanup:** Removes the physical files associated with the service to prevent it from restarting.
*   **Real-time Logging:** Provides immediate visual feedback on what the script is doing.
*   **Self-Elevating:** Automatically requests the necessary permissions to run.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **System Interaction:** Utilizes `Stop-Process`, `sc.exe`, and `Remove-Item` for system modifications.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Forceful Removal:** This script performs a forceful removal of software components. It is not a standard uninstaller and bypasses the usual uninstallation routines.
*   **System Modification:** It modifies the System Service configuration and deletes files from `Program Files (x86)`. This operation is intended to be permanent.

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
