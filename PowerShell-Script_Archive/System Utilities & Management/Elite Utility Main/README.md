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

## EliteUtility - Main

`EliteUtility - Main` is a PowerShell script that serves as the main application shell for a modular suite of system utilities. It provides a flexible framework with a navigation tree on the left and a content area on the right, designed to load various "snap-in" panels, each offering a distinct piece of functionality.

This version is a work-in-progress, with some modules fully implemented (like the AI Assistant) and others acting as placeholders for future development.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is the central hub for the EliteUtility suite and has several external dependencies for full functionality.

## 🕰️ Prerequisites
To run this script and use its features, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Local AI Server (for AI Assistant):** Requires a local, OpenAI-compatible API endpoint running at `http://192.168.10.100:1234`. This is typically provided by applications like LM Studio.
*   **`wingetsearch.ps1` (for Package Manager):** This external script must be located at `H:\Zachary Whiteman\Desktop\EliteUtility\wingetsearch.ps1` for the Package Manager snap-in to work.

## 💽 Installation & Execution
1.  **Download:** Download the `EliteUtility-Main.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if it was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\EliteUtility-Main.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage & Implemented Modules
Navigate the various utility modules using the tree view on the left. The corresponding tool will appear in the panel on the right.

### Fully Implemented Modules
*   **AI Assistant:**
    *   A complete chat interface for interacting with a local AI model.
    *   Select the desired model from the dropdown list.
    *   Type your prompt in the input box and press **Send** or `Enter`.
    *   The conversation is displayed in the main output window.
*   **Package Manager:**
    *   A launcher panel that opens the `wingetsearch.ps1` GUI in a separate window.

### Placeholder Modules
The following modules are part of the UI but are currently placeholders for future implementation:
*   Home DashBoard
*   DLL Icon Extractor
*   AI Icon Organizer
*   Startup Apps Manager
*   Services Manager

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Modular Snap-in Architecture:** A flexible design that allows for adding new tools as self-contained panels.
*   **Tree View Navigation:** Provides a clean and organized way to switch between different utilities.
*   **Integrated AI Chat:** A built-in client for connecting to a local large language model.
*   **External Tool Integration:** Capable of launching other scripts and tools, as seen with the Package Manager snap-in.
*   **Work-in-Progress Framework:** A solid foundation for building a comprehensive suite of system utilities.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **API Communication:** Uses `Invoke-RestMethod` to communicate with the local AI server's REST API.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Hardcoded Paths:** This script contains hardcoded paths to external dependencies (the `wingetsearch.ps1` script) and network endpoints (the AI server). These must be in place for the features to work.
*   **Network Access:** The AI Assistant feature makes network requests to a local IP address. Ensure your firewall permits this if necessary.
*   **Administrator Privileges:** While the main shell does not check for administrator rights, many of the intended snap-in modules (like a Services Manager or Package Manager) would require them to function correctly.

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
