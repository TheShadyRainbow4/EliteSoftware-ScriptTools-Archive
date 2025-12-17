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

## PowerShell to EXE Converter v2.3

The `PowerShell to EXE Converter` is a sophisticated PowerShell script with a user-friendly Windows Forms (WinForms) GUI, designed to transform your `.ps1` scripts into self-contained `.exe` applications. This tool leverages the power of the .NET SDK's `dotnet build` and `publish` commands to embed your PowerShell code within a compiled executable. Version 2.3 is engineered for maximum reliability, automatically detecting and utilizing the latest installed .NET SDK, and includes advanced features such as metadata customization, optional administrator elevation, comprehensive profile management, and intuitive drag-and-drop support.

Built by: Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a user-friendly GUI to compile your PowerShell scripts into standalone executables.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 7 or higher:** This script leverages modern PowerShell features and .NET integration for robust compilation.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing`, `System.Management.Automation` (included with modern Windows installations).
*   **.NET SDK:** A compatible .NET SDK (version 6.0 or higher) must be installed on your system. This tool will automatically detect and use the latest installed SDK. You can download it from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).

## 💽 Installation & Execution
1.  **Download:** Download the `PS1_2_EXE.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\PS1_2_EXE.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The GUI presents a step-by-step process for converting your scripts:

1.  **Select PowerShell Script (.ps1):**
    *   Click "Browse..." to select your `.ps1` file, or drag and drop the file directly into the text box.
    *   The script will automatically suggest a Product Name and Description based on the `.ps1` filename.
2.  **Select Icon File (.ico):**
    *   Click "Browse..." to select a custom `.ico` file, or drag and drop the `.ico` file directly into the text box.
3.  **Configure File Metadata & Options:**
    *   **Product Name:** The name of your application.
    *   **Description:** A brief description of your application.
    *   **Company Name:** Your company or organization name.
    *   **Copyright:** Copyright information (defaults to current year).
    *   **File Version:** The version of your executable (e.g., `1.0.0.0`).
    *   **Require Administrator Privileges:** Check this box if your generated `.exe` needs to run as Administrator.
4.  **Profile Management:**
    *   **"Save Profile"**: Save all current metadata and settings to a `.json` file for later reuse.
    *   **"Load Profile"**: Load previously saved settings from a `.json` profile file.
    *   **"Reset"**: Clear all input fields and revert to default metadata.
5.  **Create EXE:**
    *   Click **"Create EXE"** to start the conversion process.
    *   You will be prompted to choose the save location and filename for your `.exe` file.
    *   A status bar and messages will provide feedback on the conversion progress.

Upon successful completion, a self-contained `.exe` file will be generated at your specified location, ready to run.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Intuitive GUI:** User-friendly Windows Forms interface makes converting scripts simple and accessible.
*   **Self-Contained Executables:** Generates standalone `.exe` files that include the necessary .NET runtime, allowing them to run on systems without a PowerShell installation.
*   **Automatic .NET SDK Detection:** Intelligently locates and uses the latest installed .NET SDK (6.0+) on your system for reliable compilation.
*   **Comprehensive Metadata Customization:** Allows full control over the executable's metadata (Product Name, Description, Company, Copyright, File Version).
*   **Administrator Elevation Option:** Easily configure the generated `.exe` to require Administrator privileges on execution.
*   **Custom Application Icon:** Embeds a custom `.ico` file into your executable for professional branding.
*   **Profile Management:** Save and load your conversion settings as `.json` profiles, streamlining the process for recurring builds or multiple projects.
*   **Drag-and-Drop Support:** Conveniently drag `.ps1` script and `.ico` files directly into the input fields.
*   **Real-time Progress & Status:** Provides visual feedback via a progress bar and status messages during the conversion process.
*   **Robust Error Handling:** Includes validation checks for inputs and comprehensive `try-catch` blocks for graceful error management during compilation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging its extensive .NET integration and external tooling:

*   **Scripting Language:** PowerShell 7 or higher.
*   **GUI Framework:** .NET Windows Forms (WinForms) for the graphical user interface.
*   **Compilation Engine:** .NET SDK (`dotnet build`, `dotnet publish`) for compiling the generated C# wrapper code.
*   **Dynamic Code Generation:** PowerShell generates a C# source file that encapsulates the original PowerShell script, making it compilable.
*   **File System Operations:** Standard PowerShell cmdlets and .NET classes (`System.IO.Path`, `System.IO.File`) for managing files, directories, and temporary build artifacts.
*   **Data Serialization:** JSON (`ConvertTo-Json`, `ConvertFrom-Json`) for saving and loading user profiles.
*   **Project File Generation:** Dynamically creates `.csproj` and `global.json` files to configure the .NET build process.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`PowerShell to EXE Converter` performs a complex build process involving code generation and compilation.

*   **Code Transformation:** The script reads your `.ps1` file, escapes its content, embeds it into dynamically generated C# source code, and then compiles this C# code into an executable.
*   **.NET SDK Dependency:** The presence of a functioning .NET SDK (version 6.0 or higher) is essential on the machine running this converter. The script attempts to intelligently locate `dotnet.exe`.
*   **Self-Contained Executables:** The generated `.exe` files are self-contained, meaning they include a trimmed version of the .NET runtime. This increases the file size but removes external dependencies on the target system.
*   **Temporary Files:** The conversion process creates a temporary build directory with project files and intermediate compilation outputs. This directory is automatically cleaned up after the process completes (or on error, if possible).
*   **Administrator Elevation:** The "Require Administrator Privileges" option modifies the executable's manifest to trigger UAC (User Account Control) prompts.
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
