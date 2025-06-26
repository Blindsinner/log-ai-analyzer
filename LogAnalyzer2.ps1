# Intune/Autopilot Log Analyzer PowerShell Tool
# Version: 5.3.9 (Universal Log Support including .evtx)
# Author: MD FAYSAL MAHMUD (faysaliteng@gmail.com)
# Enhanced with Gemini AI, unified error analysis, multi-file support, HTML export, and online search for missing entries

# -----------------------------------
# Set output directory to 'Analyzed Result' folder in script location and create it if it doesn't exist
# Keep error_db.json, errorcloud.txt, and apikey.txt in the root directory
# Only exported files (HTML and text result) are saved in Analyzed Result
# -----------------------------------
$ScriptDir      = Split-Path $MyInvocation.MyCommand.Path
$OutputDir      = Join-Path $ScriptDir "Analyzed Result"
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}
$apiKeyPath     = Join-Path $ScriptDir "apikey.txt"
$errorCloudPath = Join-Path $ScriptDir "errorcloud.txt"
$errorDbPath    = Join-Path $ScriptDir "error_db.json"
$global:model   = 'gemini-2.0-flash' # Default to the latest Gemini model

# -----------------------------------
# Ensure errorcloud.txt exists (contains comma-separated keywords to detect). If missing, create an empty placeholder.
# -----------------------------------
if (-not (Test-Path $errorCloudPath)) {
    Write-Warning "errorcloud.txt not found. Creating empty file. Please populate with comma-separated keywords."
    '' | Out-File -FilePath $errorCloudPath
}

# -----------------------------------
# Load error cloud tokens once
# -----------------------------------
function Get-ErrorCloudTokens {
    if (Test-Path $errorCloudPath) {
        $content = Get-Content -Path $errorCloudPath -Raw
        $tokens  = $content -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        return $tokens
    }
    return @()
}

# -----------------------------------
# Function Parse-LogFile: extracts hex-codes and keywords from the log
# -----------------------------------
function Parse-LogFile {
    param(
        [string]$FilePath
    )

    # Trim surrounding quotes if the user included them
    $FilePath = $FilePath.Trim('"')
    if (-not (Test-Path $FilePath)) {
        Write-Warning "Log file not found: $FilePath"
        return $null
    }
    
    # *** NEW: Universal Log Reading Logic ***
    $lines = @()
    $fileExtension = [System.IO.Path]::GetExtension($FilePath)

    try {
        if ($fileExtension -eq '.evtx') {
            Write-Host "Reading .evtx file. This may take a moment for large files..." -ForegroundColor Cyan
            # Use Get-WinEvent for .evtx files and select the message part
            $lines = Get-WinEvent -Path $FilePath -ErrorAction Stop | ForEach-Object { $_.Message }
        } else {
            # Use Get-Content for all other text-based files (.log, .txt, etc.)
            $lines = Get-Content -Path $FilePath -ErrorAction Stop
        }
    } catch {
        Write-Warning "Error reading log file '$FilePath': $_"
        return $null
    }
    
    Write-Host "Successfully read $($lines.Count) log entries." -ForegroundColor Green

    $codes    = @{}  # hashtable: hex code -> list of matching lines
    $keywords = @{}  # hashtable: keyword phrase -> list of matching lines
    $cloudTokens = Get-ErrorCloudTokens

    foreach ($l in $lines) {
        if ([string]::IsNullOrWhiteSpace($l)) { continue }
        # 1) Match anything that looks like 0xXXXX or 0xXXXXXXXX
        foreach ($m in [regex]::Matches($l, '0x[0-9A-Fa-f]{4,8}\b')) {
            $hex = $m.Value
            if (-not $codes.ContainsKey($hex)) { $codes[$hex] = @() }
            $codes[$hex] += $l
        }
        # 2) Match "errorcode = 1234"
        foreach ($m in [regex]::Matches($l, '(?i)\berrorcode\s*=\s*\d+\b')) {
            $fullPhrase = $m.Value
            if (-not $keywords.ContainsKey($fullPhrase)) { $keywords[$fullPhrase] = @() }
            $keywords[$fullPhrase] += $l
        }
        # 3) Match "error code: 0x1234" or "result code=5678" etc.
        foreach ($m in [regex]::Matches($l, '(?i)\b(?:e...|result|error|hresult)\s*code[:=]?\s*(0x[0-9A-Fa-f]+|\d+)\b')) {
            $phrase = $m.Value
            if (-not $keywords.ContainsKey($phrase)) { $keywords[$phrase] = @() }
            $keywords[$phrase] += $l
        }
        # 4) Check each line against our "error cloud" tokens
        foreach ($k in $cloudTokens) {
            if ($l -match [regex]::Escape($k)) {
                if (-not $keywords.ContainsKey($k)) { $keywords[$k] = @() }
                $keywords[$k] += $l
            }
        }
    }
    return @{ Codes = $codes; Keywords = $keywords }
}

