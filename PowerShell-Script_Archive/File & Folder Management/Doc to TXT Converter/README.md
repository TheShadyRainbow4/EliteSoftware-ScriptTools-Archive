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

## Word to TXT Converter

The `Word to TXT Converter` is a simple PowerShell utility with a graphical user interface (GUI) for batch converting Microsoft Word documents (`.doc` and `.docx`) into plain text (`.txt`) files. The script recursively scans a selected source folder and saves the converted text files to a chosen destination folder.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool leverages your local installation of Microsoft Word to perform conversions.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Microsoft Word:** This script requires a local installation of Microsoft Word to be present on your system. It will not work without it.

## 💽 Installation & Execution
1.  **Download:** Download the `Doc-Docx to TXT Converter.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ".\Doc-Docx to TXT Converter.ps1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a simple interface to guide you through the conversion process.

1.  **Select Source Folder:** Click the "Browse..." button in the "Source Folder" section to choose the directory containing the Word documents you want to convert. The script will scan this folder and all its subdirectories.
2.  **Select Destination Folder:** Click the "Browse..." button in the "Destination Folder" section to choose where the converted `.txt` files will be saved.
3.  **Start Conversion:** Click the **Start Conversion** button to begin the process.
4.  **Monitor Progress:** The "Progress Log" window will display real-time updates, showing which files are being converted and whether each conversion was a success or failure.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Simple GUI:** An easy-to-use interface for selecting source and destination folders.
*   **Batch Conversion:** Automatically finds and converts all `.doc` and `.docx` files in the source directory tree.
*   **Recursive Scanning:** Scans all subfolders within the selected source directory.
*   **Live Progress Log:** Provides real-time feedback on the conversion process.
*   **COM Automation:** Utilizes the Microsoft Word application in the background to ensure high-fidelity text extraction.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Interacts with the Microsoft Word COM Object (`Word.Application`) to open and save documents.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Microsoft Word Dependency:** This script is entirely dependent on a local installation of Microsoft Word. It automates the Word application in the background to perform the conversion.
*   **Read-Only on Source:** The script only reads the source documents; it does not modify or delete them.
*   **COM Object Usage:** The script creates and releases a `Word.Application` COM object. This is a standard way to automate Microsoft Office applications.

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
