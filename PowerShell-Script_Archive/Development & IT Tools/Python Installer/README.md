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

## Quick Python & Libraries Installer v1.0

The `Quick Python & Libraries Installer` is a straightforward PowerShell script designed to automate the setup of a Python development environment. It efficiently installs the latest Python 3 version using `winget` and subsequently deploys a set of essential Python libraries via `pip`. This script simplifies the initial setup process, ensuring that developers and users have a functional Python environment with key libraries readily available.

Built by: Zachary Whiteman & Google Gemini.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a quick and direct way to set up Python and essential libraries.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses PowerShell's capabilities for system interaction.
*   **`winget`:** The Windows Package Manager (`winget`) must be installed and accessible in your system's PATH.
*   **Internet Connection:** An active internet connection is required to download Python and its libraries.

## 💽 Installation & Execution
1.  **Download:** Download the `PythonInstaller.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\PythonInstaller.PS1
    ```
    The PowerShell console window will automatically minimize upon launch, and all installation progress will be displayed within it. The window will remain open after completion for you to review the output.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Simply execute the script. It will automatically perform the following steps:

1.  **Minimize Console:** The PowerShell console window will minimize to provide a less intrusive experience.
2.  **Install Python:** The script will use `winget` to silently install the latest version of Python 3.
3.  **Locate Python:** It will then find the newly installed Python executable (`python.exe`).
4.  **Install Libraries:** `pip` will be used to install the following essential Python libraries:
    *   `wxpython`
    *   `pywin32`
    *   `requests`
    *   `psutil`
5.  **Review Output:** After all installations are attempted, the console window will remain open, displaying a log of the entire process, including any warnings or errors during library installation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automated Python Installation:** Installs the latest stable version of Python 3 using `winget`, a reliable package manager for Windows.
*   **Essential Library Setup:** Automatically installs a curated set of common and useful Python libraries, ensuring a ready-to-use development environment.
*   **Silent Execution:** Python installation is performed silently in the background, minimizing user interruptions.
*   **Intelligent Path Discovery:** The script dynamically locates the Python installation path after installation to correctly execute `pip` commands.
*   **Non-Intrusive Console:** The PowerShell console window is automatically minimized upon startup for a cleaner user experience.
*   **Post-Execution Review:** The console remains open after the installation process is complete, allowing users to review the full output and troubleshoot any potential issues.
*   **Robust Error Handling:** Includes basic `try-catch` blocks to report errors during the installation process.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging external tools for package management:

*   **Scripting Language:** PowerShell
*   **Package Management:**
    *   `winget` (Windows Package Manager) for installing the Python interpreter.
    *   `pip` (Python's package installer) for managing Python libraries.
*   **Process Management:** `Start-Process` for executing `winget` and `pip` commands.
*   **Operating System Interaction:** C# P/Invoke for console window minimization.
*   **File System Operations:** Standard PowerShell cmdlets for path discovery.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `Quick Python & Libraries Installer` script performs modifications to your system and downloads software from external sources.

*   **Local Execution:** All operations are performed locally on your machine.
*   **External Dependencies:** Relies on `winget` being installed and an active internet connection to download Python and its libraries.
*   **Installation Location:** Python is typically installed in the user's local application data directory (`%LOCALAPPDATA%\Programs\Python`).
*   **Process Execution:** Uses `Start-Process` to run `winget` and `pip` commands.
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