# -----------------------------------
# Function Find-ErrorInDatabase: looks up a given error code in error_db.json
# -----------------------------------
function Find-ErrorInDatabase {
    param(
        [string]$ErrorInput
    )
    if (-not (Test-Path $errorDbPath)) { return $null }
    $db = Get-Content -Path $errorDbPath | ConvertFrom-Json
    foreach ($entry in $db) {
        if ($entry.ErrorCode -eq $ErrorInput) { return $entry }
    }
    return $null
}

# -----------------------------------
# Function Save-APIKey: saves API key text to a file AND sets the global variable
# -----------------------------------
function Save-APIKey {
    param(
        [string]$key,
        [string]$provider = 'gemini'
    )
    $path = Join-Path $ScriptDir "${provider}_key.txt"
    Set-Content -Path $path -Value $key
    $apiKeyVarName = "apiKey_$provider"
    # Use -Force to create the variable or overwrite it if it already exists.
    New-Variable -Name $apiKeyVarName -Scope Global -Value $key -Force
    Write-Host "API key for $provider SAVED!" -ForegroundColor Green
}

# -----------------------------------
# Function Invoke-AIAnalysis: calls AI to get analysis
# -----------------------------------
function Invoke-AIAnalysis {
    param(
        [string]$Excerpt,
        [string]$Code,
        [string]$Provider = 'gemini'
    )
    Write-Host "Connecting to $Provider endpoint....." -ForegroundColor Cyan
    Write-Host "Analyzing with AI: Log Error '$Code'" -ForegroundColor Cyan
    
    $apiKeyVarName = "apiKey_$provider"
    if (-not (Get-Variable -Name $apiKeyVarName -Scope Global -ErrorAction SilentlyContinue)) {
        $keyPath = Join-Path $ScriptDir "${Provider}_key.txt"
        if (Test-Path $keyPath) {
            $val = Get-Content $keyPath -Raw
            New-Variable -Name $apiKeyVarName -Scope Global -Value $val
        } else {
            $newKey = Read-Host "WARNING: API key for $Provider not found. Please enter it now:"
            Save-APIKey $newKey $Provider
        }
    }
    
    $apiKey = (Get-Variable -Name $apiKeyVarName -Scope Global).Value
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        $newKey = Read-Host "WARNING: API key for $Provider is not defined. Please enter it now:"
        Save-APIKey $newKey $Provider
        $apiKey = $newKey
    }

    $strictPrompt = @"
You are an expert IT helpdesk technician. Analyze the IT log error below and provide a response STRICTLY in the following format.
Do NOT use any other text, commentary, or markdown like bolding or asterisks.

Description: [Provide a concise, one-sentence description of the error code in the context of the log.]

Recommended Solutions:
1. [First recommended step]
2. [Second recommended step]
3. [And so on...]

Error Information:
Error Code: $Code
Log Excerpt:
$Excerpt
"@

    $headers = @{}
    $body = ''
    $uri = ''

    switch ($Provider) {
        'gemini' {
            $uri = "https://generativelanguage.googleapis.com/v1beta/models/$($global:model):generateContent?key=$apiKey"
            $headers = @{ 'Content-Type' = 'application/json' }
            $body = @{
                contents = @(
                    @{ parts = @( @{ text = $strictPrompt } ) }
                )
            } | ConvertTo-Json -Depth 5
        }
        'openai' {
            $uri = 'https://api.openai.com/v1/chat/completions'
            $headers = @{ Authorization = "Bearer $apiKey"; 'Content-Type' = "application/json" }
            $body = @{
                model    = 'gpt-4'
                messages = @(
                    @{ role = 'user'; content = $strictPrompt }
                )
            } | ConvertTo-Json -Depth 5
        }
        'azure'  { 
            $uri = "https://<your-azure-endpoint>.openai.azure.com/openai/deployments/gpt-4/chat/completions?api-version=2023-05-15"
            $headers = @{ 'api-key' = $apiKey; 'Content-Type' = "application/json" }
            $body = @{
                model    = 'gpt-4'
                messages = @(
                    @{ role = 'user'; content = $strictPrompt }
                )
            } | ConvertTo-Json -Depth 5
        }
    }

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
        switch ($Provider) {
            'gemini' { return $response.candidates[0].content.parts[0].text.Trim() }
            'openai' { return $response.choices[0].message.content.Trim() }
            'azure'  { return $response.choices[0].message.content.Trim() }
        }
    } catch {
        Write-Warning "Failed to get AI analysis from $($Provider): $_"
        return $null
    }
}


