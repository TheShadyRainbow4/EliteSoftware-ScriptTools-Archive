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

## Icon Manager

`Icon Manager` is a specialized tool for browsing and compiling `.ico` files into a resource-only DLL. This utility is particularly useful for developers and system customizers who need to create icon libraries that can be used by other applications or for system-wide customization. It serves as a GUI wrapper around a Python script (`ico2dll.py`) that performs the actual compilation using the MinGW toolchain.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script requires specific external tools to function correctly.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Python:** `python.exe` must be installed and accessible in the system's PATH.
*   **MinGW:** The underlying `ico2dll.py` script requires MinGW tools (specifically `windres` and `gcc`) to be installed and in the PATH.
*   **Dependencies:** The `ico2dll.py` script must exist in the same directory as this PowerShell script.

## 💽 Installation & Execution
1.  **Download:** Download the `IconManager.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\IconManager.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application guides you through the process of creating an icon DLL.

1.  **Add Icons:** Use the interface to browse and select the `.ico` files you want to include in your library.
2.  **Manage List:** You can remove icons from the list if needed.
3.  **Compile:** Click the button to build the DLL. The script will copy the selected icons to a temporary folder and invoke the Python backend to compile `IcoHolder.dll`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Icon List Management:** Easily add and remove `.ico` files from your build list.
*   **DLL Compilation:** Automates the complex process of building a resource-only DLL from individual icon files.
*   **Robust Logging:** Includes the EliteSoftware standard logging module for tracking operations and errors.
*   **Simple GUI:** Provides a clean Windows Forms interface for what would otherwise be a command-line task.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend:** Python (`ico2dll.py`) + MinGW (`windres`, `gcc`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **External Execution:** This script relies on executing external processes (`python.exe`, `windres`, `gcc`). Ensure these tools are from trusted sources.
*   **Temporary Files:** The script creates a temporary `icons` folder during the compilation process.

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