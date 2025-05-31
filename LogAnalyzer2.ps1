# Intune/Autopilot Log Analyzer PowerShell Tool
# Version: 5.2
# Author: MD FAYSAL MAHMIUD (faysaliteng@gmail.com)
# Enhanced with unified error analysis, multi-file support, HTML export, and online search for missing entries

# -----------------------------------
# Set output directory to script location
# -----------------------------------
$OutputDir      = Split-Path $MyInvocation.MyCommand.Path
$apiKeyPath     = Join-Path $OutputDir "apikey.txt"
$errorCloudPath = Join-Path $OutputDir "errorcloud.txt"
$errorDbPath    = Join-Path $OutputDir "error_db.json"
$global:model   = 'gpt-4'

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
    $lines     = Get-Content -Path $FilePath
    $codes     = @{}    # hashtable: hex code -> list of matching lines
    $keywords  = @{}    # hashtable: keyword phrase -> list of matching lines

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
# Function Save-APIKey: saves API key text to a file
# -----------------------------------
function Save-APIKey {
    param(
        [string]$key,
        [string]$provider = 'openai'
    )
    $path = if ($provider -eq 'openai') { $apiKeyPath } else { Join-Path $OutputDir "${provider}_key.txt" }
    Set-Content -Path $path -Value $key
    if ($provider -eq 'openai') { $global:apiKey = $key }
    Write-Host "API SAVED!" -ForegroundColor Green
}

# -----------------------------------
# Function Invoke-AIAnalysis: calls OpenAI/Azure/Claude to get AI analysis
# -----------------------------------
function Invoke-AIAnalysis {
    param(
        [string]$Excerpt,
        [string]$Code,
        [string]$Provider = 'openai'
    )
    Write-Host "Connecting to OpenAi endpoint....." -ForegroundColor Cyan
    Write-Host "Analyzing with AI Intune Enrollment Error $Code" -ForegroundColor Cyan
    $apiKeyVarName = "apiKey_$Provider"
    if (-not (Get-Variable -Name $apiKeyVarName -Scope Global -ErrorAction SilentlyContinue)) {
        $keyPath = Join-Path $OutputDir "${Provider}_key.txt"
        if (Test-Path $keyPath) {
            $val = Get-Content $keyPath -Raw
            New-Variable -Name $apiKeyVarName -Scope Global -Value $val
        } else {
            $newKey = Read-Host "WARNING: API key for $Provider not found. Enter it now:"
            Save-APIKey $newKey $Provider
            New-Variable -Name $apiKeyVarName -Scope Global -Value $newKey
        }
    }
    $apiKey = (Get-Variable -Name $apiKeyVarName -Scope Global).Value
    if (-not $apiKey) {
        $newKey = Read-Host "WARNING: API key for $Provider is not defined. Enter it now:"
        Save-APIKey $newKey $Provider
        $apiKey = $newKey
    }
    $body = @{
        model    = $global:model
        messages = @(
            @{ role = 'system'; content = "You are an expert IT helpdesk technician." },
            @{ role = 'user';   content = "Error Code: $Code`nExcerpt:`n$Excerpt" }
        )
    }
    switch ($Provider) {
        'openai' { $uri = 'https://api.openai.com/v1/chat/completions' }
        'azure'  { $uri = "https://<your-azure-endpoint>.openai.azure.com/openai/deployments/$($global:model)/chat/completions?api-version=2023-05-15" }
        'claude' { 
            $uri  = 'https://api.anthropic.com/v1/complete'
            $body = @{
                model  = 'claude-v1'
                prompt = "<s>`n$($body.messages[1].content)`n"
            }
        }
    }
    $jsonBody = $body | ConvertTo-Json -Depth 5
    try {
        $headers = @{ Authorization = "Bearer $apiKey"; ContentType = "application/json" }
        if ($Provider -eq 'azure')   { $headers['api-key']        = $apiKey }
        if ($Provider -eq 'claude')  { 
            $headers['x-api-key']         = $apiKey
            $headers['anthropic-version'] = '2023-06-01'
        }
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        if ($Provider -in 'openai','azure') { return $response.choices[0].message.content.Trim() }
        elseif ($Provider -eq 'claude')      { return $response.completion.Trim() }
    } catch {
        Write-Warning "Failed to get AI analysis: $_"
        return $null
    }
}

