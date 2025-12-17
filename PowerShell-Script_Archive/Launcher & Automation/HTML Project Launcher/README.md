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

## HTML Project Launcher Professional

`HTML Project Launcher Professional` is an advanced PowerShell application that provides a professional-grade graphical user interface (GUI) for discovering, managing, and launching local HTML projects. It scans multiple user-defined folders, aggregates all found HTML files, and displays them in a powerful, sortable, and groupable list. The application also supports project-specific metadata and can generate a modern web-based dashboard to serve as a visual launchpad for all your projects.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script acts as a central hub for managing and accessing local web projects.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.

## 💽 Installation & Execution
1.  **Download:** Download the `HTML Project Launcher Professional.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\HTML Project Launcher Professional.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a comprehensive interface for managing your HTML projects.

*   **Main List View:** The central part of the application lists all discovered HTML projects. You can sort by clicking on column headers or group by various attributes using the "View" menu.
*   **Managing Project Folders:** Use the `File -> Manage Project Folders...` menu to add or remove directories that the application should scan for projects.
*   **Launching a Project:** Double-click a project in the list or right-click and select "Open Project" to launch it in your default web browser. A small navigation overlay will be injected into the page to allow you to go back or return to the main dashboard.
*   **Web Dashboard:** Click the **View Dashboard in Browser** button (or use the "Tools" menu) to generate and open a `dashboard.html` file. This dashboard provides a modern, tile-based interface to visually browse and launch your projects.
*   **Metadata:** Right-click a project and select "Edit Metadata..." to add or edit information like "Author" and "Version," which is stored in a separate `.meta.json` file alongside the project.
*   **Ignoring Files:** If you want to hide a specific file from the list, right-click it and select "Ignore File." You can manage your ignored files from the `Tools -> Manage Ignored Files...` menu.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Multi-Folder Scanning:** Aggregates HTML projects from multiple source directories into a single interface.
*   **Dynamic Web Dashboard:** Generates a modern, themeable (light/dark), and responsive (grid/list) HTML dashboard for visually launching projects.
*   **Metadata Support:** Stores and edits project metadata (e.g., Author, Version) in associated `.meta.json` files.
*   **In-App Navigation:** Injects a simple "Back" and "Home" navigation overlay into launched projects for a seamless experience.
*   **Powerful List Management:** The main project list can be sorted by any column and grouped by attributes like folder, date, or author.
*   **Persistent Configuration:** Saves all settings, including source folders, window size, and ignored files, to a local `config.json` file.
*   **File Cleanup Utilities:** Includes tools to clean up temporary and generated files, such as the dashboard and metadata files.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell 5.1+
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Data Handling:** Uses JSON for configuration (`config.json`) and metadata (`.meta.json`) files.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **File Injection:** The "launch" feature modifies the target HTML file to inject a small CSS/HTML navigation snippet. It is designed to be non-destructive but modifies the source file in place.
*   **Local Operations:** The script operates entirely on the local file system. It reads and writes files within your project directories and its own configuration directory.

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