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

## File Association Manager

The `File Association Manager` is a PowerShell utility with a graphical user interface (GUI) designed to easily create, modify, and remove custom file type associations in Windows. It allows users to link specific file extensions to applications, set descriptions, and configure command-line arguments without manually editing the registry.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool simplifies the process of defining how Windows handles specific file types.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Administrator Privileges (Optional):** Required only if you wish to create file associations for "All Users" (HKLM). Single-user associations (HKCU) do not require elevation.

## 💽 Installation & Execution
1.  **Download:** Download the `File-Association-Manager-GUI.ZACH.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\File-Association-Manager-GUI.ZACH.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a form to define the details of your file association.

1.  **File Extension:** Enter the extension you want to manage (e.g., `.log`, `.myext`).
2.  **Programmatic ID (ProgID):** Create a unique identifier for this file type (e.g., `MyApp.LogFile.1`).
3.  **File Description:** Enter a friendly description that will appear in File Explorer (e.g., "My Application Log File").
4.  **Application Path:** Use the **Browse...** button to select the executable (`.exe`) that should open this file type.
5.  **Command Arguments:** Specify any command-line arguments. The default `"%1"` passes the file path to the application.
6.  **Register for All Users:** Check this box to apply the association system-wide (requires Admin rights).
7.  **Create / Update Association:** Click this button to apply the changes to the registry.
8.  **Remove Association:** Click this button to delete the registry keys for the specified Extension and ProgID.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **User-Friendly GUI:** A clean interface for managing complex registry settings.
*   **Browse Functionality:** Easily locate the target application executable.
*   **Dual Scope Support:** Create associations for the current user (HKCU) or all users (HKLM).
*   **Help & Examples:** Built-in help window with clear examples of how to configure associations for common scenarios.
*   **Stability:** Automatically relaunches in Single-Threaded Apartment (STA) mode to prevent GUI crashes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Direct interaction with the Windows Registry (`New-Item`, `Set-ItemProperty`, `Remove-Item`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Registry Modification:** This script works by creating and modifying keys in `HKEY_CURRENT_USER\Software\Classes` or `HKEY_LOCAL_MACHINE\Software\Classes`.
*   **Administrator Access:** Writing to `HKEY_LOCAL_MACHINE` ("All Users") is a privileged operation and requires the script to be run as Administrator.
*   **Safety:** The script includes checks to ensure necessary fields are populated before attempting registry operations.

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
