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

## Advanced ADB & Fastboot GUI Tool

The `Advanced ADB & Fastboot GUI Tool` is a comprehensive PowerShell application that provides a rich, user-friendly graphical user interface for managing Android devices. It wraps the powerful `adb.exe` and `fastboot.exe` command-line tools into an intuitive, dark-themed interface, making it easy for both novice and expert users to perform a wide range of actions without needing to memorize complex commands.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool simplifies the process of interacting with your Android device for development and tweaking.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Internet Connection:** Required for the one-time automatic download of Android Platform Tools if they are not already present.
*   **Android Device:** With USB Debugging enabled in Developer Options.

## 💽 Installation & Execution
1.  **Download:** Download the `Advanced ADB Fastboot GUI TOOL.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ."\Advanced ADB Fastboot GUI TOOL.PS1"
    ```
4.  **First Time Setup:** If the script doesn't find the `platform-tools` (ADB & Fastboot) in its directory, it will prompt you to download them automatically.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features
The application is organized into a main device panel and a series of tabs for specific tools.

### Main Device Panel
*   **Automatic Device Detection:** Automatically detects if a device is connected in ADB or Fastboot mode.
*   **Device Info:** Displays key information about the connected device, such as Model, Android Version, and Battery Level.
*   **Reboot Controls:** Simple buttons to reboot the device into the System, Bootloader (Fastboot), or Recovery mode.

### App Management Tab
*   Install APK files onto your device using a file browser.
*   List all installed packages on the device.
*   Uninstall selected packages with a confirmation prompt.

### Device Utilities Tab
*   A collection of one-click buttons to perform common tasks, such as:
    *   Get Battery Status, Screen Resolution, or IP Address.
    *   Force-stop an application or clear its data.
    *   Take a screenshot or record the screen (saved to your desktop).
    *   Push files to the device or pull files from the device.

### Power User Tab
*   **Quick Commands:** A customizable list of your favorite or most-used ADB and Fastboot commands. Add, edit, and remove custom commands that are saved between sessions.

### Advanced Tab
*   **Flashing Utilities:** A dedicated section for advanced users to flash `.img` files (like boot, recovery, or system images) to the device in Fastboot mode.
*   **ADB Sideload:** An interface to sideload update `.zip` or `.apk` files to your device from recovery mode.
*   **Clear Warnings:** This section contains prominent warnings that these operations are for advanced users and can be dangerous.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Backend:** Acts as a frontend for the official Google Android Platform Tools (`adb.exe`, `fastboot.exe`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Platform Tools Downloader:** The script downloads the official `platform-tools-latest-windows.zip` directly from `dl.google.com`.
*   **Command Execution:** The script executes `adb.exe` and `fastboot.exe` commands based on user input. All actions are logged in the output window at the bottom of the application.
*   **Advanced Operations:** Flashing and sideloading operations can permanently damage your device if used incorrectly. This tool provides a convenient interface but does not mitigate the inherent risks of these actions.

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
