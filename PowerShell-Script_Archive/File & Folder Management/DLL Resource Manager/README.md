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

## Batch Resource Extractor/Creator

This `Batch Resource Extractor/Creator` is an advanced PowerShell utility that provides a graphical user interface (GUI) for managing resources within binary files (`.dll`, `.exe`, `.mui`). It is a powerful tool for developers and themers, combining two major functionalities into one application: extracting existing resources from files and creating new, resource-only DLLs from a collection of icons.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is an advanced developer tool with external dependencies. Please review the prerequisites for the features you intend to use.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script requires administrator access and will attempt to self-elevate.
*   **For Resource Extraction:**
    *   **Resource Hacker:** The `ResourceHacker.exe` command-line tool must be installed and accessible in your system's PATH. You can get it from [angusj.com/resourcehacker](http://www.angusj.com/resourcehacker/).
*   **For Icon DLL Creation:**
    *   **Visual Studio or VS Build Tools:** You must have either a version of Visual Studio or the "Build Tools for Visual Studio" installed. The script needs the Resource Compiler (`rc.exe`) and Linker (`link.exe`) from the C++ toolset.

## 💽 Installation & Execution
1.  **Download:** Download the `DLL Resource Manager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console. It will automatically request administrator elevation.
    ```powershell
    ".\DLL Resource Manager.PS1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage & Features
The application is organized into several tabs for different tasks.

### Resource Extraction (DLL, MUI, EXE Tabs)
These tabs allow you to extract embedded resources from binary files.
1.  Click **Add Files...** to select one or more `.dll`, `.mui`, or `.exe` files.
2.  Check the boxes for the resource types you want to extract (Icons, BMPs, Cursors, PNGs).
3.  Select an output directory.
4.  Click **Start Extraction**. The tool will create a sub-folder for each source file and save the extracted resources inside.

### Icon DLL Creation
This tab allows you to compile multiple `.ico` files into a single, resource-only DLL, which is useful for creating icon libraries.
1.  Click **Add Icons...** to select one or more `.ico` files.
2.  Specify the desired name for your output DLL (e.g., `MyIconLibrary.dll`).
3.  Select an output directory.
4.  Click **Create Icon DLL**. The script will automatically configure the Visual Studio build environment, compile the resources, and link them into a DLL.

### Other Features
*   **Automated Build Environment:** The script intelligently locates your Visual Studio installation and runs the necessary `vcvarsall.bat` script to set up the environment for `rc.exe` and `link.exe`.
*   **Persistent Configuration:** Your preferred output directories are saved and reloaded between sessions.
*   **Detailed Logging:** A log window at the bottom provides real-time feedback on all operations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Extraction Backend:** `ResourceHacker.exe` (external dependency).
*   **Creation Backend:** Microsoft Build Tools (`rc.exe`, `link.exe`) (external dependency).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **External Dependencies:** The functionality of this script is heavily dependent on the presence of `ResourceHacker.exe` and Visual Studio Build Tools.
*   **Administrator Privileges:** Required for self-elevation and potentially for writing to certain system directories.
*   **Automated Environment:** The script automates the process of setting up a build environment, which involves running batch files provided by Visual Studio.

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