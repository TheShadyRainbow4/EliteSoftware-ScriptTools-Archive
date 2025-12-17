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

## Script Launcher Pro

`Script Launcher Pro` is a robust PowerShell utility that provides a unified graphical user interface (GUI) for discovering, managing, and executing various script files (`.ps1`, `.py`, `.bat`, `.cmd`). It eliminates the need to navigate through multiple folders or open different terminals to run your scripts, offering a centralized hub for automation and development tasks.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a central launcher for your development scripts.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Python (Optional):** Required if you intend to launch Python (`.py`) scripts.

## 💽 Installation & Execution
1.  **Download:** Download the `Script Launcher Professional.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\Script Launcher Professional.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application scans specified folders and presents a list of executable scripts.

*   **View Scripts:** The main window displays all found scripts. You can change the view mode (Details, Tiles, Icons) using the "View" menu.
*   **Launch Scripts:** Select a script and click the "Run" button (or double-click) to execute it. The launcher intelligently chooses the correct interpreter (`pwsh`, `python`, `cmd`) based on the file extension.
*   **Manage Folders:** Use the "File" menu to add or remove source directories for scanning.
*   **Metadata:** Right-click a script to edit its metadata, allowing you to add custom authors, version numbers, and descriptions.
*   **Custom Icons:** You can assign custom icons to scripts via the metadata editor for easier visual identification.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Multi-Language Support:** Handles PowerShell, Python, and Batch scripts seamlessly.
*   **Dynamic Scanning:** Aggregates scripts from multiple user-defined folders.
*   **Visual Customization:** Supports custom icons per script and multiple view modes (List, Grid, Details).
*   **Metadata Management:** Stores extra information about scripts in sidecar `.meta.json` files.
*   **Persistent Configuration:** Remembers your window layout, view preferences, and source folders between sessions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Interop:** C# P/Invoke for advanced window management.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Execution Policy:** The script launches PowerShell scripts using `pwsh.exe` (or `powershell.exe`). Ensure your system's execution policy allows running scripts.
*   **Local Execution:** Scripts are executed locally with the current user's privileges.

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