# AI_CONTEXT.md — edClipManager

> **WAJIB DIBACA SEBELUM MEMBERIKAN SARAN, KODE, ATAU KONFIGURASI**

---

## 1. Lingkungan Sistem

| Komponen | Detail |
|---|---|
| **OS** | Arch Linux |
| **Window Manager** | Hyprland |
| **Display Protocol** | Wayland |
| **Shell** | Bash |
| **Terminal** | Kitty |
| **Home Directory** | `/home/tobdeuc` |

---

## 2. Konfigurasi Hyprland

Aplikasi ini memodifikasi 3 file Hyprland saat instalasi. Setiap blok ditandai dengan komentar `# edClipManager-Begin` dan `# edClipManager-End`.

| Fungsi | File | Boleh Dimodifikasi oleh AI? |
|---|---|---|
| **Keybinding** | `~/.config/hypr/bindings.conf` | ✅ Ya — **HANYA di file ini** |
| **Autostart** | `~/.config/hypr/autostart.conf` | ✅ Ya — hanya blok edClipManager |
| **Window Rules** | `~/.config/hypr/hyprland.conf` | ⚠️ Hanya window rules blok edClipManager |

### Keybinding Aktif

```conf
# edClipManager-Begin
unbind = SUPER CTRL, V
bind = SUPER CTRL, V, exec, kitty --class edClipManager --title edClipManager --override close_on_child_death=yes -e edclipmanager
# edClipManager-End
```

### Autostart Aktif

```conf
# edClipManager-Begin
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
# edClipManager-End
```

### Window Rules Aktif

```conf
# edClipManager-Begin
windowrule = float on, match:title ^(edClipManager)$
windowrule = center on, match:title ^(edClipManager)$
windowrule = size 800 600, match:title ^(edClipManager)$
# edClipManager-End
```

### ⚠️ ATURAN KEYBINDING

- Jika ada fitur yang memerlukan shortcut/keybinding Hyprland, keybinding tersebut **HANYA BOLEH** ditulis di: `~/.config/hypr/bindings.conf`
- **DILARANG** menulis keybinding di `~/.config/hypr/hyprland.conf` — akan menyebabkan error di sistem ini.

---

## 3. Tentang Aplikasi

**edClipManager** adalah aplikasi TUI clipboard manager untuk Wayland yang menggunakan `cliphist` sebagai backend penyimpanan clipboard history.

### Fitur Utama

- Menampilkan clipboard history dari `cliphist` dalam antarmuka TUI
- Pencarian/filter real-time (ketik langsung tanpa mode khusus)
- Sistem pin: menyimpan item clipboard secara permanen ke file JSON
- Multi-select (mark) untuk operasi batch (pin/delete)
- Mendukung teks dan gambar (binary data)
- Copy item yang dipilih ke clipboard lalu otomatis keluar
- Delete individual, batch, atau wipe all
- Dua tab: Clipboard (history) dan Pin (tersimpan)
- Dialog konfirmasi untuk delete all
- Halaman help built-in
- Tema berbasis config TOML (Catppuccin-style)
- Install/uninstall script dengan integrasi Hyprland otomatis

### Keybinding Aplikasi (Internal TUI)

| Key | Fungsi |
|---|---|
| `Ctrl+j` / `Ctrl+k` | Navigasi atas/bawah |
| `↓` / `↑` | Navigasi atas/bawah |
| `Enter` | Copy item terpilih ke clipboard & keluar |
| `Ctrl+Space` | Toggle mark (multi-select) |
| `Ctrl+p` | Pin / unpin item (atau semua yang di-mark) |
| `Ctrl+d` | Delete item terpilih (atau semua yang di-mark) |
| `Ctrl+Alt+d` | Delete semua item di tab aktif (dengan konfirmasi) |
| `Tab` | Switch tab Clipboard / Pin |
| `Ctrl+h` | Toggle help |
| `Esc` / `q` | Keluar aplikasi (atau tutup dialog) |
| `←` / `→` | Geser kursor pencarian |
| `Backspace` / `Delete` | Hapus karakter pencarian |
| Ketik karakter | Filter pencarian (selalu aktif) |

---

## 4. Tech Stack

| Komponen | Detail |
|---|---|
| **Bahasa** | Rust (Edition 2021) |
| **Binary Name** | `edclipmanager` |
| **TUI Framework** | Ratatui 0.29 |
| **Terminal Backend** | Crossterm 0.28 |
| **Serialization** | serde 1 + serde_json 1 |
| **Config Parser** | toml 0.8 |
| **Directory Resolver** | dirs 5 |
| **Date/Time** | chrono 0.4 |

### Release Profile

```toml
[profile.release]
opt-level = "z"
lto = true
strip = true
```

---

## 5. System Dependencies (Wajib Terinstall)

| Package | Fungsi dalam Aplikasi |
|---|---|
| `cliphist` | Backend clipboard history (list, decode, delete, wipe) |
| `wl-copy` | Mengirim data ke Wayland clipboard |
| `wl-paste` | Monitor clipboard via `cliphist store` (autostart) |
| `kitty` | Terminal emulator untuk floating window |
| `hyprctl` | Reload konfigurasi Hyprland setelah install |

---

## 6. Struktur Proyek

