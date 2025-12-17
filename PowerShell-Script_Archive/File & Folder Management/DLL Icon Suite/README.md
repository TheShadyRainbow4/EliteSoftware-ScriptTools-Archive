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
## Screenshot may be slightly outdated. Sorry in advance! :)  
<br />
<div align="center">
<!-- <a href="Screenshot"> -->
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720"> -->
<!-- </a> -->
</div>

## DLL Icon Suite: Basic Script Foundation

The `DLL Icon Suite` script serves as a minimal foundational piece for a larger PowerShell project, primarily demonstrating robust session logging capabilities. It automatically creates a dedicated "Logs" folder within its directory and meticulously records all PowerShell session output to `SessionLog.txt`. This script is useful as a starting point for ensuring basic PowerShell execution and logging mechanisms are functional before implementing more complex features.

Built by: EliteSoftware Enterprises / Zachary Whiteman / Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a basic foundation for PowerShell projects, focusing on logging.

## 🕰️ Prerequisites
To run this script, you only need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses standard PowerShell cmdlets.

## 💽 Installation & Execution
1.  **Download:** Download the `DLLIconSuite.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\DLLIconSuite.ps1
    ```
    The script will execute silently and then close. A new folder named `Logs` will be created in the script's directory, containing `SessionLog.txt` with the execution details.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
This script is primarily for demonstrating and testing basic PowerShell execution and logging. It does not have an interactive user interface or complex functionality.

After execution, you can:
*   Navigate to the `Logs` folder in the script's directory.
*   Open `SessionLog.txt` to review the transcript of the PowerShell session, confirming the script started and finished successfully.

This functionality is particularly useful as a starting point for more elaborate PowerShell projects, ensuring that foundational logging is in place.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automated Session Logging:** Utilizes `Start-Transcript` and `Stop-Transcript` to capture all PowerShell console output, providing a comprehensive record of script execution.
*   **Dedicated Log Folder:** Automatically creates a "Logs" subfolder next to the script to keep log files organized.
*   **Basic Execution Verification:** Serves as a fundamental test to confirm that PowerShell scripts can run and perform simple file system operations.
*   **Minimal Footprint:** A very small and lightweight script, ideal as a template or proof-of-concept for integrating logging into larger projects.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, utilizing core language features:

*   **Scripting Language:** PowerShell
*   **Logging:** `Start-Transcript`, `Stop-Transcript` cmdlets.
*   **File System Management:** `Join-Path`, `Test-Path`, `New-Item` cmdlets for directory creation and path manipulation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `DLL Icon Suite` script is a very basic, self-contained utility.

*   **Self-Contained:** It does not rely on external dependencies or complex modules.
*   **Local Logging:** All logging occurs strictly on the local machine, within a subfolder of the script's directory. No data is transmitted externally.
*   **No System Modification (Minor):** The only modification to the system is the creation of a local "Logs" folder and a text file within it.
*   **No Sensitive Operations:** The script does not process or generate sensitive data.
*   **No Telemetry:** The script does not collect or transmit any user data or telemetry.

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