# -----------------------------------
# Function Export-LogAnalysisToHtml: builds a styled HTML summary
# -----------------------------------
function Export-LogAnalysisToHtml {
    param([hashtable]$AnalysisResults, [string]$OutputPath)
    $htmlPath = Join-Path $OutputPath ("LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').html")
    $body = @"
<html>
  <head>
    <meta charset='UTF-8'>
    <title>Intune Log Analysis Report</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 20px; }
      h1 { color: #007bff; }
      .table { margin-top: 20px; border-collapse: collapse; width: 100%; }
      .table th, .table td { border: 1px solid #ddd; padding: 8px; }
      .table th { background-color: #343a40; color: white; }
      .error-code { font-weight: bold; color: #dc3545; }
      .context { font-style: italic; color: #6c757d; }
      .ai-analysis { background-color: #f8f9fa; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
      pre { white-space: pre-wrap; }
    </style>
  </head>
  <body>
    <div class='container'>
      <h1>Intune Log Analysis Report</h1>
      <p><strong>Generated on:</strong> $(Get-Date)</p>
      <h2>Detected Errors</h2>
      <table class='table'>
        <thead>
          <tr><th>Error Code/Keyword</th><th>Context Excerpt</th><th>Offline DB Match</th></tr>
        </thead>
        <tbody>
"@
    foreach ($key in $AnalysisResults.Contexts.Keys) {
        $excerpt  = $AnalysisResults.Contexts[$key] -replace '<','&lt;' -replace '>','&gt;'
        $dbMatch  = $null
        if ($AnalysisResults.DatabaseMatches.ContainsKey($key)) {
            $dbMatch = $AnalysisResults.DatabaseMatches[$key].Message -replace '<','&lt;' -replace '>','&gt;'
        }
        $displayMatch = if ($dbMatch) { $dbMatch } else { 'N/A' }
        $body += "          <tr><td class='error-code'>$key</td><td class='context'>$excerpt</td><td>$displayMatch</td></tr>`n"
    }
    $body += @"
        </tbody>
      </table>
"@
    if ($AnalysisResults.AIAnalyses.Keys.Count -gt 0) {
        $body += "      <h2>AI Analysis</h2>`n"
        foreach ($key in $AnalysisResults.AIAnalyses.Keys) {
            $aiContent = $AnalysisResults.AIAnalyses[$key] -replace '<','&lt;' -replace '>','&gt;'
            $body += "      <h3 class='error-code'>$key</h3>`n      <div class='ai-analysis'><pre>$aiContent</pre></div>`n"
        }
    }
    $body += @"
    </div>
  </body>
</html>
"@
    $body | Out-File -FilePath $htmlPath -Encoding utf8
    Write-Host "HTML report exported to $htmlPath" -ForegroundColor Green
}

# -----------------------------------
# Function Confirm-AIAnalysis: asks user whether to run AI analysis
# -----------------------------------
function Confirm-AIAnalysis {
    if (-not (Test-Path $apiKeyPath)) {
        Write-Warning 'WARNING: No OpenAI API key found.'
        Write-Host 'You can get one at: https://platform.openai.com/account/api-keys'
        return $false
    }
    Write-Host "`nAI Analysis Options:" -ForegroundColor Cyan
    Write-Host "1. Run AI analysis with saved API key"
    Write-Host "2. Skip AI analysis"
    $aiChoice = Read-Host "Select an option (1 or 2)"
    return ($aiChoice -eq '1')
}

# -----------------------------------
# Function Select-AIProvider: user picks which AI provider (OpenAI/Azure/Claude)
# -----------------------------------
function Select-AIProvider {
    Write-Host "`n=== AI Provider Selection ===" -ForegroundColor Cyan
    Write-Host "1. OpenAI"
    Write-Host "2. Azure OpenAI"
    Write-Host "3. Anthropic (Claude)"
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
        Write-Host "1. Set or Update OpenAI API Key"
        Write-Host "2. Set or Update Azure OpenAI API Key"
        Write-Host "3. Set or Update Anthropic (Claude) API Key"
        Write-Host "4. Back to Main Menu"
        $opt = Read-Host "Select an option (1-4)"
        switch ($opt) {
            '1' { $newKey = Read-Host 'Enter your OpenAI API key'; Save-APIKey $newKey 'openai' }
            '2' { $azureKey = Read-Host 'Enter your Azure OpenAI API key'; Save-APIKey $azureKey 'azure' }
            '3' { $claudeKey = Read-Host 'Enter your Anthropic Claude API key'; Save-APIKey $claudeKey 'claude' }
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
        Write-Host "`n=== Intune Log Analyzer Menu ===" -ForegroundColor Cyan
        Write-Host "1. Analyze Log File"
        Write-Host "2. Set or Update OpenAI API Key"
        Write-Host "3. Select AI Model (Current: $($global:model))"
        Write-Host "4. Analyze with AI Only"
        Write-Host "5. Manage AI Providers"
        Write-Host "6. Exit"
        $choice = Read-Host "Choose an option (1-6)"

        switch ($choice) {
            '1' {
                # Prompt for log path
                $LogFilePath = Read-Host 'Enter path to log file (e.g., IntuneManagementExtension.log)'
                $data = Parse-LogFile -FilePath $LogFilePath
                if (-not $data) { continue }

                # Show detection summary
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

                # Ask user to select a code or analyze all
                $selected = Read-Host "`nEnter error code (e.g., 0x80070642) or press Enter to analyze all detected items"
                if ([string]::IsNullOrWhiteSpace($selected)) {
                    # Analyze everything
                    $targets = @()
                    $targets += $data.Codes.Keys | ForEach-Object { [PSCustomObject]@{ Type = 'Code'; Value = $_ } }
                    $targets += $data.Keywords.Keys | ForEach-Object { [PSCustomObject]@{ Type = 'Keyword'; Value = $_ } }
                } else {
                    $selTrim = $selected.Trim('"')
                    if ($data.Codes.ContainsKey($selTrim)) {
                        $targets = @([PSCustomObject]@{ Type = 'Code'; Value = $selTrim })
                    } elseif ($data.Keywords.ContainsKey($selTrim)) {
                        $targets = @([PSCustomObject]@{ Type = 'Keyword'; Value = $selTrim })
                    } else {
                        Write-Warning "Specified item '$selTrim' not found in detected errors."
                        continue
                    }
                }

                # Prepare output structures
                $outputPath      = Join-Path $OutputDir "LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $missingItems    = @()
                $analysisResults = [ordered]@{ Contexts = @{}; DatabaseMatches = @{}; AIAnalyses = @{} }

                foreach ($target in $targets) {
                    $value = $target.Value
                    $type  = $target.Type
                    Write-Host "`n=== Analysis for $value ($type) ===" -ForegroundColor Yellow
                    Add-Content $outputPath "=== Analysis for $value ($type) ==="

                    if ($type -eq 'Code' -and $data.Codes.ContainsKey($value)) {
                        $excerpt = ($data.Codes[$value] -join "`n").Substring(
                            0,
                            [Math]::Min(1000, ($data.Codes[$value] -join "`n").Length)
                        )
                    } elseif ($type -eq 'Keyword' -and $data.Keywords.ContainsKey($value)) {
                        $excerpt = ($data.Keywords[$value] -join "`n").Substring(
                            0,
                            [Math]::Min(1000, ($data.Keywords[$value] -join "`n").Length)
                        )
                    } else {
                        $excerpt = "No occurrences found in the log."
                    }
                    $analysisResults.Contexts[$value] = $excerpt

                    if ($type -eq 'Code') {
                        $dbEntry = Find-ErrorInDatabase -ErrorInput $value
                        if ($dbEntry) {
                            Write-Host "`n[Offline Database Match]" -ForegroundColor Green
                            Write-Host "Error Code: $($dbEntry.ErrorCode)"
                            Write-Host "Description: $($dbEntry.Message)"
                            Write-Host "`nRecommended Solutions:"
                            $solutions = $dbEntry.Solution.Split("`n")
                            $numberedSolutionsList = @()
                            for ($i = 0; $i -lt $solutions.Count; $i++) {
                                $prefixed = "#$($i + 1). $($solutions[$i])"
                                # Output each solution on its own line to console:
                                Write-Host $prefixed
                                # Collect for writing into the file later
                                $numberedSolutionsList += $prefixed
                            }
                            # Append to the output file, each solution on its own line:
                            Add-Content $outputPath "`n[Offline Database Match]`nDescription: $($dbEntry.Message)`nRecommended Solutions:"
                            foreach ($line in $numberedSolutionsList) {
                                Add-Content $outputPath $line
                            }
                            $analysisResults.DatabaseMatches[$value] = $dbEntry
                        } else {
                            Write-Host "WARNING: No offline data found for $value" -ForegroundColor Yellow
                            $missingItems += $value
                        }
                    } else {
                        Write-Host "WARNING: No offline data found for $value" -ForegroundColor Yellow
                        $missingItems += $value
                    }
                }

                # If any missing offline entries, offer online search
                if ($missingItems.Count -gt 0) {
                    $choice2 = Read-Host "`nDo you want to search Online for not found database? (Y/N)"
                    if ($choice2 -match '^[Yy]$') {
                        Write-Host "You selected: Y. Opening browser tabs to search..."
                        foreach ($item in $missingItems | Select-Object -Unique) {
                            Start-Process "https://www.google.com/search?q=$([uri]::EscapeDataString($item))"
                        }
                    }
                }

                Write-Host "`nWARNING: No OpenAI API key found." -ForegroundColor Yellow
                Write-Host "You can get one at: https://platform.openai.com/account/api-keys" -ForegroundColor Yellow

                Write-Host "`nResults exported to $outputPath" -ForegroundColor Green
                Export-LogAnalysisToHtml -AnalysisResults $analysisResults -OutputPath $OutputDir
            }

            '2' {
                $newKey = Read-Host 'Enter your OpenAI API key (Get one at https://platform.openai.com/account/api-keys)'
                Save-APIKey $newKey 'openai'
            }

            '3' {
                $m = Read-Host 'Enter model (gpt-4 or gpt-3.5-turbo)'
                if ($m -in @('gpt-4','gpt-3.5-turbo')) {
                    $global:model = $m
                    Write-Host "Model set to: $m" -ForegroundColor Green
                } else {
                    Write-Warning "Invalid model. Must be gpt-4 or gpt-3.5-turbo"
                }
            }

            '4' {
                $LogFilePath = Read-Host 'Enter path to log file for AI-only analysis'
                $data = Parse-LogFile -FilePath $LogFilePath
                if (-not $data) { continue }

                $providerChoice = Select-AIProvider
                if ($providerChoice -notmatch '^[1-3]$') {
                    Write-Warning "AI analysis canceled"
                    continue
                }
                $providers  = @('openai','azure','claude')
                $aiProvider = $providers[[int]$providerChoice - 1]
                $outputPath = Join-Path $OutputDir "AIAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $analysisResults = [ordered]@{ Contexts = @{}; DatabaseMatches = @{}; AIAnalyses = @{} }

                foreach ($code in $data.Codes.Keys) {
                    $excerpt  = ($data.Codes[$code] -join "`n").Substring(
                        0,
                        [Math]::Min(1000, ($data.Codes[$code] -join "`n").Length)
                    )
                    $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $code -Provider $aiProvider
                    if ($aiResult) {
                        Write-Host "`nResult:" -ForegroundColor Magenta
                        Write-Host $aiResult
                        Add-Content $outputPath "=== $code ===`n$aiResult`n"
                        $analysisResults.AIAnalyses[$code] = $aiResult
                    }
                }

                foreach ($keyword in $data.Keywords.Keys) {
                    $excerpt  = ($data.Keywords[$keyword] -join "`n").Substring(
                        0,
                        [Math]::Min(1000, ($data.Keywords[$keyword] -join "`n").Length)
                    )
                    $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $keyword -Provider $aiProvider
                    if ($aiResult) {
                        Write-Host "`nResult for '$keyword':" -ForegroundColor Magenta
                        Write-Host $aiResult
                        Add-Content $outputPath "=== '$keyword' ===`n$aiResult`n"
                        $analysisResults.AIAnalyses[$keyword] = $aiResult
                    }
                }

                Write-Host "`nFull Results exported to $outputPath" -ForegroundColor Green
                $htmlOutput = Join-Path $OutputDir "LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss')_AI.html"
                Export-LogAnalysisToHtml -AnalysisResults $analysisResults -OutputPath $OutputDir
                Write-Host "HTML report of full Analysis and FIX exported to $htmlOutput" -ForegroundColor Green
            }

            '5' {
                Manage-AIProviders
            }

            '6' {
                exit
            }

            default {
                Write-Warning "Invalid input. Try again."
            }
        }
    }
}

# -----------------------------------
# Start the script
# -----------------------------------
Main-Menu
