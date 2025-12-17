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

## Reunion 7 UI Replicator

The `Reunion 7 UI Replicator` is a specialized PowerShell script designed to restore the classic Windows 7-style "Display Settings" interface on modern versions of Windows. It achieves this by replacing the system's `display.dll` with a legacy version (typically from Windows 10 Build 1511) and injecting specific registry keys to override the modern Settings app.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
**CRITICAL:** This script is designed to be run as **TrustedInstaller**. It will likely fail if run as a standard Administrator.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **TrustedInstaller Access:** You must use a tool like `NSudo` or `PowerRun` to launch this script with `TrustedInstaller` privileges.
*   **Legacy Files:** The script expects `display.dll` and `display.dll.mui` (from a legacy Windows build) to be present in the same directory.

## 💽 Installation & Execution
1.  **Download:** Download the `RestoreLegacyUI.PS1` script file.
2.  **Prepare Files:** Place your legacy `display.dll` and `display.dll.mui` files in the script's folder.
3.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
4.  **Launch via NSudo:** Open `NSudo`, select "TrustedInstaller" as the user, check "Enable All Privileges", and browse to `powershell.exe`. In the arguments box, add the path to this script:
    ```
    -File "C:\Path\To\RestoreLegacyUI.PS1"
    ```
5.  **Run:** Click Run in NSudo.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script provides a simple graphical interface.

1.  **Launch:** Once started (as TrustedInstaller), the GUI will appear.
2.  **Restore:** Click the **Restore Classic Display** button.
3.  **Process:** The script will:
    *   Take ownership of the destination system files (if necessary).
    *   Hot-swap `C:\Windows\System32\display.dll` and its MUI file with the legacy versions provided.
    *   Inject CLSID registry keys to register the classic interface.
    *   Modify the Desktop Context Menu registry keys to point to the classic interface instead of the modern Settings app.
4.  **Restart:** You will be prompted to restart Windows Explorer to apply the changes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **System File Hot-Swap:** Replaces protected system DLLs with legacy versions to restore functionality.
*   **Registry Injection:** Directly modifies `HKLM` keys to re-register the classic COM objects for display settings.
*   **Context Menu Override:** Fixes the "Display settings" right-click menu item on the desktop.
*   **TbConf Integration:** Optionally installs `TbConf.exe` if present.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **System Interaction:** Direct Registry manipulation and file system operations requiring high privileges.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **High Privilege Requirement:** This script requires `TrustedInstaller` permissions because it modifies files in `System32` that are protected by Windows Resource Protection (WFP).
*   **System Stability:** Replacing core system DLLs carries a risk of system instability or boot issues. Ensure you have backups before proceeding.

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
