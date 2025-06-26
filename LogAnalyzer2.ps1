# Intune/Autopilot Log Analyzer PowerShell Tool
# Version: 5.3.6 (Restore Feature)
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
    $lines    = Get-Content -Path $FilePath
    $codes    = @{}  # hashtable: hex code -> list of matching lines
    $keywords = @{}  # hashtable: keyword phrase -> list of matching lines

    $cloudTokens = Get-ErrorCloudTokens

    foreach ($l in $lines) {
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
    Write-Host "Analyzing with AI: Intune Enrollment Error '$Code'" -ForegroundColor Cyan
    
    $apiKeyVarName = "apiKey_$Provider"
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
You are an expert IT helpdesk technician. Analyze the Intune error below and provide a response STRICTLY in the following format.
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
    <title>Intune Log Analysis Report</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { font-family: Arial, sans-serif; background-color: #f8f9fa; }
        .container { max-width: 1200px; margin: 20px auto; }
        h1 { color: #007bff; }
        .error-card { margin-bottom: 20px; border: 1px solid #ddd; border-radius: 8px; background-color: white; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .error-header { background-color: #343a40; color: white; padding: 10px; border-radius: 8px 8px 0 0; }
        .error-body { padding: 15px; }
        .error-code { font-weight: bold; color: #dc3545; }
        .solutions-list { margin-top: 10px; padding-left: 20px; }
        pre { white-space: pre-wrap; word-wrap: break-word; background-color: #f8f9fa; padding: 10px; border-radius: 4px; font-family: Consolas, 'Courier New', monospace; border: 1px solid #eee; }
        .no-data { color: #dc3545; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="text-center my-4">Intune Log Analysis Report</h1>
        <p><strong>Generated on:</strong> $(Get-Date)</p>
"@
    if ($AnalysisResults.DatabaseMatches.Count -gt 0) {
        $body += "<h2>Offline Database Analysis</h2>"
    }
    foreach ($key in $AnalysisResults.DatabaseMatches.Keys) {
        $dbEntry = $AnalysisResults.DatabaseMatches[$key]
        $dbMatch = $dbEntry.Message -replace '<','&lt;' -replace '>','&gt;'
        $solutionsHtml = '<span class="no-data">N/A</span>'

        $solutionString = $dbEntry.Solution -replace '\s+(?=\d+\.)', "`n"
        $solutions = $solutionString.Split("`n") | Where-Object { $_ -match '\S' }

        if ($solutions) {
            $solutionsHtml = "<ol class='solutions-list'>"
            foreach ($solution in $solutions) {
                $solutionText = $solution.Trim() -replace '^\d+\.\s*', ''
                $solutionText = $solutionText -replace '<','&lt;' -replace '>','&gt;'
                $solutionsHtml += "<li>$solutionText</li>"
            }
            $solutionsHtml += "</ol>"
        }
        
        $body += @"
            <div class="error-card">
                <div class="error-header"><h3 class="error-code">[Offline Database Match for '$($dbEntry.ErrorCode)']</h3></div>
                <div class="error-body">
                    <p><strong>Description:</strong> $dbMatch</p>
                    <p><strong>Recommended Solutions:</strong></p>
                    $solutionsHtml
                </div>
            </div>
"@
    }
    if ($AnalysisResults.AIAnalyses.Keys.Count -gt 0) {
        $body += "<h2 class='mt-4'>AI Analysis</h2>"
    }
    foreach ($key in $AnalysisResults.AIAnalyses.Keys) {
        $aiContent = $AnalysisResults.AIAnalyses[$key] -replace '<','&lt;' -replace '>','&gt;'
        $body += @"
            <div class="error-card">
                <div class="error-header"><h3 class="error-code">[AI Analysis for '$key']</h3></div>
                <div class="error-body">
                    <pre>$aiContent</pre>
                </div>
            </div>
"@
    }
    $body += @"
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
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
        Write-Host "`n=== Intune Log Analyzer Menu (v5.3.6 Gemini Enhanced) ===" -ForegroundColor Cyan
        Write-Host "1. Analyze Log File (Offline DB & optional online search)"
        Write-Host "2. Analyze with AI Only (Directly analyze log with selected AI)"
        Write-Host "3. Select AI Model (Current: $($global:model))"
        Write-Host "4. Manage AI Providers & API Keys"
        Write-Host "5. Exit"
        $choice = Read-Host "Choose an option (1-5)"

        switch ($choice) {
            '1' { # Standard Analysis
                $LogFilePath = Read-Host 'Enter path to log file (e.g., IntuneManagementExtension.log)'
                $data = Parse-LogFile -FilePath $LogFilePath
                if (-not $data) { continue }

                # *** THIS IS THE RESTORED FEATURE ***
                # Show detection summary before asking for user input
                Write-Host "`n=== Detection Results ===" -ForegroundColor Cyan
                if ($data.Codes.Keys.Count -gt 0) {
                    Write-Host "Detected Error Codes:"
                    $data.Codes.Keys | ForEach-Object { Write-Host "- $_" }
                } else {
                    Write-Host "No error codes detected."
                }
                if ($data.Keywords.Keys.Count -gt 0) {
                    Write-Host "`nDetected Error Keywords:"
                    $data.Keywords.Keys | ForEach-Object { Write-Host "- $_" }
                } else {
                    Write-Host "No error keywords detected."
                }

                $selected = Read-Host "`nEnter error code/keyword or press Enter to analyze all detected items"
                if ([string]::IsNullOrWhiteSpace($selected)) {
                    $targets = @()
                    $targets += $data.Codes.Keys | ForEach-Object { [PSCustomObject]@{ Type = 'Code'; Value = $_ } }
                    $targets += $data.Keywords.Keys | ForEach-Object { [PSCustomObject]@{ Type = 'Keyword'; Value = $_ } }
                } else {
                    $selTrim = $selected.Trim('"')
                    if ($data.Codes.ContainsKey($selTrim)) {
                        $targets = @([PSCustomObject]@{ Type = 'Code'; Value = $selTrim })
                    } elseif ($data.Keywords.ContainsKey($selTrim)) {
                        $targets = @([PSCustomObject]@{ Type = 'Keyword'; Value = $selTrim })
                    } else { Write-Warning "Specified item '$selTrim' not found."; continue }
                }

                $outputPath        = Join-Path $OutputDir "LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $missingItems      = @()
                $analysisResults   = [ordered]@{ Contexts = @{}; DatabaseMatches = @{}; AIAnalyses = @{} }

                foreach ($target in $targets) {
                    $dbEntry = Find-ErrorInDatabase -ErrorInput $target.Value
                    if ($dbEntry) {
                        $analysisResults.DatabaseMatches[$target.Value] = $dbEntry
                        $border = "=" * 70
                        Write-Host "`n$border" -ForegroundColor Green
                        Write-Host "[Offline Database Match for '$($dbEntry.ErrorCode)']"
                        Write-Host "Description: $($dbEntry.Message)`n"
                        Write-Host "Recommended Solutions:"

                        $solutionString = $dbEntry.Solution -replace '\s+(?=\d+\.)', "`n"
                        $solutions = $solutionString.Split("`n") | Where-Object { $_ -match '\S' }
                        $textOutputSolutions = @()
                        for ($i = 0; $i -lt $solutions.Count; $i++) {
                            $cleanedLine = $solutions[$i].Trim() -replace '^\d+\.\s*'
                            $numberedLine = "$($i + 1). $cleanedLine"
                            Write-Host $numberedLine
                            $textOutputSolutions += $numberedLine
                        }
                        Write-Host $border -ForegroundColor Green
                        
                        Add-Content $outputPath "`n$border`n[Offline Database Match for '$($dbEntry.ErrorCode)']`nDescription: $($dbEntry.Message)`n`nRecommended Solutions:"
                        $textOutputSolutions | Out-File -FilePath $outputPath -Append -Encoding utf8
                        Add-Content $outputPath "`n$border"

                    } else { Write-Host "`nWARNING: No offline data found for $($target.Value)" -ForegroundColor Yellow; $missingItems += $target.Value }
                }

                if ($missingItems.Count -gt 0) {
                    if ((Read-Host "`nDo you want to search Online for the missing entries? (Y/N)") -match '^[Yy]$') {
                        Write-Host "Opening browser tabs to search..."
                        $missingItems | Select-Object -Unique | ForEach-Object { Start-Process "https://www.google.com/search?q=Intune%20$([uri]::EscapeDataString($_))" }
                    }
                }
                Export-LogAnalysisToHtml -AnalysisResults $analysisResults -OutputPath $OutputDir
            }

            '2' { # AI Only Analysis
                $LogFilePath = Read-Host 'Enter path to log file for AI-only analysis'
                $data = Parse-LogFile -FilePath $LogFilePath
                if (-not $data -or ($data.Codes.Count -eq 0 -and $data.Keywords.Count -eq 0)) {
                    Write-Warning "No errors detected in the log file or file not found."; continue 
                }

                $providerChoice = Select-AIProvider
                if ($providerChoice -notmatch '^[1-3]$') { Write-Warning "Invalid selection. AI analysis canceled."; continue }
                $aiProvider = @('gemini', 'openai', 'azure')[[int]$providerChoice - 1]
                
                $outputPath = Join-Path $OutputDir "AI_Analysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $analysisResults = [ordered]@{ Contexts = @{}; DatabaseMatches = @{}; AIAnalyses = @{} }
                
                $allTargets = @() + $data.Codes.Keys + $data.Keywords.Keys

                foreach ($item in $allTargets) {
                    $excerpt = ""
                    if ($data.Codes.ContainsKey($item)) { $excerpt = ($data.Codes[$item] -join "`n") } 
                    else { $excerpt = ($data.Keywords[$item] -join "`n") }
                    $excerpt = $excerpt.Substring(0, [Math]::Min(2000, $excerpt.Length))

                    $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $item -Provider $aiProvider
                    if ($aiResult) {
                        $analysisResults.AIAnalyses[$item] = $aiResult
                        $border = "=" * 70
                        Write-Host "`n$border" -ForegroundColor Magenta
                        Write-Host "[AI Analysis for '$item']" -ForegroundColor Magenta
                        Write-Host ""
                        Write-Host $aiResult
                        Write-Host $border -ForegroundColor Magenta
                        Add-Content $outputPath "`n$border`n[AI Analysis for '$item']`n`n$aiResult`n$border"
                    }
                }
                Export-LogAnalysisToHtml -AnalysisResults $analysisResults -OutputPath $OutputDir
            }

            '3' { # Select Model
                Write-Host "Select AI Model. Current is $($global:model)"
                $m = Read-Host 'Enter model (e.g., gemini-2.0-flash, gpt-4, gpt-3.5-turbo)'
                if (-not [string]::IsNullOrWhiteSpace($m)) { $global:model = $m; Write-Host "Model set to: $m" -ForegroundColor Green } 
                else { Write-Warning "Model name cannot be empty." }
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
