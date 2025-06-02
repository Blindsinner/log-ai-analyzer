# Intune/Autopilot Log Analyzer PowerShell Tool
# Version: 5.1
# Author: MD FAYSAL MAHMIUD (faysaliteng@gmail.com)
# Enhanced with unified error analysis

$OutputDir = Split-Path $MyInvocation.MyCommand.Path
$apiKeyPath = Join-Path $OutputDir "apikey.txt"
$errorCloudPath = Join-Path $OutputDir "errorcloud.txt"
$global:model = 'gpt-4'

# Initialize error cloud with common keywords
if (-not (Test-Path $errorCloudPath)) {
    @("error", "failed", "failure", "timeout", "not found", "unable", "errorCode =", "can't", "cannot", 
      "denied", "access denied", "not installed", "install failed", "rollback", "fatal", "errorCode = 3399548929", "exception", "crash", "0x", "unsuccessful", "aborted", "rejected", "failure code", 
      "error code", "exit code", "status code", "failed with", "returned", "result code", 
      "hrresult", "hresult", "win32error", "exit status", "failed to install", "installation error", 
      "enrollment failed", "autopilot error", "intune error", "mdm failure", "compliance error", 
      "policy failure", "configuration failed", "sync error", "authentication failed", "authorization error", 
      "access error", "permission denied", "connection failed", "time out", "timed out", "expired", 
      "not responding", "not reachable", "not available", "not registered", "not compliant", "not detected", 
      "missing", "could not", "unexpected error", "critical error", "severe error", 
      "autopilot", "esp", "mdm enrollment", "aad join", "hybrid join", "white glove", "pre-provisioning", 
      "self-deploying", "user-driven", "device preparation", "device setup", "account setup", 
      "network connection", "enrollment failure", "registration failure", "profile assignment", 
      "tpm", "tpm attestation", "hardware hash", "odj blob", "offline domain join", "intune connector", 
      "ad connector", "group policy", "configuration profile", "compliance policy", "win32 app", 
      "lob app", "application install failed", "security policy", "something went wrong", "identifying", 
      "securing your hardware", "joining your organization's network", "registering your device for mobile management", 
      "webview2", "ime", "sidecar", "agent", "enrollment restrictions", "device limit", "user limit", 
      "domain join", "enrollment profile", "odjconnector", "mdm app", "device health attestation", 
      "bitlocker encryption", "esp waiting for apps", "esp app install timeout", "0x80070002", 
      "0x80070005", "0x800700a0", "0x800700b7", "0x800704c7", "0x800705b4", "0x80070642", 
      "0x80070643", "0x80070652", "0x80070774", "0x80072ee7", "0x80072f8f", "0x80073cf0", 
      "0x80090016", "0x800b0101", "0x800b0109", "0x80180001", "0x80180002", "0x80180003", 
      "0x80180005", "0x80180007", "0x80180009", "0x8018000a", "0x8018000b", "0x8018000c", 
      "0x8018000d", "0x8018000e", "0x8018000f", "0x80180010", "0x80180011", "0x80180012", 
      "0x80180013", "0x80180014", "0x80180015", "0x80180016", "0x80180017", "0x80180018", 
      "0x80180019", "0x8018001a", "0x8018001b", "0x8018001c", "0x8018001d", "0x8018001e", 
      "0x8018001f", "0x80180020", "0x80180021", "0x80180022", "0x80180023", "0x80180024", 
      "0x80180025", "0x80180026", "0x80180027", "0x80180028", "0x80180029", "0x8018002a", 
      "0x8018002b", "0x8018002c", "0x8018002d", "0x8018002e", "0x8018002f", "0x80180030", 
      "0x80180031", "0x80180032", "0x80180033", "0x80180034", "0x80180035", "0x80180036", 
      "0x80180037", "0x80180038", "0x80180039", "0x8018003a", "0x8018003b", "0x8018003c", 
      "0x8018003d", "0x8018003e", "0x8018003f", "0x80180040", "0x80180041", "0x80180042", 
      "0x80180043", "0x80180044", "0x80180045", "0x80180046", "0x80180047", "0x80180048", 
      "0x80180049", "0x8018004a", "0x801901ad", "0x801c0003", "0x801c0033", "0x801c03ea", 
      "0x818001e", "0x80004005", "0x801c03f2", "0x87d1041c", "0x87d1b001", "1201000", 
      "1201300", "1201400", "aadsts50011", "aadsts50020", "aadsts50034", "invalid_aad_token", 
      "invalid_user_token", "mdm_discovery_failed", "enrollment_mdm_failed", "devicecapreached", 
      "userdevicecapreached", "devicenotsupported", "notlicensedformdm", "usernotlicensedformdm", 
      "mdmserviceunreachable", "mdmtermsofusedeclined", "devicealreadyenrolled", "mdmauthoritynotset", 
      "mdminvalidurn", "mdminstancenamemismatch", "autopilotddsnoinfo", "autopilotddsnnetwork", 
      "autopilotddsnetworkerror", "autopilotztdnonetwork", "autopilotztdnoconfig", 
      "autopilotztdconfigretrievalfailed", "autopilotassignmentnottargeted", "autopilotprofiledownloadfailed", 
      "autopilotdjpconfignotfound", "autopilotdjpmissingcomputerobject", "autopilotdjpnoouspecified", 
      "autopilotdjpprecheckfailed", "autopilothybridaadjnotsupported", "autopilotdjpnoconnector", 
      "autopilotdjpconnectorerror", "autopilotdevicenotfound", "autopilotdjpcontrollernotfound", 
      "autopilotdjpfaildtocreatecomputerobject", "autopilotdjpfaildtomovecomputerobject", 
      "autopilotdjpunsecurejoin", "autopilotdjpdomainjoinfailed", "autopilotdjpofflinejoinnoblob", 
      "autopilotdjpofflinejoininvalidblob", "failed to get imdsmdeviceinterface", "msi error", 
      "failed to connect to the wns server", "failed to retrieve autopilot profile", 
      "autopilotmanager reported failure", "dmanoenrollmentmanager::discover failed", 
      "failed to acquire aad token for intune", "sidecarclient::executesync failed", 
      "failed to execute intune management extension", "exit code 1603", "exit code 1618", 
      "win32 app processing", "lob app install error", "failed to delete previous version during esp", 
      "profilestate: error", "oobe_settings_autopilot_profile_not_found", "getautopilotconfigurationfile failed", 
      "downloadautopilotfile", "unable to retrieve autopilot settings", "check network connectivity", 
      "failed to read autopilot profile", "convertautopilotconfiguration failed", 
      "failed to apply autopilot profile", "unable to connect to the mdm enrollment service", 
      "device health attestation failed", "tpm is not available or not ready", 
      "the device is not compliant with the bitlocker policy", "bitlocker encryption failed during esp", 
      "waiting for odj connector", "odj connector timeout", "offline domain join failed", 
      "failed to apply domain join blob", "failed to assign profile", "failed to sync with intune") -join "," | Out-File $errorCloudPath
}