# -----------------------------------
# Function Export-LogAnalysisToHtml: builds a styled, responsive HTML summary
# -----------------------------------
function Export-LogAnalysisToHtml {
    param([hashtable]$AnalysisResults, [string]$OutputPath)
    $htmlPath = Join-Path $OutputPath ("LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').html")
    
    $body = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log Analysis Report</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bs-blue: #0d6efd; --bs-indigo: #6610f2; --bs-purple: #6f42c1; --bs-pink: #d63384; --bs-red: #dc3545; --bs-orange: #fd7e14; --bs-yellow: #ffc107; --bs-green: #198754; --bs-teal: #20c997; --bs-cyan: #0dcaf0; --bs-white: #fff; --bs-gray: #6c757d; --bs-gray-dark: #343a40; --bs-primary: #0d6efd; --bs-secondary: #6c757d; --bs-success: #198754; --bs-info: #0dcaf0; --bs-warning: #ffc107; --bs-danger: #dc3545; --bs-light: #f8f9fa; --bs-dark: #212529;
            --font-family-sans-serif: 'Inter', system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", "Liberation Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
            --background-color: #f0f2f5;
            --card-background: #ffffff;
            --text-color: #495057;
            --heading-color: #212529;
            --border-color: #dee2e6;
            --shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        body { font-family: var(--font-family-sans-serif); background-color: var(--background-color); color: var(--text-color); line-height: 1.6; }
        .container { max-width: 1200px; margin: 40px auto; padding: 0 20px; }
        .report-header { text-align: center; margin-bottom: 40px; padding: 20px; background-color: var(--card-background); border-radius: 12px; box-shadow: var(--shadow); }
        .report-header h1 { color: var(--heading-color); font-weight: 700; margin-bottom: 8px; }
        .report-header p { color: var(--bs-secondary); font-size: 1.1rem; }
        .section-title { font-size: 1.75rem; font-weight: 600; color: var(--heading-color); margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid var(--border-color); }
        .error-card { background-color: var(--card-background); border: 1px solid var(--border-color); border-radius: 12px; box-shadow: var(--shadow); margin-bottom: 25px; overflow: hidden; }
        .error-header { background-color: var(--bs-dark); color: var(--bs-light); padding: 15px 20px; font-weight: 600; font-size: 1.2rem; display: flex; align-items: center; }
        .error-header-icon { margin-right: 12px; font-size: 1.5rem; }
        .error-body { padding: 20px; }
        .detail-block { margin-bottom: 20px; }
        .detail-block:last-child { margin-bottom: 0; }
        .detail-block h5 { font-weight: 600; color: var(--heading-color); font-size: 1rem; margin-bottom: 10px; }
        .solutions-list { list-style-type: decimal; padding-left: 20px; margin: 0; }
        .solutions-list li { margin-bottom: 8px; padding-left: 5px; }
        pre { white-space: pre-wrap; word-wrap: break-word; background-color: var(--background-color); padding: 15px; border-radius: 8px; font-family: 'Courier New', Courier, monospace; border: 1px solid var(--border-color); max-height: 300px; overflow-y: auto; }
        .badge { display: inline-block; padding: .35em .65em; font-size: .75em; font-weight: 700; line-height: 1; color: #fff; text-align: center; white-space: nowrap; vertical-align: baseline; border-radius: .375rem; }
        .badge-danger { background-color: var(--bs-danger); }
        .footer { text-align: center; margin-top: 40px; color: var(--bs-secondary); font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="report-header">
            <h1>Log Analysis Report</h1>
            <p>Generated on: $(Get-Date)</p>
        </div>
"@
    
    function Sanitize-ForHtml {
        param([string]$Text)
        return $Text -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
    }

    function New-HtmlErrorCard {
        param([string]$Key, [string]$Type, [string]$Description, [array]$Solutions, [string]$Context)

        $headerIcon = if ($Type -eq 'AI') { '&#129504;' } else { '&#128190;' } # Brain and Floppy Disk emoji
        $sanitizedContext = if ($Context) { Sanitize-ForHtml -Text $Context } else { 'N/A' }
        $sanitizedDescription = Sanitize-ForHtml -Text $Description
        $sanitizedKey = Sanitize-ForHtml -Text $Key

        $solutionsHtml = ""
        if ($Solutions) {
            $solutionsHtml = "<ol class='solutions-list'>"
            foreach ($solution in $Solutions) { $solutionsHtml += "<li>$(Sanitize-ForHtml -Text $solution.Trim())</li>" }
            $solutionsHtml += "</ol>"
        } else { $solutionsHtml = "<p>No specific solutions found.</p>" }

        return @"
        <div class="error-card">
            <div class="error-header"><span class="error-header-icon">$headerIcon</span> <span class="badge badge-danger" style="margin-left:auto;">$sanitizedKey</span></div>
            <div class="error-body">
                <div class="detail-block"><h5>Description</h5><p>$sanitizedDescription</p></div>
                <div class="detail-block"><h5>Recommended Solutions</h5>$solutionsHtml</div>
                <div class="detail-block"><h5>Original Log Context</h5><pre>$sanitizedContext</pre></div>
            </div>
        </div>
"@
    }

    if ($AnalysisResults.DatabaseMatches.Count -gt 0) {
        $body += "<h2 class='section-title'>Offline Database Analysis</h2>"
        foreach ($key in $AnalysisResults.DatabaseMatches.Keys) {
            $dbEntry = $AnalysisResults.DatabaseMatches[$key]
            $solutionString = $dbEntry.Solution -replace '\s+(?=\d+\.)', "`n"
            $solutionsArray = $solutionString.Split("`n") | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() -replace '^\d+\.\s*' }
            $logContext = $AnalysisResults.Contexts[$key]
            $body += New-HtmlErrorCard -Key $key -Type 'DB' -Description $dbEntry.Message -Solutions $solutionsArray -Context $logContext
        }
    }

    if ($AnalysisResults.AIAnalyses.Keys.Count -gt 0) {
        $body += "<h2 class='section-title'>AI Analysis</h2>"
        foreach ($key in $AnalysisResults.AIAnalyses.Keys) {
            $aiResult = $AnalysisResults.AIAnalyses[$key]
            $description = ''; $solutionsArray = @()
            if ($aiResult -match '(?sm)Description:(.*?)Recommended Solutions:(.*)') {
                $description = $Matches[1].Trim()
                $solutionsRaw = $Matches[2].Trim()
                $solutionsArray = $solutionsRaw.Split("`n") | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() -replace '^\d+\.\s*' }
            } else { $description = "Could not parse AI response into sections."; $solutionsArray = @($aiResult) }
            $logContext = $AnalysisResults.Contexts[$key]
            $body += New-HtmlErrorCard -Key $key -Type 'AI' -Description $description -Solutions $solutionsArray -Context $logContext
        }
    }

    $body += @"
        <div class="footer"><p>Generated by Universal Log Analyzer v5.3.9</p></div>
    </div>
</body>
</html>
"@
    $body | Out-File -FilePath $htmlPath -Encoding utf8
    Write-Host "HTML report exported to $htmlPath" -ForegroundColor Green
}


