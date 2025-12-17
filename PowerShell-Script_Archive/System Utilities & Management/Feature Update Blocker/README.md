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

## Ultimate Feature Update Blocker

The `Ultimate Feature Update Blocker` is an advanced PowerShell script designed to lock a Windows 11 system to a specific feature update version (currently hardcoded to **23H2**). It performs a deep reset of local Group Policy to resolve conflicts and then applies specific registry settings to prevent the installation of newer feature updates and Windows Insider Preview builds.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is an advanced tool for taking firm control over your Windows Update behavior. Use with caution.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows 11 Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges:** The script must be run as an administrator to modify system policies and the registry.

## 💽 Installation & Execution
1.  **Download:** Download the `Feature_Update_Blocker.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run as Administrator:** You must run this script from a PowerShell console that has been opened with administrator privileges.
    ```powershell
    .\Feature_Update_Blocker.PS1
    ```
4.  **Reboot:** A system reboot is required for the changes, especially the Group Policy cache reset, to take full effect.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The script is fully automated. When run as an administrator, it will perform the following actions:

1.  **Reset Local Group Policy:** Forcefully clears the local Group Policy cache to remove any lingering or conflicting settings.
2.  **Block Insider Builds:** Sets registry keys to opt the machine out of telemetry and experimentation required for Insider builds.
3.  **Apply Target Version:** Sets the `TargetReleaseVersionInfo` and related registry keys to instruct Windows Update to target version **23H2** and no newer feature updates.
4.  **Apply Secondary Blocker:** Sets an additional registry key to block feature updates as a redundant measure.

The script provides detailed output in the console window as it performs each step.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Deep Policy Reset:** Clears the local Group Policy cache to resolve stubborn or "tattooed" policy settings that may interfere with update behavior.
*   **Targeted Version Locking:** Pins the operating system to a specific feature update (e.g., 23H2) using official policy settings.
*   **Insider Build Prevention:** Modifies registry settings to prevent the system from being offered Insider Preview builds.
*   **Automated Operation:** Runs from start to finish without user interaction.
*   **Informative Console Output:** Provides clear, color-coded feedback on the actions being performed.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **Core Logic:** Interacts directly with the Windows Registry and the file system (`cmd.exe` for `RD`) to apply its changes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
This is a powerful script that makes significant changes to your system's configuration.

*   **Administrator Privileges:** This script requires administrator access and will fail without it.
*   **System Modification:** The script deletes the contents of the `System32\GroupPolicy` folders and makes multiple changes to the `HKEY_LOCAL_MACHINE` section of the registry. This is an intentional part of its design but is an advanced and forceful action.
*   **Reversibility:** Reversing these changes requires manually deleting the added registry keys. There is no "undo" function in the script itself.
*   **Intended Use:** This script is designed for users who explicitly want to prevent their system from updating past a specific feature release. It may prevent you from receiving new Windows features and non-security updates.

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
