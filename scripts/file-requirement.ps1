# ==============================================================================
# SULTRABYTE AI STUDIO - SMART VALIDATOR (ZERO-FREEZE LIVE STOPWATCH ENGINE)
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

# Path Resolution Portabel (Drive-Agnostic)
$ScriptDir   = $PSScriptRoot
$RootPath    = (Get-Item (Join-Path $ScriptDir '..')).FullName
$BinPath     = Join-Path $RootPath 'bin'
$ModelsPath  = Join-Path $RootPath 'models'
$VaultsPath  = Join-Path $RootPath 'vaults'

# ------------------------------------------------------------------------------
# 0. ENGINE LIVE STOPWATCH & SPINNER (POWERSEHLL PURE ASCII)
# ------------------------------------------------------------------------------
function Invoke-LiveTimer {
    param(
        [string]$Message,
        [scriptblock]$Action,
        [object[]]$Arguments = @()
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $spinner = @('|', '/', '-', '\')
    $idx = 0

    $job = Start-Job -ScriptBlock $Action -ArgumentList $Arguments
    while ($job.State -eq 'Running') {
        $elapsed = $sw.Elapsed.ToString('mm\:ss\.f')
        $char = $spinner[$idx % 4]
        Write-Host -NoNewline ("`r  [$char] [$elapsed] $Message") -ForegroundColor Cyan
        Start-Sleep -Milliseconds 80
        $idx++
    }
    $jobOutput = Receive-Job -Job $job
    $hasFailed = ($job.State -eq 'Failed')
    Remove-Job -Job $job -Force
    $sw.Stop()
    $finalElapsed = $sw.Elapsed.ToString('mm\:ss\.f')

    if ($hasFailed) {
        Write-Host "`r  [FAIL] [$finalElapsed] $Message" -ForegroundColor Red
    } else {
        Write-Host "`r  [OK]   [$finalElapsed] $Message" -ForegroundColor Green
    }
    return $jobOutput
}

function Invoke-ProcessWithTimer {
    param(
        [string]$Message,
        [string]$FilePath,
        [string]$ArgumentList
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $spinner = @('|', '/', '-', '\')
    $idx = 0
    $p = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden
    while (-not $p.HasExited) {
        $elapsed = $sw.Elapsed.ToString('mm\:ss\.f')
        $char = $spinner[$idx % 4]
        Write-Host -NoNewline ("`r  [$char] [$elapsed] $Message") -ForegroundColor Cyan
        Start-Sleep -Milliseconds 80
        $idx++
    }
    $sw.Stop()
    $finalElapsed = $sw.Elapsed.ToString('mm\:ss\.f')
    if ($p.ExitCode -eq 0) {
        Write-Host "`r  [OK]   [$finalElapsed] $Message" -ForegroundColor Green
    } else {
        Write-Host "`r  [FAIL] [$finalElapsed] $Message (ExitCode: $($p.ExitCode))" -ForegroundColor Red
        throw "Process failed with exit code $($p.ExitCode)"
    }
    return $p.ExitCode
}

Write-Host '=================================================================================' -ForegroundColor Cyan
Write-Host '                     S U L T R A B Y T E   A I   S T U D I O                     ' -ForegroundColor White -BackgroundColor DarkBlue
Write-Host '                developer.haritsnb@gmail.com | Harits Nala Barrun                ' -ForegroundColor White
Write-Host '---------------------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host '                          RUNTIME & HARDWARE VALIDATOR                           ' -ForegroundColor White -BackgroundColor Green
Write-Host '=================================================================================' -ForegroundColor Cyan
Write-Host "[*] Target Root Directory: $RootPath" -ForegroundColor Gray
Write-Host ''

# ------------------------------------------------------------------------------
# 1. INTERNET GUARD TEST (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
$HasInternet = $false
Invoke-LiveTimer -Message "Menguji konektivitas Internet Guard..." -Action {
    $TcpClient = New-Object System.Net.Sockets.TcpClient
    $ConnectTask = $TcpClient.ConnectAsync('1.1.1.1', 53)
    if ($ConnectTask.Wait(3000) -and $TcpClient.Connected) {
        $TcpClient.Close()
        return $true
    }
    $TcpClient.Close()
    return $false
} | ForEach-Object { $HasInternet = $_ }

# ------------------------------------------------------------------------------
# 2. VALIDASI & PEMASANGAN PYTHON 3.12+ (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
$PythonInstalled = $false
Invoke-LiveTimer -Message "Memeriksa integritas binary Python..." -Action {
    try {
        $PyVerOutput = & python --version 2>&1
        if ($PyVerOutput -match 'Python 3\.(1[0-9]|[2-9][0-9])') { return $true }
    } catch {}
    return $false
} | ForEach-Object { $PythonInstalled = $_ }

if (-not $PythonInstalled) {
    if (-not $HasInternet) {
        Write-Host '  [!] Python belum terpasang dan sistem offline.' -ForegroundColor Red
        Read-Host 'Tekan Enter untuk keluar...'
        exit 1
    }

    if (-not (Test-Path $BinPath)) { New-Item -ItemType Directory -Path $BinPath -Force | Out-Null }
    $PyInstaller = Join-Path $BinPath 'python_installer.exe'
    
    Invoke-LiveTimer -Message "Mengunduh Python 3.12 Setup..." -Action {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe' -OutFile $args[0] -UseBasicParsing
    } -Arguments $PyInstaller | Out-Null
    
    Invoke-ProcessWithTimer -Message "Memasang Python 3.12 secara silent..." -FilePath $PyInstaller -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 Include_test=0'
    
    Remove-Item -Path $PyInstaller -Force -ErrorAction SilentlyContinue
    
    $MachinePath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
    $UserPath    = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
    $env:Path    = "$MachinePath;$UserPath"
}

# ------------------------------------------------------------------------------
# 3. VALIDASI PUSTAKA PYTHON PIP (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
$RequiredPip = @('chromadb', 'ollama', 'requests', 'duckduckgo_search', 'rich', 'colorama')
if ($HasInternet) {
    Invoke-LiveTimer -Message "Sinkronisasi pip dan pustaka dependensi Python..." -Action {
        param($packages)
        & python -m pip install --upgrade pip --quiet
        foreach ($pkg in $packages) {
            & python -m pip install $pkg --quiet
        }
    } -Arguments (,$RequiredPip) | Out-Null
} else {
    Write-Host '  [*] Mode offline aktif, melewati sinkronisasi pip.' -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 4. VALIDASI & PEMASANGAN OLLAMA DAEMON (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
$OllamaInstalled = $false
Invoke-LiveTimer -Message "Memeriksa instalasi Ollama Daemon..." -Action {
    try {
        $OllamaVerOutput = & ollama --version 2>&1
        if ($OllamaVerOutput -match 'ollama version') { return $true }
    } catch {}
    return $false
} | ForEach-Object { $OllamaInstalled = $_ }

if (-not $OllamaInstalled) {
    if (-not $HasInternet) {
        Write-Host '  [!] Ollama belum terpasang dan sistem offline.' -ForegroundColor Red
        Read-Host 'Tekan Enter untuk keluar...'
        exit 1
    }

    if (-not (Test-Path $BinPath)) { New-Item -ItemType Directory -Path $BinPath -Force | Out-Null }
    $OllamaInstaller = Join-Path $BinPath 'OllamaSetup.exe'
    
    Invoke-LiveTimer -Message "Mengunduh Ollama Setup..." -Action {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $args[0] -UseBasicParsing
    } -Arguments $OllamaInstaller | Out-Null
    
    Invoke-ProcessWithTimer -Message "Memasang Ollama Engine..." -FilePath $OllamaInstaller -ArgumentList '/silent'
    
    Remove-Item -Path $OllamaInstaller -Force -ErrorAction SilentlyContinue
    
    $MachinePath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
    $UserPath    = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
    $env:Path    = "$MachinePath;$UserPath"
}

# ------------------------------------------------------------------------------
# 5. MENGUNCI ENVIRONMENT VARIABLES OLLAMA (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
Invoke-LiveTimer -Message "Mengunci environment variable Ollama ke partisi lokal..." -Action {
    param($mPath)
    if (-not (Test-Path $mPath)) { New-Item -ItemType Directory -Path $mPath -Force | Out-Null }
    [System.Environment]::SetEnvironmentVariable('OLLAMA_MODELS', $mPath, [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable('OLLAMA_ORIGINS', '*', [System.EnvironmentVariableTarget]::User)
} -Arguments $ModelsPath | Out-Null

$env:OLLAMA_MODELS  = $ModelsPath
$env:OLLAMA_HOST    = '0.0.0.0:11434'
$env:OLLAMA_ORIGINS = '*'

# ------------------------------------------------------------------------------
# 6. MEMASTIKAN SERVICE BACKGROUND OLLAMA AKTIF & SIAP (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
$OllamaProcess = Get-Process -Name 'ollama' -ErrorAction SilentlyContinue
if (-not $OllamaProcess) {
    Invoke-LiveTimer -Message "Menjalankan daemon background Ollama..." -Action {
        Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WindowStyle Hidden
    } | Out-Null
}

# Health-Check Polling Port 11434 hingga siap menerima koneksi (Zero-Freeze)
Invoke-LiveTimer -Message "Memastikan Ollama API siap menerima koneksi (Port 11434)..." -Action {
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $task = $tcp.ConnectAsync('127.0.0.1', 11434)
            if ($task.Wait(400) -and $tcp.Connected) {
                $tcp.Close()
                return $true
            }
            $tcp.Close()
        } catch {}
        Start-Sleep -Milliseconds 250
    }
    return $false
} | Out-Null

# ------------------------------------------------------------------------------
# 7. SINKRONISASI BOBOT MODEL AI WAJIB (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
$CurrentModels = ''
Invoke-LiveTimer -Message "Membaca repositori model neural terpasang dari Ollama..." -Action {
    try {
        return ((& ollama list 2>&1) | Out-String)
    } catch {
        return ''
    }
} | ForEach-Object { $CurrentModels = $_ }

if ($HasInternet) {
    $RequiredModels = @('qwen2.5-coder:14b', 'hermes3:8b', 'nomic-embed-text')
    foreach ($m in $RequiredModels) {
        if ($CurrentModels -match [regex]::Escape($m)) {
            Write-Host "  [OK]   [00:00.1] Verifikasi model $m (Tersedia)" -ForegroundColor Green
        } else {
            Invoke-LiveTimer -Message "Mengunduh & pulling model $m (Harap tunggu)..." -Action {
                param($modelName)
                & ollama pull $modelName
            } -Arguments $m | Out-Null
        }
    }
}

# ------------------------------------------------------------------------------
# 8. INISIALISASI STRUKTUR VAULT DEFAULT (LIVE STOPWATCH)
# ------------------------------------------------------------------------------
Invoke-LiveTimer -Message "Inisialisasi direktori Knowledge Vault & Workspace..." -Action {
    param($vPath)
    $DefaultVaultKnowledge = Join-Path $vPath 'default_repo\main\v1.0\knowledge'
    $DefaultVaultWorkspace = Join-Path $vPath 'default_repo\main\v1.0\workspace'

    New-Item -ItemType Directory -Force -Path (Join-Path $DefaultVaultKnowledge 'raw_ai_studio') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $DefaultVaultKnowledge 'raw_markdown') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $DefaultVaultKnowledge 'db') | Out-Null
    New-Item -ItemType Directory -Force -Path $DefaultVaultWorkspace | Out-Null
} -Arguments $VaultsPath | Out-Null

Write-Host ''
Write-Host '[OK] SELURUH LINGKUNGAN SULTRABYTE AI STUDIO SIAP TEMPUR!' -ForegroundColor Green
Start-Sleep -Seconds 1