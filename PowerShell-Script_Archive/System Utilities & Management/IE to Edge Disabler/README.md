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

## IE to Edge Redirection Manager

The `IE to Edge Redirection Manager` is a simple PowerShell script with a graphical user interface (GUI) that allows you to control whether Internet Explorer 11 automatically redirects sites to Microsoft Edge. This tool provides an easy way to enable or disable this behavior by modifying the corresponding system registry key.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a simple toggle for the IE-to-Edge redirection policy.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 10 or 11).
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the WPF-based GUI.
*   **Administrator Privileges:** The script must be run as an administrator to modify the system registry.

## 💽 Installation & Execution
1.  **Download:** Download the `IE_to_Edge_Disabler.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell" or execute it from a PowerShell console that is running as an administrator.
    ```powershell
    .\IE_to_Edge_Disabler.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a straightforward interface with two main actions.

*   **Status:** The text box in the middle of the window displays the current status of the redirection policy. It will tell you if redirection is currently enabled or disabled.
*   **Disable Redirection:** Click this button to set the registry policy that prevents Internet Explorer from automatically redirecting to Microsoft Edge.
*   **Enable Redirection:** Click this button to remove the registry policy, restoring the default system behavior where IE will redirect to Edge.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Simple GUI:** A clean, easy-to-use interface built with WPF.
*   **One-Click Toggle:** Enable or disable the IE-to-Edge redirection policy with a single button click.
*   **Clear Status Indicator:** Immediately see whether the redirection policy is active or not.
*   **Administrator Check:** The script verifies that it is running with administrator privileges before attempting to make changes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** Windows Presentation Foundation (WPF).
*   **Core Logic:** Modifies the `RedirectSitesFromInternetExplorerToMicrosoftEdge` DWORD value in the `HKLM:\SOFTWARE\Policies\Microsoft\Edge` registry path.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`IE to Edge Redirection Manager` directly modifies the Windows Registry.

*   **Administrator Privileges:** This script requires administrator access to write to the `HKEY_LOCAL_MACHINE` registry hive.
*   **Registry Modification:** The script modifies a Group Policy setting in the registry. This is a standard and safe way to manage this specific system behavior.

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
