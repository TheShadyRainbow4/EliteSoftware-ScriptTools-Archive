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

## EliteSoftware HTML - HTTP Test Server

The `EliteSoftware HTML - HTTP Test Server` is a PowerShell script that provides a robust graphical user interface (GUI) for managing multiple simple HTTP servers. It's designed for developers and testers who need to quickly serve static web content from local directories. The tool supports multiple, persistent server configurations and runs each server in its own thread for a responsive experience.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script allows you to run multiple, configurable web servers for local development.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI and the `HttpListener` class.

## 💽 Installation & Execution
1.  **Download:** Download the `HTML-HTTP-TEST-SERVER.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\HTML-HTTP-TEST-SERVER.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a multi-paned interface for managing your test servers.

*   **Server Configurations (Left Sidebar):**
    *   This panel lists all your saved server configurations.
    *   Click on a server name to load its settings into the main panel.
    *   Use the `File -> New Server Configuration` menu item to add a new server profile to the list.
*   **Main Panel:**
    *   **Server Root Folder:** Specify the local directory that will act as the web root.
    *   **Default File Name:** The file to be served when the root URL is requested (e.g., `index.html`).
    *   **Server Port:** The port the server will listen on. If the port is in use, the server will automatically try the next available port.
    *   **IP Address to Bind:** The local IP address the server will bind to.
    *   **Action Buttons:** Start or stop the selected server, or open its URL in your default web browser.
*   **Status Log:**
    *   The text box at the bottom provides a real-time log of server activity, including startup messages, requests, and errors.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Multi-Server Management:** Configure and manage up to 10 different server profiles from a single interface.
*   **Persistent Configurations:** All server settings are saved to a JSON file in your AppData folder, so they are retained between sessions.
*   **Threaded HTTP Servers:** Each server runs in its own background thread, ensuring the GUI remains responsive.
*   **Automatic Port Resolution:** Automatically detects and resolves port conflicts by incrementing the port number.
*   **Live Logging:** Provides a real-time log of server activity for easy debugging.
*   **Graceful Shutdown:** The application attempts to stop all running servers cleanly upon exit.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Web Server:** The core web server is implemented using the `.NET System.Net.HttpListener` class.
*   **Threading:** Utilizes `System.Threading.Thread` for concurrent server operations.
*   **Configuration:** Saves and loads settings using JSON.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Local Test Server:** This tool is designed for local development and testing purposes only. It is not a production-grade web server and lacks the security features of one.
*   **File System Access:** The server will serve files from the directory you specify as the web root. Ensure that you only point it to trusted directories.
*   **Firewall:** When you start a server, you may receive a prompt from the Windows Firewall to allow the application to accept incoming network connections.

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
