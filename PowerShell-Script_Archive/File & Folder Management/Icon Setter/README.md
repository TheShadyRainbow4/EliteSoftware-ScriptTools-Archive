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

## Custom Icon Setter

The `Custom Icon Setter` is a GUI-based PowerShell utility that allows users to easily customize the icons of application shortcuts found in the Windows Start Menu. It simplifies the process of finding shortcuts and applying new `.ico` files to them, providing a quick way to personalize the desktop experience.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This tool modifies shortcut files in your Start Menu.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **Administrator Privileges:** Recommended for modifying shortcuts in the "All Users" Start Menu (`C:\ProgramData`).

## 💽 Installation & Execution
1.  **Download:** Download the `IconSetter-1.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock`.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\IconSetter-1.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application provides a list of your installed applications.

1.  **Select Application:** Choose the application shortcut you want to modify from the list. The list includes shortcuts from both your personal Start Menu and the system-wide Start Menu.
2.  **Choose Icon:** Click the browse button to find and select the `.ico` file you want to use.
3.  **Set Icon:** Click the button to apply the new icon to the shortcut.
4.  **Reset:** Use the reset option to revert the shortcut to its default icon (from the target executable).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Automatic Scanning:** Automatically finds all shortcuts (`.lnk` files) in the standard Start Menu locations.
*   **Visual Interface:** Provides a clean list of applications to choose from.
*   **Easy Customization:** Apply any standard `.ico` file with a few clicks.
*   **Reset Capability:** Easily revert changes if you don't like the new icon.
*   **Status Feedback:** Displays success or error messages to keep you informed.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Uses the `WScript.Shell` COM object to read and modify shortcut properties.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Shortcut Modification:** The script modifies the `.lnk` files directly.
*   **Permissions:** Modifying shortcuts in `C:\ProgramData\Microsoft\Windows\Start Menu` requires Administrator permissions. If run as a standard user, you may only be able to modify your own shortcuts.

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