# Intune/Autopilot Log Analyzer PowerShell Tool

**Version**: 5.1  
**Author**: MD Faysal Mahmud

**Purpose**: A PowerShell tool to quickly detect and analyze Intune/Autopilot enrollment errors using an offline error database and optional AI-powered diagnostics.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [Configuration](#configuration)
  - [Error-Cloud Keywords](#error-cloud-keywords)
  - [API Keys](#api-keys)
- [Running the Tool](#running-the-tool)
- [Main Menu Options](#main-menu-options)
  - [1. Analyze Log File](#1-analyze-log-file)
  - [2. Set or Update OpenAI API Key](#2-set-or-update-openai-api-key)
  - [3. Select AI Model](#3-select-ai-model)
  - [4. Analyze with AI Only](#4-analyze-with-ai-only)
  - [5. Manage AI Providers](#5-manage-ai-providers)
  - [6. Exit](#6-exit)
- [Parse-LogFile Function](#parse-logfile-function)
- [Error Database](#error-database)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Prerequisites
- Windows PowerShell (v5.1 or later)
- Internet connectivity for AI analysis features (optional)
- (Optional) API keys for OpenAI, Azure OpenAI, or Anthropic (Claude) for AI-powered diagnostics

## Installation
1. Clone or download this repository containing `LogAnalyzer.ps1`, `errorcloud.txt`, and `error_db.json`.
2. Open a PowerShell prompt as Administrator.
3. Navigate to the script folder:
   ```powershell
   cd C:\Path\To\LogAnalyzerFolder
   ```

## First-Time Setup
PowerShell's default execution policy may prevent running scripts. To allow `LogAnalyzer.ps1` to run:

1. **Check Execution Policy**:
   ```powershell
   Get-ExecutionPolicy
   ```
   If it returns `Restricted`, scripts are blocked.

2. **Allow the Script**:
   - **Option 1: Unblock the Script File** (Recommended):
     ```powershell
     Unblock-File .\LogAnalyzer.ps1
     ```
     This removes the "downloaded from the internet" restriction without changing the execution policy.
   - **Option 2: Change Execution Policy**:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
     ```
     `RemoteSigned` allows local scripts to run without signing but requires signed remote scripts.
   - **Option 3: Bypass for a Single Session**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\LogAnalyzer.ps1
     ```
     This bypasses the policy for the current session only.

**Note**: Changing the execution policy or unblocking files may have security implications. Only use trusted scripts and revert to `Restricted` (`Set-ExecutionPolicy Restricted`) if needed.

## Configuration

### Error-Cloud Keywords
- On first run, `errorcloud.txt` is generated with hundreds of pre-populated error keywords and phrases.
- Edit this file to add or modify comma-separated entries as needed.

### API Keys
To enable AI analysis, save your API keys in the following files (one key per file):
- `apikey.txt` (OpenAI)
- `azure_key.txt` (Azure OpenAI)
- `claude_key.txt` (Anthropic/Claude)

Alternatively, set or update keys via the tool’s Main Menu (Options 2 and 5).

## Running the Tool
1. From the PowerShell prompt, navigate to the folder containing `LogAnalyzer.ps1` by replacing `C:\Path\To\LogAnalyzerFolder` with the actual path to your downloaded or cloned repository folder:
   ```powershell
   cd C:\Path\To\LogAnalyzerFolder
   ```
   **Tip**: Copy the folder path from File Explorer and paste it into the command, ensuring the path is correct (e.g., `C:\Users\YourName\Downloads\LogAnalyzer`).
2. Run the script:
   ```powershell
   .\LogAnalyzer.ps1
   ```
3. The Main Menu will appear:
   ```
   === Intune Log Analyzer Menu ===
   1. Analyze Log File
   2. Set or Update OpenAI API Key
   3. Select AI Model (Current: gpt-4)
   4. Analyze with AI Only
   5. Manage AI Providers
   6. Exit
   Choose an option (1-6):
   ```

## Main Menu Options

### 1. Analyze Log File
- Enter the path to your log file (e.g., `C:\Logs\IntuneManagementExtension.log`).
- The tool displays:
  - **Error Codes**: All `0x…` hex codes found.
  - **Error Keywords**:
    - Exact phrases like `errorCode = 3399548929`
    - Contextual codes (e.g., `Exit code 1603`, `Status code: 0x80070005`)
    - Keywords from `errorcloud.txt` found in the log.
- Choose a specific code to analyze or press Enter to process all.
- For each code:
  - Matches against `error_db.json` for offline description and solutions.
  - Shows context excerpts from the log.
  - (Optional) AI analysis for root cause and suggested fixes.
- Results are exported to a timestamped `LogAnalysis_YYYYMMDD_HHMMSS.txt` file.

### 2. Set or Update OpenAI API Key
- Prompts for and saves your OpenAI key to `apikey.txt`.

### 3. Select AI Model
- Choose between:
  - `gpt-4` (default)
  - `gpt-3.5-turbo`

### 4. Analyze with AI Only
- Enter the log file path and select an AI provider (OpenAI, Azure, or Claude).
- AI analyzes all detected codes and keywords, skipping the offline database.
- Results are exported to `AIAnalysis_YYYYMMDD_HHMMSS.txt`.

### 5. Manage AI Providers
- Add or update keys for OpenAI, Azure OpenAI, or Anthropic (Claude).

### 6. Exit
- Closes the tool.

## Parse-LogFile Function
The `Parse-LogFile` function processes each log line and:
- Extracts `0x…` hex codes.
- Captures decimal phrases (e.g., `errorCode = 123456789`).
- Identifies contextual codes (e.g., `Exit code 1618`, `Status code: 0x80070005`, `HRESULT 0x87D1041C`).
- Matches case-insensitive keywords/phrases from `errorcloud.txt` with word boundaries.

**Returns**: A hashtable with:
- `Codes`: `<hex code>` → array of lines
- `Keywords`: `<phrase or keyword>` → array of lines
- `Lines`: All log lines

## Error Database
The `error_db.json` file contains:
- `ErrorCode`
- `Message/Description`
- `Context`
- `Solutions` (step-by-step)

The script uses this for instant offline guidance.

## Troubleshooting
- **No detections?**
  - Verify `errorcloud.txt` contains expected keywords.
  - Check log file path and permissions.
- **AI not working?**
  - Ensure API key files are correct.
  - Confirm network access to AI endpoints.
- **Log file not found?**
  - Remove stray quotes or use full UNC paths.
- **Performance on large logs?**
  - Prefilter logs using PowerShell’s `Select-String`.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
