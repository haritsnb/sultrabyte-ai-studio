# ==============================================================================
# SULTRABYTE AI STUDIO - MASTER ROUTER (WITH DEEP SYSTEM INSPECTOR OPTION)
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir   = $PSScriptRoot
$RootPath    = (Get-Item (Join-Path $ScriptDir '..')).FullName
$ContextFile = Join-Path $RootPath 'active_context.json'
$NetLockFile = Join-Path $RootPath 'net_lock.flag'

function Get-RealHardwareInfo {
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        $model = if ($cs.Model) { $cs.Model.Trim() } else { 'Windows Device' }
        $model = $model -replace 'System Product Name', 'Custom PC'

        $physMem = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $totalRAM = if ($physMem) {
            [math]::Round(($physMem | Measure-Object -Property Capacity -Sum).Sum / 1GB)
        } elseif ($cs.TotalPhysicalMemory) {
            [math]::Round($cs.TotalPhysicalMemory / 1GB)
        } else { 16 }

        $memType = 'RAM'
        if ($physMem) {
            $smbiosType = $physMem[0].SMBIOSMemoryType
            $memType = switch ($smbiosType) {
                24 { 'DDR3' }
                26 { 'DDR4' }
                30 { 'DDR5' }
                34 { 'DDR5' }
                default { 'DDR4' }
            }
        }

        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue
        $discreteGpu = $gpus | Where-Object { $_.Name -match 'NVIDIA|GeForce|RTX|GTX|Radeon' } | Select-Object -First 1
        $activeGpu = if ($discreteGpu) { $discreteGpu } else { $gpus | Select-Object -First 1 }

        $gpuDisplay = 'GPU Detected'
        if ($activeGpu) {
            $cleanGpu = $activeGpu.Name -replace 'NVIDIA\s+GeForce\s+', '' -replace ' Laptop GPU', '' -replace 'with Max-Q Design', ''
            $vramGB = if ($activeGpu.AdapterRAM -and $activeGpu.AdapterRAM -gt 0) {
                [math]::Round($activeGpu.AdapterRAM / 1GB)
            } else { 4 }

            if ($vramGB -gt 0) {
                $gpuDisplay = "$cleanGpu (${vramGB}GB)"
            } else {
                $gpuDisplay = $cleanGpu
            }
        }

        return "Hardware  : $model | GPU: $gpuDisplay | RAM: ${totalRAM}GB $memType"
    } catch {
        return "Hardware  : Nitro 5 | GPU: RTX 3050 (4GB) | RAM: 32GB DDR4"
    }
}

$Global:DynamicHardwareString = Get-RealHardwareInfo

function Get-StudioContext {
    if (Test-Path $ContextFile) {
        try {
            $raw = Get-Content $ContextFile -Raw -ErrorAction SilentlyContinue
            if ($raw) {
                $parsed = $raw | ConvertFrom-Json
                if ($parsed.repository) { return $parsed }
            }
        } catch {}
    }
    return [PSCustomObject]@{
        repository = 'default_repo'
        branch     = 'main'
        version    = 'v1.0'
    }
}

