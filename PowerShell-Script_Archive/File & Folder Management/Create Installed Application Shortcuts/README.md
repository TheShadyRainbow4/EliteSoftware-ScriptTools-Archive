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

## Application Shortcut Creator

The `Application Shortcut Creator` is a PowerShell utility with a graphical user interface (GUI) built using WPF (Windows Presentation Foundation). It is designed to help users easily find and create shortcuts for applications on their system, including officially installed programs, portable apps, and system tools.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool simplifies the process of finding applications and creating shortcuts for them.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the WPF-based GUI.

## 💽 Installation & Execution
1.  **Download:** Download the `CreateApplicationShotcuts.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\CreateApplicationShotcuts.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a simple two-step process: scan for applications, then create a shortcut.

### 1. Scan for Applications
Choose one of the available methods to find applications:
*   **Scan Registry:** Scans the Windows Registry to find applications that were installed via a standard installer.
*   **Deep Scan All Drives:** Scans the `Program Files` and `Program Files (x86)` directories on **all** connected drives. This is useful for finding portable applications or programs installed in non-standard locations. This may take some time.
*   **Manual Scan Tab:** Use the **Choose Folder to Scan...** button to select any specific drive or folder to scan for executables.
*   **System Apps Tab:** This tab is pre-populated with a list of common Windows system tools like Notepad, Calculator, and Registry Editor.

### 2. Create Shortcut
1.  After a scan is complete, select the desired application from the list in any of the tabs.
2.  Click the **Browse...** button at the bottom of the window to choose a destination folder for your shortcut (e.g., your Desktop).
3.  Click the **Create Shortcut** button. A `.lnk` file for the selected application will be created in the destination folder.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Multiple Scan Methods:** Provides several ways to discover applications, including registry scanning, deep drive scanning for portable apps, and manual folder scanning.
*   **Organized Results:** Found applications are neatly organized into tabs based on the scan method used.
*   **Simple Shortcut Creation:** A straightforward, two-step process to create shortcuts in any folder you choose.
*   **Modern GUI:** Uses WPF to provide a clean and responsive user interface.
*   **Status and Progress:** A status bar and progress bar provide feedback during long-running scan operations.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** Windows Presentation Foundation (WPF).
*   **Discovery:** Uses a combination of registry queries (`Get-ItemProperty`) and file system searches (`Get-ChildItem`) to find applications.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Read-Only Scanning:** The scanning functions only read information from the registry and file system; they do not modify any existing applications or system settings.
*   **Shortcut Creation:** The script's only write operation is the creation of a `.lnk` file in the user-specified destination folder.

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