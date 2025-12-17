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

## HTML File Launcher

The `HTML File Launcher` is a specialized PowerShell utility designed to serve as a launchpad for local HTML files. It provides a clean and professional GUI that can list HTML files from a specific directory (or directories), allowing users to open them with a single click. It's particularly useful for organizing collections of local web projects, documentation, or reports.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script simplifies the management and access of your local HTML files.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.

## 💽 Installation & Execution
1.  **Download:** Download the `AAA_HTML_FILE_LAUNCHER_2025-07-12_22-13-24 .PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    ".\AAA_HTML_FILE_LAUNCHER_2025-07-12_22-13-24 .PS1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a list view of HTML files.

1.  **Launch:** Run the script. It will scan its pre-configured source folders (or the current directory) for `.html` files.
2.  **View:** The files are displayed in a list with details like "Date Modified" and "Author" (if available in metadata).
3.  **Open:** Double-click any file in the list to open it in your default web browser.
4.  **Manage:** Use the "File" menu to add or remove folders to scan. Use the "View" menu to change how the files are grouped or sorted.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Instant Startup:** Optimized for quick loading and immediate usability.
*   **Multi-Folder Support:** Can aggregate files from multiple different directories into a single view.
*   **Metadata Awareness:** Checks for accompanying `.meta.json` files to display extra information like Author and Version.
*   **Dashboard Generation:** Includes a tool to generate a "Dashboard" HTML page that provides a visual index of all your files.
*   **Navigation Injection:** Automatically injects a small "Back" button overlay into opened HTML files to easily return to the launcher (optional/configurable).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **File Handling:** Standard PowerShell `Get-ChildItem` for scanning.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Local File Access:** The script scans local directories.
*   **Content Modification:** When launching a file, the script may temporarily modify it to inject navigation aids. This is designed to be non-destructive but modifies the file content in memory or on disk depending on the specific implementation version.

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