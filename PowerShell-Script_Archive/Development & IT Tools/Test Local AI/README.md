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

## Test Local AI Script v1.1

The `Test Local AI Script` is a straightforward PowerShell utility designed for quickly verifying the functionality and connectivity of a local AI model hosted by LM Studio. This script sends a predefined conversational prompt to your LM Studio API endpoint and then displays the AI's response directly in the PowerShell console. It serves as an excellent basic health check for your local AI setup, allowing you to confirm that your LM Studio server is running, reachable, and successfully processing requests from a specific model.

Built by: Gemini

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

# 🔰 Getting Started
This script is a simple utility to test your local AI setup.

## 🕰️ Prerequisites
To run this script, you will need:

*   **Windows Operating System:** (Windows 7 or later).
*   **PowerShell 5.1 or newer:** This script uses PowerShell's capabilities for web requests and JSON handling.
*   **LM Studio:** The LM Studio application must be installed and running on your local machine, with a model loaded and its local server API enabled. The script is configured to use `http://192.168.10.100:1234` and the `google/gemma-3-12b` model. **You may need to edit these values within the script to match your specific LM Studio setup.**
*   **Internet Connection:** Not strictly required if LM Studio is running entirely locally and not fetching remote resources, but good practice.

## 💽 Installation & Execution
1.  **Download:** Download the `Test-LocalAI.ps1` script file.
2.  **Unblock:** Right-click the file, go to Properties, and click `Unblock` if the file was downloaded from the internet.
3.  **Configure API URL and Model:** Open the `Test-LocalAI.ps1` script in a text editor and adjust the `$apiUrl` variable and the `model` parameter within the `$body` payload to match your LM Studio server address and the specific model you wish to test.
    ```powershell
    # 1. Define the server address from your LM Studio setup
    $apiUrl = "http://YOUR_LM_STUDIO_IP_OR_HOSTNAME:YOUR_PORT/v1/chat/completions" # e.g., "http://localhost:1234/v1/chat/completions"

    # ... (inside $body payload)
        model = "YOUR_MODEL_IDENTIFIER" # e.g., "google/gemma-3-12b"
    ```
4.  **Run:** Execute the script from a PowerShell console.
    ```powershell
    .\Test-LocalAI.ps1
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🚀 Usage
When you run the script, it will perform the following actions:

1.  **Send Prompt:** It constructs a JSON payload with a predefined system prompt ("You are a helpful assistant for an 'Elite' software utility developer.") and a user prompt ("In three sentences, what makes PowerShell a powerful tool for Windows administration?").
2.  **Invoke API:** It sends this payload as an HTTP POST request to the specified LM Studio API URL.
3.  **Display Response:** Upon receiving a successful response from LM Studio, it extracts the AI's generated content and prints it to your PowerShell console.
4.  **Error Reporting:** If there's an issue connecting to LM Studio or receiving a response, it will display an error message with details.

This script is ideal for quickly confirming the operational status of your local AI server and specific models without needing a full chat client.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## ✨ Key Features
*   **LM Studio API Interaction:** Directly communicates with your local LM Studio server via its HTTP API.
*   **Quick Connectivity Test:** Provides a fast way to verify that your LM Studio instance is running and responding to API calls.
*   **Predefined Conversational Prompt:** Comes with a ready-to-use system and user prompt for immediate testing.
*   **Targeted Model Testing:** Allows specifying a particular AI model (e.g., `google/gemma-3-12b`) for interaction.
*   **Console Output:** Displays the AI's response clearly in the PowerShell console.
*   **Basic Error Reporting:** Catches common network and API errors, providing informative messages to the user.
*   **Customizable API Endpoint:** Easy to modify the target LM Studio API URL and model identifier within the script.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 🛠️ Technology Stack
The script is developed entirely in PowerShell, leveraging its web and data handling capabilities:

*   **Scripting Language:** PowerShell
*   **Web Requests:** `Invoke-RestMethod` for making HTTP POST requests to the LM Studio API endpoint.
*   **JSON Processing:** `ConvertTo-Json` for serializing PowerShell objects into JSON payloads required by the API.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 📐 Architecture & Security Notes
The `Test Local AI Script` is a simple client-side utility interacting with a local AI server.

*   **Local Interaction:** The script is designed to communicate with a locally hosted AI model via LM Studio. No external servers or cloud services are involved.
*   **LM Studio API:** Communication with LM Studio occurs over its local HTTP API. Users should ensure their LM Studio setup is properly secured if they expose it beyond `localhost`.
*   **Hardcoded Configuration:** The API URL and specific model identifier are hardcoded in the script. Users must manually update these values to match their LM Studio environment.
*   **No Data Persistence:** The script does not store any chat history or configuration settings.
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
