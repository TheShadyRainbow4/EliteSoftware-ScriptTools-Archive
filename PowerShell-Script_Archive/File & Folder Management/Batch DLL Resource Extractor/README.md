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

## Batch Resource Extractor v6.2 (Final)

The `Batch Resource Extractor` is a robust PowerShell GUI application (Windows Forms) designed for efficiently extracting various types of resources from multiple DLL files. This tool simplifies the process of salvaging Icons, Bitmaps, Cursors, and PNG images embedded within dynamic link libraries. It features a user-friendly interface, customizable output management (including an archiving function to prevent accidental overwrites), and real-time logging, making it an ideal utility for developers, designers, or anyone needing to access embedded resources.

Built by: Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a GUI for extracting resources from DLL files.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses PowerShell's capabilities for GUI development and file manipulation.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **ResourceHacker.exe:** The external tool `ResourceHacker.exe` is required and must be accessible in your system's PATH. You can download it from [www.angusj.com/resourcehacker/](http://www.angusj.com/resourcehacker/).

## 💽 Installation & Execution
1.  **Download:** Download the `Batch DLL ResourceExtracter.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Install Resource Hacker:** Download and install `ResourceHacker.exe`, ensuring its executable is in your system's PATH environment variable.
4.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Batch DLL ResourceExtracter.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Upon launching the application, you will be presented with the main GUI:

1.  **Select DLL Files:**
    *   Click the **"Add Files..."** button in the "DLL Files" section to browse and select one or more DLL files.
    *   You can remove selected files or clear the entire list using the respective buttons.
2.  **Choose Resource Types:**
    *   In the "Resource Types to Extract" section, check the boxes next to "Icons", "BMP", "Cursors", and/or "PNG" to specify which types of resources you wish to extract.
3.  **Configure Output:**
    *   **"Output Directory:"**: Specify the root folder where extracted resources will be saved. Each DLL will have its own subfolder. The default is `G:\Extracted Resources`.
    *   **"Clear existing output sub-folder before extraction"**: Check this option with caution. If selected, any existing subfolder for a DLL will be deleted before new resources are extracted into it.
4.  **Start Extraction:**
    *   Click **"Start Extraction"** to begin the process. Progress and messages will be displayed in the "Log" text box.
5.  **Manage Extractions:**
    *   **"Archive Previous Extractions"**: Moves all existing content from your output directory into a new, timestamped subfolder named "Previously Extracted (YYYY-MM-DD_HH-MM-SS)", effectively archiving old results.
    *   **"Open Output Folder"**: Opens the specified output directory in Windows Explorer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-driven Resource Extraction:** Intuitive Windows Forms interface for easy batch processing of DLL files.
*   **Selective Resource Type Extraction:** Choose to extract Icons (`.ico`), Bitmaps (`.bmp`), Cursors (`.cur`, `.ani`), and/or PNG images (`.png`).
*   **Batch Processing Capability:** Efficiently process multiple DLL files in a single operation.
*   **Customizable Output Management:**
    *   Specify a root output directory for all extracted resources (defaulting to `G:\Extracted Resources`).
    *   Optionally clear existing target sub-folders for each DLL before extraction.
*   **Integrated Archiving System:** Prevents data loss by allowing users to archive all previous extractions into timestamped folders.
*   **Real-time Activity Log:** Displays detailed progress, status messages, and any errors during the extraction process directly within the GUI.
*   **Helpful Tooltips:** Provides descriptive tooltips for all interactive elements to guide the user.
*   **Direct Output Folder Access:** One-click button to open the designated output directory in Windows Explorer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging external tools and .NET components:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **External Tool:** `ResourceHacker.exe` as the backend engine for extracting resources from DLLs.
*   **File System Operations:** Standard PowerShell cmdlets (`New-Item`, `Remove-Item`, `Move-Item`, `Get-ChildItem`, `Join-Path`, `Test-Path`) for managing files and directories.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Batch Resource Extractor` integrates with an external utility and performs file system operations.

*   **External Tool Dependency:** The core functionality relies entirely on `ResourceHacker.exe`. Ensure this executable is from a trusted source. The script checks for its presence in the system PATH.
*   **File System Modification:** The script creates directories and extracts files to a user-specified output location. If the "Clear existing output sub-folder" option is checked, it will delete existing folders, which can lead to data loss if used carelessly.
*   **Hardcoded Default Output Path:** The default output path `G:\Extracted Resources` is hardcoded. Ensure this path is valid and writable, or change it within the script.
*   **Administrator Privileges (Potential):** Depending on the location of DLL files and the output directory, the script might require Administrator privileges to read/write files.
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
