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

## Ultimate Favicon Downloader (Enterprise Edition)

The `Ultimate Favicon Downloader` is a robust PowerShell utility for fetching and converting website favicons. It employs a multi-strategy retrieval engine to ensure high success rates, checking HTML tags, root directories, and external APIs (DuckDuckGo, Google). It features a built-in ICO converter, live previews, and persistent configuration.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application allows you to download favicons from any URL.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI and Image handling.
*   **Internet Connection:** Required to fetch favicons from websites.

## 💽 Installation & Execution
1.  **Download:** Download the `URL-Favion Saver.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\URL-Favion Saver.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
1.  **Enter URL:** Type the website address (e.g., `https://www.wikipedia.org`).
2.  **Fetch:** Click **Fetch Icon Resources**. The tool will attempt to find the best available icon.
3.  **Preview:** View the icon in multiple sizes.
4.  **Save:** Click **Save Icon As** to save the icon as an `.ico` file to your computer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Multi-Strategy Fetching:** HTML Parsing, Root Check, DuckDuckGo API, Google S2 API.
*   **Auto-Conversion:** Converts fetched images (PNG, JPG, etc.) to standard `.ico` format.
*   **Live Previews:** Displays the icon in 16px, 32px, 64px, and 128px sizes.
*   **Persistent Settings:** Remembers your last save directory and console preferences.
*   **Logging:** Comprehensive logging system for troubleshooting.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Networking:** `System.Net.WebClient`.
*   **Image Processing:** `System.Drawing`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Network Requests:** Makes HTTP/HTTPS requests to the target URL and potentially to third-party favicon APIs.
*   **Local Storage:** Saves configuration and logs to a `FaviconDownloader_Config` folder in the script's directory.

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