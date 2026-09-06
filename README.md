# 🌌 SultraByte AI Studio — Enterprise Local AI & RAG Engine

> **Private, Drive-Agnostic, Reinstall-Proof, and GPU-Accelerated Local AI Development Station**  
> *Architected & Engineered by: Harits Nala Barrun*

---

## 📑 DAFTAR ISI

1. [Executive Summary & Filosofi Desain](#1-executive-summary--filosofi-desain)
2. [Matriks Alokasi Perangkat Keras (Hardware Workload Allocation)](#2-matriks-alokasi-perangkat-keras-hardware-workload-allocation)
3. [Arsitektur Struktur Direktori Portabel (Drive-Agnostic)](#3-arsitektur-struktur-direktori-portabel-drive-agnostic)
4. [Panduan Instalasi & Menjalankan (2 Metode Utama)](#4-panduan-instalasi--menjalankan-2-metode-utama)
   - [Metode A: Clone dari GitHub Repository](#metode-a-clone-dari-github-repository)
   - [Metode B: Ekstraksi File Portabel (.ZIP Archive)](#metode-b-ekstraksi-file-portabel-zip-archive)
5. [Spesifikasi Fitur & Modul Utama](#5-spesifikasi-fitur--modul-utama)
   - [5.1 Gateway & Smart Validator (`setup.bat` & `file-requirement.ps1`)](#51-gateway--smart-validator-setupbat--file-requirementps1)
   - [5.2 Master Router & Terminal HUD (`vault_manager.ps1`)](#52-master-router--terminal-hud-vault_managerps1)
   - [5.3 Sinergi Dual-Mind Chamber (`dual_mind.py`)](#53-sinergi-dual-mind-chamber-dual_mindpy)
   - [5.4 Knowledge Vault RAG Engine (`ingest_vault.py` & `ask_vault.py`)](#54-knowledge-vault-rag-engine-ingest_vaultpy--ask_vaultpy)
   - [5.5 Web GUI Studio Client — Google AI Studio Edition (`index.html` & `web_server.py`)](#55-web-gui-studio-client--google-ai-studio-edition-indexhtml--web_serverpy)
   - [5.6 Fitur Intervensi Real-Time (Human-in-the-Loop Intervention)](#56-fitur-intervensi-real-time-human-in-the-loop-intervention)
   - [5.7 Deep System, Hardware & Runtime Inspector (`run_sysinfo.ps1`)](#57-deep-system-hardware--runtime-inspector-run_sysinfops1)
   - [5.8 Neural Bridge Interconnect — Laptop to VPS Deploy (`deploy_to_vps.ps1`)](#58-neural-bridge-interconnect--laptop-to-vps-deploy-deploy_to_vpsps1)
6. [SOP Backup, Kompresi Portabel, & Disaster Recovery](#6-sop-backup-kompresi-portabel--disaster-recovery)
7. [Panduan Pemecahan Masalah (Troubleshooting & FAQ)](#7-panduan-pemecahan-masalah-troubleshooting--faq)

---

## 1. EXECUTIVE SUMMARY & FILOSOFI DESAIN

**SultraByte AI Studio** adalah stasiun kerja kecerdasan buatan privat yang berjalan 100% secara lokal pada perangkat fisik pengembang (*On-Premise Local Machine*). Studio ini dirancang untuk menghilangkan ketergantungan pada API komersial berbayar, menjamin privasi data kode sumber (*Zero Data Leakage*), dan memberikan kecepatan komputasi maksimal dengan akselerasi perangkat keras GPU.

### 4 Pilar Fondasi Desain:
1. **Drive-Agnostic Portability**: Sistem tidak mengikat *hardcoded drive path* (seperti `C:\`). Seluruh skrip menggunakan referensi direktori relatif (`%~dp0` dan `$PSScriptRoot`), sehingga bebas diletakkan di partisi `D:\`, `E:\`, atau SSD Eksternal tanpa perlu konfigurasi ulang.
2. **Reinstall-Proof Architecture**: Jika Windows 11 Anda diformat ulang, cukup salin kembali folder `sultrabyte-ai-studio` dan klik ganda `setup.bat`. Seluruh dependensi, konfigurasi environment variable, dan database vektor pulih dalam waktu kurang dari 2 menit.
3. **Zero-Garbage Policy**: Setiap file instalasi biner (`.exe`, `.msi`) yang diunduh secara otomatis ke dalam folder sementara `bin/` langsung dihapus seketika setelah instalasi *silent* selesai guna menghemat ruang penyimpanan SSD.
4. **Active Real-Time Feedback**: Setiap proses komputasi yang memakan waktu (pencarian web, ekstraksi embedding, kompilasi kode, hingga pembacaan daftar model) dilengkapi dengan animasi **Live Stopwatch `[mm:ss.f]`** dan **Intervensi Instan (Esc / q)**.

---

## 2. MATRIKS ALOKASI PERANGKAT KERAS (HARDWARE WORKLOAD ALLOCATION)

Sistem telah dioptimasi secara spesifik untuk hardware **Acer Nitro 5 (Windows 11)**:

| Komponen Hardware | Spesifikasi Fisik | Alokasi Beban Komputasi AI Studio |
| :--- | :--- | :--- |
| **GPU Dedicated** | **NVIDIA RTX 3050 (4 GB VRAM)** | Menampung 100% layer model `nomic-embed-text`, `hermes3:8b`, serta meng-offload $\approx 18\text{--}22$ layer terberat `qwen2.5-coder:14b` via akselerasi CUDA. |
| **System Memory** | **32 GB RAM DDR4** | Menampung sisa layer model 14B dan *KV Cache* kontekstual hingga 32k window context. Menyisakan $\approx 23\text{ GB}$ RAM bebas untuk OS, Docker, dan IDE. |
| **Processor (CPU)**| Multi-Core High Performance | Menjalankan *background daemon* Ollama, Python Web Server Port 8000, dan parser vektor ChromaDB. |
| **Penyimpanan** | **NVMe PCIe SSD** | Partisi non-sistem menampung bobot model di `models/` dan basis data vektor persisten di `vaults/`. |

---

## 3. ARSITEKTUR STRUKTUR DIREKTORI PORTABEL (DRIVE-AGNOSTIC)

```text
sultrabyte-ai-studio/                                  <-- Root Direktori Portabel
├── .gitignore                              <-- Mencegah commit models/, vaults/, flag ke Git
├── setup.bat                               <-- Single Entry Point (Auto UAC Admin Elevation)
├── README.md                               <-- Dokumentasi Master Teknis Sistem
├── index.html                              <-- Web GUI Client (Google AI Studio Enterprise Edition)
├── active_context.json                     <-- Pointer State (Repository, Branch, Version aktif)
├── net_lock.flag                           <-- Flag penanda mode Air-Gapped Privacy
├── bin/                                    <-- Folder sementara installer biner (Auto-Purged)
├── models/                                 <-- [DI-GITIGNORE] Penyimpanan bobot neural Ollama
├── vaults/                                 <-- [DI-GITIGNORE] Basis Data Vektor RAG & Workspace
│   └── <repository>/
│       └── <branch>/
│           └── <version>/
│               ├── knowledge/
│               │   ├── raw_ai_studio/      <-- File JSON riwayat chat Google AI Studio
│               │   ├── raw_markdown/       <-- File dokumen spesifikasi teknis (.md)
│               │   └── db/                 <-- ChromaDB Persistent Vector Storage
│               └── workspace/              <-- Ruang kerja file koding proyek aktif
└── scripts/                                <-- Engine Inti & Modular Microservices
    ├── file-requirement.ps1                <-- Smart Validator & Auto-Installer (Live Stopwatch)
    ├── vault_manager.ps1                   <-- Master Router TUI HUD & Hardware Prober
    ├── ingest_vault.py                     <-- Mesin Vektorisasi RAG (Embedding Chunking)
    ├── ask_vault.py                        <-- Mesin Kueri Temu-Kembali RAG & Cosine Search
    ├── web_server.py                       <-- Python Server Port 8000, Search Proxy, & Auto-Saver
    ├── dual_mind.py                        <-- Sinergi Dual-Mind (Hermes 3 + Qwen 14B)
    └── services/                           <-- Microservice Runners Terisolasi
        ├── run_qwen.ps1                    <-- Runner sesi Qwen 2.5 Coder 14B
        ├── run_hermes.ps1                  <-- Runner sesi Hermes 3 8B
        ├── run_ingest.ps1                  <-- Runner Ingest Vault
        ├── run_ask.ps1                     <-- Runner Ask Vault
        ├── run_dual.ps1                    <-- Runner Dual-Mind Chamber
        ├── run_context.ps1                 <-- Runner Context Manager (CRUD Repo/Branch/Ver)
        ├── run_export.ps1                  <-- Runner Ekspor Backup Portabel (.ZIP)
        ├── run_sysinfo.ps1                 <-- Runner Deep System & Hardware Inspector
        └── deploy_to_vps.ps1               <-- Runner Remote VPS Deployment Bridge
```

---

## 4. PANDUAN INSTALASI & MENJALANKAN (2 METODE UTAMA)

### METODE A: Clone dari GitHub Repository

Gunakan metode ini jika Anda tidak memiliki file portable-nya:

- Clone project dari repositori dengan menjalankan script berikut di terminal.
```
git clone https://github.com/haritsnb/sultrabyte-ai-studio.git
```
- Cari file `setup.bat` lalu klik 2x

> **Apa yang terjadi selanjutnya?**
> 1. `setup.bat` meminta konfirmasi Administrator UAC secara otomatis.
> 2. `file-requirement.ps1` memverifikasi koneksi internet. Jika Python 3.12+ atau Ollama belum terpasang, installer resmi akan diunduh ke `bin/`, dipasang secara *silent*, lalu filenya langsung dihapus.
> 3. Seluruh environment variable (`OLLAMA_MODELS`, `OLLAMA_HOST=0.0.0.0:11434`, `OLLAMA_ORIGINS=*`) dikunci secara permanen ke folder lokal Anda.
> 4. Model `qwen2.5-coder:14b`, `hermes3:8b`, dan `nomic-embed-text` diunduh otomatis jika belum ada di folder `models/`.
> 5. Antarmuka **Master Router TUI HUD** langsung terbuka di terminal Anda.

---

### METODE B: Ekstraksi File Portabel (.ZIP Archive)

Gunakan metode ini untuk memindahkan studio antar perangkat atau pemulihan kilat pasca-format OS tanpa perlu mengunduh ulang source code:

1. **Ekstraksi Arsip**:
   - Salin file `SultraByte_AI_Studio_Export_YYYYMMDD.zip` ke partisi pilihan Anda (misalnya `D:\` atau `E:\`).
   - Ekstrak file `.zip` tersebut sehingga menghasilkan folder `D:\sultrabyte-ai-studio`.
2. **Pindahkan Folder Models (Opsional namun Dianjurkan)**:
   - Jika Anda memiliki backup folder `models/` (berisi bobot puluhan gigabyte), cukup letakkan folder `models/` tersebut langsung di dalam `D:\sultrabyte-ai-studio\models\`.
3. **Eksekusi Sekali Klik**:
   - Klik ganda file **`D:\sultrabyte-ai-studio\setup.bat`**.
   - Sistem akan memvalidasi *path* drive baru, mendaftarkan *environment variables* lokal ke OS baru, mengaktifkan background daemon Ollama, dan membuka TUI Dashboard dalam waktu **< 10 detik**!

---

## 5. SPESIFIKASI FITUR & MODUL UTAMA

### 5.1 Gateway & Smart Validator (`setup.bat` & `file-requirement.ps1`)
- **Self-Elevating Admin**: Memastikan skrip selalu berjalan dengan hak akses administrator penuh tanpa perlu klik kanan *Run as Administrator*.
- **Zero-Freeze Live Stopwatch**: Menampilkan timer `[mm:ss.f]` aktif dan *spinner* pada setiap tahapan (uji internet, instalasi pip, pendaftaran environment variable, dan polling kesiapan Ollama API).
- **Zero-Garbage Policy**: Menjamin folder `bin/` selalu bersih dari sisa file installer pasca-eksekusi.

### 5.2 Master Router & Terminal HUD (`vault_manager.ps1`)
- **Real-Time Dynamic Hardware Probing**: Membaca sensor *WMI / CIM* secara langsung untuk mendeteksi seri laptop asli, alokasi VRAM GPU NVIDIA RTX 3050, total kapasitas fisik RAM DDR4/DDR5, status Tailscale Mesh VPN (`100.x.y.z`), status Web GUI Port 8000, dan Net-Lock status.
- **Interactive Switch Router**: Mengatur eksekusi seluruh layanan mikro secara terisolasi tanpa saling tumpang tindih.

### 5.3 Sinergi Dual-Mind Chamber (`dual_mind.py`)
- Kolaborasi terpadu dua model spesialis:
  1. **Fase 1 (Arsitek)**: **Hermes 3 (8B)** menganalisis kebutuhan teknis dan merancang cetak biru arsitektur modular (*System Design & Design Patterns*).
  2. **Fase 2 (Programmer)**: **Qwen 2.5 Coder (14B)** menerima cetak biru tersebut dan menuliskan seluruh kode implementasi produksi yang *type-safe*, bersih, dan tanpa *placeholder*.
- Dilengkapi **Live Stopwatch Inferensi** dan **Human-in-the-loop Intervention**.

### 5.4 Knowledge Vault RAG Engine (`ingest_vault.py` & `ask_vault.py`)
- **Multi-Source Vector Ingestion**: Membaca file JSON ekspor Google AI Studio dan file Markdown (`.md`), melakukan *chunking* adaptif (1000 karakter, overlap 150), mengekstrak vektor 768-dimensi via `nomic-embed-text`, dan menyimpannya ke **ChromaDB**.
- **Context Retrieval Query**: Melakukan *Cosine Similarity Search* 4 dokumen teratas dan menyuapkannya ke model LLM lokal untuk menjawab kueri berdasarkan riwayat proyek masa lalu Anda.

### 5.5 Web GUI Studio Client — Google AI Studio Edition (`index.html` & `web_server.py`)
- **Google AI Studio Dark Theme UI**: Antarmuka visual bergaya Google AI Studio / Gemini dengan layout responsif.
- **Smart Search Query Sanitizer**: Membersihkan kata percakapan (*"cek di internet"*, *"tolong cari"*, dll) secara otomatis di backend Python sebelum dilempar ke search engine, mencegah kesalahan pencarian kata kunci.
- **Real-Time Thought Process Accordion**: Mengalirkan penalaran internal model `<think>...</think>` ke dalam kartu akordeon interaktif secara *real-time* tanpa merusak format DOM HTML.
- **Grounded Citation Badges**: Menampilkan *pills/chips* tautan referensi web yang dapat diklik langsung.
- **Local Disk Auto-Save & Manual Export**: Setiap percakapan otomatis disimpan ke `localStorage` dan disinkronkan ke folder vault di disk lokal (`/api/save_session`), serta menyediakan tombol ekspor instan ke `.md` (Markdown).
- **Jump to Request Navigator**: Dropdown navigasi untuk melompat instan ke pertanyaan mana pun.
- **Auto-Scroll Controller**: Tombol kendali *Auto-Scroll ON/OFF* saat teks sedang mengalir.

### 5.6 Fitur Intervensi Real-Time (Human-in-the-Loop Intervention)
- **Web GUI**: Tombol kirim berubah menjadi **`Intervensi AI (Esc)`** berwarna merah berkedip saat AI sedang berpikir/merespon. Cukup klik tombol tersebut atau tekan tombol **`Escape`** pada keyboard untuk membatalkan proses seketika tanpa *hang*.
- **Terminal CLI**: Pada `dual_mind.py` dan `ask_vault.py`, tekan tombol **`Esc`**, **`Ctrl+C`**, atau huruf **`q`** kapan saja saat AI sedang men-stream token untuk menghentikan respon secara mulus (*graceful exit*).

### 5.7 Deep System, Hardware & Runtime Inspector (`run_sysinfo.ps1`)
- Pilihan Menu **`[11]`** pada Master Router yang menyajikan telemetri mendalam:
  - **Hardware**: CPU Cores/Threads/Clock, RAM Used/Free/Speed MHz, GPU Driver/VRAM/Suhu real-time.
  - **Ollama**: PID daemon, RAM Working Set, status port, active model di VRAM, dan tabel detail seluruh model neural (Ukuran GB, Parameter, Kuantisasi `Q4_K_M`, Family).
  - **Python & PIP**: Lokasi biner dan status versi 9 pustaka inti data science.
  - **Knowledge Vault**: Jumlah dokumen JSON/MD dan ukuran database ChromaDB (MB).

### 5.8 Neural Bridge Interconnect — Laptop to VPS Deploy (`deploy_to_vps.ps1`)
- Pilihan Menu **`[10]`** yang memungkinkan Anda mendeploy kode dari workspace lokal laptop langsung ke server VPS **Agent DevOps** via jaringan privat **Tailscale Mesh (Port 9124)** tanpa perlu membuka terminal SSH manual.

---

## 6. SOP BACKUP, KOMPRESI PORTABEL, & DISASTER RECOVERY

### 1. SOP Backup Harian / Pembuatan File Portabel (.ZIP)
1. Buka Master Router TUI (`setup.bat`).
2. Pilih menu **`[8] Ekspor Studio ke File .ZIP Portabel`**.
3. Skrip `run_export.ps1` secara otomatis memaketkan seluruh skrip, web GUI, konfigurasi, dan basis data pengetahuan RAG ke dalam satu file arsip `SultraByte_AI_Studio_Export_YYYYMMDD_HHMMSS.zip` (folder biner `models/` dan `bin/` dikecualikan agar ukuran file zip tetap ringkas $\approx 10\text{--}50\text{ MB}$).

### 2. SOP Pemulihan Bencana Kilat (Disaster Recovery < 2 Menit)
Jika laptop mengalami kerusakan sistem operasi atau diganti dengan unit PC baru:
1. Pasang Windows 11 bersih.
2. Salin folder `models/` dan ekstrak file `.zip` hasil backup ke partisi `D:\sultrabyte-ai-studio`.
3. Klik ganda **`setup.bat`**.
4. Seluruh lingkungan AI Studio langsung aktif kembali secara utuh beserta seluruh memori RAG tanpa konfigurasi manual yang rumit!

---

## 7. PANDUAN PEMECAHAN MASALAH (TROUBLESHOOTING & FAQ)

#### Q1: Muncul error `WinError 10049: The requested address is not valid in its context` saat menjalankan Dual-Mind.
- **Penyebab**: Klien Python mencoba menghubungi `0.0.0.0:11434` sebagai alamat tujuan keluar (Winsock Windows melarang koneksi keluar ke `0.0.0.0`).
- **Solusi**: Seluruh skrip Python (`dual_mind.py`, `ask_vault.py`, `ingest_vault.py`) telah dikunci menggunakan klien eksplisit `ollama.Client(host='http://127.0.0.1:11434')`. Pastikan Anda menggunakan berkas skrip versi termutakhir.

#### Q2: Web GUI `localhost:8000` menampilkan `ERR_CONNECTION_REFUSED`.
- **Penyebab**: Server Python belum berjalan atau sebelumnya tertutup.
- **Solusi**: Buka Master Router TUI dan pilih menu **`[6]`**. Sistem akan memeriksa status port 8000 secara otomatis, meluncurkan `web_server.py`, menunggu hingga port siap, dan otomatis membuka browser.

#### Q3: Muncul error PowerShell `TerminatorExpectedAtEndOfString` pada Windows PowerShell 5.1.
- **Penyebab**: Karakter multibyte Unicode (seperti tanda centang `✓` atau em-dash `—`) terbaca sebagai ANSI oleh parser PowerShell default tanpa UTF-8 BOM.
- **Solusi**: Seluruh file `.ps1` telah distandarisasi menggunakan **100% Pure ASCII (7-bit)** yang kebal terhadap segala bentuk encoding parser error.

#### Q4: Bagaimana cara mengaktifkan Mode Air-Gapped (Privasi Mutlak Tanpa Internet)?
- Buka Master Router TUI dan pilih menu **`[9] Toggle Net-Lock`**.
- Status HUD akan berubah menjadi `LOCKED (Air-Gapped)`. Seluruh inferensi AI lokal, Dual-Mind, dan RAG tetap berjalan 100% tanpa menyentuh koneksi internet luar.

---

## 📜 KREDIT & LISENSI

- **Sistem**: SultraByte Enterprise Hybrid AI Infrastructure
- **Arsitek & Pengembang**: Harits Nala Barrun
- **Lisensi**: Proprietary / Private Enterprise Use Only