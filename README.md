# Intune/Autopilot Log Analyzer PowerShell Tool

**Version**: 5.2  
**Author**: MD Faysal Mahmud

**Purpose**: A PowerShell tool to detect and analyze Intune/Autopilot enrollment errors using an offline error database, user-defined error keywords, and optional AI-powered diagnostics. Features unified error analysis, multi-file support, responsive HTML export, and online search for missing entries.

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
  - [1. Analyze Log File](#1-analyze-log-file)
  - [2. Set or Update OpenAI API Key](#2-set-or-update-openai-api-key)
  - [3. Select AI Model](#3-select-ai-model)
  - [4. Analyze with AI Only](#4-analyze-with-ai-only)
  - [5. Manage AI Providers](#5-manage-ai-providers)
  - [6. Exit](#6-exit)
- [Parse-LogFile Function](#parse-logfile-function)
- [Error Database](#error-database)
- [Output Files](#output-files)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Prerequisites
- Windows PowerShell (v5.1 or later)
- Internet connectivity for AI analysis or online search (optional)
- (Optional) API keys for OpenAI, Azure OpenAI, or Anthropic (Claude) for AI diagnostics
- Log files (e.g., `IntuneManagementExtension.log`)
- `error_db.json` and `errorcloud.txt` in the script’s root directory

## Installation
1. Clone or download the repository containing `LogAnalyzer2.ps1`, `errorcloud.txt`, and `error_db.json`.
2. Open a PowerShell prompt as Administrator.
3. Navigate to the script folder:
   ```powershell
   cd "C:\Path\To\LogAnalyzerFolder"
   ```

## First-Time Setup
PowerShell’s execution policy may block scripts. To allow `LogAnalyzer2.ps1`:

1. **Check Execution Policy**:
   ```powershell
   Get-ExecutionPolicy
   ```
   If `Restricted`, scripts are blocked.

2. **Allow the Script**:
   - **Option 1: Unblock the Script File** (Recommended):
     ```powershell
     Unblock-File .\LogAnalyzer2.ps1
     ```
   - **Option 2: Change Execution Policy**:
     ```powershell
     Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
     ```
   - **Option 3: Bypass for a Single Session**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\LogAnalyzer2.ps1
     ```

**Note**: Changing the execution policy or unblocking files has security implications. Use trusted scripts and revert to `Restricted` (`Set-ExecutionPolicy Restricted`) if needed.

## Configuration

### Error-Cloud Keywords
- `errorcloud.txt` (in the script’s root directory) contains comma-separated error keywords/phrases (e.g., "EnablePutWithTupleResult not found").
- If missing, the script creates an empty `errorcloud.txt`. Populate it with keywords to detect in logs.
- Edit the file to add or modify entries as needed.

### Offline Error Database
- `error_db.json` (in the root directory) contains error codes, descriptions, and solutions.
- Ensure it’s present for offline analysis. The script reads it without modifying or moving it.

### API Keys
- Save API keys in the root directory:
  - `apikey.txt` (OpenAI)
  - `azure_key.txt` (Azure OpenAI)
  - `claude_key.txt` (Anthropic/Claude)
- Alternatively, set/update keys via Main Menu (Options 2 or 5).
- If a key is missing, the script prompts for it during AI analysis.

### File Locations
- **Root Directory** (where `LogAnalyzer2.ps1` is located, e.g., `C:\Scripts`):
  - `error_db.json`: Offline error database.
  - `errorcloud.txt`: User-provided error keywords.
  - `apikey.txt`, `azure_key.txt`, `claude_key.txt`: API keys (if used).
- **Analyzed Result** (subfolder, e.g., `C:\Scripts\Analyzed Result`, created automatically):
  - `LogAnalysis_YYYYMMDD_HHMMSS.html`: Responsive HTML report with error details and solutions.
  - `LogAnalysis_YYYYMMDD_HHMMSS.txt`: Text report with analysis results.
  - `AIAnalysis_YYYYMMDD_HHMMSS.txt` (for AI-only analysis).

The script does not create or move `error_db.json` or `errorcloud.txt` to `Analyzed Result`.

## Running the Tool
1. Navigate to the folder containing `LogAnalyzer2.ps1`:
   ```powershell
   cd "C:\Path\To\LogAnalyzerFolder"
   ```
   **Tip**: Copy the folder path from File Explorer and paste it into the command.
2. Run the script:
   ```powershell
   .\LogAnalyzer2.ps1
   ```
3. The Main Menu appears:
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
- **Input**: Enter the path to a log file (e.g., `C:\Logs\IntuneManagementExtension.log`).
- **Process**:
  - Detects error codes (`0x…` hex codes) and keywords (from `errorcloud.txt`, phrases like `errorCode = 1234`, or contextual codes like `Exit code 1603`).
  - Displays detected codes and keywords.
  - Prompts to select a specific code/keyword or press Enter to analyze all.
  - For each item:
    - Matches against `error_db.json` for descriptions and solutions (e.g., `#1. Verify the policy...`).
    - Extracts log context excerpts.
    - Offers online search for unmatched items (opens browser tabs).
- **Output**:
  - Text report: `Analyzed Result\LogAnalysis_YYYYMMDD_HHMMSS.txt`.
  - HTML report: `Analyzed Result\LogAnalysis_YYYYMMDD_HHMMSS.html` (responsive, with solutions formatted as `#1.`, `#2.`, etc.).

### 2. Set or Update OpenAI API Key
- Prompts for and saves an OpenAI API key to `apikey.txt` in the root directory.

### 3. Select AI Model
- Choose between:
  - `gpt-4` (default)
  - `gpt-3.5-turbo`

### 4. Analyze with AI Only
- **Input**: Enter the log file path and select an AI provider (OpenAI, Azure OpenAI, or Claude).
- **Process**: Analyzes all detected codes and keywords using the selected AI provider, skipping `error_db.json`.
- **Output**:
  - Text report: `Analyzed Result\AIAnalysis_YYYYMMDD_HHMMSS.txt`.
  - HTML report: `Analyzed Result\LogAnalysis_YYYYMMDD_HHMMSS_AI.html`.

### 5. Manage AI Providers
- Add or update API keys for OpenAI, Azure OpenAI, or Anthropic (Claude).
- Saves keys to respective files in the root directory.

### 6. Exit
- Closes the tool.

## Parse-LogFile Function
Processes each log line to:
- Extract `0x…` hex codes (4-8 digits).
- Capture decimal phrases (e.g., `errorCode = 3399548929`).
- Identify contextual codes (e.g., `Exit code 1618`, `Status code: 0x80070005`, `HRESULT 0x87D1041C`).
- Match case-insensitive keywords from `errorcloud.txt`.

**Returns**: A hashtable with:
- `Codes`: `<hex code>` → array of matching lines.
- `Keywords`: `<phrase or keyword>` → array of matching lines.

## Error Database
- **File**: `error_db.json` (root directory).
- **Structure**:
  - `ErrorCode`: Code or keyword (e.g., `0x80070643`, `EnablePutWithTupleResult not found`).
  - `Message`: Description.
  - `Solution`: Step-by-step fixes (e.g., `#1. Verify the policy...`).
- Used for instant offline guidance.

## Output Files
- **Location**: `Analyzed Result` folder (e.g., `C:\Scripts\Analyzed Result`).
- **Files**:
  - `LogAnalysis_YYYYMMDD_HHMMSS.txt`: Text summary of analysis, including error codes, keywords, database matches, and solutions.
  - `LogAnalysis_YYYYMMDD_HHMMSS.html`: Responsive HTML report with card-based layout, showing errors, context, database matches, and solutions (formatted as `#1.`, `#2.`, etc.).
  - `AIAnalysis_YYYYMMDD_HHMMSS.txt`: AI-only analysis results (Option 4).
  - `LogAnalysis_YYYYMMDD_HHMMSS_AI.html`: AI-only HTML report (Option 4).

## Troubleshooting
- **No Detections**:
  - Verify `errorcloud.txt` contains relevant keywords (e.g., `EnablePutWithTupleResult not found`).
  - Check log file path and permissions.
- **Missing `error_db.json` or `errorcloud.txt`**:
  - Ensure both files are in the root directory (e.g., `C:\Scripts`).
  - If `errorcloud.txt` is missing, the script creates an empty one.
- **AI Not Working**:
  - Verify API key files in the root directory.
  - Confirm network access to AI endpoints.
- **Log File Not Found**:
  - Remove stray quotes or use full UNC paths.
- **HTML Report Issues**:
  - Open in a modern browser to ensure responsiveness.
  - Check `Analyzed Result` for the HTML file.
- **Performance on Large Logs**:
  - Prefilter logs with `Select-String`:
    ```powershell
    Select-String "error" C:\Logs\IntuneManagementExtension.log > filtered.log
    ```

## License
Licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
