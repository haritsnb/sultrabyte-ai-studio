# ==============================================================================
# SULTRABYTE AI STUDIO - LAPTOP TO VPS DEPLOYMENT WITH LIVE TIMER
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = (Get-Item "$PSScriptRoot\..\..").FullName
$ContextFile = Join-Path $Root "active_context.json"

Clear-Host
Write-Host '=================================================================================' -ForegroundColor Cyan
Write-Host '                     S U L T R A B Y T E   A I   S T U D I O                     ' -ForegroundColor White -BackgroundColor DarkBlue
Write-Host '                developer.haritsnb@gmail.com | Harits Nala Barrun                ' -ForegroundColor White
Write-Host '---------------------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host '                          VPS REMOTE DEPLOYMENT BRIDGE                           ' -ForegroundColor White -BackgroundColor Green
Write-Host '=================================================================================' -ForegroundColor Cyan

$Ctx = @{ repository = 'default_repo'; branch = 'main'; version = 'v1.0' }
if (Test-Path $ContextFile) {
    try { $Ctx = Get-Content $ContextFile -Raw | ConvertFrom-Json } catch {}
}

Write-Host 'Konteks Workspace Aktif:' -ForegroundColor Yellow
Write-Host "  -> Repo/Branch/Ver: $($Ctx.repository) / $($Ctx.branch) / $($Ctx.version)" -ForegroundColor White
Write-Host '------------------------------------------------------------' -ForegroundColor Gray

$VpsIp = Read-Host 'Masukkan Tailscale IP VPS [contoh: 100.64.0.20]'
if (-not $VpsIp) { 
    Write-Host '[X] IP Tailscale VPS wajib diisi!' -ForegroundColor Red
    Read-Host 'Tekan Enter untuk kembali...'
    exit 1 
}

$Subdomain = Read-Host 'Masukkan Target Subdomain [contoh: pos-app]'
if (-not $Subdomain) { $Subdomain = $Ctx.repository.ToLower().Replace('_', '-') }

Write-Host "`nPilih Runtime Stack Target:" -ForegroundColor Yellow
Write-Host '  [1] php8.4 (Default Laravel / Modern PHP)'
Write-Host '  [2] php8.5 (Bleeding Edge PHP)'
Write-Host '  [3] php7.2 (Legacy PHP)'
Write-Host '  [4] node    (Node.js 20 LTS + PM2)'
Write-Host '  [5] go      (Go 1.23 Microservices)'
Write-Host '  [6] static  (Static HTML / Frontend)'
$StackChoice = Read-Host 'Pilih Stack [1-6]'

$StackMap = @{ '1'='php8.4'; '2'='php8.5'; '3'='php7.2'; '4'='node'; '5'='go'; '6'='static' }
$SelectedStack = $StackMap[$StackChoice]
if (-not $SelectedStack) { $SelectedStack = 'php8.4' }

$GitRepo = Read-Host 'Masukkan URL Git Repository (Kosongkan jika ingin template boilerplate)'
$GitBranch = Read-Host 'Masukkan Branch Git [default: main]'
if (-not $GitBranch) { $GitBranch = 'main' }

$SecretKey = Read-Host 'Masukkan N8N_ENCRYPTION_KEY / Secret VPS' -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretKey)
$PlainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Kirim Request dengan Animasi Stopwatch
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$spinner = @('|', '/', '-', '\')
$idx = 0

$Payload = @{
    secret = $PlainSecret
    action = 'deploy_app'
    args = @($Subdomain, $SelectedStack, $GitRepo, $GitBranch)
} | ConvertTo-Json

Write-Host ''
$job = Start-Job -ScriptBlock {
    param($Uri, $Body)
    Invoke-RestMethod -Uri $Uri -Method POST -Body $Body -ContentType 'application/json' -TimeoutSec 180
} -ArgumentList "http://${VpsIp}:9124", $Payload

while ($job.State -eq 'Running') {
    $elapsed = $sw.Elapsed.ToString('mm\:ss\.f')
    $char = $spinner[$idx % 4]
    Write-Host -NoNewline ("`r  [$char] [$elapsed] Mengeksekusi Autonomous Deployment di VPS via Tailscale...") -ForegroundColor Cyan
    Start-Sleep -Milliseconds 100
    $idx++
}

$Response = Receive-Job -Job $job
$JobError = $job.JobStateInfo.Reason
Remove-Job -Job $job
$sw.Stop()
$finalElapsed = $sw.Elapsed.ToString('mm\:ss\.f')

if ($JobError -or (-not $Response)) {
    Write-Host "`r  [FAIL] [$finalElapsed] Gagal menghubungi VPS: $JobError" -ForegroundColor Red
} else {
    Write-Host "`r  [OK]   [$finalElapsed] Eksekusi Deployment Selesai!" -ForegroundColor Green
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "          STATUS DEPLOYMENT: $($Response.status.ToUpper())          " -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host $Response.output -ForegroundColor White
}

Write-Host "`nTekan Enter untuk kembali ke menu utama..." -ForegroundColor Gray
Read-Host