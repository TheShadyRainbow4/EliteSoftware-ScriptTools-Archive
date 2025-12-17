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

## Zach's Advanced Network Manager

`Zach's Advanced Network Manager` is a PowerShell script that provides a graphical user interface (GUI) built with Windows Presentation Foundation (WPF) for managing network adapters. It allows for easy viewing of adapter details, configuration of IP and DNS settings, and enabling/disabling of adapters.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a comprehensive interface for managing network adapters.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 10 or later recommended).
*   **PowerShell 5.1 or newer:** This script uses modern networking cmdlets.
*   **.NET Framework 4.5 or later:** Required for the WPF-based GUI.
*   **Administrator Privileges:** The script requires administrator privileges to manage network settings.

## 💽 Installation & Execution
1.  **Download:** Download the `NetworkManager.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console with administrator privileges.
    ```powershell
    .\NetworkManager.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a detailed view and control over your network adapters.

*   **Adapter List:**
    *   The left panel lists all available network adapters on your system.
    *   Click the **Refresh Adapters** button to update this list.
*   **Adapter Details & IP Configuration:**
    *   Select an adapter to view its details, including name, description, and status.
    *   You can toggle DHCP or set a static IP address, subnet mask, and default gateway.
    *   You can also toggle automatic DNS or provide a custom list of DNS servers.
    *   Click **Apply IP/DNS Settings** to save your changes.
*   **Adapter Actions:**
    *   **Enable/Disable Adapter:** The buttons at the bottom of the details panel allow you to enable or disable the selected network adapter.
*   **Network Bridges:**
    *   The bottom of the details panel displays information about any network bridges on your system.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **WPF-based GUI:** A modern and responsive user interface for network management.
*   **Comprehensive Adapter Details:** Displays detailed information about each network adapter.
*   **IP and DNS Configuration:** Allows for easy switching between DHCP and static IP configurations, and automatic or manual DNS settings.
*   **Adapter Control:** Provides buttons to enable and disable network adapters.
*   **Network Bridge Information:** Displays information about any configured network bridges.
*   **Administrator Check:** The script will exit if not run with administrator privileges.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, integrating with several key technologies:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** Windows Presentation Foundation (WPF) for the graphical user interface.
*   **Networking Modules:** `NetAdapter` and `DnsClient` modules for managing network settings.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Zach's Advanced Network Manager` interacts with your system's network configuration.

*   **Administrator Privileges:** The script requires administrator privileges to function correctly.
*   **Network Configuration:** Changing network settings can affect your internet connectivity. Use this tool with caution.

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
