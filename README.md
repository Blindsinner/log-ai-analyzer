# LogAI Analyzer — Universal AI-Enhanced Log Parser (PowerShell Tool)

**Version**: 6.0 &#x20;
**Author**: MD Faysal Mahmud ([faysaliteng@gmail.com](mailto:faysaliteng@gmail.com)) &#x20;
**Repository**: [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer) &#x20;
**Enhanced With**: Google Gemini, OpenAI, Azure OpenAI, unified offline/online error analysis, multi-format support, and responsive HTML exports.

---

## 📖 Overview {#overview}

LogAI Analyzer is a powerful PowerShell tool designed to parse and diagnose errors from Microsoft Intune, Autopilot, and other Windows log sources. It combines a local error database with AI-powered diagnostics for comprehensive analysis.

### Key Features:

* Universal File Support (e.g., `.zip`, `.evtx`, `.xlsx`, etc.)
* Recursive Archive Extraction
* Hybrid Offline & AI-Driven Analysis
* Custom Keyword Detection
* Responsive HTML & Text Reports
* Cross-Platform (Windows, macOS, Linux)

---

## 📋 Table of Contents {#toc}

1. [Prerequisites](#prerequisites)
2. [Installation & Setup](#installation)
3. [Configuration](#configuration)
4. [File & Folder Structure](#structure)
5. [Usage Examples](#usage)
6. [Main Menu Options](#menu)
7. [Core Logic](#logic)
8. [Output](#output)
9. [Troubleshooting](#troubleshooting)
10. [Contributing & License](#license)

---

## 🛠️ Prerequisites {#prerequisites}

* PowerShell 5.1+ (Windows) or PowerShell Core v7.2+ (macOS/Linux)
* `ImportExcel` module for Excel support
* Administrator privileges to read system logs (`.evtx`, `.etl`)
* Internet connection for AI-based analysis

---

## ⚙️ Installation & Setup {#installation}

**Windows**

```powershell
# Run as Administrator
git clone https://github.com/Blindsinner/log-ai-analyzer.git
cd log-ai-analyzer
Install-Module ImportExcel -AcceptLicense -Force
Unblock-File .\LogAnalyzer.ps1
.\LogAnalyzer.ps1
```

**macOS/Linux**

```bash
# Install PowerShell Core (Ubuntu example)
wget -q https://packages.microsoft.com/.../packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y powershell

# Clone and run
git clone https://github.com/Blindsinner/log-ai-analyzer.git
cd log-ai-analyzer
pwsh -Command "Install-Module ImportExcel -AcceptLicense -Force"
pwsh ./LogAnalyzer.ps1
```

---

## 🔧 Configuration {#configuration}

* **API Keys**: Enter on first AI use; saved to `gemini_key.txt`, `openai_key.txt`, `azure_key.txt`.
* **Offline DB**: Edit `error_db.json` to add `{ErrorCode, Message, Solution}` entries.
* **Keywords**: Add tokens to `errorcloud.txt` for custom detection.

---

## 📂 File & Folder Structure {#structure}

```
log-ai-analyzer/
├── LogAnalyzer.ps1
├── error_db.json
├── errorcloud.txt
├── gemini_key.txt
├── openai_key.txt
├── azure_key.txt
└── Analyzed Results/
    ├── LogAnalysis_YYYYMMDD_HHMMSS.html
    └── ...
```

---

## 🚀 Usage Examples {#usage}

```powershell
# Hybrid Analysis
dotnet LogAnalyzer.ps1 → option 1

# AI-Only Analysis
→ option 2
```

---

## 🔍 Main Menu Options {#menu}

1. Analyze Log File (Offline + Online)
2. Analyze with AI Only
3. Select AI Model
4. Manage API Keys
5. Exit

---

## 🧩 Core Logic {#logic}

1. Identify file type
2. Extract/parse archives & logs
3. Match error codes & keywords
4. Lookup offline DB or call AI

---

## 📊 Output {#output}

* **Console** progress
* **Text** summaries (`*.txt`)
* **HTML** reports (`*.html`)
* Stored in `Analyzed Results/` with timestamps

---

## 🛠️ Troubleshooting {#troubleshooting}

* **ImportExcel Missing**: `Install-Module ImportExcel -Force`
* **Permission Denied**: Run as Administrator
* **No Errors**: Check file path and keywords
* **AI Fails**: Verify API keys & internet

---

## 🤝 Contributing & License {#license}

Contributions welcome! Open issues, submit PRs, update DB/data.

Licensed under MIT. See `LICENSE`.
