[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = (Get-Item "$PSScriptRoot\..\..").FullName
& python "$Root\scripts\dual_mind.py"
Write-Host "`nTekan Enter untuk kembali ke menu utama..." -ForegroundColor Gray
Read-Host