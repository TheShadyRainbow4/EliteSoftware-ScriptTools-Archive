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

## Batch DLL Resource Extractor

The `Batch DLL Resource Extractor` is a PowerShell utility with a graphical user interface (GUI) designed to extract embedded resources—such as icons, bitmaps, cursors, and PNGs—from multiple DLL files in a single operation. It provides a user-friendly way for developers, themers, and hobbyists to pull assets out of binary files.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool requires an external dependency to function.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Resource Hacker:** The `ResourceHacker.exe` command-line tool must be installed and accessible in your system's PATH. You can download it from the official site at [angusj.com/resourcehacker](http://www.angusj.com/resourcehacker/).

## 💽 Installation & Execution
1.  **Download:** Download the `Batch DLL ResourceExtracter.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ".\Batch DLL ResourceExtracter.PS1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a simple workflow for extracting resources.

1.  **Add Files:** Click the **Add Files...** button to select one or more `.dll` files you want to process.
2.  **Select Resource Types:** Check the boxes for the types of resources you wish to extract (Icons, BMP, Cursors, PNG).
3.  **Choose Output Directory:** Specify the main folder where the extracted resources will be saved. The script will automatically create a sub-folder for each DLL.
4.  **(Optional) Advanced Options:** You can choose to automatically clear an existing sub-folder before extraction begins.
5.  **Start Extraction:** Click the **Start Extraction** button to begin the process.
6.  **Monitor Progress:** The log window at the bottom will provide real-time updates on the files being processed and the results.

### Other Features
*   **Archive Previous Extractions:** Before starting a new batch, you can click this button to move all existing folders in your output directory into a new, timestamped "Previously Extracted" folder. This keeps your main output directory clean.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Batch Processing:** Add and process multiple DLL files at once.
*   **Selective Extraction:** Choose exactly which resource types you want to extract.
*   **Organized Output:** Automatically creates a dedicated sub-folder for each processed DLL, and a further sub-folder for each resource type within that.
*   **Live Logging:** A detailed log provides real-time feedback on the entire process.
*   **Archiving:** A convenient feature to clean up the output directory before starting a new session.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend:** `ResourceHacker.exe` (external dependency).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **External Dependency:** The functionality of this script is entirely dependent on the presence and accessibility of `ResourceHacker.exe` in the system's PATH.
*   **File System Operations:** The script reads the source DLLs and writes the extracted resource files to the user-specified output directory.

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