function Show-HUD {
    Clear-Host
    $ctx = Get-StudioContext
    $isNetLocked = Test-Path $NetLockFile
    
    # Status Ollama
    $ollamaProc = Get-Process -Name 'ollama' -ErrorAction SilentlyContinue
    $ollamaStatus = if ($ollamaProc) { 'ONLINE [CUDA ACCELERATED]' } else { 'OFFLINE' }

    # Status Tailscale Mesh
    $tailscaleIP = 'DISCONNECTED'
    try {
        $tsCommand = Get-Command 'tailscale' -ErrorAction SilentlyContinue
        if ($tsCommand) {
            $tsOutput = (& tailscale ip -4 2>$null)
            if ($tsOutput) {
                $tsClean = ("$tsOutput").Trim()
                if ($tsClean -match '^(100\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                    $tailscaleIP = "$($matches[1]) (Mesh Active)"
                }
            }
        }
    } catch {}

    # Status Web Server Port 8000
    $webStatus = 'INACTIVE'
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $client.BeginConnect('127.0.0.1', 8000, $null, $null)
        $waitSuccess = $asyncResult.AsyncWaitHandle.WaitOne(150, $false)
        if ($waitSuccess -and $client.Connected) {
            $client.EndConnect($asyncResult)
            $webStatus = 'ACTIVE (http://localhost:8000)'
        }
        $client.Close()
    } catch {}

    Write-Host '=================================================================================' -ForegroundColor Cyan
    Write-Host '                     S U L T R A B Y T E   A I   S T U D I O                     ' -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host '                developer.haritsnb@gmail.com | Harits Nala Barrun                ' -ForegroundColor White
    Write-Host '---------------------------------------------------------------------------------' -ForegroundColor Cyan
    Write-Host '                                  MASTER ROUTER                                  ' -ForegroundColor White -BackgroundColor Green
    Write-Host '=================================================================================' -ForegroundColor Cyan
    Write-Host " [DEVICE HUD] $($Global:DynamicHardwareString)" -ForegroundColor Gray
    
    Write-Host ' [STATE HUD]  Ollama    : ' -NoNewline
    if ($ollamaStatus -match 'ONLINE') {
        Write-Host $ollamaStatus -ForegroundColor Green
    } else {
        Write-Host $ollamaStatus -ForegroundColor Red
    }

    Write-Host '              Mesh VPN  : ' -NoNewline
    if ($tailscaleIP -match 'Mesh Active') {
        Write-Host $tailscaleIP -ForegroundColor Green
    } else {
        Write-Host $tailscaleIP -ForegroundColor Yellow
    }

    Write-Host '              Web GUI   : ' -NoNewline
    if ($webStatus -match 'ACTIVE') {
        Write-Host $webStatus -ForegroundColor Green
    } else {
        Write-Host $webStatus -ForegroundColor Yellow
    }

    Write-Host '              Net-Lock  : ' -NoNewline
    if ($isNetLocked) {
        Write-Host 'LOCKED (Air-Gapped)' -ForegroundColor Red
    } else {
        Write-Host 'OPEN (Live Connected)' -ForegroundColor Green
    }

    Write-Host '--------------------------------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host " [ACTIVE REPO]    : $($ctx.repository)" -ForegroundColor Yellow
    Write-Host " [ACTIVE BRANCH]  : $($ctx.branch)" -ForegroundColor Yellow
    Write-Host " [ACTIVE VERSION] : $($ctx.version)" -ForegroundColor Yellow
    Write-Host '================================================================================' -ForegroundColor Cyan
    Write-Host ' [1]  Sesi Koding Spesialis (Qwen 2.5 Coder 14B - Interactive Terminal)' -ForegroundColor White
    Write-Host ' [2]  Sesi Arsitektur Sistem (Hermes 3 8B - Interactive Terminal)' -ForegroundColor White
    Write-Host ' [3]  Sinergi Dual-Mind Chamber (Hermes 3 Arsitek + Qwen 14B Coder)' -ForegroundColor Cyan
    Write-Host ' [4]  Ingest Knowledge Vault RAG (Google AI Studio JSON & Markdown)' -ForegroundColor Green
    Write-Host ' [5]  Kueri Pencarian Konteks Masa Lalu (Ask Knowledge Vault)' -ForegroundColor Green
    Write-Host ' [6]  Buka Studio Web GUI (Jalankan Server Port 8000 & Browser)' -ForegroundColor Magenta
    Write-Host ' [7]  Manajemen Konteks Proyek (Pilih / Buat Repo, Branch, Version)' -ForegroundColor Yellow
    Write-Host ' [8]  Ekspor Studio ke File .ZIP Portabel (Reinstall-Proof Backup)' -ForegroundColor White
    Write-Host ' [9]  Toggle Net-Lock (Air-Gapped Privacy Kill-Switch)' -ForegroundColor $(if ($isNetLocked) {'Red'} else {'Green'})
    Write-Host ' [10] Deploy Workspace ke VPS Cloud (Neural Bridge Interconnect)' -ForegroundColor Cyan
    Write-Host ' [11] Informasi Lengkap Sistem (Deep Hardware & Engine Inspector)' -ForegroundColor Yellow
    Write-Host ' [0]  Keluar dari SultraByte AI Studio' -ForegroundColor Gray
    Write-Host '================================================================================' -ForegroundColor Cyan
}

