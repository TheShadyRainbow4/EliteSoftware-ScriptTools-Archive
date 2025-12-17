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

## Automated Visual Studio & Build Tools Installer

This PowerShell script completely automates the download, silent installation, and environment configuration of **Visual Studio 2022 Community** and **Visual Studio 2022 Build Tools**. It is designed for developers who need a repeatable, scripted method for setting up a full C++ and .NET development environment on a Windows machine. The script installs the products to their official default directories.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script will download and install approximately several gigabytes of data. Ensure you have a stable internet connection and sufficient disk space.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script must be run as an administrator to install software and modify system environment variables.
*   **Internet Connection:** Required to download the installers from Microsoft.

## 💽 Installation & Execution
1.  **Download:** Download the `DEFAULTPATHInstall-VisualStudio-BuildTools.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell" or execute it from a PowerShell console that is running as an administrator.
    ```powershell
    ".\DEFAULTPATHInstall-VisualStudio-BuildTools.PS1"
    ```
4.  **Be Patient:** The download and installation process will take a significant amount of time and will run silently in the background. A detailed log file is created in your `%TEMP%` directory.
5.  **Reboot/Restart Shell:** After the script is finished, you must restart any open command prompts or PowerShell windows, or reboot your system, for the new environment variables to take effect.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 What It Does
The script performs the following actions automatically:

1.  **Downloads Installers:** Downloads the latest official installers for VS 2022 Community and VS 2022 Build Tools.
2.  **Installs VS Community:** Silently installs the IDE with the following workloads:
    *   `.NET desktop development`
    *   `Desktop development with C++`
3.  **Installs VS Build Tools:** Silently installs the command-line tools with the following workload:
    *   `Desktop development with C++` (This includes the Windows SDK, compilers, etc.)
4.  **Configures Environment Variables:**
    *   It locates the paths to the MSVC compiler, the VS IDE, and the Windows SDK.
    *   It adds these paths to a custom system environment variable named `pathEXT`.
    *   It creates a new system environment variable named `VS_BUILD_ENV_SCRIPT` that points directly to the `vcvarsall.bat` file, which is essential for initializing a C++ build environment in a terminal.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Fully Automated:** Downloads, installs, and configures the development environment without any user interaction required.
*   **Silent Installation:** Runs quietly in the background.
*   **Correct Workloads:** Installs the essential workloads for both C++ and .NET desktop development.
*   **Environment Configuration:** Critically, it performs the post-install step of setting up environment variables, making the command-line tools readily accessible.
*   **Detailed Logging:** Every action is logged to a timestamped file in your temp directory for easy troubleshooting.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **Core Logic:** Uses `Invoke-WebRequest` for downloads and automates the official Visual Studio installers via command-line arguments.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Administrator Required:** This script requires administrator access to install software for all users and to modify machine-level environment variables.
*   **System-Wide Changes:** This script makes system-wide changes by installing software and creating/modifying system environment variables.
*   **Official Installers:** The script downloads installers directly and securely from official Microsoft `aka.ms` links.

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