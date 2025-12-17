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
## Screenshot may be slightly outdated. Sorry in advance! :)
<br />
<div align="center">
<!-- <a href="Screenshot">
<!-- <img src="https://i.postimg.cc/Y9QyWx7m/image.png" alt="GUI Screenshot" width="1280" height="720">
<!-- </a> -->
</div>

## New-DummyDll: PowerShell Dummy DLL Generator

`New-DummyDll` is a PowerShell function designed to create a minimal, valid, yet empty Dynamic Link Library (DLL) file. It achieves this by programmatically constructing the essential binary headers (DOS stub, PE signature, COFF header, Optional PE header, and Data Directories) and writing them directly to a specified file path. This utility can be invaluable for development, testing, or as a placeholder in scenarios where a small, valid DLL structure is required without any functional code.

Built by: EliteSoftware Enterprises / Zachary Whiteman / Google Gemini AI.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script provides a simple function to generate dummy DLL files.

## 🕰️ Prerequisites
To run this script, you only need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 2.0 or newer:** This function relies on basic PowerShell language features and .NET methods.

## 💽 Installation & Execution
1.  **Download:** Download the `New-DummyDll.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Load the Function:** To use the function in your PowerShell session, dot-source the script:
    ```powershell
    . .
New-DummyDll.ps1
    ```
    Once loaded, the `New-DummyDll` function will be available in your current session.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The `New-DummyDll` function takes one mandatory string argument, `$Path`, which specifies the full path and filename for the dummy DLL to be created.

### Syntax
```powershell
New-DummyDll -Path <FilePathAndName>
```

### Parameters
*   `-Path <FilePathAndName>`: The full path, including the filename and `.dll` extension, where the dummy DLL will be created (e.g., `"C:\temp\MyDummy.dll"`).

### Examples
```powershell
# Example 1: Create a dummy DLL in the current directory
New-DummyDll -Path ".\test_dummy.dll"

# Example 2: Create a dummy DLL in a specific temporary location
New-DummyDll -Path "C:\temp\placeholder.dll"

# Example 3: Create a dummy DLL as a placeholder for a missing dependency
New-DummyDll -Path "C:\Program Files\MyApp\missing_dependency.dll"
```
The function will create a valid 32-bit PE (Portable Executable) file (a DLL) at the specified location. This DLL will be minimal in size and contain no executable code beyond its headers.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Minimal DLL Generation:** Creates a fully compliant, yet empty, 32-bit Windows Dynamic Link Library (DLL) file.
*   **Low-Level Control:** Constructs the essential binary headers (DOS stub, PE signature, COFF header, Optional PE header, and Data Directories) programmatically in PowerShell.
*   **Lightweight Output:** The generated DLL files are extremely small, containing only the necessary structural metadata.
*   **Customizable Output Location:** Users can specify any valid file path for the creation of the dummy DLL.
*   **Development & Testing Utility:** Useful for creating placeholders, testing file system operations, or for environments that require a valid DLL presence without specific functionality.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The function is entirely written in PowerShell, utilizing its core capabilities and .NET integration:

*   **Scripting Language:** PowerShell
*   **Byte Array Manipulation:** `System.Text.Encoding` for converting strings to byte arrays and `System.BitConverter` for converting various data types (integers, shorts) into byte representations for binary file construction.
*   **File System Operations:** `System.IO.File::WriteAllBytes` for directly writing the constructed byte array to a file, forming the DLL.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`New-DummyDll.ps1` is a self-contained, low-level file generation utility.

*   **Self-Contained:** The script does not rely on external dependencies or complex modules.
*   **Direct Binary Creation:** It directly manipulates byte arrays to form the binary structure of a DLL. This is a powerful, low-level operation.
*   **No Executable Code:** The generated DLL is intentionally empty of executable code beyond the standard PE file format headers. It will not perform any actions when loaded by an application; it serves purely as a structural placeholder.
*   **Input Handling:** The function expects a valid file path. No specific validation is performed within the script to check for write permissions or valid path formats, so users should ensure they provide appropriate input.
*   **No Telemetry:** The script does not collect or transmit any user data or telemetry.

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