# -----------------------------------
# Function Select-AIProvider: user picks which AI provider
# -----------------------------------
function Select-AIProvider {
    Write-Host "`n=== AI Provider Selection ===" -ForegroundColor Cyan
    Write-Host "1. Google (Gemini)"
    Write-Host "2. OpenAI"
    Write-Host "3. Azure OpenAI"
    Write-Host "4. Back to Main Menu"
    $opt = Read-Host "Select provider (1-4)"
    return $opt
}

# -----------------------------------
# Function Manage-AIProviders: sub-menu, allows setting/updating keys for each provider
# -----------------------------------
function Manage-AIProviders {
    while ($true) {
        Write-Host "`n=== AI Provider Management ===" -ForegroundColor Cyan
        Write-Host "1. Set or Update Google (Gemini) API Key"
        Write-Host "2. Set or Update OpenAI API Key"
        Write-Host "3. Set or Update Azure OpenAI API Key"
        Write-Host "4. Back to Main Menu"
        $opt = Read-Host "Select an option (1-4)"
        switch ($opt) {
            '1' { $newKey = Read-Host 'Enter your Google (Gemini) API key'; Save-APIKey $newKey 'gemini' }
            '2' { $newKey = Read-Host 'Enter your OpenAI API key'; Save-APIKey $newKey 'openai' }
            '3' { $azureKey = Read-Host 'Enter your Azure OpenAI API key'; Save-APIKey $azureKey 'azure' }
            '4' { return }
            default { Write-Warning "Invalid input. Try again." }
        }
    }
}

