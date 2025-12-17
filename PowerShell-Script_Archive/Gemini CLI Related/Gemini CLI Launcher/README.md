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

## Gemini CLI Launcher (Gradient Box Edition)

The `Gemini CLI Launcher` is a stylish and interactive launcher script for the Gemini command-line interface. It provides a visual, text-based menu (TUI) for selecting different Gemini models, configuring launch options, and managing the execution environment. It features a modern gradient aesthetic and robust handling for PowerShell 7 and administrator privileges.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script serves as a front-end for the Gemini CLI tool.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 7 (`pwsh.exe`):** This script is optimized for PowerShell Core. It will attempt to relaunch itself in `pwsh` if run from Windows PowerShell.
*   **Gemini CLI:** The `gemini` executable must be installed and accessible in your system's PATH.

## 💽 Installation & Execution
1.  **Download:** Download the `GEMINI-CLI - Launcher.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\GEMINI-CLI - Launcher.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The launcher provides an interactive menu.

1.  **Launch:** Run the script. It will check for updates (simulated) and display a loading animation.
2.  **Menu:** Navigate the menu using the arrow keys or by typing the option number.
    *   **Start Gemini 2.5 Pro:** Launches the standard pro model.
    *   **Start Gemini 2.5 Flash:** Launches the faster, lighter model.
    *   **Start Gemini 3.0 Pro:** Launches the newest model (if available).
    *   **Advanced Launch Options:** access debug flags, custom system prompts, and other CLI arguments.
    *   **Settings:** Configure auto-elevation (Administrator mode) preferences.
    *   **Exit:** Close the launcher.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Visual TUI:** A centered, box-styled menu with gradient color support for a modern look in the terminal.
*   **PowerShell 7 Bootstrap:** Automatically detects if it's running in legacy Windows PowerShell and relaunches itself in the modern `pwsh.exe` environment.
*   **Model Selection:** Quick access to different versions of the Gemini model.
*   **Auto-Elevation:** Can be configured to automatically request Administrator privileges on start.
*   **Settings Persistence:** Saves user preferences to a local `.gemini/settings.json` file.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 7+.
*   **Interface:** Console/Host RawUI for drawing text-based user interface elements.
*   **Configuration:** JSON for saving settings.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Process Management:** The script uses `Start-Process` to handle self-elevation and to launch the target `gemini` executable.
*   **Local Config:** Settings are stored in a hidden `.gemini` folder within the script's directory.

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