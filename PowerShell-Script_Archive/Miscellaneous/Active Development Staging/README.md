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

## Opti-Link Instant Messenger (Active Development)

**Note:** This file (`OptiLink_Instant_Messenger_v0.9.3.6_Dev.ps1`) appears to be the most recent, active development version of the **Opti-Link Instant Messenger** application (v0.9.3.6).

Opti-Link is a sophisticated PowerShell-based chat client designed to interface with local Large Language Models (LLMs) via **LM Studio** or directly using a local `llama.cpp` backend (experimental). It provides a modern, "instant messenger" style interface for chatting with AI models running on your own hardware.

Built by: Zachary Whiteman & Google Gemini Ai.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application requires a running instance of LM Studio's local server or a local GGUF model configuration.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System.**
*   **PowerShell 5.1 or newer.**
*   **.NET Framework:** Required for the Windows Forms GUI.
*   **LM Studio:** For the standard backend, you must have [LM Studio](https://lmstudio.ai/) installed and its local server running (default: `http://localhost:1234`).
*   **llama.cpp (Optional):** For the experimental local GGUF backend, the script may attempt to use or require a local `llama-cli.exe`.

## 💽 Installation & Execution
1.  **Download:** Download the script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    ."\OptiLink_Instant_Messenger_v0.9.3.6_Dev.ps1"
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Features

### Chat Interface
*   **Modern UI:** Uses a WebBrowser control to render chat bubbles with HTML/CSS, providing a clean and readable conversation history.
*   **Streaming Responses:** Supports real-time text streaming from the AI model (especially with the local GGUF backend).
*   **Theming:** Supports a custom "Teal" theme and standard system colors.
*   **System Tray:** Minimizes to the system tray for background operation.

### Connectivity & Models
*   **LM Studio Integration:** Connects seamlessly to the LM Studio API.
*   **Local GGUF (Experimental):** Features an experimental backend to run GGUF models directly using `llama.cpp`.
*   **Model Management:** View loaded models and fetch a list of all downloaded models available in LM Studio or locally.
*   **Parameters:** Fine-tune model behavior with controls for Temperature, System Prompt, Context Length, and GPU Offload.

### Customization
*   **Personas:** Choose from pre-defined system prompts (e.g., "Helpful Assistant", "Pirate Captain") or create your own.
*   **Templates:** Configure stop strings and response length limits.
*   **Settings:** Customize hotkeys (Enter vs Ctrl+Enter), icons, and backend preferences.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms).
*   **Chat Rendering:** HTML/CSS via the `.NET WebBrowser` control.
*   **Data Persistence:** JSON configuration files.
*   **Async Processing:** Uses threading and event handlers for responsive UI during AI generation.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
*   **Local Communication:** The app communicates over `http` to `localhost`. Ensure your firewall allows local loopback traffic on port 1234 (or your configured port).
*   **Portable Config:** The application creates a folder named `OptiLink_Config` in the same directory as the script to store settings, logs, and icons.

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
