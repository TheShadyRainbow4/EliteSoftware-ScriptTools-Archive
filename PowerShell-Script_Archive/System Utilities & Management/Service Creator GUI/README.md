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

## Service Creator GUI v3.0.1.0

`Service Creator GUI` is a PowerShell script that provides a graphical user interface (GUI) for creating and managing Windows Services from any executable file. It uses the Non-Sucking Service Manager (NSSM) to wrap executables as services, simplifying the process of running applications in the background.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script simplifies the creation and management of Windows services.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's capabilities for GUI development and process management.
*   **Administrator Privileges:** The script requires administrator privileges to create and manage services, and will attempt to self-elevate if not run as an administrator.
*   **Internet Connection:** Required for the initial download of NSSM.

## 💽 Installation & Execution
1.  **Download:** Download the `Service-Creator-GUI.ZACH.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Service-Creator-GUI.ZACH.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a user-friendly interface for service management.

*   **Create Service Tab:**
    *   **Executable Path:** Browse to and select the executable you want to run as a service.
    *   **Service Name:** Provide a short, unique name for the service (no spaces).
    *   **Display Name:** Provide a descriptive name that will appear in the Services.msc console.
    *   Click **Create Service** to create the service.

*   **Manage Services Tab:**
    *   This tab lists all services created by this script.
    *   **Refresh:** Updates the list of services.
    *   **Stop & Disable:** Stops the selected service and sets its startup type to "Disabled".
    *   **Open Services.msc:** Opens the Windows Services console.
    *   **Delete Service:** Permanently deletes the selected service.

*   **About Tab:**
    *   Displays information about the application.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI for Service Creation:** Simplifies the process of creating Windows Services from executables.
*   **Automatic Dependency Management:** Automatically downloads and installs the Non-Sucking Service Manager (NSSM) if it's not found.
*   **Service Management:** Provides a simple interface to view, refresh, stop, disable, and delete services created by the script.
*   **Self-Elevation:** Automatically prompts for administrator privileges if not run as an administrator.
*   **Tabbed Interface:** Organizes functionality into "Create Service", "Manage Services", and "About" tabs.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, integrating with several key technologies:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Service Wrapper:** Non-Sucking Service Manager (NSSM) for creating and managing the underlying services.
*   **Process Management:** `System.Diagnostics.Process` for asynchronous execution and control of external processes.
*   **Operating System Interaction:** `Get-CimInstance`, `Stop-Service`, `Set-Service`, and `services.msc` for interacting with Windows Services.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Service Creator GUI` operates by interacting with local system services and files.

*   **Administrator Privileges:** The script requires administrator privileges to function correctly.
*   **NSSM Dependency:** The script downloads and executes `nssm.exe` from the official website. Ensure that you trust this executable.
*   **Service Creation:** The script creates Windows Services, which can have a significant impact on your system. Only create services from trusted executables.

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
