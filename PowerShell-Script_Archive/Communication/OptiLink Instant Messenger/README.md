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

## Opti-Link Instant Messenger: An AI Chat Client for LM Studio & Local GGUF Models

Opti-Link Instant Messenger is a custom PowerShell GUI application built using Windows Forms (.NET WinForms) designed to provide an interactive chat client experience for AI models. It offers seamless integration with LM Studio (via its local server API) and robust support for running local GGUF models directly using `llama.cpp` within a dedicated PowerShell Runspace.

This application empowers users to communicate with various AI personalities, configure model parameters, manage chat history, and customize their interface with a thematic design.

Built by: EliteSoftware Enterprises / Zachary Whiteman / Google Gemini Ai

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script and does not require a complex installation process.

## 🕰️ Prerequisites
To run this script, you only need:

*   Windows Operating System (Windows 7 or later).
*   PowerShell 5.1 or newer (PowerShell Core is supported, but the script is optimized for the full .NET Framework available in Windows PowerShell for WinForms).
*   The required .NET Framework assemblies (System.Windows.Forms, System.Drawing, System.IO.Compression.FileSystem) which are included with modern Windows installations and loaded automatically by the script.
*   **For LM Studio Integration:** LM Studio application running a local server.
*   **For Local GGUF Support:** Compatible `.gguf` model files. The script is pre-configured to expect `llama-cli.exe` binaries for local execution.

## 💽 Installation & Execution
1.  **Download:** Download the `OptiLink Instant Messenger.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it (if your system is configured to run PS1 files).
    ```powershell
    .\OptiLink Instant Messenger.PS1
    ```

The application's configuration files (settings.json, icons, logs) are stored in:
`[Script Directory]\OptiLink_Config`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Opti-Link Instant Messenger provides a tabbed interface for managing your AI chat experience:

*   **Chat Tab:** Your primary chat interface. Type your prompts and view AI responses in chat bubbles. The model status is displayed at the top.
*   **Connection Tab:** Configure your LM Studio server URL and port, or select a local GGUF model for direct execution.
*   **Model Parameters Tab:** Adjust AI behavior with settings like Temperature, System Prompt (personas), GPU Offload, and Context Length.
*   **Templates Tab:** Manage additional stop strings and set response length limits.
*   **Models Tab:** Scan for and select local `.gguf` model files for use with the local backend.

**Key Interactions:**
*   **Sending Messages:** Use the "Send" button or your configured hotkey (Enter, Ctrl+Enter, or Shift+Enter).
*   **Settings (`File > Settings`):** Customize application icon, send message hotkey, backend preference (LM Studio/Local GGUF), and theme.
*   **Changelog (`Help > Changelog`):** View application version history.
*   **Minimize to Tray:** Minimize the application window to send it to the system tray. Double-click the tray icon to restore.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **Dual Backend Support:** Seamlessly switch between LM Studio's HTTP API and local GGUF models powered by `llama.cpp`.
*   **Interactive Chat Bubbles:** WebBrowser control-based chat interface with dynamic HTML/CSS styling for clear conversation flow.
*   **Streaming AI Responses:** For local GGUF models, AI responses are streamed word-by-word for a more natural interaction.
*   **Comprehensive Settings:** Persistent configuration for connection details, model parameters, themes, and UI preferences.
*   **Model Parameter Tuning:** Fine-tune AI responses with configurable Temperature, System Prompts (personas), GPU Offload layers, and Context Length.
*   **Prompt Templating:** Define custom stop strings to control AI output and set maximum response token limits.
*   **Local GGUF Model Management:** Easily scan for and select `.gguf` models directly from your file system.
*   **PowerShell Runspace for `llama.cpp`:** Executes `llama-cli.exe` in a dedicated, stable PowerShell Runspace, ensuring UI responsiveness and reliable background processing.
*   **Themed GUI:** Features a distinct Teal theme with custom menu rendering, and the option to switch to a more standard theme.
*   **System Tray Integration:** Minimize the application to the system tray for discreet background operation.
*   **Robust Logging:** Comprehensive logging system with automatic archiving of logs and detailed error reports, helping with diagnostics.
*   **Customizable Icon:** Set a custom application icon for personalization.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The entire application is a self-contained PowerShell script, utilizing:

*   **Scripting Language:** PowerShell (5.1+)
*   **GUI Framework:** .NET Windows Forms (WinForms)
*   **Chat Rendering:** `System.Windows.Forms.WebBrowser` for rich HTML/CSS chat bubbles.
*   **AI Backend Integration:**
    *   `Invoke-RestMethod` for communication with LM Studio's HTTP API.
    *   Dedicated PowerShell Runspaces for stable execution of local `llama-cli.exe` processes.
*   **File Management & Archiving:** `System.IO.Compression.FileSystem` and PowerShell native commands for dependency handling (e.g., `llama.cpp` download/extraction).
*   **Persistence:** JSON-based configuration files (`settings.json`).
*   **Dynamic UI:** Custom `ToolStripProfessionalRenderer` for themed menu bars.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
Opti-Link Instant Messenger is primarily a client-side application designed to interact with either locally-hosted AI models (LM Studio) or directly with local `llama.cpp` binaries.

*   **Local-First Operation:** The application prioritizes local execution and interaction. LM Studio connections are typically to `localhost`, and GGUF models run directly on your machine.
*   **External AI Binaries:** For local GGUF support, the application relies on external `llama.cpp` binaries. While the script attempts to manage these, users are responsible for ensuring the integrity and security of these external executables.
*   **PowerShell Runspaces:** The use of dedicated PowerShell Runspaces for `llama.cpp` execution ensures that the main GUI thread remains responsive and that AI model processing is isolated, enhancing stability.
*   **Configuration Storage:** All application settings are stored locally in JSON files within the `OptiLink_Config` directory, adjacent to the script. No external cloud services are used for configuration.
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
