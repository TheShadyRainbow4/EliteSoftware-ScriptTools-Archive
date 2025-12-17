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

## Linker & Mover Utility

The `Linker & Mover Utility` is a comprehensive GUI application designed to simplify the management of file system links (symbolic links, directory junctions) and advanced file moving operations. It streamlines complex tasks like moving a directory to a new drive and automatically creating a link back to the original location, ensuring seamless operation for applications.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool provides advanced file system management capabilities.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Administrator Privileges:** Creating symbolic links often requires administrative rights. The script will attempt to self-elevate if necessary.

## 💽 Installation & Execution
1.  **Download:** Download the `Link  & Mover Utility.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\Link  & Mover Utility.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application offers several modes of operation:

1.  **Create Links:** Manually create file symbolic links, directory symbolic links, or directory junctions.
2.  **Bulk Move & Link:** Select a source directory and a destination. The utility will move the entire directory to the new location using `robocopy` and automatically create a link (symlink or junction) at the original location pointing to the new one. This is ideal for moving large games or applications to a different drive without breaking them.
3.  **Selective Move & Link:** Choose specific files or folders within a directory to move and link individually.
4.  **Visual Previews:** A live preview panel shows details about selected items, including icons and sizes.
5.  **Activity Log:** A persistent log viewer tracks all operations for review.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Advanced Link Management:** Supports all major Windows link types (Symbolic File, Symbolic Directory, Junction).
*   **Automated Moving:** Uses `robocopy` for robust and reliable file transfers.
*   **Seamless Redirection:** Automatically replaces moved content with links, maintaining file paths for software compatibility.
*   **Return Links:** Optionally create a shortcut at the destination to easily navigate back to the source.
*   **User-Friendly GUI:** Visual interface simplifies complex command-line operations like `mklink`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **System Tools:** `robocopy` for file operations, `cmd.exe /c mklink` for link creation, `WScript.Shell` for shortcuts.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Administrator Rights:** The script requires admin privileges to create symbolic links, which is a Windows security restriction.
*   **Legacy Compatibility:** Uses `cmd.exe` to invoke `mklink` ensuring compatibility with older PowerShell versions that lack native link cmdlets.

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