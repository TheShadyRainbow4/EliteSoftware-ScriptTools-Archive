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

## Unenroll Insider Program Launcher

**⚠️ IMPORTANT NOTE:** The file `UnEnrollInsiderProgram.PS1` contains Windows Batch (`.bat`) script commands, not PowerShell code, despite its file extension. Additionally, it references a target file `WIP_Unenroll.ZACH` which must be present in the same directory for it to function.

This script is intended to serve as a launcher for a Windows Insider Program unenrollment tool. It attempts to start a specific PowerShell script using PowerShell 7 (`pwsh.exe`) in a hidden window context.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is a launcher script with specific dependencies.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 7 (`pwsh.exe`):** The script explicitly hardcodes the path to `C:\Program Files\PowerShell\7\pwsh.exe`.
*   **Target Payload:** A file named `WIP_Unenroll.ZACH` (likely a PowerShell script) must exist in the same folder.

## 💽 Installation & Execution
1.  **Download:** Download the `UnEnrollInsiderProgram.PS1` script file.
2.  **Rename (Recommended):** Since the content is Batch script, you may want to rename it to `UnEnrollInsiderProgram.bat` or `.cmd`.
3.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` (if applicable).
4.  **Run:** Execute the script. If running as a `.ps1`, you would typically need to execute it from `cmd.exe` or rename it first.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script is designed to be a "fire and forget" launcher.

1.  **Launch:** When executed, it sets environment variables for the PowerShell executable and the target script path.
2.  **Execution:** It uses the `start` command to launch the `WIP_Unenroll.ZACH` script using PowerShell 7.
3.  **Cleanup:** The launcher window closes immediately (`EXIT`), leaving the target script running.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **PowerShell 7 Targeting:** Specifically targets the modern PowerShell Core executable.
*   **Window Management:** Uses the `start` command to launch the process in a separate context, preventing the launcher window from remaining open.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** Windows Batch (Cmd).
*   **Target Runtime:** PowerShell 7.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Extension Mismatch:** The file has a `.PS1` extension but contains Batch code. This prevents it from running natively in a PowerShell console without generating errors.
*   **Hardcoded Paths:** The script relies on specific install paths for PowerShell 7.

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
