#!/usr/bin/env python3
"""
=================================================================================
|                    S U L T R A B Y T E   A I   S T U D I O                    |
|               developer.haritsnb@gmail.com | Harits Nala Barrun               |
|-------------------------------------------------------------------------------|
|            Knowledge Vault RAG Ingestion Engine (Hardened Client)             |
=================================================================================
"""

import os
import sys
import json
import glob
import hashlib
import chromadb
import ollama
from rich.console import Console
from rich.progress import track

console = Console()
OLLAMA_HOST = "http://127.0.0.1:11434"
client = ollama.Client(host=OLLAMA_HOST)

def get_active_context(root_dir):
    context_file = os.path.join(root_dir, "active_context.json")
    if os.path.exists(context_file):
        try:
            with open(context_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"repository": "default_repo", "branch": "main", "version": "v1.0"}

def get_embedding(text):
    response = client.embeddings(model="nomic-embed-text", prompt=text)
    return response["embedding"]

def chunk_text(text, max_chunk_size=1000, overlap=150):
    chunks = []
    start = 0
    while start < len(text):
        end = start + max_chunk_size
        chunk = text[start:end]
        if chunk.strip():
            chunks.append(chunk.strip())
        start += max_chunk_size - overlap
    return chunks

def process_ai_studio_json(file_path):
    docs = []
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict) and "contents" in data:
                for item in data["contents"]:
                    role = item.get("role", "user")
                    parts = item.get("parts", [])
                    text_parts = [p.get("text", "") for p in parts if "text" in p]
                    full_text = f"[{role.upper()}]:\n" + "\n".join(text_parts)
                    docs.append(full_text)
            elif isinstance(data, list):
                for item in data:
                    text_content = json.dumps(item, ensure_ascii=False)
                    docs.append(text_content)
    except Exception as e:
        console.print(f"[red]Gagal memproses JSON {file_path}: {e}[/red]")
    return docs

def process_markdown_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return [f.read()]
    except Exception as e:
        console.print(f"[red]Gagal membaca Markdown {file_path}: {e}[/red]")
        return []

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    context = get_active_context(root_dir)
    
    vault_base = os.path.join(
        root_dir, "vaults", 
        context["repository"], context["branch"], context["version"], 
        "knowledge"
    )
    
    raw_ai_dir = os.path.join(vault_base, "raw_ai_studio")
    raw_md_dir = os.path.join(vault_base, "raw_markdown")
    db_dir = os.path.join(vault_base, "db")
    
    os.makedirs(raw_ai_dir, exist_ok=True)
    os.makedirs(raw_md_dir, exist_ok=True)
    os.makedirs(db_dir, exist_ok=True)
    
    console.print(f"\n[bold cyan]=== MEMULAI INGESTI KNOWLEDGE VAULT RAG ===[/bold cyan]")
    console.print(f"[dim]Konteks: {context['repository']} | {context['branch']} | {context['version']}[/dim]")
    console.print(f"[dim]Basis Data Vektor: {db_dir}[/dim]\n")
    
    chroma_client = chromadb.PersistentClient(path=db_dir)
    collection = chroma_client.get_or_create_collection(
        name="sultrabyte_knowledge",
        metadata={"hnsw:space": "cosine"}
    )
    
    json_files = glob.glob(os.path.join(raw_ai_dir, "*.json"))
    md_files = glob.glob(os.path.join(raw_md_dir, "*.md"))
    
    if not json_files and not md_files:
        console.print("[yellow][!] Tidak ada file .json di 'raw_ai_studio/' atau .md di 'raw_markdown/'.[/yellow]")
        console.print("[dim]Silakan letakkan dokumen Anda pada folder tersebut lalu jalankan kembali.[/dim]\n")
        return

    raw_documents = []
    for jf in json_files:
        console.print(f"[green]-> Memproses AI Studio JSON:[/green] {os.path.basename(jf)}")
        for text in process_ai_studio_json(jf):
            raw_documents.append({"source": os.path.basename(jf), "type": "ai_studio_json", "text": text})
            
    for mf in md_files:
        console.print(f"[green]-> Memproses Dokumen MD:[/green] {os.path.basename(mf)}")
        for text in process_markdown_file(mf):
            raw_documents.append({"source": os.path.basename(mf), "type": "markdown", "text": text})

    chunks_to_upsert = []
    for doc in raw_documents:
        chunks = chunk_text(doc["text"])
        for idx, ch in enumerate(chunks):
            chunk_id = hashlib.sha256(f"{doc['source']}_{idx}_{ch[:50]}".encode('utf-8')).hexdigest()[:16]
            chunks_to_upsert.append({
                "id": chunk_id,
                "text": ch,
                "metadata": {"source": doc["source"], "type": doc["type"], "chunk_index": idx}
            })
            
    console.print(f"\n[bold]Mengekstrak Vektor untuk {len(chunks_to_upsert)} Chunk via nomic-embed-text...[/bold]")
    
    for item in track(chunks_to_upsert, description="Vektorisasi"):
        emb = get_embedding(item["text"])
        collection.upsert(
            ids=[item["id"]],
            embeddings=[emb],
            documents=[item["text"]],
            metadatas=[item["metadata"]]
        )
        
    console.print(f"\n[bold green][✓] Sukses! {len(chunks_to_upsert)} pengetahuan baru berhasil disimpan ke ChromaDB.[/bold green]\n")

if __name__ == "__main__":
    main()