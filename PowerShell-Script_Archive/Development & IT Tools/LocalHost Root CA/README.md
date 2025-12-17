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
## Screenshot may be slightly outdated. Sorry in advance! :)
<br />
<div align="center">
<!-- <a href="Screenshot">
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720">
<!-- </a> -->
</div>

## LocalHost Root CA: SSL Certificate Generation and Signing Utility

`LocalHost Root CA` is a straightforward PowerShell script designed to simplify the process of creating an SSL certificate for `localhost` and signing it with an existing root Certificate Authority (CA). This utility is particularly useful for developers and system administrators who need to set up local development environments with trusted SSL/TLS connections, avoiding browser warnings and ensuring secure local testing. The script generates a new certificate and exports it as a PFX file, ready for import into local certificate stores or web servers.

Built by: EliteSoftware Enterprises / Zachary Whiteman / Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a quick way to generate and sign `localhost` SSL certificates.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses PowerShell's built-in certificate management cmdlets.
*   **An Existing Root CA Certificate:** A root CA certificate in `.cer` format must exist at `C:\temp\WdpTestCA.cer`. This CA will be used to sign the newly generated `localhost` certificate.
*   **Administrator Privileges:** The script implicitly requires Administrator privileges to import certificates into the local machine's certificate store.

## 💽 Installation & Execution
1.  **Download:** Download the `LocalHostRootCA.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Ensure Root CA:** Place your root CA certificate named `WdpTestCA.cer` at `C:\temp\`.
4.  **Review Configuration:** Open the `.PS1` script in a text editor and review/modify the following variables if needed:
    *   `$IssuedTo`: The DNS name for the certificate (defaults to "localhost").
    *   `$Password`: The password for the exported PFX file (defaults to "PickAPassword" - **CHANGE THIS!**).
    *   `$OutputPath`: The directory where the PFX file will be saved (defaults to `c:\temp\`).
5.  **Run as Administrator:** Open a PowerShell console **as Administrator** and execute the script:
    ```powershell
    .\LocalHostRootCA.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
After execution, the script will:

1.  Import the specified root CA certificate.
2.  Generate a new self-signed certificate for `localhost`.
3.  Sign the `localhost` certificate using your imported root CA.
4.  Export the newly signed `localhost` certificate as a PFX file (e.g., `c:\temp\localhost.pfx`) using the specified password.

You can then import this PFX file into your personal certificate store, or configure local web servers (like IIS, Apache, Nginx) to use it for trusted SSL/TLS connections for `localhost`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Simplified SSL Generation:** Automates the creation of SSL certificates for `localhost`.
*   **CA-Signed Trust:** Enables the generation of certificates signed by your own root CA, making them trusted within your local development environment.
*   **PFX Export:** Provides the certificate in a widely compatible PFX format, including the private key for easy deployment.
*   **Customizable Output:** Allows easy modification of the output path and PFX password.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, utilizing its robust certificate management capabilities:

*   **Scripting Language:** PowerShell
*   **Certificate Cmdlets:** `New-SelfSignedCertificate`, `Import-Certificate`, `Export-PfxCertificate` for certificate lifecycle management.
*   **Security:** `ConvertTo-SecureString` for secure password handling during PFX export.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `LocalHostRootCA.PS1` script performs sensitive operations related to digital certificates on your local machine.

*   **Administrator Privileges:** Modifying the local machine's certificate store requires elevated privileges. Ensure you run the script as Administrator.
*   **Password Management:** The `$Password` variable for the PFX file is currently hardcoded in the script. **It is highly recommended to change "PickAPassword" to a strong, unique password for any practical use.** For production scenarios, consider using more secure methods for password handling (e.g., reading from a secure prompt).
*   **Root CA Trust:** The security of the generated `localhost` certificate is dependent on the security and trustworthiness of your `WdpTestCA.cer` root CA.
*   **Local Storage:** All generated files (PFX) are stored locally at the specified `$OutputPath`.
*   **No Telemetry:** The script does not collect or transmit any user data or telemetry.

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
