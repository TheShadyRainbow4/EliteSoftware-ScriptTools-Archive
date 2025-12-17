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

## Launch As Trusted Installer

`Launch As Trusted Installer` is a specialized wrapper script designed to elevate the execution privileges of another PowerShell script to "TrustedInstaller" level. This is the highest level of access in Windows, surpassing standard Administrator rights, and is often required to modify protected system files or registry keys.

This specific script is configured to launch the `Restore-Legacy-Resolution-Control-Panel.PS1` script.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is a launcher script that relies on external tools.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **NSudo:** The `NSudo.exe` utility must be present in the same directory as this script. NSudo is the tool that actually performs the token impersonation to grant TrustedInstaller rights.
*   **Target Script:** The script `Restore-Legacy-Resolution-Control-Panel.PS1` must also be in the same directory.

## 💽 Installation & Execution
1.  **Download:** Download the `Launch-As_Trusted-Installer.PS1` script file.
2.  **Dependencies:** Ensure `NSudo.exe` and `Restore-Legacy-Resolution-Control-Panel.PS1` are in the folder with it.
3.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
4.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Launch-As_Trusted-Installer.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script is fully automated and has no user interface of its own.

1.  **Launch:** When you run the script, it immediately hides its own console window to reduce clutter.
2.  **Elevation:** It calls `NSudo.exe` with specific flags (`-U:T -P:E`) to request TrustedInstaller user privileges and Enable All Privileges.
3.  **Execution:** It tells NSudo to launch `pwsh.exe` (PowerShell Core) to run the target script `Restore-Legacy-Resolution-Control-Panel.PS1`.
4.  **Exit:** Once the target script closes, this launcher script will exit automatically.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Silent Launch:** Uses native Windows APIs to hide its own console window immediately upon startup.
*   **Maximum Privileges:** Leverages NSudo to bypass standard Windows file protection (WFP) and registry permission lists (ACLs) by running as the TrustedInstaller account.
*   **Targeted Execution:** Specifically designed to launch a companion script that requires these high-level permissions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **Elevation Tool:** `NSudo.exe` (External Dependency).
*   **Windows API:** P/Invoke access to `user32.dll` and `kernel32.dll` for window management.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Security Risk:** Running scripts as TrustedInstaller bypasses almost all security controls in Windows. Only run scripts you fully trust with this launcher.
*   **Dependency:** This script will fail if `NSudo.exe` is missing.

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
