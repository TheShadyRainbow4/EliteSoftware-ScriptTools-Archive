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

## AI Conversational Assistant - Fully Automated Multi-threaded Setup Script

This PowerShell script provides a fully automated, multi-threaded solution for a clean installation and setup of a local AI conversational assistant environment. It streamlines the complex process of installing Python (via `pyenv-win`), downloading `SillyTavern` (a web-based chat frontend for AI), and setting up `XTTS-WebUI` (for Text-to-Speech capabilities). The script leverages PowerShell jobs to perform these tasks concurrently, significantly reducing setup time for users.

Built by: Zachary Whiteman & Google Gemini AI

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script designed for a clean installation of an AI conversational assistant environment.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** (PowerShell Core is supported).
*   **Administrator Privileges:** The script must be run as Administrator to configure the environment (e.g., PATH variables).
*   **Git Installed:** Git must be installed and accessible in your system's PATH: [Download Git](https://git-scm.com/download/win).

## 💽 Installation & Execution
1.  **Download:** Download the `AISetup_CleanInstall.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Open a PowerShell console **as Administrator** and execute the script:
    ```powershell
    .\AISetup_CleanInstall.ps1
    ```
    The script will guide you through the automated setup process, including Python installation, and downloading/setting up `SillyTavern` and `XTTS-WebUI`.

The core project directory will be created at `E:\LOCAL_TTS_CONVERSATION_AI`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Once the script completes its execution, your local AI conversational assistant environment will be largely set up. Follow these crucial post-installation steps:

1.  **NVIDIA CUDA Toolkit (Manual Step):** If you plan to use GPU acceleration, manually install the NVIDIA CUDA Toolkit (the LOCAL version) if you haven't already.
2.  **Launch LM Studio (or Jan):** Start your preferred local LLM server (e.g., LM Studio or Jan) and ensure its API server is running.
3.  **Launch XTTS-WebUI:** Navigate to the `E:\LOCAL_TTS_CONVERSATION_AI\XTTS-WebUI` folder and run its `start.bat` file to launch the Text-to-Speech server.
4.  **Launch SillyTavern:** Navigate to the `E:\LOCAL_TTS_CONVERSATION_AI\SillyTavern` folder and run its `Start.bat` file to launch the chat frontend.
5.  **Configure SillyTavern:** Within the SillyTavern UI, connect to your running LLM and TTS servers.

You are now ready to enjoy your local conversational AI!

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Fully Automated Setup:** Automates the complex process of setting up a local AI conversational assistant environment.
*   **Multi-threaded Execution:** Leverages PowerShell jobs for parallel downloading and installation of components, saving time.
*   **Python Version Management:** Integrates `pyenv-win` for isolated and managed Python installations.
*   **SillyTavern & XTTS-WebUI Integration:** Automatically downloads and sets up popular AI chat frontend (SillyTavern) and Text-to-Speech (XTTS-WebUI) tools.
*   **Clean Installation Focus:** Designed to provide a fresh and conflict-free setup.
*   **Dependency Management:** Automatically installs Python dependencies using `pip` for `XTTS-WebUI`.
*   **Error Handling:** Includes basic error handling and informative messages throughout the setup process.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The entire setup process is orchestrated by a PowerShell script, utilizing:

*   **Scripting Language:** PowerShell
*   **Python Ecosystem:** `pyenv-win` (Python version manager), `pip` (package installer), `python`
*   **Version Control:** `Git` for cloning repositories
*   **AI Frontends/Backends:** SillyTavern, XTTS-WebUI
*   **Core Windows Components:** `.NET Framework` (for PowerShell functions).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `AISetup_CleanInstall.ps1` script is designed for a one-time setup of a local AI environment.

*   **Administrator Privileges:** Requires elevation to Administrator to manage system-wide PATH environment variables and install software.
*   **External Downloads:** Downloads software and dependencies from trusted public repositories (GitHub, pip). Users should ensure network security.
*   **Local Installation:** All components are installed locally on your system, typically within `E:\LOCAL_TTS_CONVERSATION_AI`. No data is sent externally by this setup script.
*   **Dependency on Git:** Relies on Git being pre-installed and accessible in the system PATH.
*   **Multi-threading (Jobs):** Uses PowerShell's `Start-Job` for concurrency, improving efficiency without blocking the main script flow.

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
