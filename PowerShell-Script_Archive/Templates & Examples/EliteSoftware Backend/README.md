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

## EliteSoftware Local Backend Server

This script is a simple, self-contained backend server written in PowerShell. It is designed to support a local web application by serving static files (HTML, CSS, JavaScript, images) and providing a basic JSON file-based REST API for data persistence. It's intended to be the backend for the "EliteSoftware Southern Branch Corporate Portal".

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script runs the local web server needed for the frontend application to function.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the `HttpListener` class.
*   **Frontend Files:** This script requires the frontend application files (e.g., `index.html`, etc.) to be in the same directory.

## 💽 Installation & Execution
1.  **Download:** Place the `elitesoftware south department backend.ps1` script in the root directory of your web application project.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ."\elitesoftware south department backend.ps1"
    ```
4.  **Access:** Keep the PowerShell window running and open your web browser to `http://localhost:8080`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 API Endpoints
The server provides several API endpoints to interact with the local `database.json` file and file system.

*   `GET /api/data`: Retrieves all data from `database.json` and dynamically includes any blog posts from the `/posts` directory.
*   `POST /api/data`: Overwrites the contents of `database.json` with the JSON data provided in the request body.
*   `GET /api/images`: Returns a JSON array of filenames found in the `/images` directory.
*   `GET /api/videos`: Returns a JSON array of filenames found in the `/videos` directory.
*   `POST /api/upload`: Handles multipart/form-data file uploads and saves them to the `/images` directory.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Local HTTP Server:** Runs a simple web server on `http://localhost:8080` using the built-in .NET `HttpListener`.
*   **Static File Serving:** Serves HTML, CSS, JS, and media files. Includes a fallback to `index.html` for Single Page Application (SPA) routing.
*   **JSON Database:** Uses a local `database.json` file for simple data persistence. The file is created with default data if it doesn't exist.
*   **RESTful API:** Provides basic API endpoints for reading and writing data, listing images/videos, and uploading files.
*   **CORS Enabled:** Automatically includes CORS headers to allow requests from the frontend application.
*   **Dynamic Post Loading:** Automatically discovers and serves text and markdown files from a `/posts` directory as blog posts.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **Web Server:** The core web server is implemented using the `.NET System.Net.HttpListener` class.
*   **Data Format:** JSON for the database and API responses.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Development Only:** This server is intended for local development and testing only. It is not secure and should not be exposed to the internet.
*   **No Authentication:** The API endpoints do not have any authentication or authorization mechanisms.
*   **File System Access:** The server reads from and writes to the directory where it is located. Ensure it is run in a trusted project folder.

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
