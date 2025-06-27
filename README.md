# LogAI Analyzer — Universal AI-Enhanced Log Parser (PowerShell Tool)

**Version**: 6.0  
**Author**: MD Faysal Mahmud  
**Repository**: [https://github.com/Blindsinner/LogAnalyzer-Powershell-](https://github.com/Blindsinner/LogAnalyzer-Powershell-)  
**Contribute**: We welcome issues, feature requests, and pull requests!

---

## Overview

LogAI Analyzer is a versatile, menu-driven PowerShell tool designed for IT professionals and system administrators to rapidly diagnose and troubleshoot errors across a broad spectrum of log formats. By combining a comprehensive offline database with AI-powered analysis (Google Gemini, OpenAI, or Azure OpenAI), you get instant insights on known issues and deep diagnostics on unknown errors.

Key strengths:
- **Universal File Support**: `.zip`, `.xlsx`, `.xls`, `.evtx`, `.etl`, `.log`, `.txt`, `.html`, `.xml`, and any text-based file.
- **Recursive Archive Processing**: Automatically unpacks and analyzes nested archives.
- **Dual Analysis Engine**: Fast offline lookup via `error_db.json` plus optional AI deep dive for new errors.
- **Custom Keywords**: User-defined error-cloud via `errorcloud.txt` for bespoke searches.
- **Professional Reports**: Generates both plain-text and responsive HTML output.
- **Cross-Platform**: Runs on Windows (PowerShell 5.1+), macOS, and Linux via PowerShell Core (v7+).

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Cross-Platform Support](#cross-platform-support)
- [Installation and Setup](#installation-and-setup)
- [Configuration](#configuration)
- [File and Folder Structure](#file-and-folder-structure)
- [Running the Tool](#running-the-tool)
- [Main Menu Options](#main-menu-options)
- [Parse-LogFile Function Details](#parse-logfile-function-details)
- [Output Formats](#output-formats)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Prerequisites

1. **PowerShell**
   - Windows: PowerShell 5.1 or later.
   - macOS/Linux: PowerShell Core v7.2 or higher.
2. **ImportExcel Module** (required for `.xlsx` / `.xls` files)
3. **Administrator (Windows)**: Needed for reading certain system logs (`.evtx`).
4. **Internet Connectivity**: For AI-powered analysis.
5. **Project Files**: `LogAnalyzer.ps1`, `error_db.json`, and `errorcloud.txt` located together.

---

## Cross-Platform Support

LogAI Analyzer leverages PowerShell Core to deliver consistent functionality on Windows, macOS, and Linux platforms.

### Windows
- Uses native modules (`Get-WinEvent`, `Expand-Archive`) for best performance.
- Supports `.evtx` and `.etl` parsing via Windows APIs.
- Requires running PowerShell as Administrator for security logs.

### macOS / Linux
- Install [PowerShell Core](https://github.com/PowerShell/PowerShell).
- `.evtx`/`.etl` parsing is not supported on non-Windows hosts; such files will be skipped with a warning.
- All text-based, archive, and spreadsheet formats remain fully supported.
- Example install on Debian/Ubuntu:
  ```bash
  # Download and install Microsoft repository GPG keys
  wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb

  # Install PowerShell
  sudo apt update
  sudo apt install -y powershell
  ```

---

## Installation and Setup

### 1. Clone the Repository
```bash
git clone https://github.com/Blindsinner/LogAnalyzer-Powershell-.git
cd LogAnalyzer-Powershell-
```

### 2. Install Dependencies
```powershell
# Windows (Admin PowerShell):
Install-Module -Name ImportExcel -AcceptLicense -Force

# macOS/Linux (pwsh):
pwsh -Command "Install-Module -Name ImportExcel -AcceptLicense -Force"
```

### 3. Unblock and Prepare
```powershell
# Windows:
Unblock-File -Path ./LogAnalyzer.ps1
```
*On macOS/Linux, ensure execution permission:*
```bash
chmod +x LogAnalyzer.ps1
```

---

## Configuration

### API Keys
- **Google Gemini**: Stored in `gemini_key.txt`
- **OpenAI**: Stored in `openai_key.txt`
- **Azure OpenAI**: Stored in `azure_key.txt`

> First run will prompt for missing keys and auto-save them.

### Offline Error Database (`error_db.json`)
- JSON array of `{ ErrorCode, Message, Solution }` objects.
- Extendable via community pull requests.

### Error-Cloud Keywords (`errorcloud.txt`)
- Comma-separated terms for custom detections.
- Example:
  ```text
  failed to connect, timeout, access denied, critical error
  ```

---

## File and Folder Structure

```
LogAnalyzer-Powershell-
├── LogAnalyzer.ps1         # Main script
├── error_db.json           # Offline lookup database
├── errorcloud.txt          # Custom keywords
├── gemini_key.txt          # Auto-generated
├── openai_key.txt          # Auto-generated
└── Analyzed Results/       # Output directory
    ├── LogAnalysis_*.html
    └── LogAnalysis_*.txt
```

---

## Running the Tool

1. **Launch PowerShell** (or `pwsh` on macOS/Linux)
2. Change to the script directory:
   ```powershell
   cd path/to/LogAnalyzer-Powershell-
   ```
3. Execute:
   ```powershell
   .\LogAnalyzer.ps1  # Windows
   pwsh ./LogAnalyzer.ps1  # macOS/Linux
   ```

The interactive menu will guide you through analysis options.

---

## Main Menu Options

1. **Analyze Log File (Offline DB + Online Search)**
2. **Analyze with AI Only**
3. **Select AI Model**
4. **Manage AI Providers & API Keys**
5. **Exit**

Detailed docs for each option are in the [Parse-LogFile Function Details](#parse-logfile-function-details) section.

---

## Parse-LogFile Function Details

This core function:
- Detects file type by extension.
- Uses `Expand-Archive` for `.zip`, then processes nested files.
- Imports `.xlsx`/`.xls` via `Import-Excel`.
- Reads `.evtx`/`.etl` with `Get-WinEvent` (Windows only).
- Falls back to `Get-Content` for all other text-based files.
- Aggregates results and queries offline DB first, then AI if needed.

---

## Output Formats

### Console Display
Clean, bordered sections for each error and its analysis.

### HTML Report
- Responsive, card-based layout.
- Includes error code, description, and recommended solutions.

### Text Report
- Summarized `.txt` output for quick sharing.

---

## Troubleshooting

- **ImportExcel Not Found**: Ensure module is installed in the session.
- **Permission Errors**: Run as Admin (Windows) or use `sudo` where necessary (Linux).
- **No Errors Detected**: Verify log path and customize `errorcloud.txt`.
- **AI Fails**: Check API keys under Option 4 and internet connectivity.

---

## Contributing

Submit issues, feature requests, or pull requests on GitHub. We especially appreciate:
- New entries for `error_db.json`.
- Additional platform support or bug fixes.
- Documentation improvements.

---

## License

This project is licensed under the MIT License. See `LICENSE` for details.

