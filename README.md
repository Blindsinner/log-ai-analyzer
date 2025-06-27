# Universal Log Analyzer PowerShell Tool

**Version**: 6.0
**Author**: MD Faysal Mahmud
**Contribute**: We welcome contributions! Help improve this tool on [GitHub](https://github.com/Blindsinner/LogAnalyzer-Powershell-).

---

## Overview

The Universal Log Analyzer is a powerful, menu-driven PowerShell tool designed for IT professionals and system administrators to efficiently diagnose errors from a wide variety of sources. It excels at parsing complex log formats from environments like Microsoft Intune and Autopilot but is flexible enough for any log analysis task.

It supports compressed archives (`.zip`), Microsoft Excel files (`.xlsx`), Windows Event Logs (`.evtx`, `.etl`), and all text-based formats (`.log`, `.txt`, `.html`, `.xml`). The tool uses a hybrid analysis model, combining a fast offline database for known errors, user-defined keyword detection, and advanced AI-powered diagnostics via Google Gemini, OpenAI, or Azure OpenAI.

### Key Features
-   **Universal File Support**: Natively analyzes `.zip`, `.xlsx`, `.xls`, `.evtx`, `.etl`, `.log`, `.txt`, `.html`, `.xml`, and any other text-readable file.
-   **Recursive Archive Analysis**: Automatically extracts and analyzes the entire contents of `.zip` archives.
-   **Multi-Provider AI Diagnostics**: Integrates with Google Gemini, OpenAI, and Azure OpenAI to provide expert-level descriptions and solutions for unknown errors.
-   **Offline Error Database**: Delivers instant results for common errors using a local `error_db.json` file.
-   **Custom Keyword Detection**: Allows users to define a custom list of keywords to search for via `errorcloud.txt`.
-   **Professional Reports**: Generates detailed analysis reports in both plain text (`.txt`) and a beautifully styled, responsive HTML format.
-   **Interactive Menu**: A user-friendly, menu-driven interface makes all features easily accessible.

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation and Setup](#installation-and-setup)
- [Configuration](#configuration)
  - [Getting a Free Google Gemini API Key](#getting-a-free-google-gemini-api-key)
  - [Error-Cloud Keywords](#error-cloud-keywords)
  - [Offline Error Database](#offline-error-database)
  - [API Keys](#api-keys)
  - [File and Folder Structure](#file-and-folder-structure)
- [Running the Tool](#running-the-tool)
- [Main Menu Options](#main-menu-options)
- [The `Parse-LogFile` Function: How It Works](#the-parse-logfile-function-how-it-works)
- [Output Formats](#output-formats)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Prerequisites
-   Windows PowerShell 5.1 or later.
-   **`ImportExcel` Module**: This is **required** for analyzing `.xlsx` and `.xls` files.
-   **Administrator Privileges**: Recommended for installing modules and required for reading certain system logs (`.evtx`).
-   **Internet Connectivity**: Required for AI-powered analysis and the online search feature.
-   **Project Files**: The script (`LogAnalyzer.ps1`), `error_db.json`, and `errorcloud.txt` must all be located in the same directory.

## Installation and Setup

### Step 1: Get the Project Files
Clone or download the entire project repository from [GitHub](https://github.com/Blindsinner/LogAnalyzer-Powershell-). Place all files (`LogAnalyzer.ps1`, `error_db.json`, `errorcloud.txt`) into a single folder (e.g., `C:\Tools\LogAnalyzer`).

### Step 2: Install Dependencies
The tool requires the `ImportExcel` module to read spreadsheet files. Open a PowerShell terminal **as an Administrator** and run the following command once:
```powershell
Install-Module -Name ImportExcel -AcceptLicense -Force
```

### Step 3: Allow the Script to Run
By default, PowerShell's security policy may prevent scripts from running. The recommended way to permit this script is to "unblock" the file.

1.  Open a regular (non-admin) PowerShell window.
2.  Navigate to the directory where you saved the script.
    ```powershell
    cd C:\Tools\LogAnalyzer
    ```
3.  Run the `Unblock-File` cmdlet:
    ```powershell
    Unblock-File -Path .\LogAnalyzer.ps1
    ```
Now, you can run the script without changing your system's global execution policy.

---

## Configuration

### Getting a Free Google Gemini API Key
The AI features work best with a Google Gemini API key, which has a generous free tier suitable for most users.

1.  **Go to Google AI Studio**: Navigate to [aistudio.google.com](https://aistudio.google.com/).
2.  **Sign In** with your Google account.
3.  Click the **`</> Get API key`** button.
4.  **Create API Key**: Follow the prompts to create an API key.
5.  **Copy the Key**: When you use an AI feature in the script for the first time, it will prompt you to enter this key.

### Error-Cloud Keywords
-   **File**: `errorcloud.txt`
-   **Purpose**: Define a custom list of keywords you want the tool to find. The script will flag any line containing these terms.
-   **Format**: A simple, comma-separated list.
    ```
    failed to connect,timeout,access denied,cannot find,critical error
    ```

### Offline Error Database
-   **File**: `error_db.json`
-   **Purpose**: Provides instant, offline analysis for common errors. You can contribute to this database to make the tool more powerful for everyone.
-   **Format**: A JSON array of objects, where each object has three properties:
    ```json
    [
      {
        "ErrorCode": "0x80070005",
        "Message": "Access is denied.",
        "Solution": "1. Run the process with elevated (Administrator) privileges. 2. Check NTFS permissions on the target file or folder. 3. Ensure no security software is blocking the action."
      }
    ]
    ```

### API Keys
When you use an AI provider for the first time, the script will ask for your API key and save it to a local text file for convenience. You can also manage keys proactively via **Option 4** in the menu.
-   `gemini_key.txt` (Google Gemini)
-   `openai_key.txt` (OpenAI)
-   `azure_key.txt` (Azure OpenAI)

### File and Folder Structure
To function correctly, the files must be organized as follows:
```
C:\Tools\LogAnalyzer\
│
├── LogAnalyzer.ps1         (The main script)
├── error_db.json           (The offline error database)
├── errorcloud.txt          (Your custom keywords)
├── gemini_key.txt          (Auto-generated)
│
└── Analyzed Result\        (Auto-generated subfolder)
    └── LogAnalysis_...html (Generated reports are saved here)
    └── LogAnalysis_...txt
```

---

## Running the Tool
1.  Navigate to the script's folder in PowerShell.
2.  Execute the script:
    ```powershell
    .\LogAnalyzer.ps1
    ```
3.  The main menu will appear, ready for your selection.

## Main Menu Options

#### `1. Analyze Log File (Offline DB & optional online search)`
This is the standard, hybrid analysis mode.
-   **Workflow**:
    1.  Parses the source file(s) to detect all error codes and keywords.
    2.  For each detected item, it first queries the fast, offline `error_db.json`.
    3.  If a match is found, it displays the known solution.
    4.  For any item *not* found in the database, it gives you the option to instantly launch a Google search for it.
-   **Output**: Saves a comprehensive `.html` report and a `.txt` summary to the `Analyzed Result` folder.

#### `2. Analyze with AI Only`
This mode bypasses the offline database and sends all detected errors directly to an AI for analysis. It is ideal for complex or obscure errors not found in the local database.
-   **Workflow**:
    1.  Parses the source file(s) to detect all errors.
    2.  Prompts you to select an AI provider (Gemini, OpenAI, or Azure).
    3.  Sends each detected error and its surrounding log context to the AI.
    4.  Displays the formatted response from the AI, which includes a description and recommended solutions.
-   **Output**: Saves a dedicated `AI_Analysis_...txt` file and a full `.html` report.

#### `3. Select AI Model`
Lets you specify which AI model to use (e.g., `gemini-2.0-flash`, `gpt-4`). This allows you to switch between different models offered by a provider.

#### `4. Manage AI Providers & API Keys`
A settings menu where you can securely add or update the API keys for any of the supported AI providers.

#### `5. Exit`
Closes the application.

---

## The `Parse-LogFile` Function: How It Works
This is the intelligent core of the script. It automatically identifies the file type and uses the correct method to extract text for analysis:

-   **`.zip` files**: It uses `Expand-Archive` to unpack the contents into a temporary directory. It then **recursively** calls itself to analyze every file inside, ensuring no log is missed. All results are aggregated before the temporary folder is deleted.
-   **`.xlsx` and `.xls` files**: It leverages the `Import-Excel` module to read all data from all worksheets, converting each row into a searchable text string.
-   **`.evtx` and `.etl` files**: It uses the native `Get-WinEvent` cmdlet to correctly parse and read messages from these binary Windows Event Log formats.
-   **All Other Files**: For `.log`, `.txt`, `.html`, `.xml`, or any other format, it falls back to `Get-Content`, reading the file as plain text.

This universal approach allows you to drop almost any file into the analyzer and get meaningful results.

---

## Output Formats

#### Console Output
All results are displayed in a clean, easy-to-read format in the console, using borders to separate each analyzed item.
```
======================================================================
[AI Analysis for '0x80070643']

Description: This is a fatal error during installation, often related to MSI packages, permissions, or corrupted installations.

Recommended Solutions:
1. Check the application install command in the Intune portal for syntax errors.
2. Ensure the user or system has adequate permissions to the installation directory.
======================================================================
```

#### File Outputs
-   **HTML Report (`LogAnalysis_...html`)**: A professional, styled HTML file with a responsive, card-based layout. Each card represents a found error and neatly organizes its description, recommended solutions, and the original log context.
-   **Text Report (`.txt`)**: A simple text file containing a summary of the analysis, suitable for quick viewing or copying.

---

## Troubleshooting
-   **Excel File Errors**: If you see a warning that the `ImportExcel` module is not found, you did not complete Step 2 of the installation. Please run `Install-Module -Name ImportExcel` from an **Administrator** PowerShell window.
-   **File Not Found**: Ensure `error_db.json` and `errorcloud.txt` are in the same directory as `LogAnalyzer.ps1`.
-   **No Detections**: Verify the log file path is correct. For protected system logs like the Security event log, you must run PowerShell as an Administrator. Also, check that your `errorcloud.txt` has relevant keywords.
-   **AI Analysis Fails**: Use **Option 4** to check that your API key is correct. Verify your internet connection and ensure no firewall is blocking access to `googleapis.com` or `openai.com`.

---

## Contributing
This project is open source, and community contributions are highly encouraged and welcome! You can help make this tool better for everyone.

**How to Contribute:**
-   **Report Bugs**: If you find a bug, please open an issue on GitHub. Include the error message, the type of file you were analyzing, and steps to reproduce the problem.
-   **Suggest Features**: Have an idea for a new feature? Open an issue and describe what you would like to see.
-   **Improve the Error Database**: The `error_db.json` is a community effort. If you discover a solution to a common error code, submit a pull request to add it to the database.
-   **Submit Code**: If you are a developer, you can help by fixing bugs or adding new features. Fork the repository, make your changes, and submit a pull request.

**[Contribute on GitHub](https://github.com/Blindsinner/LogAnalyzer-Powershell-)**

---

## License
This project is licensed under the MIT License.
