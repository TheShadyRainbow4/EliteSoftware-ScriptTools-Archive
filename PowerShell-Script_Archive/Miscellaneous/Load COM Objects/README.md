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

## PowerShell COM Object Browser

The `PowerShell COM Object Browser` is an advanced utility for developers and system administrators that provides a graphical user interface (GUI) to browse, search, and launch executable COM objects registered on the system. It asynchronously scans the registry and displays filterable results, focusing specifically on COM objects that run as standalone executables.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This is an advanced tool for exploring registered COM objects on your system.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **Administrator Privileges (Recommended):** Running as an administrator is recommended to ensure a complete and unrestricted scan of the Windows Registry.

## 💽 Installation & Execution
1.  **Download:** Download the `Load_COM_Objects.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\Load_COM_Objects.PS1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
The application will automatically begin scanning for executable COM objects upon launch.

*   **Loading:** A progress bar will show the status of the COM object enumeration. This process may take some time.
*   **Searching:** Use the search box at the top to filter the list by ProgID, CLSID, or Description in real-time.
*   **Launching:** Select a COM object from the list and click **Launch Selected** to attempt to create an instance of it. The script will try to make the object visible if it has a standard `Visible` property.
*   **Viewing Details:** Select an object and click **View Details** to see more information, including its server path and registry location.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI Browser:** Displays registered executable COM objects in a clear, searchable data grid.
*   **Asynchronous Loading:** Scans the registry in the background without freezing the user interface.
*   **Live Filtering:** Instantly filters the results as you type in the search box.
*   **Targeted Scan:** Specifically enumerates `LocalServer32` type COM objects, which are standalone executables.
*   **Object Instantiation:** Allows users to attempt to launch selected COM objects.
*   **Detailed View:** Provides a detailed look at the properties of a selected COM object.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Core Logic:** Interacts directly with the Windows Registry to enumerate keys under `HKEY_CLASSES_ROOT\CLSID`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
This is an advanced tool intended for development and diagnostic purposes.

*   **Risk of Instability:** Launching unknown COM objects can cause unexpected behavior, system instability, or crashes. Use this feature with caution.
*   **Read-Only Scan:** The scanning and browsing functions are read-only and do not modify the registry.
*   **Administrator Access:** While the script may run as a standard user, it may fail to read certain protected registry keys, resulting in an incomplete list. Running as an administrator is recommended.

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
