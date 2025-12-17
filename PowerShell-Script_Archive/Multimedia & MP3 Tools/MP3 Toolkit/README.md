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

## EliteSoftware MP3 Toolkit

The `EliteSoftware MP3 Toolkit` is a feature-rich PowerShell application designed for managing your MP3 collection. It provides a comprehensive graphical user interface (GUI) for browsing files, editing metadata tags (ID3), managing album art, and even playing tracks directly within the app. It's built with robustness in mind, featuring automated dependency handling, detailed logging, and persistent configuration.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is a standalone application that manages its own dependencies.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Internet Connection:** Required on the *first run* to automatically download the `TagLibSharp.dll` library, which handles the MP3 metadata editing.

## 💽 Installation & Execution
1.  **Download:** Download the `MP3Toolkit.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\MP3Toolkit.ps1
    ```
4.  **First Run:** The script will check for `TagLibSharp.dll` in a `lib` subfolder. If missing, it will attempt to download it automatically.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features

### File Management
*   **File Browser:** Integrated tree-view explorer to easily navigate your music folders.
*   **Save Copy:** The "Safe House" feature allows you to save a modified copy of your MP3 file to a new location, preserving the original.

### Metadata Editor
*   **Comprehensive Tagging:** Edit Title, Artist, Album, Year, Genre, Track #, Disc #, BPM, Composer, Conductor, and more.
*   **Album Art:** Add, view, or remove album cover artwork directly embedded in the file.
*   **Star Rating:** Rate your tracks from 0 to 5 stars.

### Playback
*   **Built-in Player:** Play, stop, and scrub through tracks to verify your files without leaving the application.
*   **Visual Scrubber:** Track playback progress with a visual slider.

### System Features
*   **Auto-Dependency:** Automatically downloads and installs the required `TagLibSharp` library.
*   **Logging:** Maintains detailed logs of operations and errors in a local `Log Files` directory.
*   **Configuration:** Remembers your preferences, such as showing startup hints.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Library:** `TagLibSharp` (External DLL) for robust audio tag manipulation.
*   **Media Player:** Windows Media Player OCX (`WMPlayer.OCX.7`) for playback.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Local Operations:** The script operates locally on your files. The internet connection is only used for downloading the initial dependency.
*   **FileSystem Access:** The script reads and writes files in its own directory (for logs/config) and the directories you explicitly browse to.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🪪 License
Distributed under the MIT License. See LICENSE.txt for more information.

This project utilizes the **TagLibSharp** library, which is licensed under the **LGPL 2.1**. Please refer to [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt) and [TagLibSharp-LICENSE.txt](TagLibSharp-LICENSE.txt) in this directory for full legal details and attribution.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ☎️ Contact
Zach Whiteman - elitesoftwarecolimited@gmail.com

HuggingFace - https://huggingface.co/EliteSoftware

HuggingFace (Personal) - https://huggingface.co/TheShadyRainbow

LinkTree - https://linktr.ee/zachrainbow

Patreon - https://www.patreon.com/c/EliteSoftwareCo

<p align="right">(<a href="#readme-top">back to top</a>)</p>
