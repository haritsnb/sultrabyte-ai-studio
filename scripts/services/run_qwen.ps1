[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "`n[SultraByte AI Studio] Memulai Sesi Interaktif Qwen 2.5 Coder 14B..." -ForegroundColor Green
& ollama run qwen2.5-coder:14b