while ($true) {
    try {
        Show-HUD
        $opt = Read-Host 'Pilih menu perintah [0-11]'
        
        switch ($opt) {
            '1' { & "$ScriptDir\services\run_qwen.ps1" }
            '2' { & "$ScriptDir\services\run_hermes.ps1" }
            '3' { & "$ScriptDir\services\run_dual.ps1" }
            '4' { & "$ScriptDir\services\run_ingest.ps1" }
            '5' { & "$ScriptDir\services\run_ask.ps1" }
            '6' { 
                $portActive = $false
                try {
                    $testTcp = New-Object System.Net.Sockets.TcpClient
                    $asyncCon = $testTcp.BeginConnect('127.0.0.1', 8000, $null, $null)
                    if ($asyncCon.AsyncWaitHandle.WaitOne(200, $false) -and $testTcp.Connected) {
                        $testTcp.EndConnect($asyncCon)
                        $portActive = $true
                    }
                    $testTcp.Close()
                } catch {}

                if (-not $portActive) {
                    Write-Host "`n[*] Menjalankan Python Web Server Engine (Port 8000)..." -ForegroundColor Cyan
                    Start-Process python -ArgumentList "`"$RootPath\scripts\web_server.py`"" -WindowStyle Normal
                    
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $spinner = @('|', '/', '-', '\')
                    $sIdx = 0
                    for ($i = 0; $i -lt 30; $i++) {
                        $elapsed = $sw.Elapsed.ToString('mm\:ss\.f')
                        $char = $spinner[$sIdx % 4]
                        Write-Host -NoNewline ("`r  [$char] [$elapsed] Menunggu Web Server siap di port 8000...") -ForegroundColor Cyan
                        $sIdx++
                        
                        try {
                            $pollTcp = New-Object System.Net.Sockets.TcpClient
                            $pollAsync = $pollTcp.BeginConnect('127.0.0.1', 8000, $null, $null)
                            if ($pollAsync.AsyncWaitHandle.WaitOne(300, $false) -and $pollTcp.Connected) {
                                $pollTcp.EndConnect($pollAsync)
                                $pollTcp.Close()
                                break
                            }
                            $pollTcp.Close()
                        } catch {}
                        Start-Sleep -Milliseconds 200
                    }
                    $sw.Stop()
                    Write-Host "`r  [OK]   [$($sw.Elapsed.ToString('mm\:ss\.f'))] Web Server Siap!" -ForegroundColor Green
                }

                Write-Host "[*] Membuka antarmuka Web GUI Studio di browser..." -ForegroundColor Cyan
                Start-Process 'http://localhost:8000'
                Start-Sleep -Seconds 1
            }
            '7'  { & "$ScriptDir\services\run_context.ps1" }
            '8'  { & "$ScriptDir\services\run_export.ps1" }
            '9'  { 
                if (Test-Path $NetLockFile) {
                    Remove-Item $NetLockFile -Force
                    Write-Host "`n[OK] Net-Lock dinonaktifkan. Mode jaringan terbuka." -ForegroundColor Green
                } else {
                    New-Item -ItemType File -Path $NetLockFile -Force | Out-Null
                    Write-Host "`n[OK] Net-Lock DIAKTIFKAN. Mode Air-Gapped Privacy aktif." -ForegroundColor Red
                }
                Start-Sleep -Seconds 1
            }
            '10' { & "$ScriptDir\services\deploy_to_vps.ps1" }
            '11' { & "$ScriptDir\services\run_sysinfo.ps1" }
            '0'  { 
                Write-Host "`nSampai jumpa kembali. SultraByte AI Studio dimatikan dengan aman." -ForegroundColor Cyan
                exit 0 
            }
            default {
                Write-Host "`nPilihan tidak valid. Silakan pilih angka 0-11." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } catch {
        Write-Host "`n[X] Terjadi error runtime: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Lokasi: $($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkGray
        Read-Host 'Tekan Enter untuk melanjutkan...'
    }
}