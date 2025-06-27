# LogAI Analyzer — Universal AI-Enhanced Log Parser (PowerShell Tool)

**Version**: 6.0 &#x20;
**Author**: MD Faysal Mahmud ([faysaliteng@gmail.com](mailto:faysaliteng@gmail.com)) &#x20;
**Repository**: [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer) &#x20;
**Enhanced With**: Google Gemini, OpenAI, Azure OpenAI, unified offline/online error analysis, multi-format support, and responsive HTML exports.

---

## 📖 Overview

LogAI Analyzer is a powerful PowerShell tool designed to parse and diagnose errors from Microsoft Intune, Autopilot, and other Windows log sources. It intelligently combines a local error database (`error_db.json`) with AI-powered analysis from Google Gemini, OpenAI, and Azure OpenAI to deliver comprehensive diagnostics.

### Key Features:

* **Universal File Support**: Natively handles `.zip`, `.xlsx`, `.xls`, `.evtx`, `.etl`, `.log`, `.txt`, `.html`, `.xml`, and more.
* **Recursive Archive Extraction**: Automatically processes nested archives to find all relevant logs.
* **Hybrid Analysis**:

  * **Offline**: Fast lookups using the local `error_db.json`.
  * **Online**: AI-driven diagnostics for unrecognized or complex errors.
