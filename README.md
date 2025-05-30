````markdown
# Intune/Autopilot Log Analyzer

![PowerShell](https://img.shields.io/badge/PowerShell-Script-blue.svg)
![Version](https://img.shields.io/badge/version-5.1-green)
![AI-Ready](https://img.shields.io/badge/AI--Analysis-Optional-orange)

> A PowerShell-based tool for parsing, diagnosing, and optionally AI-analyzing Intune/Autopilot deployment logs.

---

## 🔧 Features

- ✅ Detects **hexadecimal** error codes (e.g., `0x80070643`)
- ✅ Extracts **errorCode = #######** and context phrases like `exit code 1603`
- ✅ Searches for over **300+ known failure keywords**
- ✅ Matches against offline **JSON error database** with suggested fixes
- ✅ Optionally runs AI-based analysis using **OpenAI**, **Azure OpenAI**, or **Claude**
- ✅ Auto-export of analysis results to a timestamped `.txt` report
- ✅ Menu-driven interface, user-friendly flow

---

## 📝 Requirements

- PowerShell 5.1+ or PowerShell Core
- Windows OS (tested with Intune logs)
- Internet connection for AI analysis (OpenAI/Azure/Claude)
- Optional: `error_db.json` for offline match suggestions

---

## 🚀 Usage

### 1. Clone the repo

```bash
git clone https://github.com/YOUR-USERNAME/Intune-Autopilot-Log-Analyzer.git
cd Intune-Autopilot-Log-Analyzer
````

### 2. Run the analyzer

```powershell
.\LogAnalyzer.ps1
```

### 3. Choose from the menu:

```
1. Analyze Log File
2. Set or Update OpenAI API Key
3. Select AI Model (gpt-4, gpt-3.5-turbo)
4. Analyze with AI Only
5. Manage AI Providers
6. Exit
```

---

## 📂 File Structure

```
.
├── LogAnalyzer.ps1         # Main script
├── errorcloud.txt          # List of known keywords & error signatures
├── error_db.json           # Optional offline error code -> fix mapping
├── apikey.txt              # (generated) stored OpenAI key
├── openai_key.txt          # (optional) stored AI provider keys
├── LogAnalysis_*.txt       # Output report(s)
```

---

## 🤖 AI Support (Optional)

If you enable AI analysis, the tool supports:

* **OpenAI API** ([https://platform.openai.com/](https://platform.openai.com/))
* **Azure OpenAI** (via Azure deployment endpoint)
* **Anthropic Claude API**

You will be prompted to enter your API key once and it will be securely stored in a text file (locally).

### Example Prompt Sent to AI:

```
Analyze this log excerpt for 0x80070642 and suggest root cause and fix:
[log lines...]
```

---

## 🧠 How It Works

The tool:

* Parses each line in your log file
* Searches for known patterns (`0x` codes, `errorCode = ####`, keywords)
* Matches findings against a local `error_db.json` database
* Optionally sends the context to an AI model for deeper insight

---

## 🧩 Sample `error_db.json` Entry

```json
[
  {
    "ErrorCode": "0x80070643",
    "Message": "Installation failed due to MSI issues.",
    "Context": "Win32 App Installation",
    "Solution": "1. Verify MSI logs\n2. Ensure .NET prerequisites\n3. Repackage app"
  }
]
```

---

## 📸 Screenshots *(Optional)*

> Add screenshots of the tool menu and output here (if desired).

---

## ⚖ License

MIT License
© 2025 [MD Faysal Mahmiud](mailto:faysaliteng@gmail.com)

---

## 🙋‍♂️ Contributing

* Found a new error not in the database? Add it to `error_db.json`
* Pull requests welcome!
* Or just open an issue with suggestions

---

## 🔗 Related

* [Intune Management Extension Logs](https://learn.microsoft.com/en-us/mem/intune/apps/intune-management-extension)
* [Windows Autopilot Troubleshooting](https://learn.microsoft.com/en-us/mem/autopilot/troubleshooting)
* [OpenAI API Docs](https://platform.openai.com/docs/)

---

```

---

Let me know if you'd like a version with embedded screenshots, auto-deploy scripts, or GitHub Actions CI setup too.
```
