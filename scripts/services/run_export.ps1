[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = (Get-Item "$PSScriptRoot\..\..").FullName
$ExportZip = Join-Path $Root "SultraByte_AI_Studio_Export_$((Get-Date).ToString('yyyyMMdd_HHmmss')).zip"

Write-Host "`n[*] Menyiapkan backup portabel SultraByte AI Studio..." -ForegroundColor Cyan
Write-Host "[*] Mengompresi seluruh skrip, vault, web GUI (mengecualikan models/ biner)..." -ForegroundColor Yellow

# Filter mengecualikan folder models dan zip sementara
$ItemsToZip = Get-ChildItem -Path $Root -Exclude "models", "bin", "*.zip"

Compress-Archive -Path $ItemsToZip.FullName -DestinationPath $ExportZip -Force

Write-Host "`n[✓] Backup Portabel Berhasil Dibuat!" -ForegroundColor Green
Write-Host "Lokasi File: $ExportZip" -ForegroundColor White
Write-Host "`nTekan Enter untuk kembali ke menu utama..." -ForegroundColor Gray
Read-Host