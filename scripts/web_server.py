#!/usr/bin/env python3
"""
=================================================================================
|                    S U L T R A B Y T E   A I   S T U D I O                    |
|               developer.haritsnb@gmail.com | Harits Nala Barrun               |
|-------------------------------------------------------------------------------|
|                Python Local Web Server & Local Disk Auto-Saver                |
|                           WEB GUI & Live Disk Sync                            |
=================================================================================
"""

import os
import sys
import re
import json
import time
import http.server
import socketserver
import urllib.parse
from rich.console import Console

console = Console()
PORT = 8000
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

try:
    from duckduckgo_search import DDGS
except ImportError:
    DDGS = None

def sanitize_search_query(raw_query):
    noise_patterns = [
        r'(?i)\b(tolong|coba|tolong carikan|carikan|cari|cek|search|browsing|googling)\b',
        r'(?i)\b(di internet|di web|di google|internet|online|terbaru|info)\b',
        r'[?,.!"]'
    ]
    cleaned = raw_query
    for pat in noise_patterns:
        cleaned = re.sub(pat, ' ', cleaned)
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    return cleaned if len(cleaned) >= 2 else raw_query

class StudioHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT_DIR, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)

        # ENDPOINT AUTO-SAVE SESSION LANGSUNG KE DISK LOKAL
        if parsed_url.path == "/api/save_session":
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            try:
                payload = json.loads(post_data.decode('utf-8'))
                session_id = payload.get("id", f"session_{int(time.time())}")
                messages = payload.get("messages", [])

                # Simpan ke folder vaults/default_repo/main/v1.0/knowledge/raw_markdown/
                context_file = os.path.join(ROOT_DIR, "active_context.json")
                ctx = {"repository": "default_repo", "branch": "main", "version": "v1.0"}
                if os.path.exists(context_file):
                    try:
                        with open(context_file, "r", encoding="utf-8") as f:
                            ctx = json.load(f)
                    except Exception:
                        pass

                save_dir = os.path.join(ROOT_DIR, "vaults", ctx.get("repository", "default_repo"), ctx.get("branch", "main"), ctx.get("version", "v1.0"), "knowledge", "raw_markdown")
                os.makedirs(save_dir, exist_ok=True)

                # Format Markdown Backup
                md_content = f"# SultraByte AI Studio Session: {session_id}\n\n"
                md_content += f"- **Timestamp**: {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
                md_content += f"- **Context**: {ctx.get('repository')} / {ctx.get('branch')} / {ctx.get('version')}\n\n---\n\n"

                for msg in messages:
                    role = msg.get("role", "user").upper()
                    content = msg.get("content", "")
                    thoughts = msg.get("thoughts", "")
                    
                    md_content += f"### [{role}]\n\n"
                    if thoughts:
                        md_content += f"> **Thought Process**:\n> {thoughts.replace(chr(10), chr(10) + '> ')}\n\n"
                    md_content += f"{content}\n\n---\n\n"

                target_file = os.path.join(save_dir, f"{session_id}.md")
                with open(target_file, "w", encoding="utf-8") as f:
                    f.write(md_content)

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "saved", "path": target_file, "time": time.strftime('%H:%M:%S')}).encode('utf-8'))
                return

            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode('utf-8'))
                return

        self.send_response(404)
        self.end_headers()

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)

        # 1. API LIVE SEARCH DENGAN SANITIZER
        if parsed_url.path == "/api/search":
            query_params = urllib.parse.parse_qs(parsed_url.query)
            raw_q = query_params.get("q", [""])[0].strip()
            
            if not raw_q:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Query 'q' kosong"}).encode('utf-8'))
                return

            clean_q = sanitize_search_query(raw_q)
            console.print(f"[bold cyan][Live Search][/bold cyan] Query: [bold yellow]'{clean_q}'[/bold yellow]")
            results = []

            if DDGS is not None:
                try:
                    with DDGS() as ddgs:
                        try:
                            raw_results = list(ddgs.text(clean_q, max_results=5))
                        except TypeError:
                            raw_results = list(ddgs.text(keywords=clean_q, max_results=5))

                        for r in raw_results:
                            results.append({
                                "title": r.get("title", ""),
                                "url": r.get("href", r.get("link", "")),
                                "snippet": r.get("body", r.get("snippet", ""))
                            })
                except Exception as e:
                    console.print(f"[yellow][!] Search engine exception: {e}[/yellow]")
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({"raw_query": raw_q, "clean_query": clean_q, "results": results}, ensure_ascii=False).encode('utf-8'))
            return

        # 2. API CONTEXT
        elif parsed_url.path == "/api/context":
            context_file = os.path.join(ROOT_DIR, "active_context.json")
            data = {"repository": "default_repo", "branch": "main", "version": "v1.0"}
            if os.path.exists(context_file):
                try:
                    with open(context_file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                except Exception:
                    pass
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode('utf-8'))
            return

        return super().do_GET()

    def log_message(self, format, *args):
        pass

def run_server():
    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("0.0.0.0", PORT), StudioHandler) as httpd:
            console.print(f"\n[bold green]================================================================[/bold green]")
            console.print(f"[bold white]  SULTRABYTE AI STUDIO - ADVANCED WORKSPACE (PORT {PORT})      [/bold white]")
            console.print(f"[bold green]================================================================[/bold green]")
            console.print(f"[*] Web GUI Portal         : [bold cyan]http://localhost:{PORT}[/bold cyan]")
            console.print(f"[*] Local Disk Auto-Saver  : [bold green]Active (Vault Markdown Sync)[/bold green]")
            console.print(f"[*] Tekan Ctrl+C untuk mematikan server.\n")
            httpd.serve_forever()
    except Exception as e:
        console.print(f"[bold red][X] Web Server Error: {e}[/bold red]")

if __name__ == "__main__":
    run_server()