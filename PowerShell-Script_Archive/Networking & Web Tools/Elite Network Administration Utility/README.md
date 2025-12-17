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

## Elite Network & Web Administration Suite

The `Elite Network & Web Administration Suite` is a definitive, all-in-one PowerShell application with a graphical user interface (GUI) for local web development, server management, and network administration. It combines a wide array of powerful tools into a single, cohesive suite, making it an indispensable utility for developers and system administrators. The application uses PowerShell for the frontend and orchestrates a series of embedded Python scripts to run robust backend services.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is an advanced, multi-functional suite. Please review the prerequisites carefully.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer** with .NET Framework 4.5+.
*   **Administrator Privileges:** The script requires administrator access for most of its functions and will attempt to self-elevate if not run as an administrator.
*   **Python 3.x:** Python must be installed and added to your system's PATH. This is a critical dependency for all server functionalities.
*   **Python `pyftpdlib` Library:** The FTP server requires this library. The script will detect if it's missing and offer to install it via `pip`.

## 💽 Installation & Execution
1.  **Download:** Download the `EliteNetworkAdministratoionUtility.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it. The script will automatically request administrator elevation.
    ```powershell
    .\EliteNetworkAdministratoionUtility.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Key Features

### Server Management
*   **Web Servers:** Create, configure, and run multiple local web servers. Supports HTTPS/SSL, custom 404 pages, and Basic Authentication.
*   **FTP Servers:** Easily set up local FTP servers for file management and testing.
*   **Proxy Servers:** Run simple TCP forwarding proxies to redirect network traffic.
*   **Email (SMTP) Sink:** A local SMTP server that catches all outgoing application emails, logs them, and saves them as `.eml` files for debugging.

### Certificate Authority
*   Create a local, self-signed Root Certificate Authority (CA).
*   Issue server certificates signed by your local Root CA.
*   Install the Root CA into the system's trusted stores to eliminate browser security warnings for local development.

### Network & System Utilities
*   **Hosts File Manager:** A full GUI for easily adding, editing, and removing entries in the Windows hosts file.
*   **Network Tools:** A dedicated tab with tools for Ping, Traceroute, and Port Scanning.
*   **Hotspot & Bridging:** Utilities to create a mobile hotspot and bridge network connections.
*   **Network Information Viewer:** A detailed breakdown of your system's IP, DNS, and adapter configurations.

### System Integration
*   **System Tray:** The application can be minimized to the system tray for unobtrusive background operation.
*   **Persistent Configuration:** All server configurations and UI settings are saved to JSON files in your `%APPDATA%` folder and reloaded on launch.
*   **Scheduled Task Helper:** Includes a function to create a scheduled task to automatically start selected servers when you log in.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Frontend/Orchestration:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend Servers:** Python (using embedded scripts for HTTP, FTP, SMTP, and Proxy services).
*   **Python Libraries:** `pyftpdlib` for the FTP server.
*   **System Interaction:** WMI, `netsh`, and various PowerShell cmdlets for network and certificate management.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Hybrid Architecture:** This suite uses a powerful hybrid model where the PowerShell GUI acts as a frontend controller for robust backend services written in Python.
*   **Development Focus:** This suite is intended for local development, testing, and administration. The servers are not hardened for production use.
*   **Administrator Access:** The script requires and will request administrator privileges to manage system-level settings like the hosts file, network adapters, and certificate stores.

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
