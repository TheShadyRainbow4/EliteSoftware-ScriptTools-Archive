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

## Internet Explorer Fixer

The `Internet Explorer Fixer` is a PowerShell script designed to restore and stabilize the functionality of Internet Explorer 11 on modern Windows systems where it may be aggressively redirected to Microsoft Edge. It performs a multi-step operation to remove the specific Browser Helper Objects (BHOs) responsible for redirection and applies Group Policy settings to enforce standard IE behavior.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script modifies system registry settings to prevent Edge redirection.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script requires full administrator access to modify `HKEY_LOCAL_MACHINE` registry keys.

## 💽 Installation & Execution
1.  **Download:** Download the `Internet Explorer Fixer.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell". Ensure you confirm the UAC prompt.
    ```powershell
    .\Internet Explorer Fixer.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script runs in an interactive console mode with built-in safety checkpoints.

1.  **Backup:** Upon launch, it immediately creates a timestamped backup of all registry keys it intends to modify. This backup is saved in the script's directory.
2.  **Checkpoint 1:** You will be asked to confirm before the script deletes the BHO keys responsible for Edge redirection. Press `ENTER` to continue or type `C` to cancel.
3.  **Checkpoint 2:** After deletion, you will be asked to confirm before the script applies new Group Policy settings to enforce IE compatibility and TLS 1.2.
4.  **Completion:** The script will provide final instructions, such as running `gpupdate /force` and restarting your computer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automatic Backup:** Creates individual `.reg` files for every key modified, allowing for easy restoration if needed.
*   **BHO Removal:** Targets and removes the specific CLSIDs associated with the "IE to Edge" redirection plugin.
*   **Policy Enforcement:** Sets registry keys corresponding to Group Policies that disable redirection and enable legacy compatibility features.
*   **Safety Checkpoints:** Pauses at critical stages to allow the user to review progress or cancel the operation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **System Interaction:** Direct Registry manipulation (`Remove-Item`, `Set-ItemProperty`) and interaction with the `reg.exe` tool for backups.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **System Modification:** This script modifies core system settings. While it includes backup functionality, it is recommended to create a System Restore point before running it.
*   **Administrator Access:** Registry operations on `HKLM` require elevated privileges.
*   **Manual Restart:** A system restart is usually required for these registry changes to take full effect and unload the BHOs from memory.

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
