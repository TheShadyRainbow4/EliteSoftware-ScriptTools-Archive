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

## Icon Extractor Master

`Icon Extractor Master` is a Graphical User Interface (GUI) tool designed to search for executable files (`.exe`) within a directory and extract their associated icons. The extracted icons can be saved as `.ico` files to a specified output folder, making it easy to collect assets from applications.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool simplifies the process of harvesting icons from program files.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI and Drawing libraries.

## 💽 Installation & Execution
1.  **Download:** Download the `IconExtractor_Master.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\IconExtractor_Master.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a straightforward workflow:

1.  **Search:** Select a target folder to scan for executable files. You can choose to include subfolders (recursive search).
2.  **Visualize:** The tool displays a list of all found programs along with their extracted icons in a ListView.
3.  **Select:** Use the checkboxes to select the specific icons you wish to save.
4.  **Extract:** Click the extract button to bulk save the selected icons as `.ico` files to your chosen output directory.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Recursive Search:** Can scan deep into directory structures to find all executables.
*   **Visual Preview:** See the icons before you extract them.
*   **Bulk Extraction:** Save multiple icons at once with a single click.
*   **Sanitized Filenames:** Automatically handles file naming to ensure compatibility.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Icon Handling:** Utilizes `System.Drawing.Icon.ExtractAssociatedIcon` for retrieving icon data.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Read-Only Scan:** The script only reads the source files to extract icon data; it does not modify the executables.
*   **File System Access:** Requires read access to the source directories and write access to the output directory.

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