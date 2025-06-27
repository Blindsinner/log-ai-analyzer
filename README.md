# LogAI Analyzer — Universal AI-Enhanced Log Parser (PowerShell Tool)

**Version**: 6.0\
**Author**: MD Faysal Mahmud ([faysaliteng@gmail.com](mailto\:faysaliteng@gmail.com))\
**Repository**: [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer)\
**Enhanced With**: Google Gemini, OpenAI, Azure OpenAI, unified offline/online error analysis, multi-format support, and responsive HTML exports.

---

## 📖 Overview

LogAI Analyzer is a powerful PowerShell tool designed to parse and diagnose errors from Microsoft Intune, Autopilot, and other Windows log sources. It intelligently combines a local error database (`error_db.json`) with AI-powered analysis from Google Gemini, OpenAI, and Azure OpenAI to deliver comprehensive diagnostics.

### Key Features:

- **Universal File Support**: Natively handles `.zip`, `.xlsx`, `.xls`, `.evtx`, `.etl`, `.log`, `.txt`, `.html`, `.xml`, and more.
- **Recursive Archive Extraction**: Automatically processes nested archives to find all relevant logs.
- **Hybrid Analysis**:
  - **Offline**: Fast lookups using the local `error_db.json`.
  - **Online**: AI-driven diagnostics for unrecognized or complex errors.
