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

## Advanced Startup Manager

The `Advanced Startup Manager` is a comprehensive PowerShell utility with a rich graphical user interface (GUI) built using WPF (Windows Presentation Foundation). It provides a centralized and powerful platform for viewing, managing, and analyzing all auto-starting applications, scheduled tasks, and system services on a Windows machine. This tool consolidates functionality from multiple system utilities (Task Manager, Task Scheduler, Services) into a single, feature-rich application.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is an advanced system utility designed for power users and system administrators.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework 4.5 or later:** Required for the WPF-based GUI.
*   **Administrator Privileges:** The script requires administrator access for full functionality and will attempt to self-elevate if not run as an administrator.

## 💽 Installation & Execution
1.  **Download:** Download the `AdvancedStartupManager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it. The script will automatically request administrator elevation.
    ```powershell
    .\AdvancedStartupManager.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features
The application is organized into three main tabs, each packed with features.

### Startup Apps
*   **Comprehensive Listing:** Displays startup items from all common locations, including multiple registry hives and system-wide startup folders.
*   **Modern App Support:** Correctly identifies and manages the enabled/disabled state of modern startup apps.
*   **Multiple Views:** View items in a detailed data grid or a more visual icon-based layout.
*   **Full Management:** Enable, disable, delete, or add new startup applications.
*   **Rich Details:** Shows application icons, publisher information, and digital signature status.

### Scheduled Tasks
*   **Complete Overview:** Lists all configured scheduled tasks on the system.
*   **Full Control:** Enable, disable, delete, or manually trigger any task from the list.
*   **Detailed Information:** Displays the task's path, state, last run time, and next run time.

### Services
*   **Service Management:** Lists all system services, similar to `services.msc`.
*   **Service Control:** Start, stop, or change the startup type (Automatic, Manual, Disabled) of any service.
*   **Detailed Tooltips:** Hover over a service to see its full description and the path to its executable.

### Universal Features
*   **Search, Sort, and Group:** Each tab features powerful controls to search, sort, and group items to quickly find what you're looking for.
*   **Rich Context Menus:** Right-click on an item to access a context menu with advanced options like "Open File Location," "Properties," "Verify Digital Signature," "Check on VirusTotal," and "Open in Registry Editor."
*   **JSON Export:** Back up the list of items from any tab to a structured JSON file.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** Windows Presentation Foundation (WPF).
*   **System Interaction:** Utilizes a combination of PowerShell cmdlets (`Get-ScheduledTask`, `Get-CimInstance`), .NET classes, and registry queries to gather and manage system information.

<p align="-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Administrator Required:** The script's core functionality relies on having administrator privileges to read and write to protected system locations. It includes a self-elevation mechanism.
*   **System Modification:** This tool can make significant changes to your system's configuration (disabling services, deleting startup items, etc.). Use it with care.
*   **External Lookups:** The "Check on VirusTotal" feature will open your default web browser and navigate to the VirusTotal website with the file hash of the selected item.

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
