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
## Screenshot may be slightly outdated. Sorry in advance! :)  
<br />
<div align="center">
<!-- <a href="Screenshot"> -->
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720"> -->
<!-- </a> -->
</div>

## Python & Library Installer v1.2

The `Python & Library Installer` is a user-friendly PowerShell GUI application designed to streamline the setup of a Python development environment. This tool automates the installation of the latest Python 3 version system-wide using `winget` and subsequently installs a curated list of essential and popular Python libraries via `pip`. It ensures a smooth installation process for all users on the system, handles administrator privileges, and provides real-time progress updates and logging within a responsive graphical interface.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides an automated solution for installing Python and common libraries.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's capabilities for GUI development and package management.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **`winget`:** The Windows Package Manager (`winget`) must be installed and accessible in your system's PATH.
*   **Internet Connection:** An active internet connection is required to download Python and its libraries.

## 💽 Installation & Execution
1.  **Download:** Download the `Python & Library Installer v1.0.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it. The script will automatically prompt for Administrator privileges if not already running with them.
    ```powershell
    .\Python & Library Installer v1.0.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
1.  **Launch the Application:** Run the script as described in the Installation section. The GUI window will appear.
2.  **Review Information:** Read the description and welcome message in the output log.
3.  **Start Installation:** Click the **"Start Installation"** button.
    *   The button will disable and its text will change to "Installing..." to indicate progress.
    *   The output log will display real-time progress from `winget` (for Python) and `pip` (for libraries).
4.  **Monitor Progress:** Observe the output log for messages regarding Python installation, discovery of `pip`, and the installation of each specified library.
5.  **Completion:** Once all installations are complete, a success message will appear in the log. The "Start Installation" button will re-enable.
6.  **Close:** Click the **"Close"** button to exit the application.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-based Python Environment Setup:** Provides a user-friendly Windows Forms interface for an all-in-one Python and library installation.
*   **Automated Python 3 Installation:** Automatically installs the latest Python 3 version system-wide (`--scope machine`) using `winget`.
*   **Curated Library Installation:** Installs a pre-defined list of popular and essential Python libraries (e.g., `pywin32`, `wxPython`, `requests`, `numpy`, `pandas`, `matplotlib`, `scipy`, `Pillow`, `beautifulsoup4`, `lxml`, `openpyxl`, `virtualenv`).
*   **Real-time Progress Feedback:** Displays live output from `winget` and `pip` commands directly within the GUI's RichTextBox.
*   **Responsive User Interface:** All installation processes run as background PowerShell jobs, ensuring the GUI remains interactive and does not freeze during long-running operations.
*   **Administrator Elevation:** Automatically handles the request for Administrator privileges, which is necessary for system-wide installations.
*   **Robust Logging:** Detailed messages are logged to the GUI and the PowerShell console, aiding in troubleshooting.
*   **Themed UI:** Enables visual styles for native Windows theming of UI controls, enhancing aesthetic consistency.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, integrating with external tools and .NET components:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Package Management:**
    *   `winget` (Windows Package Manager) for installing Python.
    *   `pip` (Python's package installer) for managing Python libraries.
*   **Process Management:** PowerShell Jobs (`Start-Job`) for executing `winget` and `pip` commands in the background.
*   **UI Updates:** Utilizes `System.Windows.Forms.RichTextBox` for styled output and ensures cross-thread safety for GUI updates.
*   **Environment Interaction:** `System.Security.Principal` for privilege checks.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `Python & Library Installer` performs system-wide installations and external downloads.

*   **Administrator Privileges:** The script explicitly re-launches itself with Administrator privileges if not already running elevated, as system-wide Python installation requires it.
*   **External Downloads:** Relies on `winget` to fetch Python and `pip` to fetch libraries from their respective official repositories. An active internet connection is necessary.
*   **System-Wide Installation:** Python is installed for all users on the machine.
*   **Process Isolation:** Installation commands are run as background PowerShell jobs, which isolates them from the main GUI thread.
*   **Output Monitoring:** The script actively monitors the output of background jobs to display real-time progress to the user.
*   **No Telemetry:** The application does not collect or transmit any user data or telemetry.

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
