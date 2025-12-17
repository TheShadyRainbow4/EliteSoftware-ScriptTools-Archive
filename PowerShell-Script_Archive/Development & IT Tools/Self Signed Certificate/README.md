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
## Screenshot may be slightly outdated. Sorry in advance! :)  
<br />
<div align="center">
<!-- <a href="Screenshot"> -->
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720"> -->
<!-- </a> -->
</div>

## Self-Signed Certificate Utility v1.0

The `Self-Signed Certificate Utility` is a user-friendly PowerShell GUI application built with Windows Forms, designed to simplify the creation and establishment of trust for self-signed SSL certificates. This tool is invaluable for local development environments, particularly when working with web servers like IIS, as it allows you to generate a custom certificate for `localhost` (or other local DNS names) and automatically install it into your system's "Trusted Root Certification Authorities" store, thereby resolving common browser security warnings.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a straightforward way to create and trust self-signed SSL certificates for local development.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's built-in certificate management cmdlets.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **Administrator Privileges:** The script *must* be run as an Administrator to modify the local computer's certificate stores.

## 💽 Installation & Execution
1.  **Download:** Download the `SelfSigned_Certificate.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** Open a PowerShell console **as Administrator** and execute the script:
    ```powershell
    .\SelfSigned_Certificate.PS1
    ```
    If you are not running as Administrator, the script will display a warning and exit.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Upon launching the application, you will find a simple interface:

1.  **Certificate Details:**
    *   **"DNS Name (e.g., localhost, my.site):"**: Enter the DNS name(s) for which the certificate should be valid (e.g., `localhost`).
    *   **"Friendly Name (for easy identification):"**: Provide a memorable name for the certificate (e.g., `My Local Dev Cert`).
    *   **"Validity Period (Years):"**: Specify how many years the certificate should be valid.
2.  **"Generate & Install Certificate" Button:**
    *   Click this button to create the self-signed certificate and install it into the trusted root store.
    *   The "Log" text box will display the progress and outcome of the operation.
3.  **Review Log:** The "Log" section will provide feedback on whether the certificate was successfully created and installed. In case of errors, relevant messages will be displayed here.
4.  **Completion:** Upon successful installation, a message box will confirm the process. You may need to restart your web browser or IIS for the changes to take effect.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-driven Certificate Creation:** User-friendly Windows Forms interface for effortless generation of self-signed SSL certificates.
*   **Customizable Certificate Properties:** Easily define the certificate's DNS Name (Common Name), a descriptive Friendly Name, and its Validity Period (in years).
*   **Automated Trust Establishment:** Automatically installs the newly generated certificate into the "Trusted Root Certification Authorities" store on your local machine, resolving browser security warnings for local development sites.
*   **Administrator Privileges Check:** Ensures the script is run with the necessary elevated permissions for secure certificate store access.
*   **Integrated Activity Log:** Provides real-time feedback and status updates within the GUI's log area.
*   **Error Reporting:** Clear error messages are displayed both in the GUI log and via message boxes if any issues arise during the certificate generation or installation process.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging its powerful .NET integrations and built-in cmdlets:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Certificate Management:** PowerShell's specialized cmdlets for certificate operations:
    *   `New-SelfSignedCertificate`: For generating the self-signed SSL certificate.
    *   `Cert:\LocalMachine\My` and `Cert:\LocalMachine\Root`: For accessing and manipulating certificate stores.
*   **Security Context:** `System.Security.Principal.WindowsPrincipal` for checking and enforcing Administrator privileges.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `Self-Signed Certificate Utility` performs operations that modify your system's security settings.

*   **Administrator Privileges:** The script requires Administrator privileges because it installs certificates into the local machine's trusted certificate stores. These are system-wide security settings.
*   **Local Use Only:** Certificates generated by this tool are self-signed and are intended *only* for local development and testing environments. They should *never* be used for public-facing production websites, as they lack validation from a publicly trusted Certificate Authority.
*   **Certificate Stores:** Certificates are installed into "Personal" and "Trusted Root Certification Authorities" stores of the Local Computer.
*   **Input Validation:** Basic validation for empty input fields is performed.
*   **No Telemetry:** The application does not collect or transmit any user data or telemetry.

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
