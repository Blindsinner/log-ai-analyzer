# Universal Log Analyzer PowerShell Tool

**Version**: 5.3.9
**Author**: MD Faysal Mahmud

**Purpose**: A powerful PowerShell tool to detect and analyze errors in various log formats, including standard text logs (`.log`, `.txt`) and Windows Event Logs (`.evtx`). It uses a local offline error database, user-defined keywords (`errorcloud.txt`), and optional AI-powered diagnostics with Google Gemini as the primary provider. Key features include unified error analysis, multi-provider AI support, and professional, responsive HTML reports.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [Configuration](#configuration)
  - [Getting a Free Google Gemini API Key](#getting-a-free-google-gemini-api-key)
  - [Error-Cloud Keywords](#error-cloud-keywords)
  - [Offline Error Database](#offline-error-database)
  - [API Keys](#api-keys)
  - [File Locations](#file-locations)
- [Running the Tool](#running-the-tool)
- [Main Menu Options](#main-menu-options)
  - [1. Analyze Log File (Offline DB & optional online search)](#1-analyze-log-file-offline-db--optional-online-search)
  - [2. Analyze with AI Only](#2-analyze-with-ai-only)
  - [3. Select AI Model](#3-select-ai-model)
  - [4. Manage AI Providers & API Keys](#4-manage-ai-providers--api-keys)
  - [5. Exit](#5-exit)
- [Parse-LogFile Function](#parse-logfile-function)
- [Output Formats](#output-formats)
- [Output Files](#output-files)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Prerequisites
- Windows PowerShell (v5.1 or later).
- **Administrator privileges** may be required to read certain log files, especially `.evtx` files from secure locations.
- Internet connectivity for AI analysis or online search features.
- (Optional) API keys for Google (Gemini), OpenAI, or Azure OpenAI for AI diagnostics.
- Log files to be analyzed (e.g., `Application.evtx`, `IntuneManagementExtension.log`, etc.).
- `error_db.json` and `errorcloud.txt` must be present in the script’s root directory.

## Installation
1.  Clone or download the repository containing the script (`LogAnalyzer.ps1`), `errorcloud.txt`, and `error_db.json`.
2.  Place all files in a single folder (e.g., `C:\Scripts\LogAnalyzer`).
3.  Open a PowerShell prompt.
4.  Navigate to the script's folder:
    ```powershell
    cd "C:\Scripts\LogAnalyzer"
    ```

## First-Time Setup
PowerShell’s execution policy may block scripts from running. To allow the script:

1.  **Check Execution Policy**:
    ```powershell
    Get-ExecutionPolicy
    ```
    If it returns `Restricted`, scripts are blocked.

2.  **Allow the Script**:
    * **Option 1: Unblock the Script File (Recommended)**:
        ```powershell
        Unblock-File .\LogAnalyzer.ps1
        ```
    * **Option 2: Bypass for a Single Session**:
        ```powershell
        powershell -ExecutionPolicy Bypass -File .\LogAnalyzer.ps1
        ```

**Note**: Modifying execution policies has security implications. Only run scripts from trusted sources.

## Configuration

### Getting a Free Google Gemini API Key
The AI features of this tool work best with a Google Gemini API key, which is available with a generous free tier.

1.  **Go to Google AI Studio**: Navigate to [aistudio.google.com](https://aistudio.google.com/).
2.  **Sign In**: Sign in with your Google account.
3.  **Get API Key**: Click the `</> Get API key` button.
4.  **Create API Key**: Follow the prompts to create an API key in a new or existing project.
5.  **Copy the Key**: Copy the generated API key. When you run the AI analysis in the script for the first time, it will prompt you to enter this key.

The free tier is suitable for typical usage but has limits (e.g., requests per minute).

### Error-Cloud Keywords
-   **File**: `errorcloud.txt` (must be in the script’s root directory).
-   **Purpose**: Contains a comma-separated list of custom error keywords or phrases (e.g., "failed to connect,timed out,access denied").
-   The script will detect any line in the log that contains these keywords.

### Offline Error Database
-   **File**: `error_db.json` (must be in the root directory).
-   **Purpose**: A JSON file containing known error codes, their descriptions, and recommended solutions. This allows for instant, offline analysis.

### API Keys
-   API keys are used for the optional AI analysis features.
-   The script will prompt you for a key the first time you use a specific AI provider. The key is then saved to a `.txt` file in the root directory for future use.
-   **Key Files**:
    -   `gemini_key.txt` (Google Gemini)
    -   `openai_key.txt` (OpenAI)
    -   `azure_key.txt` (Azure OpenAI)
-   You can also add or update keys proactively using **Option 4** in the main menu.

### File Locations
-   **Root Directory** (where the `.ps1` script is located):
    -   `error_db.json`: The offline error database.
    -   `errorcloud.txt`: Your custom error keywords.
    -   `gemini_key.txt`, `openai_key.txt`, `azure_key.txt`: Saved API keys.
-   **Analyzed Result** (subfolder created automatically by the script):
    -   This folder stores all generated `.html` and `.txt` reports.

## Running the Tool
1.  Navigate to the script's folder in PowerShell.
2.  Run the script:
    ```powershell
    .\LogAnalyzer.ps1
    ```
3.  The Main Menu will appear:
    ```
    === Universal Log Analyzer Menu (v5.3.9 Gemini Enhanced) ===
    1. Analyze Log File (Offline DB & optional online search)
    2. Analyze with AI Only (Directly analyze log with selected AI)
    3. Select AI Model (Current: gemini-2.0-flash)
    4. Manage AI Providers & API Keys
    5. Exit
    Choose an option (1-5):
    ```

## Main Menu Options

### 1. Analyze Log File (Offline DB & optional online search)
-   **Input**: The path to a log file (e.g., `C:\Logs\Application.evtx` or `C:\Temp\someservice.log`).
-   **Process**:
    1.  Parses the log file, automatically handling `.evtx` or text-based formats.
    2.  Displays a **Detection Results** summary listing all found errors.
    3.  Prompts you to select a specific error or press Enter to analyze all of them.
    4.  For each selected error, it queries the local `error_db.json` and displays any matches in a clean, bordered format.
    5.  For errors not found in the local database, it offers to launch a Google search in your browser.
-   **Output**: A detailed `LogAnalysis_...txt` file and a professional `LogAnalysis_...html` report are saved in the `Analyzed Result` folder.

### 2. Analyze with AI Only
-   **Input**: The path to any log file (`.evtx`, `.log`, `.txt`, etc.) and your choice of AI provider.
-   **Process**:
    1.  Detects all errors and keywords.
    2.  Skips the offline database search entirely.
    3.  Sends each detected error and its log context to the selected AI provider for analysis.
    4.  Displays the AI's response in a standardized, clean, bordered format.
-   **Output**: An `AI_Analysis_...txt` report and a full `LogAnalysis_...html` report are saved.

### 3. Select AI Model
-   Allows you to change the AI model used for analysis.
-   **Default**: `gemini-2.0-flash`.
-   You can enter other compatible models like `gpt-4`. The selected model will be used by the corresponding AI provider.

### 4. Manage AI Providers & API Keys
-   A central menu for managing your API provider keys.
-   You can add or update keys for Google (Gemini), OpenAI, and Azure OpenAI.

### 5. Exit
-   Closes the tool.

## Parse-LogFile Function
This core function now intelligently detects the file type:
-   **For `.evtx` files**, it uses the `Get-WinEvent` cmdlet to properly read event log entries.
-   **For `.log`, `.txt`, and all other files**, it uses `Get-Content` to read them as plain text.

It then processes the text from either source to find hexadecimal codes, error-code phrases, and keywords from your `errorcloud.txt`.

## Output Formats
The script now enforces a standardized output format for both offline and AI analysis to ensure clarity and readability.

**Example Console Output:**

======================================================================
[AI Analysis for '0x80070643']

Description: This is a fatal error during installation, often related to MSI packages, permissions, or corrupted installations.

Recommended Solutions:

Check the application install command in the Intune portal for syntax errors.

Ensure the user or system has adequate permissions to the installation directory.

Test the installation command manually on a test device with elevated privileges.

Clear the CCM cache if the application was previously installed or failed.
======================================================================


## Output Files
-   **Location**: All reports are saved in the `Analyzed Result` subfolder.
-   **Files**:
    -   `LogAnalysis_YYYYMMDD_HHMMSS.txt`: A text summary of the analysis.
    -   `LogAnalysis_YYYYMMDD_HHMMSS.html`: A professional HTML report with a card-based layout for each error, showing details and solutions.
    -   `AI_Analysis_YYYYMMDD_HHMMSS.txt`: A text file containing only the results from the "Analyze with AI Only" option.

## Troubleshooting
-   **No Detections**:
    -   Ensure your `errorcloud.txt` contains relevant keywords.
    -   Verify the log file path is correct and accessible. For `.evtx` files, you may need to run PowerShell as an Administrator.
-   **File Not Found Errors**:
    -   Make sure `error_db.json` and `errorcloud.txt` are in the same folder as the script.
-   **AI Not Working**:
    -   Use **Option 4** to verify your API key is set correctly.
    -   Check your internet connection and any firewalls that might block access to AI endpoints.
-   **HTML Report Issues**:
    -   Open the report in a modern web browser (Edge, Chrome, Firefox).
    -   Confirm the file exists in the `Analyzed Result` folder.

## License
Licensed under the MIT License.