if (Test-Path $apiKeyPath) {
    $global:apiKey = Get-Content $apiKeyPath -Raw
} else {
    $global:apiKey = ''
}

function Save-APIKey($key, $provider = 'openai') {
    $path = if ($provider -eq 'openai') { $apiKeyPath } else { Join-Path $OutputDir "$provider`_key.txt" }
    Set-Content -Path $path -Value $key
    if ($provider -eq 'openai') { $global:apiKey = $key }
}

function Get-ErrorCloud {
    if (Test-Path $errorCloudPath) {
        return (Get-Content $errorCloudPath -Raw).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
    return @()
}

function Prompt-AIUse {
    if (-not $global:apiKey) {
        Write-Warning 'No OpenAI API key found.'
        Write-Host 'You can get one at: https://platform.openai.com/account/api-keys'
        return $false
    }
    Write-Host "`nAI Analysis Options:" -ForegroundColor Cyan
    Write-Host "1. Run AI analysis with saved API key"
    Write-Host "2. Skip AI analysis"
    $aiChoice = Read-Host "Select an option (1 or 2)"
    return ($aiChoice -eq '1')
}

function Select-AIProvider {
    Write-Host "`n=== AI Provider Selection ===" -ForegroundColor Cyan
    Write-Host "1. OpenAI"
    Write-Host "2. Azure OpenAI"
    Write-Host "3. Anthropic (Claude)"
    Write-Host "4. Back to Main Menu"
    $opt = Read-Host "Select provider (1-4)"
    return $opt
}

function Manage-AIProviders {
    while ($true) {
        Write-Host "`n=== AI Provider Management ===" -ForegroundColor Cyan
        Write-Host "1. Set or Update OpenAI API Key"
        Write-Host "2. Set or Update Azure OpenAI API Key"
        Write-Host "3. Set or Update Anthropic (Claude) API Key"
        Write-Host "4. Back to Main Menu"
        $opt = Read-Host "Select an option (1-4)"
        switch ($opt) {
            '1' {
                $newKey = Read-Host 'Enter your OpenAI API key'
                Save-APIKey $newKey 'openai'
                Write-Host 'OpenAI key saved.' -ForegroundColor Green
            }
            '2' {
                $azureKey = Read-Host 'Enter your Azure OpenAI API key'
                Save-APIKey $azureKey 'azure'
                Write-Host 'Azure key saved.' -ForegroundColor Green
            }
            '3' {
                $claudeKey = Read-Host 'Enter your Anthropic Claude API key'
                Save-APIKey $claudeKey 'claude'
                Write-Host 'Claude key saved.' -ForegroundColor Green
            }
            '4' { return }
            default { Write-Warning "Invalid selection" }
        }
    }
}

function Parse-LogFile {
    param($FilePath)

    # will hold exact hex codes (0x…)
    $codes    = @{}
    # will hold all keyword & code-phrase matches
    $keywords = @{}
    $lines    = @()

    # load our generic error-cloud list
    $errorCloud = Get-ErrorCloud

    # strip any surrounding quotes
    $fp = $FilePath -replace '^"|"$',''

    if (-not (Test-Path $fp)) {
        Write-Warning "Log file not found at $fp"
        Log-Error "Log missing: $fp"
        return $null
    }

    try {
        $lines = Get-Content $fp -ErrorAction Stop

        foreach ($l in $lines) {
            #
            # 1) Extract explicit 0x… error codes
            #
            foreach ($m in [regex]::Matches($l, '0x[0-9A-Fa-f]{4,8}\b')) {
                $hex = $m.Value
                if (-not $codes.ContainsKey($hex)) { $codes[$hex] = @() }
                $codes[$hex] += $l
            }

            #
            # 2) Special-case: pull out the full “errorCode = <digits>” phrase
            #
            foreach ($m in [regex]::Matches($l, '(?i)\berrorcode\s*=\s*\d+\b')) {
                $fullPhrase = $m.Value
                if (-not $keywords.ContainsKey($fullPhrase)) { $keywords[$fullPhrase] = @() }
                $keywords[$fullPhrase] += $l
            }

            #
            # 3) New: catch decimal-and-hex codes in common contexts:
            #    Exit code 1618, Status code: 0x80070005, Result code = 42, HRESULT 0x87D1041C
            #
            foreach ($m in [regex]::Matches($l, '(?i)\b(?:exit|status|result|error|hresult)\s*code[:=]?\s*(0x[0-9A-Fa-f]+|\d+)\b')) {
                $phrase = $m.Value
                if (-not $keywords.ContainsKey($phrase)) { $keywords[$phrase] = @() }
                $keywords[$phrase] += $l
            }

            #
            # 4) Your existing error-cloud keyword matching
            #
            foreach ($w in $errorCloud) {
                # word-boundary match, case-insensitive
                if ($l -imatch "\b$([regex]::Escape($w))\b") {
                    if (-not $keywords.ContainsKey($w)) { $keywords[$w] = @() }
                    $keywords[$w] += $l
                }
            }
        }

        return @{
            Codes    = $codes
            Keywords = $keywords
            Lines    = $lines
        }

    } catch {
        Write-Warning "Parse-LogFile error: $_"
        Log-Error "Parse-LogFile error: $_"
        return $null
    }
}


function Get-ErrorDatabase {
    $errorDb = @{}
    $jsonPath = Join-Path $OutputDir 'error_db.json'
    if (Test-Path $jsonPath) {
        try {
            $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
            foreach ($entry in $json) {
                if ($entry.ErrorCode) {
                    $code = $entry.ErrorCode.ToLower()
                    $errorDb[$code] = @{
                        ErrorCode   = $entry.ErrorCode
                        Description = $entry.Message
                        Solutions   = @($entry.Solution -split '\d+\.\s*' | Where-Object { $_ })
                        Context     = $entry.Context
                        Message     = $entry.Message
                    }
                }
            }
        } catch {
            Write-Warning "Failed to load error_db.json: $_"
        }
    } else {
        Write-Warning "error_db.json not found at $jsonPath"
    }
    return $errorDb
}

function Search-OnlineError {
    param($Code)
    Start-Process "https://learn.microsoft.com/en-us/search/?terms=$Code"
}

function Invoke-AIAnalysis {
    param($Excerpt, $Code, $Provider = 'openai')
    $apiKeyVarName = "apiKey_$Provider"
    
    # Check if we have the key in memory
    if (-not (Get-Variable -Name $apiKeyVarName -Scope Global -ErrorAction SilentlyContinue)) {
        $keyPath = Join-Path $OutputDir "${Provider}_key.txt"
        if (Test-Path $keyPath) {
            # Create global variable if not exists
            New-Variable -Name $apiKeyVarName -Scope Global -Value (Get-Content $keyPath -Raw) -ErrorAction SilentlyContinue
        } else {
            Write-Warning "API key for $Provider not found. Set it via Provider Management first."
            return $null
        }
    }

    $apiKey = (Get-Variable -Name $apiKeyVarName -Scope Global -ErrorAction SilentlyContinue).Value
    if (-not $apiKey) {
        Write-Warning "API key for $Provider is not defined."
        return $null
    }

    # Endpoint configuration
    $endpoint = switch ($Provider) {
        'openai' { 'https://api.openai.com/v1/chat/completions' }
        'azure' { 'https://YOUR_AZURE_ENDPOINT.openai.azure.com/openai/deployments/$model/chat/completions?api-version=2023-12-01-preview' }
        'claude' { 'https://api.anthropic.com/v1/messages' }
    }

    # Body configuration
    $body = $null
    if ($Provider -in @('openai', 'azure')) {
        $body = @{
            model    = $global:model
            messages = @(
                @{ role = 'system'; content = 'You are an expert Intune diagnostics assistant.' }
                @{ role = 'user'; content = "Analyze this log excerpt for $Code and suggest root cause and fix:`n$Excerpt" }
            )
        }
    }
    elseif ($Provider -eq 'claude') {
        $body = @{
            model     = "claude-3-opus-20240229"
            max_tokens = 1000
            messages   = @(
                @{ role = "user"; content = "Analyze this log excerpt for $Code and suggest root cause and fix:`n$Excerpt" }
            )
        }
    }

    $jsonBody = $body | ConvertTo-Json -Depth 5

    try {
        $headers = @{ 
            Authorization = "Bearer $apiKey"
            ContentType = "application/json"
        }
        
        if ($Provider -eq 'claude') {
            $headers['anthropic-version'] = '2023-06-01'
            $headers['x-api-key'] = $apiKey
        }
        elseif ($Provider -eq 'azure') {
            $headers['api-key'] = $apiKey
        }

        $resp = Invoke-RestMethod -Uri $endpoint -Method Post -Body $jsonBody -ContentType 'application/json' -Headers $headers

        if ($Provider -in @('openai', 'azure')) {
            return $resp.choices[0].message.content
        }
        elseif ($Provider -eq 'claude') {
            return $resp.content[0].text
        }
    } catch {
        Write-Warning "AI call to $Provider failed: $_"
        return $null
    }
}

function Find-ErrorInDatabase {
    param($ErrorInput, $ErrorDb)
    # First try exact match
    if ($ErrorDb.ContainsKey($ErrorInput.ToLower())) {
        return $ErrorDb[$ErrorInput.ToLower()]
    }
    
    # Try partial match (without 0x prefix)
    $cleanInput = $ErrorInput -replace '^0x', ''
    foreach ($key in $ErrorDb.Keys) {
        $cleanKey = $key -replace '^0x', ''
        if ($cleanKey -eq $cleanInput) {
            return $ErrorDb[$key]
        }
    }
    
    return $null
}

function Main-Menu {
    while ($true) {
        Write-Host "`n=== Intune Log Analyzer Menu ===" -ForegroundColor Cyan
        Write-Host "1. Analyze Log File"
        Write-Host "2. Set or Update OpenAI API Key"
        Write-Host "3. Select AI Model (Current: $global:model)"
        Write-Host "4. Analyze with AI Only"
        Write-Host "5. Manage AI Providers"
        Write-Host "6. Exit"
        $choice = Read-Host "Choose an option (1-6)"

        switch ($choice) {
            '1' {
                $LogFilePath = Read-Host 'Enter path to log file (e.g., IntuneManagementExtension.log)'
                $data = Parse-LogFile -FilePath $LogFilePath
                
                # Display detection results
                Write-Host "`n=== Detection Results ===" -ForegroundColor Yellow
                if ($data.Codes.Keys.Count) {
                    Write-Host "Detected Error Codes:" -ForegroundColor Cyan
                    $data.Codes.Keys | ForEach-Object { Write-Host "- $_" }
                }
                
                if ($data.Keywords.Keys.Count) {
                    Write-Host "`nDetected Error Keywords:" -ForegroundColor Cyan
                    $data.Keywords.Keys | ForEach-Object { Write-Host "- $_" }
                }
                
                if (-not $data.Codes.Keys.Count -and -not $data.Keywords.Keys.Count) {
                    Write-Warning "No errors detected in log file"
                    continue
                }
                
                $ErrorInput = Read-Host "`nEnter error code (e.g., 0x80070642) or press Enter to analyze all detected items"
                $outputPath = Join-Path $OutputDir "LogAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $errorDb = Get-ErrorDatabase
                $useAI = $false
                $aiProvider = $null

                # Determine analysis targets
                $targets = if ($ErrorInput) {
                    # User entered specific error code
                    @{ Type = 'Code'; Value = $ErrorInput }
                } else {
                    # Analyze all detected items
                    @($data.Codes.Keys | ForEach-Object { @{ Type = 'Code'; Value = $_ } }) +
                    @($data.Keywords.Keys | ForEach-Object { @{ Type = 'Keyword'; Value = $_ } })
                }

                # Ask about AI upfront
                if ($targets.Count -gt 0) {
                    $useAI = Prompt-AIUse
                    if ($useAI) {
                        $providerChoice = Select-AIProvider
                        if ($providerChoice -in '1','2','3') {
                            $providers = @('openai','azure','claude')
                            $aiProvider = $providers[[int]$providerChoice - 1]
                        } else {
                            $useAI = $false
                        }
                    }
                }

                # Process targets
                foreach ($target in $targets) {
                    Write-Host "`n=== Analysis for $($target.Value) ($($target.Type)) ===" -ForegroundColor Yellow
                    Add-Content $outputPath "=== Analysis for $($target.Value) ($($target.Type)) ==="
                    
                    $excerpt = $null
                    
                    # Get context for the item
                    if ($target.Type -eq 'Code') {
                        if ($data.Codes.ContainsKey($target.Value)) {
                            $excerpt = ($data.Codes[$target.Value] -join "`n").Substring(0, [math]::Min(1000, ($data.Codes[$target.Value] -join "`n").Length))
                        } else {
                            # Search entire log for this code
                            $matchingLines = $data.Lines | Where-Object { $_ -match [regex]::Escape($target.Value) }
                            if ($matchingLines) {
                                $excerpt = ($matchingLines -join "`n").Substring(0, [math]::Min(1000, ($matchingLines -join "`n").Length))
                            } else {
                                $excerpt = "No occurrences of this code found in the log."
                            }
                        }
                    }
                    else {
                        if ($data.Keywords.ContainsKey($target.Value)) {
                            $excerpt = ($data.Keywords[$target.Value] -join "`n").Substring(0, [math]::Min(1000, ($data.Keywords[$target.Value] -join "`n").Length))
                        } else {
                            $excerpt = "No occurrences of this keyword found in the log."
                        }
                    }
                    
                    # Try to find in error database
                    $dbEntry = $null
                    if ($target.Type -eq 'Code') {
                        $dbEntry = Find-ErrorInDatabase -ErrorInput $target.Value -ErrorDb $errorDb
                    }
                    
                    if ($dbEntry) {
                        Write-Host "`n[Offline Database Match]" -ForegroundColor Green
                        Write-Host "Error Code: $($dbEntry.ErrorCode)"
                        Write-Host "Description: $($dbEntry.Description)"
                        Write-Host "`nRecommended Solutions:"
                        $dbEntry.Solutions | ForEach-Object { Write-Host " - $_" }
                        
                        Add-Content $outputPath "`n[Offline Database Match]"
                        Add-Content $outputPath "Error Code: $($dbEntry.ErrorCode)"
                        Add-Content $outputPath "Description: $($dbEntry.Description)"
                        Add-Content $outputPath "`nRecommended Solutions:"
                        Add-Content $outputPath ($dbEntry.Solutions -join "`n - ")
                    } else {
                        if ($target.Type -eq 'Code') {
                            Write-Warning "No offline data found for $($target.Value)"
                            $search = Read-Host "`nSearch online for $($target.Value)? (Y/N)"
                            if ($search -match '^[Yy]$') { 
                                Search-OnlineError -Code $target.Value
                            }
                        }
                        
                        # Show context
                        Write-Host "`nContext Excerpt:" -ForegroundColor Cyan
                        Write-Host $excerpt
                        Add-Content $outputPath "`nContext Excerpt:`n$excerpt"
                    }
                    
                    # AI Analysis
                    if ($useAI) {
                        $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $target.Value -Provider $aiProvider
                        if ($aiResult) {
                            Write-Host "`n[AI Analysis ($aiProvider)]:`n$aiResult" -ForegroundColor Magenta
                            Add-Content $outputPath "`n[AI Analysis for $($target.Value)]:`n$aiResult"
                        }
                    }
                }
                
                Write-Host "`nResults exported to $outputPath" -ForegroundColor Green
            }
            '2' {
                $newKey = Read-Host 'Enter your OpenAI API key (Get one at https://platform.openai.com/account/api-keys)'
                Save-APIKey $newKey
                Write-Host "API key saved." -ForegroundColor Green
            }
            '3' {
                $m = Read-Host 'Enter model (gpt-4 or gpt-3.5-turbo)'
                if ($m -in @('gpt-4','gpt-3.5-turbo')) {
                    $global:model = $m
                    Write-Host "Model set to: $m" -ForegroundColor Green
                } else {
                    Write-Warning "Invalid model."
                }
            }
            '4' {
                $LogFilePath = Read-Host 'Enter path to log file (e.g., IntuneManagementExtension.log)'
                $data = Parse-LogFile -FilePath $LogFilePath
                
                if (-not $data.Codes.Keys.Count -and -not $data.Keywords.Keys.Count) {
                    Write-Warning "No errors detected in log file"
                    continue
                }
                
                $providerChoice = Select-AIProvider
                if ($providerChoice -notmatch '^[1-3]$') {
                    Write-Warning "AI analysis canceled"
                    continue
                }
                
                $providers = @('openai','azure','claude')
                $aiProvider = $providers[[int]$providerChoice - 1]
                $outputPath = Join-Path $OutputDir "AIAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                
                foreach ($code in $data.Codes.Keys) {
                    $excerpt = ($data.Codes[$code] -join "`n").Substring(0, [math]::Min(1000, ($data.Codes[$code] -join "`n").Length))
                    $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $code -Provider $aiProvider
                    if ($aiResult) {
                        Write-Host "`n[AI Analysis for $code]:`n$aiResult" -ForegroundColor Magenta
                        Add-Content $outputPath "=== $code ===`n$aiResult`n"
                    }
                }
                
                foreach ($keyword in $data.Keywords.Keys) {
                    $excerpt = ($data.Keywords[$keyword] -join "`n").Substring(0, [math]::Min(1000, ($data.Keywords[$keyword] -join "`n").Length))
                    $aiResult = Invoke-AIAnalysis -Excerpt $excerpt -Code $keyword -Provider $aiProvider
                    if ($aiResult) {
                        Write-Host "`n[AI Analysis for '$keyword']:`n$aiResult" -ForegroundColor Magenta
                        Add-Content $outputPath "=== '$keyword' ===`n$aiResult`n"
                    }
                }
                
                Write-Host "`nAI analysis exported to $outputPath" -ForegroundColor Green
            }
            '5' { Manage-AIProviders }
            '6' { exit }
            default { Write-Warning "Invalid input. Try again." }
        }
    }
}

Main-Menu
