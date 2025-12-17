<a id="readme-top"></a>

<!-- EliteSoftware Co. LOGO -->

<br />
<div align="center">
<!-- <a href="Logo">
<!-- <img src="https://i.postimg.cc/85MDTcrJ/Elite-Software-LOGO-Mocup2.png" alt="Logo" width="256" height="256">
<!-- </a> -->
</div>

<!-- ABOUT THE PROJECT -->

# 💾 About The Project <div align="center">

## App Monitor (The "Keep It Alive" Utility)

`App Monitor` is a lightweight, background PowerShell utility designed to keep your essential applications running. It sits quietly in your system tray, monitoring a list of specified processes. If an application crashes or closes unexpectedly, App Monitor waits for a grace period and then automatically relaunches it.

This tool is perfect for maintaining a kiosk environment, ensuring always-on utilities (like PowerToys or WindowBlinds) stay active, or just keeping your favorite apps persistent.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script runs in the background and is managed via the system tray.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the System Tray icon and menus.
*   **Icons (Optional):** For the best visual experience, place `ICON.ICO` (Green), `ICON2.ICO` (Red), and `ICON3.ICO` (Alert) in the same directory as the script. It will fallback to system icons if these are missing.

## 💽 Installation & Execution
1.  **Download:** Download the `AppMonitor.ps1` script file.
2.  **Configuration:** Open the script in a text editor (like Notepad or ISE) and edit the `$MonitoredApps` array at the top to include the paths to the applications *you* want to keep alive.
    ```powershell
    $MonitoredApps = @(
        @{ Name = "Notepad"; Path = "C:\Windows\System32\notepad.exe" },
        @{ Name = "Calculator"; Path = "C:\Windows\System32\calc.exe" }
    )
    ```
3.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
4.  **Run:** Execute the script. It handles its own backgrounding loop.
    ```powershell
    .\AppMonitor.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Once running, the script lives in your system tray (near the clock).

*   **Tray Icon Status:**
    *   🟢 **Green:** Idle. All monitored apps are running or within their grace period.
    *   🔴 **Red:** Active. The script is currently launching an application.
    *   🟡 **Yellow/Alert:** Error or Paused. An app failed to launch, a file is missing, or monitoring is globally paused.
*   **Context Menu (Right-Click):**
    *   **Force Check Now:** Manually triggers a scan of all processes immediately.
    *   **Manage Apps:** A submenu where you can toggle monitoring on or off for individual applications on the fly.
    *   **Pause All Monitoring:** Globally pauses the script. No apps will be relaunched while paused.
    *   **Exit:** Closes the monitor and removes the tray icon.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Self-Healing:** Automatically detects closed applications and restarts them after a 120-second grace period (configurable).
*   **Visual Feedback:** The tray icon changes color to reflect the current status (Monitoring, Launching, Error, Paused).
*   **Startup Self-Test:** Runs a quick color-cycling animation on the tray icon at launch to verify UI responsiveness.
*   **Granular Control:** Toggle monitoring for specific apps without stopping the entire script.
*   **Global Pause:** Quickly disable all monitoring when you need to perform maintenance or close apps intentionally.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the System Tray integration.
*   **Core Logic:** Uses `Get-Process` to check app status and `Start-Process` for resurrection.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Configuration:** The list of monitored apps is hardcoded in the `$MonitoredApps` variable at the top of the script. You must edit the file to change targets.
*   **Process Launching:** The script launches applications in their own working directory.
*   **User Context:** The script runs in the context of the user who started it. It cannot restart services or system-level processes unless run as Administrator.

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