# -----------------------------------
# Main Menu function: ties everything together
# -----------------------------------
function Main-Menu {
    while ($true) {
        Write-Host "`n=== Universal Log Analyzer Menu (v5.3.9 Gemini Enhanced) ===" -ForegroundColor Cyan
        Write-Host "1. Analyze Log File (Offline DB & optional online search)"
        Write-Host "2. Analyze with AI Only (Directly analyze log with selected AI)"
        Write-Host "3. Select AI Model (Current: $($global:model))"
        Write-Host "4. Manage AI Providers & API Keys"
        Write-Host "5. Exit"
        $choice = Read-Host "Choose an option (1-5)"

        switch ($choice) {
            '1' { # Standard Analysis
                $LogFilePath = Read-Host 'Enter path to log file (e.g., C:\Logs\Application.evtx or IntuneManagementExtension.log)'
                $data = Parse-LogFile -FilePath $LogFilePath
                if (-not $data) { continue }

                Write-Host "`n=== Detection Results ===" -ForegroundColor Cyan
                if ($data.Codes.Keys.Count -gt 0) { Write-Host "Detected Error Codes:"; $data.Codes.Keys | ForEach-Object { Write-Host "- $_" } } else { Write-Host "No error codes detected." }
                if ($data.Keywords.Keys.Count -gt 0) { Write-Host "`nDetected Error Keywords:"; $data.Keywords.Keys | ForEach-Object { Write-Host "- $_" } } else { Write-Host "No error keywords detected." }

                $selected = Read-Host "`nEnter error code/keyword or press Enter to analyze all detected items"
                if ([string]::IsNullOrWhiteSpace($selected)) {
                    $targets = @()
                    $targets += $data.Codes.Keys | ForEach-Object { [PSCustomObject]@{ Type = 'Code'; Value = $_ } }
                    $targets += $data.Keywords.Keys | ForEach-Object { [PSCustomObject]@{ Type = 'Keyword'; Value = $_ } }
                } else {
                    $selTrim = $selected.Trim('"')
                    if ($data.Codes.ContainsKey($selTrim)) { $targets = @([PSCustomObject]@{ Type = 'Code'; Value = $selTrim }) } 
                    elseif ($data.Keywords.ContainsKey($selTrim)) { $targets = @([PSCustomObject]@{ Type = 'Keyword'; Value = $selTrim }) } 
                    else { Write-Warning "Specified item '$selTrim' not found."; continue }
                }

                $outputPath        = Join-Path $OutputDir "LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $missingItems      = @()
                $analysisResults   = [ordered]@{ Contexts = @{}; DatabaseMatches = @{}; AIAnalyses = @{} }

                foreach ($target in $targets) {
                    $analysisResults.Contexts[$target.Value] = if ($target.Type -eq 'Code') { ($data.Codes[$target.Value] -join "`n") } else { ($data.Keywords[$target.Value] -join "`n") }
                    $dbEntry = Find-ErrorInDatabase -ErrorInput $target.Value
                    if ($dbEntry) {
                        $analysisResults.DatabaseMatches[$target.Value] = $dbEntry
                        $border = "=" * 70
                        Write-Host "`n$border" -ForegroundColor Green; Write-Host "[Offline Database Match for '$($dbEntry.ErrorCode)']"
                        Write-Host "Description: $($dbEntry.Message)`n"; Write-Host "Recommended Solutions:"
                        $solutionString = $dbEntry.Solution -replace '\s+(?=\d+\.)', "`n"
                        $solutions = $solutionString.Split("`n") | Where-Object { $_ -match '\S' }
                        $textOutputSolutions = @()
                        for ($i = 0; $i -lt $solutions.Count; $i++) {
                            $cleanedLine = $solutions[$i].Trim() -replace '^\d+\.\s*'
                            $numberedLine = "$($i + 1). $cleanedLine"
                            Write-Host $numberedLine; $textOutputSolutions += $numberedLine
                        }
                        Write-Host $border -ForegroundColor Green
                        Add-Content $outputPath "`n$border`n[Offline Database Match for '$($dbEntry.ErrorCode)']`nDescription: $($dbEntry.Message)`n`nRecommended Solutions:"
                        $textOutputSolutions | Out-File -FilePath $outputPath -Append -Encoding utf8
                        Add-Content $outputPath "`n$border"
                    } else { Write-Host "`nWARNING: No offline data found for $($target.Value)" -ForegroundColor Yellow; $missingItems += $target.Value }
                }
                if ($missingItems.Count -gt 0) { if ((Read-Host "`nDo you want to search Online for the missing entries? (Y/N)") -match '^[Yy]$') { $missingItems | Select-Object -Unique | ForEach-Object { Start-Process "https://www.google.com/search?q=Intune%20$([uri]::EscapeDataString($_))" } } }
                Export-LogAnalysisToHtml -AnalysisResults $analysisResults -OutputPath $OutputDir
            }

            '2' { # AI Only Analysis
                $LogFilePath = Read-Host 'Enter path to log file (e.g., C:\Logs\Application.evtx or IntuneManagementExtension.log)'
                $data = Parse-LogFile -FilePath $LogFilePath
                if (-not $data -or ($data.Codes.Count -eq 0 -and $data.Keywords.Count -eq 0)) { Write-Warning "No errors detected in the log file or file not found."; continue }

                $providerChoice = Select-AIProvider
                if ($providerChoice -notmatch '^[1-3]$') { Write-Warning "Invalid selection. AI analysis canceled."; continue }
                $aiProvider = @('gemini', 'openai', 'azure')[[int]$providerChoice - 1]
                
                $outputPath = Join-Path $OutputDir "AI_Analysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $analysisResults = [ordered]@{ Contexts = @{}; DatabaseMatches = @{}; AIAnalyses = @{} }
                
                $allTargets = @() + $data.Codes.Keys + $data.Keywords.Keys
                foreach ($item in $allTargets) {
                    $excerpt = ""
                    if ($data.Codes.ContainsKey($item)) { $excerpt = ($data.Codes[$item] -join "`n") } else { $excerpt = ($data.Keywords[$item] -join "`n") }
                    $analysisResults.Contexts[$item] = $excerpt
                    $excerpt = $excerpt.Substring(0, [Math]::Min(2000, $excerpt.Length))

                    $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $item -Provider $aiProvider
                    if ($aiResult) {
                        $analysisResults.AIAnalyses[$item] = $aiResult
                        $border = "=" * 70
                        Write-Host "`n$border" -ForegroundColor Magenta; Write-Host "[AI Analysis for '$item']" -ForegroundColor Magenta
                        Write-Host ""; Write-Host $aiResult; Write-Host $border -ForegroundColor Magenta
                        Add-Content $outputPath "`n$border`n[AI Analysis for '$item']`n`n$aiResult`n$border"
                    }
                }
                Export-LogAnalysisToHtml -AnalysisResults $analysisResults -OutputPath $OutputDir
            }

            '3' { # Select Model
                Write-Host "Select AI Model. Current is $($global:model)"
                $m = Read-Host 'Enter model (e.g., gemini-2.0-flash, gpt-4, gpt-3.5-turbo)'
                if (-not [string]::IsNullOrWhiteSpace($m)) { $global:model = $m; Write-Host "Model set to: $m" -ForegroundColor Green } else { Write-Warning "Model name cannot be empty." }
            }

            '4' { Manage-AIProviders }
            '5' { exit }
            default { Write-Warning "Invalid input. Try again." }
        }
    }
}

# -----------------------------------
# Start the script
# -----------------------------------
Main-Menu
