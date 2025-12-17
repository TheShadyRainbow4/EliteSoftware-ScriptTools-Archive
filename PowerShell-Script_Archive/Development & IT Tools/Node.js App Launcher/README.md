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

## Node.js App Launcher with XML v1.2.0.0

`Node.js App Launcher with XML` is a versatile PowerShell script that provides a graphical user interface (GUI) for managing and launching Node.js applications. Its unique feature is an entirely XML-driven UI, allowing for flexible customization of the interface without altering the PowerShell code. This tool simplifies common development tasks by offering quick access to `npm` commands, control over development servers, and easy management of `.env` configuration files.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script simplifies the management of your Node.js projects.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's capabilities for GUI development and process management.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **Node.js and npm:** Node.js and its package manager (`npm`) must be installed and accessible in your system's PATH.
*   **`ui.xml` file:** An XML file named `ui.xml` must be present in the same directory as the script, defining the GUI layout.

## 💽 Installation & Execution
1.  **Download:** Download the `Node.JS App Launcher with XML.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Place Files:** Place `Node.JS App Launcher with XML.ps1` and its accompanying `ui.xml` file in the root directory of your Node.js project.
4.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Node.JS App Launcher with XML.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application assumes it is launched from the root directory of your Node.js project.

*   **GUI Controls (as defined in `ui.xml`):**
    *   **"Install Dependencies" Button (e.g., `btnInstall`):** Executes `npm install` in your project directory.
    *   **"Run Dev Server" Button (e.g., `btnRunDev`):** Executes `npm run dev` to start your development server. A visual indicator will change color.
    *   **"Stop Server" Button (e.g., `btnStop`):** Terminates the running development server process.
    *   **"Open in Browser" Button (e.g., `btnBrowser`):** Opens `http://localhost:3000` (or your configured dev server URL) in your default web browser.
    *   **"Edit .env" Button (e.g., `btnEnv`):** Copies a `.env.local` template (from a hardcoded path) to your project as `.env` and opens it for editing.
    *   **Output Box (e.g., `outputBox`):** Displays real-time `stdout` and `stderr` from `npm` commands.

*   **Closing the Application:** If the dev server is running, the application will prompt you to stop it before closing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **XML-driven User Interface:** The entire GUI layout and initial properties are loaded dynamically from an external `ui.xml` file, enabling easy customization of the launcher's appearance and functionality without script modification.
*   **Streamlined Node.js Workflow:** Provides one-click access to essential `npm` commands (`npm install`, `npm run dev`) directly from a desktop GUI.
*   **Development Server Management:** Offers dedicated buttons to start and gracefully stop your Node.js development server process.
*   **Integrated Browser Launch:** Quickly open your local development server in your default web browser.
*   **.env File Utility:** Facilitates easy creation and editing of `.env` configuration files from a template.
*   **Real-time Process Output:** Displays standard output and error streams from executed `npm` processes directly within the GUI.
*   **Visual Status Indicator:** Provides immediate visual feedback (e.g., color change) on the running status of the development server.
*   **Responsive GUI:** Executes `npm` commands as background processes, ensuring the user interface remains interactive and responsive.
*   **Graceful Exit:** Prompts to stop running development servers before closing the application to prevent lingering processes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, integrating with several key technologies:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **UI Definition:** XML for external and dynamic configuration of the user interface layout and controls.
*   **Process Management:** `System.Diagnostics.Process` for asynchronous execution and control of external `npm` and `Node.js` processes.
*   **Operating System Interaction:** `taskkill` for terminating processes and `Invoke-Item` for opening files and URLs.
*   **File System Operations:** Standard PowerShell cmdlets like `Join-Path`, `Copy-Item`, `Test-Path` for managing project files.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`Node.js App Launcher with XML` operates by interacting with local development tools and files.

*   **External UI Configuration:** The GUI's layout is loaded from `ui.xml`. Ensure this file is trusted, as malicious XML could potentially influence UI behavior.
*   **Local Process Execution:** The script directly executes `npm` commands. It is assumed that Node.js and npm are installed correctly and their executables are trusted.
*   **Hardcoded `.env` Template Path:** The path to the `.env` template file (`H:\Program Files\New+\Templates\.env.local`) is hardcoded. For deployment or shared environments, this path should be made configurable within `ui.xml` or via user settings for flexibility and security.
*   **Process Control:** Uses `taskkill` to stop processes. This is a common method for terminating applications but requires appropriate permissions.
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
