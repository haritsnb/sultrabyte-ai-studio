# ==============================================================================
# SULTRABYTE AI STUDIO - DEEP SYSTEM, HARDWARE, OLLAMA, & RUNTIME INSPECTOR
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'

$ScriptDir   = $PSScriptRoot
$RootPath    = (Get-Item (Join-Path $ScriptDir '..\..')).FullName
$ContextFile = Join-Path $RootPath 'active_context.json'
$NetLockFile = Join-Path $RootPath 'net_lock.flag'
$ModelsPath  = Join-Path $RootPath 'models'
$VaultsPath  = Join-Path $RootPath 'vaults'

Clear-Host
Write-Host '=================================================================================' -ForegroundColor Cyan
Write-Host '                     S U L T R A B Y T E   A I   S T U D I O                     ' -ForegroundColor White -BackgroundColor DarkBlue
Write-Host '                developer.haritsnb@gmail.com | Harits Nala Barrun                ' -ForegroundColor White
Write-Host '---------------------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host '                                 SYSTEM INSPECT                                  ' -ForegroundColor White -BackgroundColor Green
Write-Host '=================================================================================' -ForegroundColor Cyan
Write-Host ' [*] Melakukan deep probing hardware, Ollama models, pip packages, & RAG Vault...' -ForegroundColor Yellow

# ------------------------------------------------------------------------------
# 1. HARDWARE ENGINE & OS PROBING (WMI / CIM / NVIDIA-SMI)
# ------------------------------------------------------------------------------
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$physMem = Get-CimInstance Win32_PhysicalMemory
$gpus = Get-CimInstance Win32_VideoController

# CPU Details
$cpuName = ($cpu.Name -replace '\s+', ' ').Trim()
$cpuCores = $cpu.NumberOfCores
$cpuThreads = $cpu.NumberOfLogicalProcessors
$cpuMaxClock = "$([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz"

