<a id="readme-top"></a>

<!-- EliteSoftware Co. LOGO -->

<br />
<div align="center">
<!-- <a href="Logo">
<!-- <img src="https://i.postimg.cc/85MDTcrJ/Elite-Software-LOGO-Mocup2.png" alt="Logo" width="256" height="256">
<!-- </a> -->
</div>

<!-- ABOUT THE PROJECT -->

# 💾 About The Project <div align="center">

## Network Information Viewer

`Network Information Viewer` is a PowerShell script that provides a graphical user interface (GUI) using Windows Forms to display detailed information about your system's network adapters. It organizes data into clear, tabbed sections for easy viewing.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a detailed view of your network configuration.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 10 or later recommended).
*   **PowerShell 5.1 or newer.**
*   **External Batch Script (Optional):** For the "Launch ipcfg.bat" button to function, a file named `ipcfg.bat` must exist in `C:\Windows\System32\`. This script could contain a command like `ipconfig /all`.

## 💽 Installation & Execution
1.  **Download:** Download the `Network Information Viewer.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ."Network Information Viewer.PS1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application window opens maximized and displays network information across three tabs:

*   **IP Address Tab:** Shows the IP addresses, subnet masks, default gateways, and DHCP information for each IP-enabled network adapter.
*   **DNS Configuration Tab:** Displays the DNS server search order for each adapter.
*   **Adapter Details Tab:** Provides general details for each adapter, such as its descriptive name, MAC address, link speed, and driver version.
*   **Launch ipcfg.bat Button:** At the bottom of the window, this button will execute the `ipcfg.bat` script from your `System32` folder, which is useful for quickly running commands like `ipconfig /all` in a separate console window.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Tabbed GUI:** Organizes complex network data into easy-to-read sections (IP Address, DNS, Adapter Details).
*   **Detailed Information:** Gathers and displays a comprehensive set of properties for all IP-enabled network adapters.
*   **Auto-Populated on Launch:** The script automatically gathers and displays the network information when the window is opened.
*   **External Script Launcher:** Includes a button to launch a custom network utility batch script (`ipcfg.bat`).
*   **DPI Aware:** The GUI is configured to scale correctly on high-DPI displays.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Data Source:** Retrieves network information primarily through WMI (`Win32_NetworkAdapterConfiguration`) and the `Get-NetAdapter` cmdlet.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Read-Only:** The script only reads and displays network information; it does not make any changes to your system's configuration.
*   **External Script:** The "Launch ipcfg.bat" button executes an external script. Ensure that the `ipcfg.bat` file in your `System32` directory is trusted.

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