- **Custom Keyword Detection**: Define your own search tokens in the `errorcloud.txt` file.
- **Responsive Reports**: Generates professional, SEO-friendly HTML and plain-text reports.
- **Cross-Platform**: Compatible with Windows PowerShell 5.1+ and PowerShell Core (macOS/Linux).

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation & Cross-Platform Setup](#installation--cross-platform-setup)
3. [Configuration](#configuration)
4. [File & Folder Structure](#file--folder-structure)
5. [Usage Examples](#usage-examples)
6. [Main Menu Options](#main-menu-options)
7. [Core Logic](#core-logic)
8. [Output](#output)
9. [Troubleshooting](#troubleshooting)
10. [Contributing & License](#contributing--license)

---

## 🛠️ Prerequisites {#prerequisites}

- **PowerShell**:
  - **Windows**: PowerShell 5.1 or later.
  - **macOS/Linux**: PowerShell Core v7.2+ (`pwsh`).
- **PowerShell Module**: `ImportExcel` (for `.xlsx` & `.xls`).
- **Permissions**: Administrator privileges on Windows to analyze `.evtx` and `.etl` files.
- **Internet Connection**: Required for AI-based analysis and optional online searches.
- **Required Files**: Ensure `LogAnalyzer.ps1`, `error_db.json`, and `errorcloud.txt` are in the same directory.

---

## ⚙️ Installation & Cross-Platform Setup {#installation--cross-platform-setup}

### Windows (Administrator PowerShell)

1. Run PowerShell as Administrator.
2. Verify Git:
   ```powershell
   git --version
   ```
   - If missing, install from [git-scm.com](https://git-scm.com/download/win).
3. Clone or download the repo:
   - **With Git (Recommended)**:
     ```powershell
     ```

git clone [https://github.com/Blindsinner/log-ai-analyzer.git](https://github.com/Blindsinner/log-ai-analyzer.git) cd log-ai-analyzer

````
   - **Without Git**: Download ZIP, extract, then `cd` to the folder.
4. Install ImportExcel:
   ```powershell
Install-Module -Name ImportExcel -AcceptLicense -Force
````

5. Unblock script:
   ```powershell
   ```

Unblock-File -Path .\LogAnalyzer.ps1

````
6. Run the analyzer:
   ```powershell
.\LogAnalyzer.ps1
````

### macOS / Linux

1. Install PowerShell Core (example for Ubuntu):
   ```bash
   ```

wget -q [https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb](https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb) sudo dpkg -i packages-microsoft-prod.deb sudo apt-get update sudo apt-get install -y powershell

````
2. Clone repo and `cd log-ai-analyzer`.
3. Install ImportExcel:
   ```bash
pwsh -Command "Install-Module -Name ImportExcel -AcceptLicense -Force"
````

4. Run the analyzer:
   ```bash
   ```

pwsh ./LogAnalyzer.ps1

````

> **Note**: `.evtx` and `.etl` analysis requires Windows. Other formats are cross-platform.

---

## 🔧 Configuration {#configuration}

1. **API Keys**: On first AI run, enter keys when prompted. Stored in `gemini_key.txt`, `openai_key.txt`, `azure_key.txt`.
2. **Offline Database**: Edit `error_db.json` to add entries:
   ```json
   { "ErrorCode": "0x12345678", "Message": "Description.", "Solution": "Detailed solution." }
````

3. **Custom Keywords**: Add comma-separated tokens to `errorcloud.txt` (e.g., `timeout,access denied`).

---

## 📂 File & Folder Structure {#file--folder-structure}

```plaintext
log-ai-analyzer/
├── LogAnalyzer.ps1         # Main script
├── error_db.json           # Offline error database
├── errorcloud.txt          # Custom keyword list
├── gemini_key.txt          # Auto-created on first AI run
├── openai_key.txt          # Auto-created on first AI run
├── azure_key.txt           # Auto-created on first AI run
└── Analyzed Results/       # Output directory
    ├── LogAnalysis_YYYYMMDD_HHMMSS.html
    ├── LogAnalysis_YYYYMMDD_HHMMSS.txt
    └── AI_Analysis_YYYYMMDD_HHMMSS.txt
```

---

## 🚀 Usage Examples {#usage-examples}

### Hybrid Analysis (Offline DB + Online Search)

```powershell
.\LogAnalyzer.ps1
# Choose option 1
# Enter path, e.g., C:\Logs\example.evtx
```

### Analyze a ZIP Archive

```powershell
.\LogAnalyzer.ps1
# Option 1
# Enter path, e.g., C:\Path\To\ArchiveLogs.zip
```

### AI-Only Analysis

```powershell
.\LogAnalyzer.ps1
# Option 2
# Enter path, e.g., C:\Logs\verbose-debug.log
```

---

## 🔍 Main Menu Options {#main-menu-options}

```plaintext
=== Universal Log Analyzer Menu (v6.0 Gemini Enhanced) ===
1. Analyze Log File (Offline DB & optional online search)
2. Analyze with AI Only (Directly analyze log with selected AI)
3. Select AI Model (Current: gemini-pro)
4. Manage AI Providers & API Keys
5. Exit
Choose an option (1-5):
```

---

## 🧩 Core Logic {#core-logic}

1. **File Identification**: Determines type by extension.
2. **Extraction & Parsing**: Recursively extracts archives; imports Excel; parses event/trace logs.
3. **Pattern Matching**: Scans for hex error codes, phrases, and custom keywords.
4. **Hybrid Resolution**: Looks up known errors offline; unknown sent to AI.

---

## 📊 Output {#output}

- **Console**: Real-time progress with bordered sections.
- **Text Files**: Simple summaries in `*.txt`.
- **HTML Reports**: Responsive, card-based layout in `*.html`.
- Saved in `Analyzed Results/` with timestamp.

---

## 🛠️ Troubleshooting {#troubleshooting}

- **ImportExcel Module Not Found**: Run `Install-Module ImportExcel -Force` as admin.
- **Permission Denied**: Run PowerShell as Administrator for system logs.
- **No Errors Detected**: Verify file path and keywords in logs or `errorcloud.txt`.
- **AI Analysis Fails**: Check API keys and internet connectivity; verify AI provider status.

---

## 🤝 Contributing & License {#contributing--license}

Contributions welcome! Open issues, submit PRs, update the error DB, or enhance docs.

Licensed under the MIT License. See `LICENSE` for details.

