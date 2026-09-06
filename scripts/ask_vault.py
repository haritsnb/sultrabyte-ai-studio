#!/usr/bin/env python3
"""
=================================================================================
|                    S U L T R A B Y T E   A I   S T U D I O                    |
|               developer.haritsnb@gmail.com | Harits Nala Barrun               |
|-------------------------------------------------------------------------------|
|               Knowledge Vault Query with Real-Time Intervention               |
|   Tekan [Esc], [Ctrl+C], atau [q] kapan saja untuk menghentikan respon RAG!   |
=================================================================================
"""

import os
import sys
import json
import time
import threading
import chromadb
import ollama
from rich.console import Console
from rich.live import Live
from rich.text import Text

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
        return Text(f"  {char} [{int(mins):02d}:{secs:04.1f}] {self.message}", style=self.style)

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
            console.print(f"  [bold red][FAIL][/bold red] {formatted} {self.message}")

def check_terminal_intervention():
    if msvcrt and msvcrt.kbhit():
        key = msvcrt.getch()
        if key in [b'\x1b', b'\x03', b'q', b'Q']:
            return True
    return False

def get_active_context(root_dir):
    context_file = os.path.join(root_dir, "active_context.json")
    if os.path.exists(context_file):
        try:
            with open(context_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"repository": "default_repo", "branch": "main", "version": "v1.0"}

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    context = get_active_context(root_dir)
    
    db_dir = os.path.join(
        root_dir, "vaults", 
        context["repository"], context["branch"], context["version"], 
        "knowledge", "db"
    )
    
    if not os.path.exists(db_dir):
        console.print("[red][X] Basis data vektor belum diinisialisasi. Jalankan 'Ingest Vault' terlebih dahulu.[/red]")
        sys.exit(1)
        
    chroma_client = chromadb.PersistentClient(path=db_dir)
    try:
        collection = chroma_client.get_collection(name="sultrabyte_knowledge")
    except Exception:
        console.print("[red][X] Koleksi 'sultrabyte_knowledge' tidak ditemukan di database vektor.[/red]")
        sys.exit(1)
        
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
    else:
        query = console.input("\n[bold yellow]Masukkan pertanyaan / kueri konteks masa lalu:[/bold yellow] ")
        
    if not query.strip():
        console.print("[yellow]Kueri dibatalkan.[/yellow]")
        return

    retrieved_docs = []
    metadatas = []
    with LiveStopwatch("Mengekstrak embedding & mencari kesamaan kosinus di ChromaDB..."):
        emb = client.embeddings(model="nomic-embed-text", prompt=query)["embedding"]
        results = collection.query(query_embeddings=[emb], n_results=4)
        retrieved_docs = results.get("documents", [[]])[0]
        metadatas = results.get("metadatas", [[]])[0]

    if not retrieved_docs:
        console.print("[yellow]Tidak ditemukan konteks yang relevan di Knowledge Vault.[/yellow]")
        context_str = "Tidak ada konteks masa lalu."
    else:
        context_parts = []
        console.print("\n[bold green]Dokumen Relevan Ditemukan:[/bold green]")
        for idx, (doc, meta) in enumerate(zip(retrieved_docs, metadatas)):
            src = meta.get("source", "unknown")
            console.print(f" [cyan]{idx+1}. {src}[/cyan] -> [dim]{doc[:120]}...[/dim]")
            context_parts.append(f"--- DOKUMEN {idx+1} (Sumber: {src}) ---\n{doc}")
        context_str = "\n\n".join(context_parts)
        
    system_prompt = (
        "Anda adalah SultraByte AI Studio Expert Assistant. Jawab pertanyaan pengguna secara akurat "
        "berdasarkan Konteks Pengetahuan Masa Lalu yang disediakan. Jika konteks tidak mencukupi, gunakan pengetahuan "
        "rekayasa perangkat lunak terbaik Anda secara profesional.\n\n"
        f"=== KONTEKS PENGETAHUAN VAULT ===\n{context_str}\n================================"
    )
    
    console.print("\n" + "="*70)
    console.print("[bold cyan]JAWABAN AI STUDIO (Qwen 2.5 Coder 14B):[/bold cyan] [dim](Tekan Esc / q untuk Stop)[/dim]\n")
    
    start_time = time.time()
    interrupted = False

    try:
        with LiveStopwatch("Menginisialisasi stream inferensi Qwen 2.5 Coder 14B..."):
            stream = client.chat(
                model="qwen2.5-coder:14b",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": query}
                ],
                stream=True
            )
            first_chunk = next(stream)

        first_token = first_chunk.get('message', {}).get('content', '')
        sys.stdout.write(first_token)
        sys.stdout.flush()

        for chunk in stream:
            if check_terminal_intervention():
                interrupted = True
                break

            content = chunk.get('message', {}).get('content', '')
            sys.stdout.write(content)
            sys.stdout.flush()

    except KeyboardInterrupt:
        interrupted = True
    except Exception as e:
        console.print(f"\n[red][X] Error: {e}[/red]")

    total_time = time.time() - start_time
    mins, secs = divmod(total_time, 60)
    print("\n\n" + "="*70)

    if interrupted:
        console.print(f"[bold red]⚠️ [INTERVENSI BERHASIL][/bold red] [yellow]Kueri RAG dihentikan manual oleh Anda pada ({int(mins):02d}:{secs:04.1f}).[/yellow]\n")
    else:
        console.print(f"[dim italic]⏱️ Waktu respons: {int(mins):02d}:{secs:04.1f}[/dim italic]\n")

if __name__ == "__main__":
    main()