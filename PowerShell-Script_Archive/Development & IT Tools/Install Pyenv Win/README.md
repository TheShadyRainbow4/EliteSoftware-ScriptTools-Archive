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

## install-pyenv-win: Automated pyenv-win Installation and Management

`install-pyenv-win` is a PowerShell script designed to automate the setup, update, and uninstallation of `pyenv-win`, a popular Python version management tool for Windows. This script simplifies the process of getting `pyenv-win` up and running, ensuring proper environment variable configuration and handling existing Python installations during updates.

Built by: pyenv-win project, with contributions by Zachary Whiteman & Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a standalone PowerShell script for managing your Python development environment.

## 🕰️ Prerequisites
To run this script, you only need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses PowerShell's built-in capabilities for file system and environment variable management.
*   **Internet Connection:** Required for downloading `pyenv-win` from GitHub.

## 💽 Installation & Execution
1.  **Download:** Download the `install-pyenv-win.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run for Installation:** Execute the script from a PowerShell console:
    ```powershell
    .\install-pyenv-win.ps1
    ```
    This will install `pyenv-win` to `$HOME\.pyenv` and configure your user-level environment variables. You may need to close and reopen your terminal for changes to take effect.
4.  **Run for Uninstallation:** To uninstall `pyenv-win` and all Python versions managed by it, execute with the `-Uninstall` switch:
    ```powershell
    .\install-pyenv-win.ps1 -Uninstall
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage

### Installation / Update
Simply run the script without any parameters to install `pyenv-win`. If `pyenv-win` is already installed, the script will check for the latest version and prompt to update if a newer version is available. It intelligently backs up existing Python installations during this process.

```powershell
.\install-pyenv-win.ps1
```

### Uninstallation
To completely remove `pyenv-win` and all Python versions installed through it, use the `-Uninstall` parameter.

```powershell
.\install-pyenv-win.ps1 -Uninstall
```
**Warning:** This action will remove all Python versions managed by `pyenv-win`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automated Installation:** Installs `pyenv-win` and sets up necessary environment variables in one go.
*   **Smart Updates:** Detects existing `pyenv-win` installations and updates to the latest version, backing up current Python environments before proceeding.
*   **Complete Uninstallation:** Provides a clean removal of `pyenv-win` and all associated Python installations.
*   **Environment Variable Configuration:** Automatically configures `PATH`, `PYENV`, `PYENV_ROOT`, and `PYENV_HOME` user-level environment variables.
*   **Robust File Operations:** Handles file system creation, moving, and deletion for `pyenv-win` components.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, utilizing its core capabilities:

*   **Scripting Language:** PowerShell
*   **Web Requests:** `System.Net.WebClient` for downloading `pyenv-win` archives and version information.
*   **Archive Management:** `Expand-Archive` (via `Microsoft.PowerShell.Archive`) for extracting downloaded files.
*   **File System Management:** Standard PowerShell cmdlets like `New-Item`, `Remove-Item`, `Move-Item`, `Test-Path`, `Get-Content` for directory and file operations.
*   **Environment Variable Control:** `[System.Environment]::SetEnvironmentVariable` for precise control over user-level environment variables.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `install-pyenv-win.ps1` script performs modifications to your user environment and downloads executables from the internet.

*   **Local System Modification:** The script modifies your user-level `PATH` environment variable and installs files within your user profile directory (`$HOME\.pyenv`).
*   **External Downloads:** `pyenv-win` is downloaded from its official GitHub repository. Users should be aware of the source and ensure they trust it.
*   **Uninstallation Warning:** The `-Uninstall` parameter performs a destructive operation by removing all `pyenv-win` managed Python installations. Exercise caution.
*   **Network Access:** Requires an active internet connection to perform installations and updates.
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
