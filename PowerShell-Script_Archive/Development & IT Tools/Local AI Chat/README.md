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

## PowerShell LM Studio Chat v1.4

`PowerShell LM Studio Chat` is a robust Windows Forms (WinForms) GUI application built with PowerShell, designed to facilitate interaction with local AI models powered by LM Studio. This script provides a user-friendly interface for connecting to your local LM Studio server, selecting from loaded AI models, customizing system prompts to influence AI behavior, and engaging in natural language conversations with a maintained chat history. Version 1.4 features re-architected event handling for enhanced stability and comprehensive logging for improved diagnostics.

Built by: Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This application is a single PowerShell script designed for interacting with local AI models.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script leverages PowerShell's capabilities for GUI development and API interaction.
*   **Required .NET Assemblies:** `System.Windows.Forms`, `System.Drawing` (included with modern Windows installations).
*   **LM Studio:** The LM Studio application must be installed and running on your local machine, with a model loaded and its local server API enabled.

## 💽 Installation & Execution
1.  **Download:** Download the `Local_Ai_Chat.PS1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Run:** Execute the script from a PowerShell console or by double-clicking it.
    ```powershell
    .\Local_Ai_Chat.PS1
    ```

A detailed log file named `LMChatGUI.log` will be created in the script's directory (or your user's `%TEMP%` directory if the script path cannot be determined), documenting the application's activity.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
Upon launching the application, you will find a straightforward interface:

1.  **Configure LM Studio Server:**
    *   Enter the URL (e.g., `http://localhost:1234`) of your running LM Studio server in the provided text box.
    *   Click the **"Connect"** button to fetch a list of available AI models from the server.
2.  **Select AI Model:**
    *   Choose your desired AI model from the "Select Model" dropdown list.
3.  **Set System Prompt (Optional):**
    *   Enter a system prompt in the "System Prompt" text box to define the AI's persona or behavioral guidelines (e.g., "You are a helpful assistant.").
4.  **Chat with the AI:**
    *   Type your messages into the "User Input" text box.
    *   Click the **"Send"** button (or press Enter) to send your message to the AI.
    *   The conversation will be displayed in the "Chat History" box.

The script provides status updates in the status bar at the bottom of the window, informing you about connection status and AI activity.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **GUI-driven AI Chat:** Provides an intuitive Windows Forms graphical user interface for easy interaction with local AI models.
*   **LM Studio API Integration:** Seamlessly connects to and leverages the local API of LM Studio for chat completion services.
*   **Dynamic Model Selection:** Allows users to dynamically fetch and select from models currently loaded and served by LM Studio.
*   **Configurable System Prompt:** Empower users to set a custom system prompt, enabling persona-driven conversations with the AI.
*   **Persistent Chat History:** Maintains the flow of conversation within the chat history display, providing context for ongoing interactions.
*   **Robust Logging System:** Implements a comprehensive logging function that outputs detailed information to both a dedicated log file and the console, aiding in debugging and monitoring.
*   **Error Resiliency:** Features extensive `try-catch-finally` blocks for robust error handling, ensuring the application can gracefully manage unexpected issues.
*   **Modular Event Handling:** Re-architected event handler logic into separate, focused functions for improved code readability, maintainability, and stability.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The application is a self-contained PowerShell script, utilizing:

*   **Scripting Language:** PowerShell
*   **GUI Framework:** .NET Windows Forms (WinForms) for all graphical user interface elements.
*   **API Communication:** `Invoke-RestMethod` for making HTTP POST requests to the LM Studio's local API.
*   **Text Rendering:** `System.Windows.Forms.RichTextBox` for displaying styled chat history, including different colors for user and AI messages.
*   **Error Handling:** PowerShell's native `try-catch-finally` blocks and custom `Write-Log` function for robust error management and logging.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
`PowerShell LM Studio Chat` is designed as a client-side application for local AI interaction.

*   **Local Execution:** The script runs entirely on your local Windows machine.
*   **Local AI Interaction:** Primarily connects to an LM Studio server typically running on `localhost`. This setup keeps AI processing and data local to your machine.
*   **LM Studio API:** Communication is via standard HTTP requests to the LM Studio API. Users should ensure their LM Studio server configuration is secure, especially if it's made accessible beyond `localhost`.
*   **Logging:** All application activities and errors are logged to a file (`LMChatGUI.log`) for diagnostic purposes. This log file is stored locally and is not transmitted.
*   **No Data Persistence:** This specific version of the script does not save connection settings or chat history across application sessions.
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