# RAM Details
$totalRamGB = [math]::Round(($physMem | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1024 / 1024, 2)
$usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
$ramSpeed = $physMem[0].Speed
$ramSlots = ($physMem | Measure-Object).Count
$ramType = switch ($physMem[0].SMBIOSMemoryType) {
    24 { 'DDR3' }
    26 { 'DDR4' }
    30 { 'DDR5' }
    34 { 'DDR5' }
    default { 'DDR4' }
}

# GPU Details (NVIDIA Discrete Priority)
$discreteGpu = $gpus | Where-Object { $_.Name -match 'NVIDIA|GeForce|RTX|GTX' } | Select-Object -First 1
$activeGpu = if ($discreteGpu) { $discreteGpu } else { $gpus | Select-Object -First 1 }
$gpuName = $activeGpu.Name
$gpuDriver = $activeGpu.DriverVersion
$gpuVRAM = if ($activeGpu.AdapterRAM -and $activeGpu.AdapterRAM -gt 0) { "$([math]::Round($activeGpu.AdapterRAM / 1GB, 1)) GB" } else { "N/A" }

# Cek NVIDIA-SMI jika tersedia untuk data CUDA & Suhu real-time
$nvidiaSmiDetails = "N/A"
try {
    $smiCmd = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    if ($smiCmd) {
        $smiOut = (& nvidia-smi --query-gpu=driver_version,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>$null)
        if ($smiOut) {
            $parts = $smiOut.Split(',')
            $nvidiaSmiDetails = "Temp: $($parts[1].Trim())C | Usage: $($parts[2].Trim())% | VRAM In-Use: $($parts[3].Trim())MB / $($parts[4].Trim())MB"
        }
    }
} catch {}

# Storage / Drive Details
$driveRoot = (Get-Item $RootPath).PSDrive
$driveTotalGB = [math]::Round($driveRoot.Used / 1GB + $driveRoot.Free / 1GB, 1)
$driveFreeGB = [math]::Round($driveRoot.Free / 1GB, 1)
$drivePercent = [math]::Round((($driveRoot.Used / 1GB) / $driveTotalGB) * 100, 1)

# Ukuran Folder Models & Studio di Disk
$studioSizeGB = [math]::Round((Get-ChildItem -Path $RootPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
$modelsSizeGB = if (Test-Path $ModelsPath) {
    [math]::Round((Get-ChildItem -Path $ModelsPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
} else { 0.0 }

# ------------------------------------------------------------------------------
# 2. LOCAL AI INFERENCE ENGINE (OLLAMA DAEMON & NEURAL MODELS)
# ------------------------------------------------------------------------------
$ollamaProc = Get-Process -Name 'ollama' -ErrorAction SilentlyContinue
$ollamaPid = if ($ollamaProc) { ($ollamaProc | Select-Object -First 1).Id } else { "N/A" }
$ollamaMemMB = if ($ollamaProc) { [math]::Round(($ollamaProc | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 1) } else { 0 }
$ollamaVer = (& ollama --version 2>&1)

# Query Ollama REST API Tags (Model Details: Parameter Size, Quantization, Digest)
$modelsList = @()
try {
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -Method GET -TimeoutSec 2
    $modelsList = $res.models
} catch {}

# Query Active Loaded Model in VRAM/RAM (Ollama ps)
$activeLoadedModels = "None (Idle)"
try {
    $psRes = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/ps" -Method GET -TimeoutSec 2
    if ($psRes.models -and $psRes.models.Count -gt 0) {
        $activeLoadedModels = ($psRes.models | ForEach-Object {
            "$($_.name) (VRAM: $([math]::Round($_.size_vram / 1GB, 2)) GB | Total: $([math]::Round($_.size / 1GB, 2)) GB)"
        }) -join ", "
    }
} catch {}

# ------------------------------------------------------------------------------
# 3. PYTHON ENVIRONMENT & PIP PACKAGES
# ------------------------------------------------------------------------------
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
$pythonVer = (& python --version 2>&1)
$pipVer = (& pip --version 2>&1)

# Daftar Paket PIP Utama
$targetPackages = @('chromadb', 'ollama', 'duckduckgo-search', 'rich', 'colorama', 'httpx', 'httpcore', 'requests', 'urllib3')
$pipListRaw = (& pip list --format=json 2>&1) | ConvertFrom-Json
$installedPipTable = @()

foreach ($tp in $targetPackages) {
    $found = $pipListRaw | Where-Object { $_.name -like "*$tp*" -or $_.name -eq $tp } | Select-Object -First 1
    if ($found) {
        $installedPipTable += [PSCustomObject]@{
            Package = $found.name
            Version = $found.version
            Status  = "Installed"
        }
    } else {
        $installedPipTable += [PSCustomObject]@{
            Package = $tp
            Version = "Not Installed"
            Status  = "Missing"
        }
    }
}

# ------------------------------------------------------------------------------
# 4. KNOWLEDGE VAULT RAG & ACTIVE CONTEXT
# ------------------------------------------------------------------------------
$ctx = @{ repository = 'default_repo'; branch = 'main'; version = 'v1.0' }
if (Test-Path $ContextFile) {
    try { $ctx = Get-Content $ContextFile -Raw | ConvertFrom-Json } catch {}
}

$activeVaultDir = Join-Path $VaultsPath "$($ctx.repository)\$($ctx.branch)\$($ctx.version)"
$rawAiStudioDir = Join-Path $activeVaultDir "knowledge\raw_ai_studio"
$rawMarkdownDir = Join-Path $activeVaultDir "knowledge\raw_markdown"
$chromaDbDir    = Join-Path $activeVaultDir "knowledge\db"
$workspaceDir   = Join-Path $activeVaultDir "workspace"

$jsonCount = if (Test-Path $rawAiStudioDir) { (Get-ChildItem -Path $rawAiStudioDir -Filter *.json).Count } else { 0 }
$mdCount   = if (Test-Path $rawMarkdownDir) { (Get-ChildItem -Path $rawMarkdownDir -Filter *.md).Count } else { 0 }
$chromaSizeMB = if (Test-Path $chromaDbDir) {
    [math]::Round((Get-ChildItem -Path $chromaDbDir -Recurse -Force | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
} else { 0.0 }
$workspaceFiles = if (Test-Path $workspaceDir) { (Get-ChildItem -Path $workspaceDir -Recurse -File).Count } else { 0 }

# ------------------------------------------------------------------------------
# 5. NETWORK, MESH VPN, & SECURITY STATUS
# ------------------------------------------------------------------------------
$tailscaleIP = "Disconnected"
try {
    $tsOut = (& tailscale ip -4 2>$null)
    if ($tsOut) { $tailscaleIP = "$($tsOut.Trim()) (Mesh Connected)" }
} catch {}

$isNetLocked = Test-Path $NetLockFile

$webPortStatus = "Inactive"
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    if ($tcp.ConnectAsync('127.0.0.1', 8000).Wait(150) -and $tcp.Connected) {
        $webPortStatus = "Online (http://localhost:8000)"
        $tcp.Close()
    }
} catch {}

# ------------------------------------------------------------------------------
# RENDER LAPORAN KOMPREHENSIF
# ------------------------------------------------------------------------------
Write-Host "`n[1] HOST HARDWARE & SYSTEM INFRASTRUCTURE" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  -> Device Model   : $($cs.Manufacturer) $($cs.Model)" -ForegroundColor White
Write-Host "  -> Operating Sys  : $($os.Caption) ($($os.OSArchitecture)) | Build: $($os.BuildNumber)" -ForegroundColor White
Write-Host "  -> Processor (CPU): $cpuName" -ForegroundColor White
Write-Host "     Topology       : $cpuCores Physical Cores | $cpuThreads Logical Threads @ $cpuMaxClock" -ForegroundColor DarkGray
Write-Host "  -> System Memory  : $totalRamGB GB $ramType ($ramSlots Slot @ $ramSpeed MHz)" -ForegroundColor White
Write-Host "     RAM Allocation : Used: $usedRamGB GB | Free: $freeRamGB GB" -ForegroundColor DarkGray
Write-Host "  -> Graphics (GPU) : $gpuName" -ForegroundColor White
Write-Host "     VRAM / Driver  : VRAM: $gpuVRAM | Driver: $gpuDriver" -ForegroundColor DarkGray
if ($nvidiaSmiDetails -ne "N/A") {
    Write-Host "     NVIDIA Telemetry: $nvidiaSmiDetails" -ForegroundColor Cyan
}
Write-Host "  -> Storage (Disk) : Drive $($driveRoot.Name): ($driveFreeGB GB Free of $driveTotalGB GB [$drivePercent% Used])" -ForegroundColor White
Write-Host "     Studio Footprint: Total: $studioSizeGB GB (Models Storage: $modelsSizeGB GB)" -ForegroundColor DarkGray

Write-Host "`n[2] LOCAL AI INFERENCE ENGINE (OLLAMA DAEMON)" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  -> Daemon Status  : $(if ($ollamaProc) { "Running (PID: $ollamaPid | Working Set: $ollamaMemMB MB)" } else { "OFFLINE" })" -ForegroundColor $(if ($ollamaProc) { "Cyan" } else { "Red" })
Write-Host "  -> Engine Version : $ollamaVer" -ForegroundColor White
Write-Host "  -> Host / Binding : $($env:OLLAMA_HOST) (Port 11434)" -ForegroundColor White
Write-Host "  -> Models Cache   : $($env:OLLAMA_MODELS)" -ForegroundColor White
Write-Host "  -> Active In VRAM : $activeLoadedModels" -ForegroundColor $(if ($activeLoadedModels -ne "None (Idle)") { "Green" } else { "Yellow" })

Write-Host "`n  Daftar Model Neural Terpasang:" -ForegroundColor Yellow
if ($modelsList.Count -gt 0) {
    foreach ($m in $modelsList) {
        $mSizeGB = [math]::Round($m.size / 1GB, 2)
        $pSize = $m.details.parameter_size
        $quant = $m.details.quantization_level
        $family = $m.details.family
        Write-Host "   * $($m.name.PadRight(22)) | Size: $($mSizeGB.ToString().PadRight(6)) GB | Params: $($pSize.PadRight(5)) | Quant: $($quant.PadRight(8)) | Family: $family" -ForegroundColor White
    }
} else {
    Write-Host "   (Belum ada model terdeteksi atau daemon sedang offline)" -ForegroundColor DarkGray
}

Write-Host "`n[3] PYTHON RUNTIME & DATA SCIENCE LIBRARIES" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  -> Python Path    : $pythonPath" -ForegroundColor White
Write-Host "  -> Python Version : $pythonVer" -ForegroundColor White
Write-Host "  -> Pip Executable : $pipVer" -ForegroundColor White
Write-Host "  -> Installed Core Libraries:" -ForegroundColor Yellow

$col1 = $installedPipTable[0..2]
$col2 = $installedPipTable[3..5]
$col3 = $installedPipTable[6..8]

for ($i = 0; $i -lt 3; $i++) {
    $line = ""
    if ($col1[$i]) { $line += "   * $($col1[$i].Package.PadRight(18)): $($col1[$i].Version.PadRight(10)) " }
    if ($col2[$i]) { $line += " | $($col2[$i].Package.PadRight(18)): $($col2[$i].Version.PadRight(10)) " }
    if ($col3[$i]) { $line += " | $($col3[$i].Package.PadRight(16)): $($col3[$i].Version)" }
    Write-Host $line -ForegroundColor White
}

Write-Host "`n[4] KNOWLEDGE VAULT RAG & WORKSPACE STATE" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  -> Active Context : Repository: $($ctx.repository) | Branch: $($ctx.branch) | Version: $($ctx.version)" -ForegroundColor Yellow
Write-Host "  -> Vault Base Dir : $activeVaultDir" -ForegroundColor White
Write-Host "  -> AI Studio JSON : $jsonCount file riwayat chat tersimpan di 'raw_ai_studio/'" -ForegroundColor White
Write-Host "  -> Markdown Docs  : $mdCount file dokumen tersimpan di 'raw_markdown/'" -ForegroundColor White
Write-Host "  -> ChromaDB Vector: Ukuran DB: $chromaSizeMB MB di 'knowledge/db/'" -ForegroundColor White
Write-Host "  -> Workspace Code : $workspaceFiles file proyek aktif di 'workspace/'" -ForegroundColor White

Write-Host "`n[5] NETWORK, MESH VPN, & SECURITY PERIMETER" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  -> Tailscale Mesh : $tailscaleIP" -ForegroundColor $(if ($tailscaleIP -match "Connected") { "Cyan" } else { "Yellow" })
Write-Host "  -> Web GUI Server : $webPortStatus" -ForegroundColor $(if ($webPortStatus -match "Online") { "Green" } else { "Yellow" })
Write-Host "  -> Net-Lock Guard : $(if ($isNetLocked) { "LOCKED (Air-Gapped Offline Protection Active)" } else { "OPEN (Internet Connected)" })" -ForegroundColor $(if ($isNetLocked) { "Red" } else { "Green" })
Write-Host "  -> CORS Policy    : OLLAMA_ORIGINS = $($env:OLLAMA_ORIGINS) (CORS Bypass Enabled)" -ForegroundColor White

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Tekan Enter untuk kembali ke Master Router..." -ForegroundColor Gray
Read-Host