```
edClipManager/
├── config/
│   └── config.toml              # Default config (theme + general settings)
├── scripts/
│   ├── install.sh               # Installer (build, binary, config, Hyprland integration)
│   └── uninstall.sh             # Uninstaller (cleanup semua yang di-install)
├── src/
│   ├── clipboard/
│   │   ├── mod.rs               # Module declaration
│   │   ├── cliphist.rs          # Interface ke cliphist CLI (list, decode, copy, delete, wipe)
│   │   └── pin.rs               # Pin storage (load/save JSON, pin/unpin, CRUD)
│   ├── config/
│   │   ├── mod.rs               # Config loader (TOML parser, path resolver)
│   │   └── theme.rs             # Hex color parser → ratatui Style/Color
│   ├── ui/
│   │   ├── mod.rs               # Layout utama (search + tabs + list + statusbar + dialog + help)
│   │   ├── search.rs            # Search box widget dengan cursor
│   │   ├── tabs.rs              # Tab switcher (Clipboard / Pin)
│   │   ├── list.rs              # List widget (items, selection, mark, pin indicator, truncation)
│   │   ├── statusbar.rs         # Status bar (keybinding hints + marked count)
│   │   ├── dialog.rs            # Dialog konfirmasi delete all
│   │   └── help.rs              # Halaman help (keybinding, paths, dependencies)
│   ├── app.rs                   # Application state & logic (filter, navigation, copy, pin, delete)
│   ├── event.rs                 # Event handler (keyboard input → app actions per mode)
│   └── main.rs                  # Entry point (terminal setup, main loop)
├── .gitignore
└── Cargo.toml
```

---

## 7. File Paths di Sistem

| Item | Path |
|---|---|
| **Binary** | `~/.local/bin/edclipmanager` |
| **Config** | `~/.config/edClipManager/config.toml` |
| **Pin Storage** | `~/.local/share/edClipManager/pins.json` |
| **Clipboard DB** | `~/.cache/cliphist/db` |
| **Hypr Keybinding** | `~/.config/hypr/bindings.conf` |
| **Hypr Autostart** | `~/.config/hypr/autostart.conf` |
| **Hypr Window Rules** | `~/.config/hypr/hyprland.conf` |

---

## 8. Application Modes

Aplikasi memiliki 3 mode yang ditangani di `event.rs`:

| Mode | Trigger | Behavior |
|---|---|---|
| `Normal` | Default | Navigasi, search, copy, pin, delete |
| `ConfirmDeleteAll` | `Ctrl+Alt+d` | Dialog yes/no, hanya terima `y`/`n`/`Esc` |
| `Help` | `Ctrl+h` | Tampilkan help, hanya terima `Esc`/`q`/`Ctrl+h` untuk keluar |

---

## 9. Arsitektur & Pola Kode

- **State terpusat:** Semua state aplikasi ada di `App` struct (`app.rs`)
- **Event-driven:** `event.rs` menangani input → memanggil method di `App`
- **UI stateless:** Semua widget di `ui/` hanya membaca `&App`, tidak mengubah state
- **External process:** Interaksi dengan `cliphist` dan `wl-copy` melalui `std::process::Command` dengan stdin pipe (menghindari shell injection)
- **Config cascade:** Load dari `~/.config/edClipManager/config.toml`, fallback ke embedded default (`include_str!`)
- **Pin independence:** Pin teks disimpan dengan konten lengkap (bukan hanya ID cliphist), sehingga tetap bisa di-copy meskipun history cliphist sudah terhapus

---

## 10. Gaya Bantuan yang Diinginkan

- **Prioritas utama:** Jika AI memiliki kemampuan membaca/menulis file secara langsung, lakukan itu langsung.
- **Jika tidak bisa:** AI harus memberi solusi dalam bentuk perintah terminal yang siap dijalankan (copy-paste-run). Gunakan:
  - `cat << 'EOF' > path/file` untuk membuat/mengganti file
  - `sed -i` untuk edit sebagian baris
  - `mkdir -p` untuk membuat direktori
  - Script `bash` atau `python` sekali jalan untuk perubahan kompleks
- **HINDARI** instruksi manual seperti "buka file ini lalu edit baris ke-50"
- Semua path file dalam command harus **relatif terhadap root proyek** kecuali file sistem (Hyprland config)

---

## 11. Aturan Keras (HARD RULES) — DILARANG DILANGGAR

- ❌ **DILARANG** berasumsi tentang isi file jika file belum diberikan
- ❌ **DILARANG** berasumsi tentang struktur proyek jika belum diberikan
- ❌ **DILARANG** menulis keybinding Hyprland ke `hyprland.conf` — harus ke `bindings.conf`
- ❌ **DILARANG** menyarankan tools berbasis X11 (`xdotool`, `xprop`, `xclip`, `xsel`) — sistem ini Wayland
- ❌ **DILARANG** memaksa workflow edit manual jika command terminal bisa diberikan
- ❌ **DILARANG** merombak arsitektur proyek tanpa izin eksplisit
- ❌ **DILARANG** menambahkan dependency baru ke `Cargo.toml` tanpa konfirmasi
- ❌ **DILARANG** mengubah release profile tanpa konfirmasi
- ❌ **DILARANG** mengabaikan konteks di file ini — jika ada konflik antara pengetahuan umum AI dan file ini, **IKUTI FILE INI**
- ✅ Jika ragu, **TANYAKAN** sebelum membuat perubahan
- ✅ Proyek ini sudah berjalan (v1). Tugas AI adalah **memperbaiki/mengembangkan**, bukan membangun ulang

---

## 12. Instruksi untuk AI di Sesi Baru

1. **BACA** seluruh konteks di atas sebelum memberikan saran apapun
2. **PAHAMI** struktur kode, arsitektur, dan pola yang sudah ada
3. **PATUHI** semua aturan keras di Bagian 11
4. **GUNAKAN** hanya tools Wayland yang tersedia di Bagian 5
5. **SESUAIKAN** semua path dengan yang tertulis di Bagian 7
6. **BERIKAN** solusi dalam format command terminal siap eksekusi (Bagian 10)
7. Jika konteks kode belum cukup, **MINTA** file yang dibutuhkan secara spesifik — jangan menebak
---
