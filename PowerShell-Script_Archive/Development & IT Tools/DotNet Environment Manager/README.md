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

## .NET Environment Manager v1.2

The .NET Environment Manager is a PowerShell GUI application built with Windows Forms (.NET WinForms) designed to streamline the process of installing and verifying .NET SDK versions on your system. It provides a user-friendly interface with quick access buttons to install common Long-Term Support (LTS) .NET SDKs using `winget` and diagnostic tools to inspect your current .NET installation and system PATH.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script that simplifies .NET environment management.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** (PowerShell Core is supported).
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **`winget`:** The Windows Package Manager (`winget`) must be installed and accessible in your system's PATH.
*   **`.NET CLI`:** The `dotnet` command-line interface should be available in your system's PATH for verification tools.

## 💽 Installation & Execution
1.  **Download:** Download the `DotNet Environment Manager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\DotNet Environment Manager.PS1
    ```
    The PowerShell console window will automatically minimize upon launch for a cleaner GUI experience. Installation progress for SDKs will appear in new terminal windows.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The .NET Environment Manager provides two main sections:

*   **Install .NET SDK:**
    *   **"Install .NET 8 SDK (LTS)"**: Clicks this button to initiate the `winget` installation of .NET 8 SDK.
    *   **"Install .NET 6 SDK (LTS)"**: Clicks this button to initiate the `winget` installation of .NET 6 SDK.
    *   Installation progress will be shown in a new terminal window.
*   **Diagnostics:**
    *   **"Verify .NET Info"**: Clicks this button to run `dotnet --info` in a new terminal window, displaying detailed information about your .NET installations.
    *   **"Check System PATH"**: Clicks this button to display your system's Machine and User PATH environment variables in a message box, useful for troubleshooting environment issues.

The main application window also includes an output text box for status messages and a console window (minimized) that will show script-related output.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-based .NET Management:** User-friendly Windows Forms interface for simplified .NET environment interactions.
*   **One-Click SDK Installation:** Quickly install commonly used .NET LTS SDKs (e.g., .NET 8, .NET 6) with a single button click via `winget`.
*   **Integrated Diagnostic Tools:**
    *   Verify your .NET installation details using `dotnet --info`.
    *   Inspect system PATH variables to troubleshoot environment configuration.
*   **Streamlined User Experience:** PowerShell console automatically minimizes on launch, providing a clean desktop application feel.
*   **Clear Feedback:** Provides status messages within the GUI and launches separate terminal windows for installation progress visibility.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The application is a self-contained PowerShell script, utilizing:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Package Management:** `winget` (Windows Package Manager) for installing .NET SDKs.
*   **Core .NET Commands:** `dotnet` command-line interface for querying .NET installation information.
*   **Operating System Integration:** C# P/Invoke for direct calls to Windows API functions for console window management.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The .NET Environment Manager operates by executing local system commands and interacting with the Windows environment.

*   **Local Execution:** All operations are performed locally on your machine. No external network services are directly accessed by the script itself beyond what `winget` might do to fetch SDKs.
*   **Dependency on `winget` and `dotnet` CLI:** Relies on `winget` and the `dotnet` command-line interface being correctly installed and configured in the system's PATH.
*   **Process Launching:** Uses `Start-Process` to execute `winget` and `dotnet` commands in new, independent terminal windows. This is a secure method as it isolates the spawned processes.
*   **Console Minimization:** Employs C# P/Invoke to minimize the PowerShell console, a standard technique for GUI applications written in PowerShell.
*   **No Telemetry:** The application does not collect or transmit any user data or telemetry.

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
