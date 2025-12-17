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

## Install-VisualStudio-BuildTools v2.3

`Install-VisualStudio-BuildTools` is a powerful PowerShell script designed to automate the complete setup of a C++ and .NET development environment using Visual Studio 2022 components. This script handles the silent download and installation of both Visual Studio 2022 Community Edition and Visual Studio 2022 Build Tools into a structured directory. Crucially, it then automatically identifies and adds the necessary paths for the Visual Studio IDE, the MSVC C++ compiler toolchain, and the Windows SDK to your system's PATH environment variable, ensuring your development tools are immediately accessible.

Built by: Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a critical tool for setting up a robust development environment.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses PowerShell's built-in capabilities.
*   **Administrator Privileges:** The script *must* be run with Administrator privileges to modify system-wide PATH environment variables and install software.

## 💽 Installation & Execution
1.  **Download:** Download the `Install-VisualStudio-BuildTools.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Open a PowerShell console **as Administrator** and execute the script:
    ```powershell
    .\Install-VisualStudio-BuildTools.PS1
    ```
    The script will log its progress to the console and to a timestamped log file in your temporary directory (`%TEMP%`).

**Important:** You must restart any open terminal windows or reboot your system for the PATH changes to take full effect.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Simply execute the script as Administrator. The script will:

1.  **Check for Prerequisites:** Verify Administrator privileges and the existence of the target installation drive.
2.  **Download Installers:** Download the Visual Studio Community and Build Tools installers from Microsoft's official channels (if not already present in your `%TEMP%` directory).
3.  **Install Visual Studio Community:** Perform a silent installation of Visual Studio 2022 Community Edition with specified workloads (Managed Desktop, Native Desktop) to `E:\VisualStudio\Community`.
4.  **Install Visual Studio Build Tools:** Perform a silent installation of Visual Studio 2022 Build Tools with the Native Desktop workload (including Windows SDK) to `E:\VisualStudio\BuildTools`.
5.  **Locate Key Paths:** Automatically find the installation directories for the Visual Studio IDE (`devenv.exe`), the latest MSVC C++ compiler toolchain, and the latest Windows SDK (`rc.exe`).
6.  **Update System PATH:** Add the located paths to your system's `PATH` environment variable, ensuring they are only added once to avoid duplicates.

A detailed log file will be generated in your `%TEMP%` directory (e.g., `vs_install_log_YYYYMMDD_HHMMSS.txt`) documenting all steps.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Full Automation:** Automates the entire process of downloading, installing, and configuring Visual Studio 2022 Community and Build Tools.
*   **Structured Installation:** Installs components into a logical and configurable root directory (`E:\VisualStudio`).
*   **Workload-Specific Installation:** Ensures necessary workloads for .NET and C++ desktop development are included.
*   **Automatic PATH Configuration:** Intelligently identifies and adds critical development tool paths to the system's `PATH` environment variable.
*   **Detailed Logging:** Creates a timestamped log file for each execution, providing a clear record of the installation process and any issues.
*   **Idempotent Downloads:** Skips re-downloading installer executables if they are already present.
*   **Robust Error Handling:** Includes comprehensive `try-catch` blocks for resilient execution and informative error messages.
*   **Prerequisite Verification:** Checks for Administrator privileges and target drive availability before proceeding.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, utilizing its core capabilities:

*   **Scripting Language:** PowerShell
*   **Web Requests:** `Invoke-WebRequest` for secure downloading of official Microsoft installers.
*   **System Environment Management:** `[Environment]::SetEnvironmentVariable` for modifying the system's `PATH` variable.
*   **Process Management:** `Start-Process` with silent arguments (`--quiet --norestart --wait`) for non-interactive installations.
*   **File System Management:** Standard PowerShell cmdlets like `Join-Path`, `Test-Path`, `Get-ChildItem` for path resolution and directory handling.
*   **Security Context:** `Security.Principal.WindowsPrincipal` for verifying Administrator privileges.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Install-VisualStudio-BuildTools.PS1` performs significant system-level modifications.

*   **Administrator Privileges:** The script explicitly `requires -RunAsAdministrator` because it modifies system-wide settings like the `PATH` environment variable and installs software.
*   **External Downloads:** Installer executables are downloaded directly from Microsoft's official content delivery network (e.g., `aka.ms/vs/17/release/vs_community.exe`), ensuring legitimate sources.
*   **System-Wide Impact:** Modifications to the system `PATH` affect all users and processes. A system reboot or restarting relevant applications may be necessary for changes to fully propagate.
*   **Installation Paths:** Installs Visual Studio components to a user-defined root directory, ensuring a clean and organized installation location.
*   **Logging:** All actions and any errors are meticulously logged to a file in the user's `%TEMP%` directory, which is crucial for troubleshooting.
*   **Silent Installation:** The `--quiet` flag used with the Visual Studio installers ensures a non-interactive installation process, but users should be aware of the components being installed as defined in the script's configuration.
*   **No Telemetry:** The script itself does not collect or transmit any user data or telemetry.

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
