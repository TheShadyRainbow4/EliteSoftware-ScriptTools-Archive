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

## PowerShell GUI Template - Master Edition

This script, `COMPLEX-TEMPLATE.PS1`, is a comprehensive and modular template for building advanced PowerShell GUI applications. It serves as a foundation for developing complex tools with a consistent look and feel, robust architecture, and built-in features like configuration persistence and system tray integration.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is a template for developers to build upon.

## 🕰️ Prerequisites
To run or develop with this template, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Resource Structure:** The script expects a specific folder structure (`Resources\Icons`, `Resources\HTML`) to be present in the same directory for loading assets.

## 💽 Installation & Execution
1.  **Download:** Download the `COMPLEX-TEMPLATE.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console to see the template in action.
    ```powershell
    .\COMPLEX-TEMPLATE.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features & Architecture

### Modular Design
*   **Main Form:** A resizeable, center-screen window with a customizable layout.
*   **Navigation:** Uses a `TabControl` to separate different functional areas (Home, Browser, File Explorer).
*   **Split Containers:** Resizable panels allow users to adjust the layout to their preference.

### Advanced Capabilities
*   **Persistence:** Automatically saves and loads user settings (window size, font choices, layout positions) to a JSON file.
*   **System Tray:** Minimizes to the notification area with a context menu.
*   **Console Management:** Can toggle the visibility of the parent console window.
*   **Browser Integration:** Includes a `WebBrowser` control for displaying HTML content or web pages.
*   **File Explorer:** A functional file browser with tree view, list view, and icon support.

### Customization
*   **Theming:** Supports custom fonts and styles defined in the "Advanced Settings" dialog.
*   **Icons:** Loads application icons from external files, with fallback to generated bitmaps.
*   **Help System:** Built-in "Guidance System" dialog for documentation and changelogs.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Drawing:** GDI+ (`System.Drawing`) for custom rendering and gradients.
*   **Windows API:** P/Invoke for advanced window management (hiding console).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Template Status:** This code is intended to be modified. It contains placeholders and example logic (like `Add-ClickLogic`) that developers should replace with actual functionality.
*   **Resource Dependency:** The script relies on external files for icons and HTML content. Ensure these are deployed with the script.

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