* **Custom Keyword Detection**: Define your own search tokens in the `errorcloud.txt` file.
* **Responsive Reports**: Generates professional, SEO-friendly HTML and plain-text reports.
* **Cross-Platform**: Compatible with Windows PowerShell 5.1+ and PowerShell Core (macOS/Linux).

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation & Cross-Platform Setup](#installation)
3. [Configuration](#configuration)
4. [File & Folder Structure](#structure)
5. [Usage Examples](#usage)
6. [Main Menu Options](#menu)
7. [Core Logic](#logic)
8. [Output](#output)
9. [Troubleshooting](#troubleshooting)
10. [Contributing & License](#license)

---

<!-- Explicit anchors -->

<a id="prerequisites"></a>

## 🛠️ Prerequisites

* **PowerShell**:

  * **Windows**: PowerShell 5.1 or later.
  * **macOS/Linux**: PowerShell Core v7.2+ (`pwsh`).
* **PowerShell Module**: The `ImportExcel` module is required for `.xlsx` and `.xls` file support.
* **Permissions**: Administrator privileges are required on Windows to analyze `.evtx` and `.etl` files.
* **Internet Connection**: Required for AI-based analysis and optional online searches.
* **Required Files**: The `LogAnalyzer.ps1`, `error_db.json`, and `errorcloud.txt` files must be located in the same directory.

---

<a id="installation"></a>

## ⚙️ Installation & Cross-Platform Setup

### Windows (Run in an Administrator PowerShell)

1. **Run as Administrator**: Search for “PowerShell”, right-click it, and select **Run as administrator**.
2. **Verify Git Installation**:

   ```powershell
   git --version
   ```

   * If Git is not installed, download it from [https://git-scm.com/download/win](https://git-scm.com/download/win) and restart your administrative PowerShell session.
3. **Get the Code**:

   * **With Git (Recommended)**:

     ```powershell
     git clone https://github.com/Blindsinner/log-ai-analyzer.git
     cd log-ai-analyzer
     ```
   * **Without Git**:

     1. Navigate to [https://github.com/Blindsinner/log-ai-analyzer](https://github.com/Blindsinner/log-ai-analyzer).
     2. Click **Code → Download ZIP**.
     3. Extract the archive to a known location (e.g., `C:\Users\YourUser\Downloads\log-ai-analyzer`).
     4. In PowerShell, navigate to the directory:

        ```powershell
        cd "C:\Users\YourUser\Downloads\log-ai-analyzer"
        ```
4. **Install Required Module**:

   ```powershell
   Install-Module -Name ImportExcel -AcceptLicense -Force
   ```
5. **Unblock the Script**:

   ```powershell
   Unblock-File -Path .\LogAnalyzer.ps1
   ```
6. **Run the Analyzer**:

   ```powershell
   .\LogAnalyzer.ps1
   ```

### macOS / Linux

1. **Install PowerShell Core** (Example for Ubuntu):

   ```bash
   wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt-get update
   sudo apt-get install -y powershell
   ```
2. **Clone Repository & Navigate**:

   ```bash
   git clone https://github.com/Blindsinner/log-ai-analyzer.git
   cd log-ai-analyzer
   ```
3. **Install Required Module**:

   ```bash
   pwsh -Command "Install-Module -Name ImportExcel -AcceptLicense -Force"
   ```
4. **Run the Analyzer**:

   ```bash
   pwsh ./LogAnalyzer.ps1
   ```

> **Note**: Analysis of `.evtx` and `.etl` files is only supported on Windows. All other formats are fully functional across all platforms.

---

<a id="configuration"></a>

## 🔧 Configuration

1. **API Keys**: The first time you use an AI-powered feature, the script will prompt you to enter and save your API keys. The keys will be stored locally in `gemini_key.txt`, `openai_key.txt`, and `azure_key.txt`.
2. **Offline Database**: You can extend the local database by editing `error_db.json`. Add new entries using the format: `{ "ErrorCode": "0x12345678", "Message": "A brief description.", "Solution": "A detailed solution." }`.
3. **Custom Keywords**: Add your own comma-separated keywords to `errorcloud.txt` (e.g., `timeout,access denied,failed to connect`) to customize error detection.

---

<a id="structure"></a>

## 📂 File & Folder Structure

```plaintext
log-ai-analyzer/
├── LogAnalyzer.ps1         # Main script
├── error_db.json           # Offline error database
├── errorcloud.txt          # Custom keyword list
├── gemini_key.txt          # Created automatically on first AI run
├── openai_key.txt          # Created automatically on first AI run
├── azure_key.txt           # Created automatically on first AI run
└── Analyzed Results/       # Default directory for output files
    ├── LogAnalysis_YYYYMMDD_HHMMSS.html
    └── AI_Analysis_YYYYMMDD_HHMMSS.txt
```

---

<a id="usage"></a>

## 🚀 Usage Examples

```powershell
.\LogAnalyzer.ps1
# Select option 1 from the menu
# Enter the path to your log file, e.g., C:\Logs\example.evtx
```

---

<a id="menu"></a>

## 🔍 Main Menu Options

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

<a id="logic"></a>

## 🧩 Core Logic

1. **File Identification**: The script first determines the file type based on its extension.
2. **Extraction & Parsing**: Archives are recursively extracted, and Excel files are imported. Event logs (`.evtx`), trace logs (`.etl`), and plain-text logs are parsed accordingly.
3. **Pattern Matching**: The content is scanned for hexadecimal error codes, error-related phrases, and custom keywords from `errorcloud.txt`.
4. **Hybrid Resolution**: Detected errors are first looked up in the local `error_db.json`. If an error is not found, it is sent to the selected AI model for advanced analysis.

---

<a id="output"></a>

## 📊 Output

* **Console**: Real-time progress and results are displayed in neatly bordered sections.
* **Text Files**: `*.txt` files provide a simple summary of findings.
* **HTML Reports**: `*.html` files offer a responsive, card-based layout for easy reading and sharing.
* All reports are saved to the `Analyzed Results/` folder with a timestamp for clear organization.

---

<a id="troubleshooting"></a>

## 🛠️ Troubleshooting

* **`ImportExcel` Module Not Found**: Ensure the module is installed by running `Install-Module ImportExcel -Force` in an administrative PowerShell session.
* **Permission Denied Errors**: The script requires elevated (administrator) privileges to read certain system logs (`.evtx`, `.etl`). Right-click PowerShell and select "Run as administrator."
* **No Errors Detected**: Double-check that the file path is correct and that the logs contain searchable error codes or keywords defined in `errorcloud.txt`.
* **AI Analysis Fails**: Verify that your API keys are correct and that you have a stable internet connection. Check the AI provider's status page for any outages.

---

<a id="license"></a>

## 🤝 Contributing & License

We welcome contributions! Feel free to open issues, submit pull requests, update the error database, or improve the documentation.

This project is licensed under the MIT License. See the `LICENSE` file in the repository for details.
