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

## Make Chrome Enterprise (Manifest V2 Enabler)

`Make Chrome Enterprise` is a PowerShell script designed for advanced users who wish to continue using Manifest V2 extensions (such as uBlock Origin) in Google Chrome after their official deprecation. The script modifies the Windows Registry to simulate an enterprise policy that re-enables support for these extensions.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script modifies the Windows Registry to allow the installation of Manifest V2 extensions in Google Chrome.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script must be run as an administrator to modify the required registry keys.

## 💽 Installation & Execution
1.  **Download:** Download the `MakeChromeEnterprise.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Right-click the script and select "Run with PowerShell" or execute it from a PowerShell console that is running as an administrator.
    ```powershell
    .\MakeChromeEnterprise.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Running the script performs the necessary registry modification automatically. After the script completes successfully, it will display a set of instructions in the console window for you to follow.

*   **Manual Extension Installation (Post-Script):**
    1.  Download the `.zip` file for your desired Manifest V2 extension (e.g., from the official GitHub page for uBlock Origin).
    2.  Extract the contents to a permanent folder on your computer.
    3.  Open Chrome and navigate to `chrome://extensions`.
    4.  Enable **Developer mode**.
    5.  Click **Load unpacked** and select the folder where you extracted the extension.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automated Registry Modification:** Automatically creates and sets the required `ExtensionManifestV2Availability` policy for Google Chrome.
*   **Enables Manifest V2 Extensions:** Allows for the continued use of powerful extensions that have not been updated to Manifest V3.
*   **Clear User Instructions:** Provides detailed, step-by-step guidance on how to manually install an extension after the registry has been modified.
*   **Error Handling:** Includes basic error handling and will pause on exit for the user to read any messages.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **Core Components:** Uses built-in PowerShell cmdlets (`New-Item`, `Set-ItemProperty`, `Test-Path`) to interact with the Windows Registry.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Make Chrome Enterprise` directly modifies the Windows Registry.

*   **Administrator Privileges:** This script requires administrator access to write to the `HKEY_LOCAL_MACHINE` registry hive.
*   **Registry Changes:** The script adds a policy to `HKLM:\SOFTWARE\Policies\Google\Chrome`. This is the standard location for enterprise policies and is generally safe. However, modifying the registry always carries some risk.
*   **Third-Party Extensions:** This script only enables the *ability* to install Manifest V2 extensions. The security of the extensions you choose to install is your own responsibility. Only install extensions from trusted sources.

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
