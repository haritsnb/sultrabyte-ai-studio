[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = (Get-Item "$PSScriptRoot\..\..").FullName
$ContextFile = Join-Path $Root "active_context.json"
$VaultsDir = Join-Path $Root "vaults"

Clear-Host
Write-Host '=================================================================================' -ForegroundColor Cyan
Write-Host '                     S U L T R A B Y T E   A I   S T U D I O                     ' -ForegroundColor White -BackgroundColor DarkBlue
Write-Host '                developer.haritsnb@gmail.com | Harits Nala Barrun                ' -ForegroundColor White
Write-Host '---------------------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host '                             CONTEXT MANAGER (CRUD)                              ' -ForegroundColor White -BackgroundColor Green
Write-Host '=================================================================================' -ForegroundColor Cyan

$CurrentCtx = @{ repository = "default_repo"; branch = "main"; version = "v1.0" }
if (Test-Path $ContextFile) {
    try {
        $CurrentCtx = Get-Content $ContextFile -Raw | ConvertFrom-Json
    } catch {}
}

Write-Host "Konteks Saat Ini:" -ForegroundColor Yellow
Write-Host "  -> Repository : $($CurrentCtx.repository)" -ForegroundColor White
Write-Host "  -> Branch     : $($CurrentCtx.branch)" -ForegroundColor White
Write-Host "  -> Version    : $($CurrentCtx.version)" -ForegroundColor White
Write-Host "------------------------------------------------------------" -ForegroundColor Gray
Write-Host "1. Pilih / Buat Konteks Baru"
Write-Host "2. Tampilkan Seluruh Vault yang Ada"
Write-Host "3. Kembali ke Menu Utama"
Write-Host "------------------------------------------------------------" -ForegroundColor Gray

$Choice = Read-Host "Pilih opsi [1-3]"
switch ($Choice) {
    "1" {
        $Repo = Read-Host "Masukkan Nama Repository [contoh: pos_system]"
        $Branch = Read-Host "Masukkan Nama Branch [contoh: dev/auth]"
        $Ver = Read-Host "Masukkan Versi [contoh: v1.0.0]"

        if (-not $Repo) { $Repo = "default_repo" }
        if (-not $Branch) { $Branch = "main" }
        if (-not $Ver) { $Ver = "v1.0" }

        # Inisialisasi struktur vault jika baru
        $NewVaultBase = Join-Path $VaultsDir "$Repo\$Branch\$Ver"
        New-Item -ItemType Directory -Force -Path (Join-Path $NewVaultBase "knowledge\raw_ai_studio") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $NewVaultBase "knowledge\raw_markdown") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $NewVaultBase "knowledge\db") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $NewVaultBase "workspace") | Out-Null

        $NewObj = @{
            repository = $Repo
            branch = $Branch
            version = $Ver
            updated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        $NewObj | ConvertTo-Json | Set-Content $ContextFile -Encoding UTF8
        Write-Host "`n[✓] Konteks berhasil diubah ke: $Repo / $Branch / $Ver" -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    "2" {
        Write-Host "`nDaftar Hierarki Vaults Terdaftar:" -ForegroundColor Cyan
        Get-ChildItem -Path $VaultsDir -Recurse -Directory -Depth 2 | ForEach-Object {
            Write-Host "  -> $($_.FullName.Replace($VaultsDir, ''))" -ForegroundColor Gray
        }
        Write-Host "`nTekan Enter untuk kembali..." -ForegroundColor Gray
        Read-Host
    }
}