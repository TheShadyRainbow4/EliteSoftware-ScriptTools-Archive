<a id="readme-top"></a>

<!-- EliteSoftware Co. LOGO -->

<br />
<div align="center">
<!-- <a href="Logo">
<!-- <img src="https://i.postimg.cc/85MDTcrJ/Elite-Software-LOGO-Mocup2.png" alt="Logo" width="256" height="256">
<!-- </a> -->
</div>

<!-- ABOUT THE PROJECT -->

# 💾 About The Project <div align="center">
## Screenshot may be slightly outdated. Sorry in advance! :)
<br />
<div align="center">
<!-- <a href="Screenshot">
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720">
<!-- </a> -->
</div>

## EliteSoftware - Batch Resource Extractor/Creator v6.8.4

The `EliteSoftware - Batch Resource Extractor/Creator` is a sophisticated PowerShell GUI application (Windows Forms) offering comprehensive tools for managing embedded resources within binary files and creating custom resource-only DLLs. This version (v6.8.4) stands out with its automated Visual Studio build environment setup, ensuring reliable execution of SDK tools like `rc.exe` and `link.exe`. It provides a tabbed interface for extracting various resource types (Icons, BMP, Cursors, PNG) from DLL, MUI, and EXE files using `ResourceHacker.exe`, alongside a dedicated tab for easily compiling collections of ICO files into a single, custom resource DLL.

Built by: Gemini (Modified by Zachary Whiteman/Scripy)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a powerful GUI for managing embedded resources in binary files and creating custom Icon DLLs.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's capabilities for GUI development and system interaction.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **`ResourceHacker.exe`:** For resource extraction functionality. It must be downloaded and placed in your system's PATH. You can download it from [www.angusj.com/resourcehacker/](http://www.angusj.com/resourcehacker/).
*   **Visual Studio Build Tools (or full Visual Studio):** Required for Icon DLL creation. Specifically, the script uses `rc.exe` (Resource Compiler) and `link.exe` (Linker) which are part of the Windows SDK and Visual C++ Build Tools.

## 💽 Installation & Execution
1.  **Download:** Download the `DLL Resource Manager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Install Resource Hacker:** Download and install `ResourceHacker.exe`, ensuring its executable is in your system's PATH environment variable.
4.  **Install Visual Studio Build Tools:** If you don't have Visual Studio installed, install the free Visual Studio Build Tools with the "Desktop development with C++" workload to ensure `rc.exe` and `link.exe` are available.
5.  **Run as Administrator:** Open a PowerShell console **as Administrator** and execute the script:
    ```powershell
    .'DLL Resource Manager.PS1'
    ```
    The script requires Administrator privileges for accessing certificate stores and configuring build environments.

Configuration files (`DLLResourceManager.config.json`) are stored in:
`%APPDATA%\EliteSoftware\DLLResourceManager\`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a tabbed interface for its two primary functions:

### 1. DLL/MUI/EXE Resource Extraction
This tab allows you to extract various resources from binary files.
*   **"DLL/MUI/EXE Files"**: Use "Add Files..." to queue multiple DLL, MUI, or EXE files.
*   **"Resource Types to Extract"**: Select the specific types of resources (Icons, BMP, Cursors, PNG) you want to extract.
*   **"Output Directory"**: Specify the base folder for extracted resources. Each binary file will get its own subfolder.
*   **"Clear existing output sub-folder before extraction"**: Use with caution.
*   **"Start Extraction"**: Initiates the extraction process using `ResourceHacker.exe`.
*   **"Archive Previous Extractions"**: Moves current extraction results to a timestamped archive folder.
*   **"Open Output Folder"**: Quickly open the output directory.

### 2. Icon DLL Creation
This tab allows you to compile multiple `.ico` files into a single resource-only DLL.
*   **"Source Icon Files (*.ico)"**: Use "Add Icons..." to select `.ico` files to include in your custom DLL.
*   **"Output Settings"**:
    *   **DLL Name**: Specify the desired name for your output DLL (e.g., `MyCustomIcons.dll`).
    *   **Output Directory**: Choose where the resulting DLL will be saved.
*   **"Create Icon DLL"**: Starts the compilation process. The script will automatically configure the Visual Studio build environment and use `rc.exe` and `link.exe` to create the DLL.

All actions are logged in the "Log" text box at the bottom of the window.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Comprehensive GUI:** Intuitive Windows Forms interface with distinct tabs for resource extraction and DLL creation.
*   **Batch Resource Extraction:** Efficiently extract Icons, Bitmaps, Cursors, and PNG images from multiple DLL, MUI, and EXE files.
*   **Custom Icon DLL Creation:** Easily compile a collection of `.ico` files into a single, resource-only DLL, useful for custom icon libraries.
*   **Automated Visual Studio Environment Setup:** Automatically detects and loads the correct Visual Studio build environment (`vcvarsall.bat`) ensuring `rc.exe` and `link.exe` are properly configured for DLL creation.
*   **Configurable Output:** Specify output directories for both extraction and creation tasks, with persistence across sessions.
*   **Archiving Functionality:** Safely archive previous extraction results into timestamped folders to prevent data loss.
*   **Real-time Activity Log:** Provides detailed progress, status messages, and error reporting within an integrated log text box.
*   **Administrator Privileges Enforcement:** Ensures the script runs with necessary elevated permissions for system-level operations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, integrating with several external tools and .NET components:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Resource Extraction Backend:** `ResourceHacker.exe` (external command-line tool).
*   **Icon DLL Creation Backend:**
    *   `rc.exe` (Resource Compiler from Windows SDK)
    *   `link.exe` (Linker from Visual C++ Build Tools)
    *   `vswhere.exe` (Visual Studio Installer discovery tool)
*   **Process Management:** `Start-Process` for executing external command-line tools.
*   **File System Operations:** Standard PowerShell cmdlets for file and directory management.
*   **Configuration Persistence:** JSON (`ConvertTo-Json`, `ConvertFrom-Json`) for saving and loading application settings.
*   **Environment Management:** Dynamic loading of Visual Studio environment variables.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`EliteSoftware - Batch Resource Extractor/Creator` performs significant system-level operations and relies on external executables.

*   **Administrator Privileges:** The script explicitly checks for and requires Administrator privileges. This is necessary for modifying system environment (temporarily for `vcvarsall.bat`), accessing certain file system locations, and ensuring full functionality of `ResourceHacker.exe` and Visual Studio build tools.
*   **External Tool Dependencies:** The core functionality relies heavily on `ResourceHacker.exe` and the Visual Studio build tools (`rc.exe`, `link.exe`, `vswhere.exe`). Ensure these executables are from trusted sources and are correctly installed.
*   **Dynamic Environment Setup:** The script temporarily modifies the PowerShell process's environment variables to correctly run `rc.exe` and `link.exe` by invoking `vcvarsall.bat`. This ensures the build tools can find their necessary libraries and includes.
*   **File System Modification:** The script performs file extraction, creation, deletion (with the "Clear existing" option), and archiving. Users should be aware of these operations and use the "Clear existing" option with caution to avoid unintended data loss.
*   **Configuration Storage:** Application settings (like output directories) are saved in a `DLLResourceManager.config.json` file located in `%APPDATA%\EliteSoftware\DLLResourceManager\`.
*   **No Telemetry:** The application does not collect or transmit any user data or telemetry.

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
