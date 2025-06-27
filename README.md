# LogAI Analyzer — Universal AI-Enhanced Log Parser (PowerShell Tool)

# Intune/Autopilot Log Analyzer PowerShell Tool

**Version**: 6.0\
**Author**: MD Faysal Mahmud ([faysaliteng@gmail.com](mailto\:faysaliteng@gmail.com))\
**Repository**: [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer)\
**Enhanced With**: Google Gemini AI, OpenAI, Azure OpenAI, unified offline/online error analysis, multi-format support, responsive HTML export.

---

## 📖 Overview

Intune/Autopilot Log Analyzer is a PowerShell tool for parsing and diagnosing errors from Microsoft Intune, Autopilot, and Windows log sources. It combines a local error database (`error_db.json`) with AI-powered analysis (Google Gemini, OpenAI, Azure OpenAI) to deliver:

- **Universal File Support**: `.zip`, `.xlsx`/`.xls`, `.evtx`, `.etl`, `.log`, `.txt`, `.html`, `.xml`, and more.
- **Recursive Archive Extraction**: Processes nested archives automatically.
- **Hybrid Analysis**:
  - Offline lookup via `error_db.json`.
  - AI diagnostics for unmatched errors.
- **Custom Keyword Detection**: Define tokens in `errorcloud.txt`.
- **Responsive Reports**: SEO-friendly HTML and plain-text outputs.
- **Cross-Platform**: Windows PowerShell 5.1+ and PowerShell Core (macOS/Linux).

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

## 🛠️ Prerequisites

- **PowerShell**
  - Windows: PowerShell 5.1 or later.
  - macOS/Linux: PowerShell Core v7.2+ (`pwsh`).
- **Module**: `ImportExcel` for `.xlsx`/`.xls` support.
- **Permissions**: Administrator on Windows (for `.evtx`/`.etl`).
- **Internet**: For AI analysis and optional online search.
- **Files**: Place `LogAnalyzer.ps1`, `error_db.json`, and `errorcloud.txt` in one folder.

---

## ⚙️ Installation & Cross-Platform Setup

### Windows (Admin PowerShell)

1. **Run as Administrator**: Search “PowerShell”, right-click, **Run as administrator**.
2. **Verify Git**:
   ```powershell
   git --version
   ```
   - If not found, install Git from [https://git-scm.com/download/win](https://git-scm.com/download/win), then reopen PowerShell as admin.
3. **Get the Code**:
   - **With Git**:
     ```powershell
     git clone https://github.com/Blindsinner/log-ai-analyzer.git
     cd log-ai-analyzer
     ```
   - **Without Git**:
     1. Go to [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer)
     2. Click **Code → Download ZIP** and extract (e.g., to `C:\Users\YourUser\Downloads\log-ai-analyzer`).
     3. In PowerShell:
        ```powershell
        cd "C:\Users\YourUser\Downloads\log-ai-analyzer"
        ```
4. **Install ImportExcel**:
   ```powershell
   Install-Module -Name ImportExcel -AcceptLicense -Force
   ```
5. **Unblock Script**:
   ```powershell
   Unblock-File -Path .\LogAnalyzer.ps1
   ```
6. **Run Analyzer**:
   ```powershell
   .\LogAnalyzer.ps1
   ```

### macOS / Linux

1. **Install PowerShell Core** (Ubuntu example):
   ```bash
   wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt update
   sudo apt install -y powershell
   ```
2. **Clone & Navigate**:
   ```bash
   git clone https://github.com/Blindsinner/log-ai-analyzer.git
   cd log-ai-analyzer
   ```
3. **Install ImportExcel**:
   ```bash
   pwsh -Command "Install-Module -Name ImportExcel -AcceptLicense -Force"
   ```
4. **Run Analyzer**:
   ```bash
   pwsh ./LogAnalyzer.ps1
   ```

> **Note**: `.evtx`/`.etl` support is Windows-only; other formats work on all platforms.

---

## 🔧 Configuration

1. **API Keys**: On first AI run, you’ll be prompted to save keys in `gemini_key.txt`, `openai_key.txt`, and `azure_key.txt`.
2. **Offline DB**: Edit `error_db.json` to add `{ "ErrorCode": "0x1234", "Message": "...", "Solution": "..." }` entries.
3. **Keywords**: Populate `errorcloud.txt` with comma-separated terms (e.g., `timeout,access denied`).

---

## 📂 File & Folder Structure

```
log-ai-analyzer/
├── LogAnalyzer.ps1       # Main script
├── error_db.json         # Offline error data
├── errorcloud.txt        # Custom keyword list
├── gemini_key.txt        # Created on first run
├── openai_key.txt        # Created on first run
├── azure_key.txt         # Created on first run
└── Analyzed Results/     # Output files
    ├── LogAnalysis_YYYYMMDD_HHMMSS.html
    ├── LogAnalysis_YYYYMMDD_HHMMSS.txt
    └── AI_Analysis_YYYYMMDD_HHMMSS.txt
```

---

## 🚀 Usage Examples

### Offline + Online Search

```powershell
.
\LogAnalyzer.ps1
# Select option 1
Enter path: C:\Logs\example.evtx
```

### ZIP Archive Scan

```powershell
.
\LogAnalyzer.ps1
# Option 1
Enter path: ./ArchiveLogs.zip
```

### AI-Only Analysis

```powershell
.
\LogAnalyzer.ps1
# Option 2
Enter path: C:\Logs\example.log
```

---

## 🔍 Main Menu Options

1. Analyze Log File (Offline DB + Online Search)
2. Analyze with AI Only
3. Select AI Model
4. Manage API Keys
5. Exit

---

## 🧩 Core Logic

1. Determine file type by extension.
2. Extract archives or import Excel sheets.
3. Parse event logs or text lines.
4. Match hex codes, error phrases, and keywords.
5. Lookup offline DB, then AI for unknowns.

---

## 📊 Output

- **Console**: Bordered sections.
- **Text**: `*.txt` summaries.
- **HTML**: Responsive, card-based.
- Saved under `Analyzed Results/` with timestamps.

---

## 🛠️ Troubleshooting

- **ImportExcel missing**: `Install-Module ImportExcel` as admin.
- **Permission denied**: Run elevated.
- **No detections**: Verify file path and keywords.
- **AI errors**: Check API keys and network.

---

## 🤝 Contributing & License

Contributions welcome: issues, PRs, DB updates, docs.\
Licensed under MIT. See `LICENSE`.

