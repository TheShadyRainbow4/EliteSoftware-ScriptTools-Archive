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

## getRelativePath: A PowerShell Function for Calculating Relative Paths

`getRelativePath` is a straightforward PowerShell function designed to calculate the relative path from a starting point (`$from`) to a destination (`$to`). It provides a programmatic way to determine how to navigate from one location in a file system to another using relative references (e.g., `../`, `./`). The function is versatile enough to handle different slash types and allows for a custom path separator.

Built by: EliteSoftware Enterprises / Zachary Whiteman / Google Gemini Ai

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This function is a standalone PowerShell script.

## 🕰️ Prerequisites
To use this script, you only need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 2.0 or newer:** This function relies on basic PowerShell language features.

## 💽 Installation & Execution
1.  **Download:** Download the `getRelativePath.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Load the Function:** To use the function in your PowerShell session, dot-source the script:
    ```powershell
    . .\getRelativePath.ps1
    ```
    Once loaded, the `getRelativePath` function will be available in your current session.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The `getRelativePath` function takes two mandatory string arguments (`$from`, `$to`) and one optional string argument (`$joinSlash`).

### Syntax
```powershell
getRelativePath -from <SourcePath> -to <DestinationPath> [-joinSlash <Separator>]
```

### Parameters
*   `-from <SourcePath>`: The base path from which to start the relative calculation.
*   `-to <DestinationPath>`: The target path to which the relative path should point.
*   `-joinSlash <Separator>`: (Optional) The character(s) to use as the path separator in the returned relative path. Defaults to `/`.

### Examples
```powershell
# Example 1: Basic usage
getRelativePath -from "C:/Folder1/Folder2" -to "C:/Folder1/Folder3/File.txt"
# Expected Output: ../Folder3/File.txt

# Example 2: Paths with Windows backslashes
getRelativePath -from "C:\Users\John" -to "C:\Users\John\Documents\Report.docx"
# Expected Output: Documents/Report.docx

# Example 3: Using a custom separator
getRelativePath -from "C:\Projects\ProjectA" -to "C:\Projects\ProjectA\src\main.js" -joinSlash "\"
# Expected Output: src\main.js

# Example 4: Traversing up multiple levels
getRelativePath -from "C:\a\b\c" -to "C:\a\d\e\file.txt"
# Expected Output: ../../d/e/file.txt
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Accurate Relative Path Calculation:** Reliably determines the shortest relative path between two given file system locations.
*   **Flexible Path Inputs:** Accepts paths using either forward slashes (`/`) or backslashes (`\`), normalizing them internally for consistent processing.
*   **Customizable Path Separator:** Allows the user to define the character(s) used to join path segments in the output.
*   **Simple Integration:** Can be easily loaded into any PowerShell session by dot-sourcing the script.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The function is entirely written in PowerShell, utilizing core language features:

*   **Scripting Language:** PowerShell
*   **Data Structures:** `System.Collections.ArrayList` for dynamic manipulation of path segments.
*   **String Manipulation:** Regular expressions (`-replace`) and string splitting/joining for path processing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `getRelativePath` function is a self-contained, stateless utility.

*   **Self-Contained:** It does not rely on external modules or complex APIs beyond standard PowerShell.
*   **No Side Effects:** The function is designed to be pure, meaning it calculates and returns a value without modifying the system state or interacting with the file system directly (e.g., creating/deleting files).
*   **Input Validation:** Basic input handling is performed (e.g., slash normalization), but users are responsible for providing valid and well-formed input paths.
*   **No Telemetry:** The function does not collect or transmit any data.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🪳 License
Distributed under the MIT License. See LICENSE.txt for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ☎️ Contact
Zach Whiteman - elitesoftwarecolimited@gmail.com

HuggingFace - https://huggingface.co/EliteSoftware

HuggingFace (Personal) - https://huggingface.co/TheShadyRainbow

LinkTree - https://linktr.ee/zachrainbow

Patreon - https://www.patreon.com/c/EliteSoftwareCo

<p align="right">(<a href="#readme-top">back to top</a>)</p>
