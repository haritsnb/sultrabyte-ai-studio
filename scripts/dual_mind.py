#!/usr/bin/env python3
"""
=================================================================================
|                    S U L T R A B Y T E   A I   S T U D I O                    |
|               developer.haritsnb@gmail.com | Harits Nala Barrun               |
|-------------------------------------------------------------------------------|
|              Dual-Mind Chamber with Real-Time Human Intervention              |
|  Tekan [Esc], [Ctrl+C], atau [q] kapan saja untuk menghentikan inferensi AI!  |
=================================================================================
"""

import sys
import os
import time
import threading
import ollama
from rich.console import Console
from rich.panel import Panel
from rich.rule import Rule
from rich.live import Live
from rich.text import Text

# Import modul keyboard non-blocking khusus Windows
try:
    import msvcrt
except ImportError:
    msvcrt = None

console = Console()
OLLAMA_HOST = "http://127.0.0.1:11434"
client = ollama.Client(host=OLLAMA_HOST)

class LiveStopwatch:
    def __init__(self, message, style="bold cyan"):
        self.message = message
        self.style = style
        self.start_time = None
        self.running = False
        self.thread = None
        self.live = None

    def __enter__(self):
        self.start_time = time.time()
        self.running = True
        self.live = Live(self._render(), refresh_per_second=10, transient=True)
        self.live.start()
        self.thread = threading.Thread(target=self._update, daemon=True)
        self.thread.start()
        return self

    def _render(self):
        elapsed = time.time() - self.start_time if self.start_time else 0
        mins, secs = divmod(elapsed, 60)
        spinners = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        idx = int(elapsed * 10) % len(spinners)
        char = spinners[idx]
        return Text(f"  {char} [{int(mins):02d}:{secs:04.1f}] {self.message} [Tekan Esc untuk Intervensi]", style=self.style)

    def _update(self):
        while self.running:
            try:
                self.live.update(self._render())
                time.sleep(0.1)
            except Exception:
                break

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.running = False
        if self.thread:
            self.thread.join(timeout=0.2)
        try:
            self.live.stop()
        except Exception:
            pass
        elapsed = time.time() - self.start_time
        mins, secs = divmod(elapsed, 60)
        formatted = f"[{int(mins):02d}:{secs:04.1f}]"
        if exc_type is None:
            console.print(f"  [bold green][OK][/bold green] {formatted} {self.message}")
        else:
            console.print(f"  [bold red][INTERVENSI][/bold red] {formatted} {self.message}")

def check_terminal_intervention():
    """Mengecek apakah Anda menekan tombol Esc, Ctrl+C, atau 'q'"""
    if msvcrt and msvcrt.kbhit():
        key = msvcrt.getch()
        if key in [b'\x1b', b'\x03', b'q', b'Q']:  # Esc, Ctrl+C, 'q'
            return True
    return False

def stream_llm(model, system_prompt, user_prompt, panel_title, border_style):
    console.print(Rule(title=panel_title, style=border_style))
    console.print("[dim]💡 Tip: Tekan [bold yellow]Esc[/bold yellow] atau [bold yellow]q[/bold yellow] pada keyboard kapan saja untuk melakukan Intervensi/Stop.[/dim]\n")
    
    start_total = time.time()
    interrupted = False
    full_text = ""

    try:
        with LiveStopwatch(f"Menginisialisasi {model} (RTX 3050 CUDA)...", style=border_style):
            stream = client.chat(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                stream=True
            )
            first_chunk = next(stream)

        first_token = first_chunk.get('message', {}).get('content', '')
        sys.stdout.write(first_token)
        sys.stdout.flush()
        full_text += first_token

        for chunk in stream:
            # Pengecekan Intervensi Keyboard di setiap token
            if check_terminal_intervention():
                interrupted = True
                break

            token = chunk.get('message', {}).get('content', '')
            sys.stdout.write(token)
            sys.stdout.flush()
            full_text += token

    except KeyboardInterrupt:
        interrupted = True
    except Exception as e:
        console.print(f"\n[bold red][X] Error: {e}[/bold red]")
        return ""

    total_elapsed = time.time() - start_total
    mins, secs = divmod(total_elapsed, 60)

    if interrupted:
        console.print(f"\n\n[bold red]⚠️ [INTERVENSI BERHASIL][/bold red] [yellow]Generasi model {model} dihentikan manual oleh Anda pada ({int(mins):02d}:{secs:04.1f}).[/yellow]\n")
    else:
        console.print(f"\n[dim italic]⏱️ Total durasi inferensi: {int(mins):02d}:{secs:04.1f}[/dim italic]\n")

    return full_text if not interrupted else ""

def main():
    console.print(Panel(
        "[bold white]DUAL-MIND CHAMBER - SINERGI DENGAN KENDALI INTERVENSI[/bold white]\n"
        "[cyan]Mind 1: Hermes 3 8B (Enterprise Software Architect)[/cyan]\n"
        "[green]Mind 2: Qwen 2.5 Coder 14B (Production Implementation Engineer)[/green]\n"
        "[yellow]Fitur Intervensi: Tekan Esc / q / Ctrl+C kapan saja untuk membatalkan proses.[/yellow]",
        title="[bold magenta]SultraByte AI Studio[/bold magenta]",
        border_style="magenta"
    ))
    
    if len(sys.argv) > 1:
        task = " ".join(sys.argv[1:])
    else:
        task = console.input("[bold yellow]Jelaskan fitur, sistem, atau masalah yang ingin dipecahkan:[/bold yellow] ")
        
    if not task.strip():
        console.print("[red]Instruksi kosong. Dibatalkan.[/red]")
        return

    # FASE 1: ARSITEK (HERMES 3)
    architect_system_prompt = (
        "Anda adalah Principal Systems Architect di SultraByte AI. Rancang cetak biru arsitektur sistem modular yang elegan, "
        "pola desain, alur data, edge-case mitigasi, serta spesifikasi antarmuka fungsi/kelas. Fokus pada blueprint cetak biru teknis."
    )
    
    blueprint = stream_llm(
        model="hermes3:8b",
        system_prompt=architect_system_prompt,
        user_prompt=f"Rancang cetak biru arsitektur teknis lengkap untuk kebutuhan berikut:\n\n{task}",
        panel_title="🧠 FASE 1: HERMES 3 8B - SYSTEM BLUEPRINT",
        border_style="cyan"
    )

    if not blueprint:
        console.print("[yellow][*] Sesi dihentikan pada Fase 1. Mengembalikan kendali ke menu utama.[/yellow]")
        return

    # FASE 2: PROGRAMMER (QWEN 2.5 CODER 14B)
    coder_system_prompt = (
        "Anda adalah Lead Production Engineer di SultraByte AI Studio. Tuliskan kode implementasi utuh, modular, "
        "clean code, type-hinted, aman, dan siap pakai tanpa placeholder."
    )
    
    coder_input = (
        f"Kebutuhan Asli:\n{task}\n\n"
        f"Cetak Biru Arsitektur Hermes 3:\n{blueprint}\n\n"
        f"Instruksi: Tuliskan seluruh kode produksi implementasi lengkapnya sekarang."
    )
    
    code_output = stream_llm(
        model="qwen2.5-coder:14b",
        system_prompt=coder_system_prompt,
        user_prompt=coder_input,
        panel_title="⚡ FASE 2: QWEN 2.5 CODER 14B - FULL IMPLEMENTATION",
        border_style="green"
    )
    
    if code_output:
        console.print(Rule(title="[bold green]DUAL-MIND SYNTHESIS COMPLETE[/bold green]", style="green"))

if __name__ == "__main__":
    main()