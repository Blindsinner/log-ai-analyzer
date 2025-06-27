# LogAI Analyzer — Universal AI-Enhanced Log Parser (PowerShell Tool)

# Intune/Autopilot Log Analyzer PowerShell Tool

**Version**: 6.0\
**Author**: MD Faysal Mahmud ([faysaliteng@gmail.com](mailto\:faysaliteng@gmail.com))\
**Repository**: [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer)\
**Enhanced With**: Google Gemini AI, OpenAI, Azure OpenAI, unified offline/online error analysis, multi-format support, responsive HTML export.

---

## 📖 Overview

Intune/Autopilot Log Analyzer is a comprehensive PowerShell-based solution for parsing and diagnosing errors from Microsoft Intune, Autopilot, and any Windows-related log sources. Leveraging a local error database (`error_db.json`) and advanced AI providers, it delivers:

- **Universal File Compatibility**: `.zip`, `.xlsx`/`.xls`, `.evtx`, `.etl`, `.log`, `.txt`, `.html`, `.xml`, and all text-based files.
- **Recursive Archive Extraction**: Automatically unpacks nested archives for full coverage.
- **Hybrid Analysis Engine**:
  - **Offline DB Lookup**: Instant matches from `error_db.json`.
  - **Online AI Diagnostics**: Deep analysis via Google Gemini, OpenAI, or Azure OpenAI for unknown issues.
- **Custom Keyword (“Error-Cloud”) Detection**: User-defined tokens in `errorcloud.txt`.
- **SEO-Friendly HTML & Plain-Text Reports**: Responsive, card-based HTML and summary `.txt` outputs.
- **Cross-Platform**: Runs on Windows PowerShell 5.1+, macOS/Linux via PowerShell Core 7+.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Cross-Platform Support & Installation](#cross-platform-support--installation)
3. [Configuration](#configuration)
4. [File & Folder Structure](#file--folder-structure)
5. [Usage Examples](#usage-examples)
6. [Main Menu Options](#main-menu-options)
7. [Core Processing Logic](#core-processing-logic)
8. [Output Formats & Locations](#output-formats--locations)
9. [Troubleshooting](#troubleshooting)
10. [Contributing & License](#contributing--license)

---

## 🛠️ Prerequisites

- **PowerShell**
  - Windows: PowerShell 5.1 or later (built-in).
  - macOS/Linux: PowerShell Core v7.2+ (`pwsh`).
- **Modules**: `ImportExcel` (for `.xlsx`/`.xls` support).
- **Permissions**: Windows Admin (required for certain `.evtx`/`.etl` logs).
- **Internet**: Required for AI analysis and optional online search.
- **Local Files**: Place `LogAnalyzer.ps1`, `error_db.json`, and `errorcloud.txt` together.

---

## 🌐 Cross-Platform Support & Installation

### Windows

1. **Clone & Navigate**:
   ```powershell
   git clone https://github.com/Blindsinner/log-ai-analyzer.git
   cd log-ai-analyzer
   ```
2. **Install ImportExcel** (Admin PowerShell):
   ```powershell
   Install-Module -Name ImportExcel -AcceptLicense -Force
   ```
3. **Unblock Script**:
   ```powershell
   Unblock-File -Path .\LogAnalyzer.ps1
   ```
4. **Run**:
   ```powershell
   .\LogAnalyzer.ps1
   ```

### macOS / Linux

1. **Install PowerShell Core** (Ubuntu 20.04 example):
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
4. **Make Executable & Run**:
   ```bash
   chmod +x LogAnalyzer.ps1
   pwsh ./LogAnalyzer.ps1
   ```

> **Note**: `.evtx`/`.etl` parsing is supported only on Windows; other formats work identically.

---

## ⚙️ Configuration

1. **API Keys**: On first run, you’ll be prompted to enter and save keys in:
   - `gemini_key.txt`
   - `openai_key.txt`
   - `azure_key.txt`
2. **Offline Error Database**: Edit `error_db.json` to add objects with `ErrorCode`, `Message`, and `Solution`.
3. **Error-Cloud Keywords**: Edit `errorcloud.txt` with comma-separated tokens (e.g., `timeout,access denied,critical error`).

---

## 📂 File & Folder Structure

```
log-ai-analyzer
├── LogAnalyzer.ps1         # Main script
├── error_db.json           # Offline error definitions
├── errorcloud.txt          # Custom keywords
├── gemini_key.txt          # Auto-created on first run
├── openai_key.txt          # Auto-created on first run
├── azure_key.txt           # Auto-created on first run
└── Analyzed Results/       # Generated outputs
    ├── LogAnalysis_YYYYMMDD_HHMMSS.html
    ├── LogAnalysis_YYYYMMDD_HHMMSS.txt
    └── AI_Analysis_YYYYMMDD_HHMMSS.txt
```

---

## 🚀 Usage Examples

### Analyze a Single `.evtx` or `.etl` Log

```powershell
.
\LogAnalyzer.ps1
# Choose option 1
Enter path: C:\IntuneLogs\DeviceManagement.evtx
```

### Batch Analyze a ZIP Archive

```powershell
.
\LogAnalyzer.ps1
# Option 1
Enter path: ./AutopilotLogs.zip
```

### AI-Only Deep Dive

```powershell
.
\LogAnalyzer.ps1
# Option 2
Enter path: C:\Logs\IntuneLogs.log
```

---

## 🔍 Main Menu Options

1. **Analyze Log File** (Offline DB + Online Search)
2. **Analyze with AI Only**
3. **Select AI Model** (e.g., `gemini-2.0-flash`, `gpt-4`)
4. **Manage AI Providers & API Keys**
5. **Exit**

---

## 🧩 Core Processing Logic

1. **Detect File Type** by extension.
2. **Extract**
   - `.zip`: `Expand-Archive` (up to 5 recursions).
   - `.xlsx`/`.xls`: `Import-Excel` all sheets.
3. **Parse**
   - `.evtx`/`.etl`: `Get-WinEvent` (Windows only).
   - Text: `Get-Content`.
4. **Match Patterns**
   - Hex codes (`0x####/0x########`).
   - Phrases (`errorcode = ####`, `HRESULT`, etc.).
   - Error-cloud tokens.
5. **Analyze**
   - Lookup in `error_db.json`.
   - AI for unknowns.

---

## 📊 Output Formats & Locations

- **Console**: Bordered sections per error.
- **Plain-Text (**``**)**: Summaries for sharing.
- **Responsive HTML**: Card-based layout.
- **Saved To**: `Analyzed Results/` with timestamped filenames.

---

## 🛠️ Troubleshooting

- **ImportExcel Missing**: Run `Install-Module ImportExcel` as Admin.
- **Permission Denied**: Use elevated privileges.
- **No Detections**: Verify path & update `errorcloud.txt`.
- **AI Failures**: Check API keys and connectivity.

---

## 🤝 Contributing & License

- Bug Reports & Feature Requests: Open GitHub Issues.
- Improve `error_db.json` entries.
- Documentation updates via PR.

Licensed under **MIT**. See [`LICENSE`](LICENSE) for details.

