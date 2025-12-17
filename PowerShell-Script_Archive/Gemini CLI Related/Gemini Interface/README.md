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

## GEMINI Interface

`GEMINI Interface` is a comprehensive PowerShell WinForms application that serves as a robust base template and interface for custom GUI tools. It integrates a logging module, advanced console window management, and a direct interface to the Gemini API. The application features a modern tabbed layout that includes a System Dashboard, Dual Web Browsers (Modern/Legacy), a File Explorer, and a fully functional Gemini Chat interface.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a powerful dashboard for managing your system and interacting with AI.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Gemini API Key:** A valid API key must be stored in the `GEMINI_API_KEY` environment variable for the chat features to work.

## 💽 Installation & Execution
1.  **Download:** Download the `GEMINI Interface.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\GEMINI Interface.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The interface is divided into several tabs:

*   **Dashboard:** View real-time system status indicators and general information.
*   **Browsers:** Access web content through embedded Modern and Legacy browser controls.
*   **File Explorer:** Navigate your local file system with a custom tree view and list view, supporting sorting and grouping.
*   **Gemini Chat:** Interact directly with the Gemini AI models through a chat interface built with HTML/JS and powered by PowerShell.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Robust Logging:** Built-in logging module that saves events to JSON files and automatically archives old logs.
*   **Console Management:** Toggle the visibility of the parent PowerShell console window to keep your desktop clean.
*   **API Integration:** Native PowerShell function to query the Gemini API, supporting multiple models.
*   **Visual Styling:** Features custom gradient headers, "Aero-style" buttons, and dynamic icon management for a polished look.
*   **Configuration:** Saves user settings to a local JSON file.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Integration:** Uses a `WebBrowser` control with HTML/JavaScript to render the chat interface, communicating with the PowerShell backend.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **API Key Security:** The script relies on an environment variable (`GEMINI_API_KEY`) rather than hardcoding credentials, which is a security best practice.
*   **Local Resources:** The application expects a `Resources` directory containing icons and HTML templates to function correctly.

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