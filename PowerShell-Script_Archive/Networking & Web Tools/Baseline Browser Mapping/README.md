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

## Baseline Browser Mapping - PowerShell Wrapper

This script, `baseline-browser-mapping.ps1`, is a PowerShell wrapper designed to execute the `baseline-browser-mapping` Node.js command-line interface (CLI). It is not a standalone tool but acts as a convenience launcher for PowerShell users, bridging the gap between a PowerShell environment and the underlying JavaScript application.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is part of a larger Node.js project. It requires the project's file structure to be intact.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Node.js:** Must be installed on your system. The script will try to use a `node` executable located in its directory or one available in the system's PATH.
*   **Project Files:** The script expects to be located within the project's directory structure, specifically where it can find the main CLI file at `../baseline-browser-mapping/dist/cli.js` relative to its own location.

## 💽 Installation & Execution
This script is intended to be run from within the context of the `baseline-browser-mapping` project, likely from a PowerShell console.

1.  Navigate to the directory containing the script.
2.  Execute the script, passing any arguments intended for the Node.js CLI.
    ```powershell
    .\baseline-browser-mapping.ps1 [arguments-for-the-cli]
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script acts as a transparent proxy to the Node.js application. Any arguments passed to the PowerShell script will be forwarded directly to the `baseline-browser-mapping` CLI. It also correctly handles piped input.

**Example:**
```powershell
# Example of passing arguments
.\baseline-browser-mapping.ps1 --help

# Example of using piped input
'{"feature": "flexbox"}' | .\baseline-browser-mapping.ps1
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Node.js Execution:** Automatically finds and runs the `cli.js` application using the appropriate Node.js executable.
*   **Cross-Platform Aware:** Includes logic to handle differences between Windows and non-Windows environments.
*   **Argument Forwarding:** Seamlessly passes all command-line arguments to the underlying Node.js script.
*   **Pipeline Support:** Correctly handles input piped to it from other PowerShell commands.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Launcher:** PowerShell
*   **Core Application:** Node.js

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Wrapper Script:** This script's primary function is to launch another application. Its logic is focused on finding the correct executables and paths.
*   **File Structure Dependency:** The script is tightly coupled to the project's directory structure and will fail if run from a different location.

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
