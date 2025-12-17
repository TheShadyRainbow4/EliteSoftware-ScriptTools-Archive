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

## Winget Program Manager (Unstable)

**⚠️ WARNING: This script is marked as unstable and is known to have issues or crash, as indicated by its filename. It is provided as a developmental example and is not recommended for general use.**

This PowerShell script is an attempt to create a graphical user interface (GUI) that acts as a "Program Manager" for the Windows Package Manager (`winget`). Its intended purpose is to allow users to search for applications available through `winget` and install them from a user-friendly interface, without needing to use the command line directly.

The script uses advanced PowerShell concepts, including background jobs (`Start-Job`), to run `winget` operations asynchronously to prevent the GUI from freezing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a developmental example and is not guaranteed to be functional.

## 🕰️ Prerequisites
To attempt to run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Windows Package Manager (`winget`):** `winget` must be installed and accessible from your system's PATH.

## 💽 Installation & Execution
1.  **Download:** Download the `CRASHES HiddenSettings.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if it was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ."\CRASHES HiddenSettings.PS1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Intended Usage
The intended functionality of the application is as follows:

*   Upon launch, the script is supposed to load all packages available via `winget`.
*   Users can type a search term in the search box and click **Search** to filter the list of programs.
*   The list view should display the Name, ID, Version, and Source of the available packages.
*   Users can select one or more programs from the list and click **Install Selected** to begin the installation process.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Architectural Concepts
*   **GUI Front-End:** Uses Windows Forms to create a familiar program manager interface.
*   **`winget` Wrapper:** The script is designed to be a graphical wrapper around the `winget search` and `winget install` commands.
*   **Asynchronous Operations:** Attempts to use `Start-Job` to run the `winget search` command in the background to keep the UI from freezing. This is a complex operation and is a likely source of the script's instability.
*   **Dynamic UI Updates:** The script is intended to populate the list of programs with the results from the background job.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend:** Windows Package Manager (`winget`).
*   **Concurrency:** PowerShell Jobs (`Start-Job`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Unstable Code:** This script is provided for educational or diagnostic purposes only. Its filename indicates it is prone to crashing. The use of background jobs, inter-thread communication (`Invoke`), and `Invoke-Expression` can lead to race conditions and unhandled exceptions.
*   **Administrator Privileges:** While not explicitly enforced with a self-elevation check, installing software via `winget` typically requires administrator rights.

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
