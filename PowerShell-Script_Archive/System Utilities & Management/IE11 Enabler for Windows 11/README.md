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

## IE11 Enabler for Windows 11

The `IE11 Enabler for Windows 11` is a PowerShell script that provides a simple graphical user interface (GUI) to re-enable and launch a standalone Internet Explorer 11 instance on Windows 11. It works by applying necessary registry modifications to prevent the automatic redirection to Microsoft Edge and then launches IE using a COM object.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is for advanced users or developers who need to access legacy websites or applications that require Internet Explorer 11.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows 11 Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script must be run as an administrator to modify the system registry.
*   **Internet Explorer Components:** The underlying IE11 components must still be present on the operating system.

## 💽 Installation & Execution
1.  **Download:** Download the `IE11 Enabler for Windows 11 v2.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell" or execute it from a PowerShell console that is running as an administrator.
    ```powershell
    ."\IE11 Enabler for Windows 11 v2.ps1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a straightforward interface for launching Internet Explorer 11.

1.  When the window opens, you can enter a specific URL into the text box. A default URL is provided.
2.  Click the **Enable & Launch Internet Explorer 11** button.
3.  The script will apply the required registry changes and then launch an IE11 window navigated to the specified URL.
4.  A status label at the bottom of the window will provide feedback on the process.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **One-Click Launch:** Applies necessary registry fixes and launches IE11 with a single button click.
*   **Disables Edge Redirection:** Modifies the registry to disable the Browser Helper Object (BHO) that forces IE to redirect to Microsoft Edge.
*   **Reverses Group Policy:** Sets the registry value to reverse the "Disable Internet Explorer 11 as a standalone browser" policy.
*   **COM-Based Launch:** Uses a COM object to reliably create a new, visible Internet Explorer instance.
*   **Administrator Check:** The script includes a check to ensure it is being run with the necessary administrator privileges.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Interacts with the Windows Registry and uses a COM object (`InternetExplorer.Application`) to control the browser.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`IE11 Enabler for Windows 11` directly modifies the Windows Registry.

*   **Administrator Privileges:** This script requires administrator access to write to the `HKEY_LOCAL_MACHINE` registry hive.
*   **Registry Changes:** The script modifies system policies related to Internet Explorer and its interaction with Microsoft Edge. These changes are necessary for the tool to function.
*   **Legacy Browser:** Internet Explorer 11 is a legacy browser that no longer receives feature updates and may lack modern security protections. Use it with caution and only for trusted, legacy applications.

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
