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

## PowerShell Winget Interface (Enhanced v2.5)

This script, `WingetSearch_Enhanced.PS1`, is an alternative version of the PowerShell Winget Interface. Like its successor, it offers both a text-based Shell mode and a graphical GUI mode for managing software via the Windows Package Manager (`winget`). It allows for searching, installing, upgrading, and uninstalling applications.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool provides a flexible way to interact with `winget`.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 10 Version 1709 or later).
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the GUI mode.
*   **Windows Package Manager (`winget`):** Must be installed.

## 💽 Installation & Execution
1.  **Download:** Download the `WingetSearch_Enhanced.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\WingetSearch_Enhanced.PS1
    ```
4.  **Choose Mode:** Enter `1` for Shell Mode or `2` for GUI Mode when prompted.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features

### GUI Mode
A graphical window providing:
*   **Search Bar:** Quickly find packages by name.
*   **Results List:** Displays package Name, ID, Version, and Availability.
*   **Actions:** Install, Upgrade, or Uninstall selected packages via buttons.
*   **Status Bar:** Shows current operation and package counts.

### Shell Mode
A menu-driven command-line interface offering:
*   **Package Search:** Search for software directly in the terminal.
*   **Listing:** View all currently installed `winget` packages.
*   **Management:** Interactive prompts to install, upgrade, or uninstall packages by ID.
*   **Source Management:** View configured package sources.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend:** Windows Package Manager (`winget.exe`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Wrapper:** This script processes user input and constructs `winget` commands to execute in the background.
*   **Dependencies:** Functionality is entirely dependent on the `winget` executable being present in the system PATH.

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
