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

## Folder & Duplicate Scanner

The `Folder & Duplicate Scanner` is a feature-rich Windows Forms GUI tool for analyzing folder contents. It serves two main purposes: scanning folders to generate detailed reports (TXT, CSV, HTML) and identifying duplicate files based on content (MD5 hashing).

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool provides a powerful way to audit your file storage and recover space.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.

## 💽 Installation & Execution
1.  **Download:** Download the `FolderScanner.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\FolderScanner.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage

### Folder Scanner Tab
This tab allows you to generate a comprehensive list of files in a directory.
1.  **Folder to Scan:** Select the directory you want to analyze.
2.  **Save Location:** Choose where the report file will be saved.
3.  **Output Format:**
    *   **Text File (.txt):** A simple, tree-like structure of your folders.
    *   **CSV File (.csv):** A structured data file suitable for opening in Excel.
    *   **Interactive HTML File (.html):** A modern, sortable, and searchable web page report.
4.  **Advanced Options:**
    *   **Calculate MD5 Hash:** Enables precise content identification (slower but more accurate).
    *   **Filter:** Only scan for specific file extensions (e.g., `.jpg,.png`).

### Duplicate Finder Tab
This tab helps you find redundant files.
1.  **Scan Mode:**
    *   **Scan a folder:** Perform a fresh scan of a directory to find duplicates immediately.
    *   **Analyze a report:** Re-use a previously generated CSV or TXT report to find duplicates without re-scanning the drive.
2.  **Find Duplicates:** Click the button to start the process. The results list will show groups of files that have identical content (matching MD5 hashes).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Recursive Scanning:** Deeply scans all subfolders of the target directory.
*   **Multiple Report Formats:** Flexible output options to suit different needs (Text, Excel-ready CSV, or Web Report).
*   **Content-Based Matching:** Uses MD5 hashing to find true duplicates, even if they have different filenames.
*   **Interactive HTML Reports:** The HTML output includes built-in search and sorting capabilities, making it easy to navigate large file lists.
*   **Settings Persistence:** Remembers your custom application icon setting between sessions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Algorithms:** MD5 Hashing for file comparison.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Read-Only:** The script primarily reads file metadata and content (for hashing). It does not delete or modify your files automatically.
*   **Performance:** Calculating MD5 hashes for large files (like videos) can take time. The interface includes a progress bar to indicate activity.
*   **Console Hiding:** Uses P/Invoke (`kernel32.dll`) to hide the console window on launch.
*   **Configuration:** Stores settings in `$env:APPDATA\GeminiFolderScanner`.

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