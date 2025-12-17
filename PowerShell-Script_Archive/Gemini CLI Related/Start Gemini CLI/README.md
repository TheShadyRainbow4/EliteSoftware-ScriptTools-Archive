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

## Start Gemini CLI

`Start Gemini CLI` is a simple, robust launcher script designed to easily start the Gemini Command Line Interface. It handles the details of determining the script's directory, setting the working environment, and executing the `gemini` command, ensuring a smooth startup experience.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a launcher for the Gemini CLI tool.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Gemini CLI:** The `gemini` executable must be installed and available in your system's PATH environment variable.

## 💽 Installation & Execution
1.  **Download:** Download the `Start-Gemini-CLI.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Start-Gemini-CLI.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Simply run the script. It will:
1.  Identify its own location.
2.  Set the console's working directory to match the script.
3.  Launch the `gemini` command.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Auto-Directory Detection:** Automatically finds the correct path using `$PSScriptRoot` or fallback methods.
*   **Context Management:** Sets the session location to the script's folder, which is helpful for relative file access.
*   **Error Handling:** Catches errors (like a missing executable) and displays detailed information. It pauses the console before closing so you can read the error message.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Wrapper:** This is purely a wrapper script. It does not contain the logic for the Gemini CLI itself; it only invokes the external command.

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