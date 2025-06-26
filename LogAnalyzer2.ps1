# Intune/Autopilot Log Analyzer PowerShell Tool

**Version**: 5.3.6
**Author**: MD Faysal Mahmud

**Purpose**: A PowerShell tool to detect and analyze Intune/Autopilot enrollment errors. It uses a local offline error database, user-defined keywords (`errorcloud.txt`), and optional AI-powered diagnostics with Google Gemini as the primary provider. Key features include unified error analysis, multi-provider AI support (Gemini, OpenAI, Azure), responsive HTML export, and consistent, clean output formatting for all analysis types.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [Configuration](#configuration)
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
- Windows PowerShell (v5.1 or later)
- Internet connectivity for AI analysis or online search features.
- (Optional) API keys for Google (Gemini), OpenAI, or Azure OpenAI for AI diagnostics.
- Log files to be analyzed (e.g., `IntuneManagementExtension.log`).
- `error_db.json` and `errorcloud.txt` must be present in the script’s root directory.

## Installation
1.  Clone or download the repository containing the script (`.ps1`), `errorcloud.txt`, and `error_db.json`.
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
        Unblock-File .\TheScriptName.ps1
        ```
    * **Option 2: Bypass for a Single Session**:
        ```powershell
        powershell -ExecutionPolicy Bypass -File .\TheScriptName.ps1
        ```

**Note**: Modifying execution policies has security implications. Only run scripts from trusted sources.

## Configuration

### Error-Cloud Keywords
-   **File**: `errorcloud.txt` (must be in the script’s root directory).
-   **Purpose**: Contains a comma-separated list of custom error keywords or phrases (e.g., "EnablePutWithTupleResult not found,timed out,failed to connect").
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
    .\TheScriptName.ps1
    ```
3.  The Main Menu will appear:
    ```
    === Intune Log Analyzer Menu (v5.3.6 Gemini Enhanced) ===
    1. Analyze Log File (Offline DB & optional online search)
    2. Analyze with AI Only (Directly analyze log with selected AI)
    3. Select AI Model (Current: gemini-2.0-flash)
    4. Manage AI Providers & API Keys
    5. Exit
    Choose an option (1-5):
    ```

## Main Menu Options

### 1. Analyze Log File (Offline DB & optional online search)
-   **Input**: The path to a log file.
-   **Process**:
    1.  Parses the log file to detect error codes (`0x...`) and any keywords from your `errorcloud.txt`.
    2.  Displays a **Detection Results** summary listing all found errors.
    3.  Prompts you to select a specific error or press Enter to analyze all of them.
    4.  For each selected error, it queries the local `error_db.json` and displays any matches in a clean, bordered format.
    5.  For errors not found in the local database, it offers to launch a Google search in your browser.
-   **Output**: A detailed `LogAnalysis_...txt` file and a responsive `LogAnalysis_...html` report are saved in the `Analyzed Result` folder.

### 2. Analyze with AI Only
-   **Input**: The path to a log file and your choice of AI provider (Gemini, OpenAI, or Azure).
-   **Process**:
    1.  Detects all errors and keywords just like in Option 1.
    2.  Skips the offline database search entirely.
    3.  Sends each detected error and its log context to the selected AI provider for analysis.
    4.  Displays the AI's response in a standardized, clean, bordered format.
-   **Output**: An `AI_Analysis_...txt` report and a full `LogAnalysis_...html` report are saved in the `Analyzed Result` folder.

### 3. Select AI Model
-   Allows you to change the AI model used for analysis.
-   **Default**: `gemini-2.0-flash`.
-   You can enter other compatible models like `gpt-4` or `gpt-3.5-turbo`. The selected model will be used by the corresponding AI provider.

### 4. Manage AI Providers & API Keys
-   A central menu for managing your AI provider API keys.
-   You can add or update keys for Google (Gemini), OpenAI, and Azure OpenAI.
-   Keys are saved to their respective `.txt` files in the root directory.

### 5. Exit
-   Closes the tool.

## Parse-LogFile Function
This core function processes each line of a log file to find:
-   Hexadecimal codes (e.g., `0x80070643`).
-   Phrases containing error codes (e.g., `errorCode = 1603`).
-   Contextual codes (e.g., `Exit code 1618`, `HRESULT 0x87D1041C`).
-   Any case-insensitive keywords from `errorcloud.txt`.

## Output Formats
The script now enforces a standardized output format for both offline and AI analysis to ensure clarity and readability.

**Example Console Output:**
