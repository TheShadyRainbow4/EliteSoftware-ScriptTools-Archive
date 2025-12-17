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

## Metadata Editor

The `Metadata Editor` is a GUI-based tool designed to view and edit metadata for both files and folders. It provides a convenient interface for modifying standard file properties and leverages system capabilities to customize folder attributes like comments (InfoTips) and tags.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool helps you organize and tag your files and folders.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.

## 💽 Installation & Execution
1.  **Download:** Download the `MetaData Editor Tool.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\MetaData Editor Tool.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application features a dynamic interface for editing properties.

1.  **Select Item:** Choose a file or folder to edit.
2.  **Edit File Metadata:** For files, you can modify standard properties like Title, Subject, Authors, and media-specific tags like Artist and Album. The tool uses the Windows Shell to access these extended properties.
3.  **Edit Folder Metadata:** For folders, the tool allows you to set a custom "InfoTip" (which appears as a comment when hovering) and tags. It achieves this by creating or modifying the `desktop.ini` file within the folder.
4.  **Save:** Apply your changes to write the metadata back to the item.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Unified Interface:** Handle both file and folder metadata in one tool.
*   **Folder Customization:** Easily add comments to folders using `desktop.ini` manipulation.
*   **Extensive Properties:** Supports a wide range of file properties including details for documents, music, and images.
*   **Dynamic UI:** The property editing grid is generated dynamically based on the selected item type.
*   **Safe Handling:** Reads and writes `desktop.ini` files carefully to preserve existing system attributes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **COM Object:** `Shell.Application` for accessing file extended properties.
*   **System:** `desktop.ini` file manipulation for folder customization.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **System Files:** When customizing folders, the script creates a hidden, system-marked `desktop.ini` file inside the folder. This is standard Windows behavior for folder customization.
*   **COM Interaction:** The script relies on the Windows Shell COM object, ensuring compatibility with how Windows Explorer sees metadata.

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