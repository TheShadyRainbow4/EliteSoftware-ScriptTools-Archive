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

URL-LNK Extension Toggler: A System Tray Utility

This lightweight system tray utility allows users to quickly toggle the visibility of `.LNK` (Shortcut) and `.URL` (Internet Shortcut) file extensions in Windows Explorer. It runs silently in the background and provides immediate feedback via balloon tips.

Built by: Zachary Whiteman & Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script designed to run as a persistent background process.

## 🕰️ Prerequisites
To run this script, you only need:

Windows Operating System (Windows 7 or later).

PowerShell 5.1 or newer.

The required .NET Framework assemblies (System.Windows.Forms, System.Drawing) which are included with modern Windows installations.

## 💽 Installation & Execution
Download: Download the URL-LNK Extension Toggler.PS1 script file.

Unblock: Right-click the file, go to Properties, and click Unblock if the file was downloaded from the internet.

Run: Execute the script from a PowerShell console or by double-clicking it.
.\URL-LNK Extension Toggler.PS1

The script expects an icon file at `[ScriptRoot]\Resources\URL-LNK-Extension-Toggler.ICO`. If not found, it will use a system default.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application resides in the system tray:

Toggle: Double-click the tray icon to toggle the visibility of `.LNK` and `.URL` extensions. A notification will appear confirming the new state.

Exit: Right-click the tray icon and select "Exit" to close the application.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
This application leverages PowerShell WinForms for a seamless desktop experience:

System Tray Integration: Runs unobtrusively in the system tray.

Instant Toggle: Modifies registry keys to show/hide extensions and immediately refreshes Windows Explorer to apply changes without a restart.

Visual Feedback: Uses balloon tips to inform the user of the current extension state (Hidden/Shown).

Robust Path Detection: Correctly identifies its running directory whether executed as a script or a compiled EXE.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The entire application is a self-contained PowerShell script, utilizing:

Scripting Language: PowerShell (5.1+)

GUI Framework: .NET Windows Forms (WinForms) - specifically `NotifyIcon`.

Native Interop: Uses P/Invoke to call `shell32.dll`'s `SHChangeNotify` for instant Explorer refreshing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes

This application modifies user-specific registry keys to control file extension visibility:

### ⚙️ Registry Modification
The script targets `HKEY_CLASSES_ROOT\lnkfile` and `HKEY_CLASSES_ROOT\InternetShortcut`. It adds or removes the `NeverShowExt` property to toggle visibility.

### 🛡️ Permissions
Standard user privileges are typically sufficient for modifying these keys, though Administrator rights may be needed depending on system configuration.

### 🖥️ Native Integration
It defines a C# class on-the-fly to access the native Windows API `SHChangeNotify`, ensuring that changes to the registry are immediately reflected in the Windows shell.

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
