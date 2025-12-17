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

## EliteSoftware - AssetManager Pro (Web App Launcher)

`AssetManager Pro` is a comprehensive, self-contained asset management application launched via a PowerShell script. The script initiates a powerful, local web application, driven by a Python backend, that provides a rich user interface for tracking and managing physical and virtual assets. All application data, including a SQLite database, attachments, and backups, is stored permanently in `C:\AssetManager`.

This is a full-featured application designed for individuals, small businesses, or homelab enthusiasts who need a robust system to manage hardware, software, and network resources.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This launcher script performs a one-time setup and runs a persistent web application. Please review the prerequisites carefully.

## 🕰️ Prerequisites
To run this application, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Python 3.x:** Python must be installed and added to your system's PATH.
*   **Python Libraries:** The script will attempt to automatically install the following required libraries using `pip`: `python-barcode`, `qrcode`, `Pillow`, and `python-nmap`.
*   **Nmap (for Network Discovery):** The `nmap` command-line tool must be installed and in your system's PATH. You can download it from [nmap.org](https://nmap.org/).
*   **Administrator Privileges:** Required for the initial one-time setup to modify the Windows `hosts` file and check for dependencies. The script will self-elevate.

## 💽 Installation & Execution
1.  **Download:** Download the `AssetManager.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console. It will perform a one-time setup if needed, then launch the web server.
    ```powershell
    .\AssetManager.ps1
    ```
4.  **Access:** Once the server is running, the script will automatically open the web application in your default browser at `http://asset.manager.local:8080`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Key Features

### Core Asset Management
*   **Full CRUD Operations:** Add, view, edit, and delete assets.
*   **Detailed Tracking:** Fields for name, category, status, purchase date, cost, manufacturer, model, serial number, location, and more.
*   **Check-in / Check-out:** Track who has possession of an asset.
*   **History & Logging:** Every check-in, check-out, and change is logged for a complete audit trail.
*   **Attachments:** Upload images and other files directly to an asset's record.
*   **Archiving:** Archive retired assets to remove them from the main view without deleting their history.

### Advanced Features
*   **Network Discovery:** Scan your local network with Nmap to discover new devices and add them as assets with one click.
*   **IPAM (IP Address Management):** Define subnets and track IP address assignments to your assets.
*   **Barcode & QR Codes:** Automatically generates unique barcodes and QR codes for every asset, perfect for printing labels.
*   **Kiosk & Scan Modes:** Use a dedicated interface to quickly look up assets with a barcode scanner or your device's camera.
*   **Logistics Management:** Includes modules for managing Software Licenses, Racks, and Vendors.
*   **Data Utilities:**
    *   Import and export assets via CSV.
    *   Create and restore full database backups.
    *   Generate printable sheets of barcode labels for new or existing assets.
*   **Customization:** Use the settings page to change the UI theme, configure asset number prefixes, and set a default user for check-outs.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Launcher/Wrapper:** PowerShell
*   **Web Application Backend:** Python (using the built-in `http.server`).
*   **Database:** SQLite 3.
*   **Frontend:** Standard HTML, CSS, and vanilla JavaScript.
*   **Dependencies:** `python-barcode`, `qrcode`, `Pillow`, `python-nmap`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Self-Contained Application:** All application data, including the Python script, database, and user uploads, is stored in the `C:\AssetManager` directory.
*   **Localhost Only:** The web server is bound to `127.0.0.1` and is intended for local access only. The script adds a `hosts` file entry (`127.0.0.1 asset.manager.local`) for a friendly URL.
*   **Administrator for Setup:** The script only requires administrator rights for the initial setup to check dependencies and modify the hosts file.
*   **Development Server:** The Python web server is for single-user, local application use and is not hardened for a production environment.

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
