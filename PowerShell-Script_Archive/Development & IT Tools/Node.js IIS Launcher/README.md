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

## Node.js IIS Launcher: GUI for Node.js App Deployment and Management

The `Node.js IIS Launcher` is a robust PowerShell script providing a graphical user interface (GUI) to streamline the management and hosting of Node.js applications on Internet Information Services (IIS). Designed to reside within your Node.js project folder, this tool offers intuitive buttons for common `npm` commands, control over development servers, dynamic `.env` file management, and automated IIS website configuration, including application pool setup and port/binding management.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a powerful GUI for deploying and managing Node.js applications with IIS.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later) with IIS installed.
*   **PowerShell 7 or higher:** This script leverages modern PowerShell features and Jobs.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **Node.js and npm:** Node.js and its package manager (`npm`) must be installed and accessible in your system's PATH.
*   **`WebAdministration` PowerShell Module:** This module is required for IIS management. You can install it from an elevated PowerShell terminal:
    ```powershell
    Install-Module -Name WebAdministration
    ```
*   **Administrator Privileges:** The script implicitly requires Administrator privileges to configure IIS settings.

## 💽 Installation & Execution
1.  **Download:** Download the `Node.js - IIS Launcher.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Place Script:** Place the `Node.js - IIS Launcher.ps1` script directly into the root directory of your Node.js project.
4.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .
ode.js - IIS Launcher.ps1
    ```
    The PowerShell console window will automatically minimize upon launch for a cleaner GUI experience.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Upon launching the application from your Node.js project's root folder, you will be presented with a GUI:

*   **`npm` Commands:**
    *   **"NPM Install"**: Click to run `npm install` and install project dependencies. Progress will be shown in the output log.
    *   **"NPM Run Dev"**: Click to execute `npm run dev` to start your local development server. The status indicator will change to green.
    *   **"Stop Server"**: Click to gracefully terminate the running development server process.
*   **IIS Hosting:**
    *   **Port:** Enter the desired port for your IIS website (e.g., `80`).
    *   **Bindings:** Enter the host headers for your IIS website (e.g., `www.yourdomain.com`).
    *   **"Host in IIS"**: Click to configure and launch your Node.js application as an IIS website. This will create or update an application pool and site.
*   **Environment Management:**
    *   **"Set Api Key"**: Click to open a dialog to enter an API key, which will be saved to a `.env.local` file in your project root.
*   **Output Log:** The central text box displays real-time output from `npm` commands and script actions.
*   **Status Indicator:** A small panel changes color to reflect the state of your development server (Red: Stopped, Green: Running, Yellow: Installing/Unknown).
*   **"Open in Browser"**: Click to launch the configured `http://localhost:3000` (or the IIS site URL) in your default web browser.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-Driven Workflow:** Intuitive Windows Forms interface for managing Node.js application development and deployment.
*   **Automated `npm` Tasks:** One-click execution of `npm install` and `npm run dev` directly from the GUI.
*   **Full IIS Integration:** Automates the creation and configuration of an IIS website for your Node.js application, including setting up appropriate application pools.
*   **Real-time Process Feedback:** Displays standard output and error streams from executed `npm` commands in a dedicated RichTextBox.
*   **Visual Status Indicator:** Provides immediate visual feedback on the operational status of your Node.js development server.
*   **Development Server Control:** Enables starting, stopping, and launching the development server in a browser with ease.
*   **`.env` File Management:** Simplifies the process of creating and updating `.env.local` files for sensitive configuration (e.g., API keys).
*   **Background Operations:** Executes `npm` commands as PowerShell background jobs, ensuring the GUI remains responsive during long-running tasks.
*   **Persistent Configuration:** Saves IIS port and bindings settings across sessions for quick reuse.
*   **Console Minimization:** Automatically minimizes the PowerShell console window for a cleaner user experience.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging powerful integrations:

*   **Scripting Language:** PowerShell 7 or higher.
*   **GUI Framework:** .NET Windows Forms (WinForms) for the rich graphical user interface.
*   **Process Management:** `System.Diagnostics.Process` and PowerShell Jobs (`Start-Job`) for asynchronous and non-blocking execution of external commands like `npm` and Node.js.
*   **IIS Management:** The `WebAdministration` PowerShell module for programmatic control and configuration of Internet Information Services.
*   **File System Operations:** Standard PowerShell cmdlets (`Join-Path`, `Get-Content`, `Set-Content`, `New-Item`, `Import-CliXml`, `Export-CliXml`) for file and directory management.
*   **Windows API Interaction:** C# P/Invoke for console window minimization.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Node.js IIS Launcher` performs significant system-level operations and integrates directly with core web technologies.

*   **Administrator Privileges:** Due to IIS configuration and potentially `npm install` operations, the script implicitly requires Administrator privileges to function correctly.
*   **IIS Configuration:** The script directly modifies IIS settings, including creating/updating websites and application pools. These are system-wide changes.
*   **External Dependencies:** Relies on Node.js, `npm`, and the `WebAdministration` PowerShell module being installed and correctly configured.
*   **Process Management:** `npm` commands are executed as background jobs, allowing for concurrent execution without freezing the UI. Output is captured and displayed.
*   **Sensitive Information:** The "Set Api Key" feature handles writing API keys to a `.env.local` file. Ensure this file is properly secured and excluded from version control in production environments.
*   **Configuration Persistence:** IIS settings are saved locally via XML (`config.xml`) in `C:\Users\<YourUser>\AppData\Roaming\EliteSoftwareCorp\NodeIISLauncher\`.
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
