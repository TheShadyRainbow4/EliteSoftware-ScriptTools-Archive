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

## PS1 to JSON Converter

`PS1 to JSON Converter` is a utility script that provides a graphical user interface (GUI) to find all PowerShell scripts (`.ps1` files) in a chosen directory and its subdirectories, and then compile them into a single JSON file. Each entry in the JSON file contains the full path to the script and its complete text content. This is useful for batch processing, analysis, or preparing script data for other applications or AI models.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script simplifies the process of aggregating multiple PowerShell scripts into one structured data file.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.

## 💽 Installation & Execution
1.  **Download:** Download the `Batch PS1 - single JSON.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    ."\Batch PS1 - single JSON.ps1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application guides you through the process with a simple interface.

1.  Click the **Select Folder and Convert** button.
2.  A dialog will appear prompting you to select the source folder you want to scan for `.ps1` files.
3.  After selecting a folder, the script will scan it recursively. The status label will update with the number of files found.
4.  A "Save File" dialog will then appear, allowing you to choose the location and name for the output JSON file.
5.  Once you save the file, the script will read all the PowerShell files and write their contents to the specified JSON file.
6.  A confirmation message will appear upon completion.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Simple GUI:** An easy-to-use interface for selecting folders and saving the output.
*   **Recursive Search:** Automatically scans all subdirectories of the chosen folder.
*   **JSON Compilation:** Aggregates the full path and content of each `.ps1` file into a structured JSON array.
*   **User-Guided Process:** Uses standard Windows dialogs for folder selection and file saving.
*   **Status Feedback:** Provides real-time updates on the conversion process directly in the GUI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Utilizes `Get-ChildItem` for file system traversal and `ConvertTo-Json` for data serialization.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Read-Only Operation:** The script only reads from the source directory and does not modify any of the original `.ps1` files.
*   **User-Specified Output:** The script writes a single JSON file to a location of the user's choosing.

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
