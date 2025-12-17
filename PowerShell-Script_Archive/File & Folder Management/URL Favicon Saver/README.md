<a id="readme-top"></a>

<!-- EliteSoftware Co. LOGO -->

<br />
<div align="center">
<a href="Logo">
<img src="https://i.postimg.cc/85MDTcrJ/Elite-Software-LOGO-Mocup2.png" alt="Logo" width="256" height="256">
</a>
</div>

<!-- ABOUT THE PROJECT -->

# 💾 About The Project <div align="center">
## Screenshot may be slightly outdated. Sorry in advance! :)  
<br />
<div align="center">
<a href="Screenshot">
<img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720">
</a>
</div>

Ultimate Favicon Downloader (Enterprise Edition): A robust utility for fetching and converting favicons.

This tool provides a comprehensive solution for downloading favicons from any URL. It employs multiple strategies to ensure success, including intelligent HTML parsing, root directory checks, and fallback to external APIs like DuckDuckGo and Google S2. It also features a built-in ICO converter and a persistent configuration system.

Built by: Zachary Whiteman & Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script and does not require a complex installation process.

## 🕰️ Prerequisites
To run this script, you only need:

Windows Operating System (Windows 7 or later).

PowerShell 5.1 or newer (PowerShell Core is supported, but the script is optimized for the full .NET Framework available in Windows PowerShell for WinForms).

The required .NET Framework assemblies (System.Windows.Forms, System.Drawing, System.Net) which are included with modern Windows installations and loaded automatically by the script.

## 💽 Installation & Execution
Download: Download the URL-Favion Saver.PS1 script file.

Unblock: Right-click the file, go to Properties, and click Unblock if the file was downloaded from the internet (a common necessity for scripts downloaded from the web).

Run: Execute the script from a PowerShell console or by double-clicking it (if your system is configured to run PS1 files).

.\URL-Favion Saver.PS1

The application's configuration files and logs are stored in:
[Script Directory]\FaviconDownloader_Config

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application is designed for simplicity:

Enter URL: Type or paste the website URL into the input field.

Fetch: Click "Fetch Icon Resources" to attempt retrieval using all available strategies.

Preview: View the fetched icon in multiple sizes (16px, 32px, 64px, 128px) to ensure quality.

Save: Click "Save Icon As" to convert and save the image as a standard .ico file.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
This application leverages PowerShell WinForms for a feature-rich desktop experience:

Multi-Strategy Retrieval: Uses HTML parsing, root directory checking, and third-party APIs (DuckDuckGo, Google) to guarantee finding a favicon.

Built-in ICO Converter: Automatically converts fetched images (PNG, JPG, etc.) into proper .ico format with multiple sizes.

Live Previews: Displays the fetched icon in four standard sizes immediately after retrieval.

Persistent Settings: Remembers your preferences for console visibility, explorer actions, and last save location.

Detailed Logging: Maintains comprehensive logs of all actions and errors for troubleshooting.

Auto-Elevation: Automatically relaunches itself with Administrator privileges if required.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The entire application is a self-contained PowerShell script, utilizing:

Scripting Language: PowerShell (5.1+)

GUI Framework: .NET Windows Forms (WinForms)

Networking: System.Net.WebClient for HTTP requests and data downloading.

Image Processing: System.Drawing for image manipulation and ICO conversion.

XML: Used for persistent settings storage.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes

This application operates locally and interacts with external web servers only to fetch icon data:

### 🌐 Network Activity
The script makes outbound HTTP/HTTPS requests to the user-provided URL and, if necessary, to DuckDuckGo and Google favicon APIs. No user data is transmitted other than the target domain for icon retrieval.

### 🛡️ Permissions
The script requires Administrator privileges to ensure it can write logs and configuration files reliably in all environments, and potentially to save files to protected system directories if the user chooses.

### 🗃️ Data Handling
Configuration data is stored locally in an XML file within the script's configuration directory. Logs are stored in a dedicated subdirectory.

<!-- LICENSE -->

## 🪪 License
Distributed under the MIT License. See LICENSE.txt for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## ☎️ Contact
Zach Whiteman - elitesoftwarecolimited@gmail.com

HuggingFace - https://huggingface.co/EliteSoftware

HuggingFace (Personal) - https://huggingface.co/TheShadyRainbow

LinkTree - https://linktr.ee/zachrainbow

Patreon - https://www.patreon.com/c/EliteSoftwareCo

<p align="right">(<a href="#readme-top">back to top</a>)</p>
