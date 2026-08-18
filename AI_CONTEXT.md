# AI_CONTEXT.md — edClipManager

> **WAJIB DIBACA SEBELUM MEMBERIKAN SARAN, KODE, ATAU KONFIGURASI**

---

## 1. Lingkungan Sistem

| Komponen | Detail |
|---|---|
| **OS** | Omarchy (Arch-based Linux) |
| **Kernel** | `7.1.8-arch1-3` |
| **Window Manager** | Hyprland `v0.56.2` |
| **Display Protocol** | Wayland |
| **Shell** | Bash |
| **Terminal** | Kitty |
| **User** | `tobdeuc` |
| **Home Directory** | `/home/tobdeuc` |

---

## 2. Cara User Memberikan Konteks ke AI

Repository ini memakai dua sumber konteks utama saat sesi AI baru:

1. **`AI_CONTEXT.md`** → aturan sistem, arsitektur, hard rules, preferensi bantuan
2. **`repomix-output.xml`** → snapshot isi repository

### Penting
- File **`AI_CONTEXT.md` sengaja tidak dimasukkan** ke `repomix-output.xml`
- Repository memakai **`.repomixignore`** agar `AI_CONTEXT.md` tetap ikut dipush ke git, tetapi tidak ikut dipaketkan oleh Repomix
- Karena itu, pada sesi AI baru, user biasanya akan:
  1. paste `AI_CONTEXT.md` lebih dulu
  2. lalu paste `repomix-output.xml`

### Implikasi untuk AI
- **Jangan** menganggap `repomix-output.xml` sudah memuat konteks sistem
- **Selalu prioritaskan isi `AI_CONTEXT.md` ini** jika diberikan bersamaan dengan repomix

---

## 3. Konfigurasi Hyprland

### File Hyprland yang relevan di sistem ini

| Fungsi | File | Boleh Dimodifikasi oleh AI? |
|---|---|---|
| **Keybinding** | `~/.config/hypr/bindings.conf` | ✅ Ya — **HANYA di file ini** |
| **Autostart** | `~/.config/hypr/autostart.conf` | ✅ Ya — hanya blok `edClipManager` |
| **Window Rules** | `~/.config/hypr/hyprland.conf` | ⚠️ Hanya blok `edClipManager` |

### Aturan keybinding Hyprland
- Jika ada fitur yang memerlukan shortcut/keybinding Hyprland, keybinding tersebut **HANYA BOLEH** ditulis di:
  - `~/.config/hypr/bindings.conf`
- **DILARANG** menulis keybinding ke:
  - `~/.config/hypr/hyprland.conf`

### Managed block yang digunakan installer (`.conf` mode)

#### Keybinding
```conf
# edClipManager-Begin
unbind = SUPER CTRL, V
bind = SUPER CTRL, V, exec, kitty --class edClipManager --title edClipManager --override close_on_child_death=yes -e /home/tobdeuc/.local/bin/edclipmanager
# edClipManager-End
```

#### Autostart
```conf
# edClipManager-Begin
exec-once = /home/tobdeuc/.local/bin/edclipmanager-cliphist-watch
# edClipManager-End
```

#### Window rules
```conf
# edClipManager-Begin
windowrule = float on, match:title ^(edClipManager)$
windowrule = center on, match:title ^(edClipManager)$
windowrule = size 800 600, match:title ^(edClipManager)$
# edClipManager-End
```

### Catatan
- Script installer/uninstaller juga mendukung layout Hyprland berbasis **`.lua` / Omarchy**
- Namun, **untuk sistem user ini**, default path yang harus diprioritaskan adalah file `.conf` di atas **kecuali user memberikan file live lain secara eksplisit**

---

## 4. Tentang Aplikasi

**edClipManager** adalah aplikasi TUI clipboard manager untuk Wayland yang menggunakan `cliphist` sebagai backend clipboard history.

### Fitur Utama
- Menampilkan clipboard history dari `cliphist`
- Pencarian/filter real-time tanpa mode khusus
- Dua tab: **Clipboard** dan **Pin**
- Multi-select (mark) untuk operasi batch
- Mendukung teks dan gambar
- Copy item terpilih ke clipboard lalu otomatis keluar
- Delete individual, batch, atau wipe all
- Dialog konfirmasi untuk delete all
- Built-in help screen
- Tema berbasis config TOML
- Installer dan uninstaller dengan integrasi Hyprland
- Mendukung layout Hyprland `.conf` dan `.lua`
- **Pin disort dari terbaru ke terlama** berdasarkan `pinned_at`

### Perilaku pin yang penting
- Saat user menekan `Ctrl+p`, item akan dipin/unpin
- Untuk item teks, pin menyimpan **konten lengkap**, bukan hanya preview dari `cliphist list`
- Tab **Pin** harus menampilkan item **terbaru di atas**
- Sorting pin mengandalkan field `pinned_at`

---

## 5. Tech Stack

| Komponen | Detail |
|---|---|
| **Bahasa** | Rust (Edition 2021) |
| **Binary Name** | `edclipmanager` |
| **TUI Framework** | Ratatui `0.29` |
| **Terminal Backend** | Crossterm `0.28` |
| **Serialization** | `serde` + `serde_json` |
| **Config Parser** | `toml` |
| **Directory Resolver** | `dirs` |
| **Date/Time** | `chrono` |

### Release profile
```toml
[profile.release]
opt-level = "z"
lto = true
strip = true
```

---

## 6. System Dependencies

### Wajib untuk aplikasi
| Package | Fungsi |
|---|---|
| `cliphist` | Backend clipboard history |
| `wl-copy` | Mengirim data ke Wayland clipboard |
| `wl-paste` | Watch clipboard untuk `cliphist store` |
| `kitty` | Terminal launcher untuk floating window |
| `hyprctl` | Reload konfigurasi Hyprland |

### Tool sistem lain yang boleh diasumsikan ada
- `grim`
- `slurp`
- `fuzzel`
- `notify-send`

### Larangan penting
Walaupun beberapa tool X11 mungkin terinstall di sistem, **AI tetap dilarang menyarankan tool X11** untuk proyek ini.

---

## 7. Struktur Proyek

```text
edClipManager/
├── AI_CONTEXT.md
├── Cargo.lock
├── Cargo.toml
├── README.md
├── .gitignore
├── .repomixignore
├── config/
│   └── config.toml
├── scripts/
│   ├── install.sh
│   └── uninstall.sh
└── src/
    ├── app.rs
    ├── clipboard/
    │   ├── cliphist.rs
    │   ├── mod.rs
    │   └── pin.rs
    ├── config/
    │   ├── mod.rs
    │   └── theme.rs
    ├── event.rs
    ├── main.rs
    └── ui/
        ├── dialog.rs
        ├── help.rs
        ├── list.rs
        ├── mod.rs
        ├── search.rs
        ├── statusbar.rs
        └── tabs.rs
```

---

## 8. File Paths di Sistem

| Item | Path |
|---|---|
| **Binary** | `~/.local/bin/edclipmanager` |
| **Watcher Helper** | `~/.local/bin/edclipmanager-cliphist-watch` |
| **Config** | `~/.config/edClipManager/config.toml` |
| **Pin Storage** | `~/.local/share/edClipManager/pins.json` |
| **Clipboard DB** | `~/.cache/cliphist/db` |
| **Hypr Keybinding** | `~/.config/hypr/bindings.conf` |
| **Hypr Autostart** | `~/.config/hypr/autostart.conf` |
| **Hypr Window Rules** | `~/.config/hypr/hyprland.conf` |

### Path Hyprland alternatif yang didukung script
| Item | `.lua` mode |
|---|---|
| **Autostart** | `~/.config/hypr/autostart.lua` |
| **Keybinding** | `~/.config/hypr/bindings.lua` |
| **Window Rules** | `~/.config/hypr/looknfeel.lua` |

---

## 9. Application Modes

Aplikasi memiliki 3 mode utama yang ditangani di `src/event.rs`:

| Mode | Trigger | Behavior |
|---|---|---|
| `Normal` | Default | Navigasi, search, copy, pin, delete |
| `ConfirmDeleteAll` | `Ctrl+Alt+d` | Dialog yes/no, hanya terima `y`/`n`/`Esc` |
| `Help` | `Ctrl+h` | Menampilkan help, hanya menerima input untuk keluar |

---

## 10. Keybinding Aplikasi (Internal TUI)

| Key | Fungsi |
|---|---|
| `Ctrl+j` / `Ctrl+k` | Navigasi bawah / atas |
| `↓` / `↑` | Navigasi bawah / atas |
| `Enter` | Copy item terpilih ke clipboard lalu keluar |
| `Ctrl+Space` | Toggle mark |
| `Ctrl+p` | Pin / unpin item terpilih atau semua yang di-mark |
| `Ctrl+d` | Delete item terpilih atau semua yang di-mark |
| `Ctrl+Alt+d` | Delete semua item di tab aktif |
| `Tab` | Switch tab Clipboard / Pin |
| `Ctrl+h` | Toggle help |
| `Esc` / `q` | Keluar aplikasi atau menutup dialog/help |
| `←` / `→` | Geser cursor search |
| `Backspace` / `Delete` | Hapus karakter search |
| Ketik karakter | Filter/search selalu aktif |

### Launcher global Hyprland
| Key | Fungsi |
|---|---|
| `Super + Ctrl + V` | Membuka `edclipmanager` di Kitty |

---

## 11. Arsitektur & Pola Kode

- **State terpusat:** semua state aplikasi ada di `App` (`src/app.rs`)
- **Event-driven:** `src/event.rs` menangani input lalu memanggil method di `App`
- **UI stateless:** modul di `src/ui/` hanya membaca `&App`, tidak mengubah state
- **External process:** interaksi dengan `cliphist` dan `wl-copy` memakai `std::process::Command`
- **No shell injection:** operasi clipboard ditulis dengan pipe/process langsung, bukan `sh -c`
- **Config cascade:** load dari `~/.config/edClipManager/config.toml`, fallback ke default embedded via `include_str!`
- **Pin independence:**
  - pin teks disimpan dengan konten penuh sehingga tetap bisa di-copy walau history `cliphist` hilang
  - pin gambar masih bergantung pada `cliphist_id` untuk restore binary data
- **Pin ordering:** `PinStorage` memelihara urutan pin terbaru ke terlama melalui `pinned_at`

---

## 12. Perilaku Kode yang Perlu Diketahui AI

### `src/clipboard/cliphist.rs`
- `cliphist list` dipakai untuk memuat history
- `cliphist decode` dipakai untuk memulihkan isi penuh
- `wl-copy` dipakai untuk menulis kembali ke clipboard
- delete item dilakukan lewat stdin pipe ke `cliphist delete`
- wipe all memakai `cliphist wipe`

### `src/clipboard/pin.rs`
- `PinnedItem` memiliki field:
  - `cliphist_id`
  - `content`
  - `is_image`
  - `image_size`
  - `pinned_at`
- Saat load, pin disort **descending** berdasarkan `pinned_at`
- Saat pin baru ditambahkan, item baru diletakkan di urutan paling atas

### `src/app.rs`
- `copy_selected_and_quit()` memiliki logika berbeda untuk tab Clipboard vs Pin
- Clipboard tab:
  - copy selalu lewat `cliphist decode`
- Pin tab:
  - teks memakai konten tersimpan
  - gambar tetap memakai `cliphist decode`

---

## 13. Gaya Bantuan yang Diinginkan

### Prioritas bantuan
1. Jika AI bisa membaca/menulis file langsung, lakukan itu
2. Jika tidak bisa, berikan **perintah terminal yang siap dijalankan**
3. Hindari instruksi edit manual yang menyuruh user membuka editor dan mengubah baris tertentu

### Format command yang diinginkan
- `cat << 'EOF' > path/file` untuk membuat atau mengganti file
- `sed -i` untuk edit kecil
- `mkdir -p` untuk direktori
- script `bash` atau `python` sekali jalan untuk perubahan kompleks

### Aturan path
- Semua path command harus **relatif terhadap root proyek**
- Kecuali file sistem seperti config Hyprland di `~/.config/hypr/...`

### Cara menyajikan patch
- Jika perubahan kecil dan aman, boleh patch 1 file penuh dengan heredoc
- Jika perubahan menyentuh banyak file, sajikan per file dengan command terpisah
- Jangan menyajikan pseudo-code; sajikan kode final

---

## 14. Aturan Keras (HARD RULES) — DILARANG DILANGGAR

- ❌ **DILARANG** berasumsi tentang isi file jika file belum diberikan
- ❌ **DILARANG** berasumsi tentang struktur proyek jika belum diberikan
- ❌ **DILARANG** menulis keybinding Hyprland ke `hyprland.conf` — harus ke `bindings.conf`
- ❌ **DILARANG** menyarankan tool berbasis X11 seperti:
  - `xdotool`
  - `xprop`
  - `xclip`
  - `xsel`
- ❌ **DILARANG** memaksa workflow edit manual jika command terminal bisa diberikan
- ❌ **DILARANG** merombak arsitektur proyek tanpa izin eksplisit
- ❌ **DILARANG** menambahkan dependency baru ke `Cargo.toml` tanpa konfirmasi
- ❌ **DILARANG** mengubah release profile tanpa konfirmasi
- ❌ **DILARANG** mengabaikan konteks Wayland/Hyprland/Omarchy pada file ini
- ❌ **DILARANG** menganggap `AI_CONTEXT.md` sudah ada di dalam `repomix-output.xml`
- ✅ Jika ragu, **TANYAKAN**
- ✅ Proyek ini sudah berjalan (v1.x). Tugas AI adalah **memperbaiki/mengembangkan**, bukan membangun ulang

---

## 15. Instruksi untuk AI di Sesi Baru

1. **BACA** seluruh `AI_CONTEXT.md` ini sebelum menganalisis repo
2. **PAHAMI** bahwa user biasanya akan mengirim:
   - `AI_CONTEXT.md`
   - lalu `repomix-output.xml`
3. **PATUHI** semua hard rules di Bagian 14
4. **GUNAKAN** hanya tool Wayland yang sesuai
5. **PRIORITASKAN** file `.conf` Hyprland pada sistem user ini kecuali user memberi konteks live lain
6. **JANGAN MENEBak** isi file yang belum diberikan
7. **BERIKAN** solusi dalam bentuk command terminal siap eksekusi bila AI tidak bisa menulis file langsung
8. Jika konteks belum cukup, **MINTA file yang spesifik**
9. Jika ada konflik antara pengetahuan umum AI dan file ini, **IKUTI FILE INI**

---

## 16. Ringkasan Singkat untuk AI

Jika hanya mengingat sedikit, ingat ini:

- Sistem user: **Wayland + Hyprland + Bash + Kitty**
- Proyek: **Rust TUI clipboard manager** berbasis `cliphist`
- Keybinding Hyprland: **hanya di `~/.config/hypr/bindings.conf`**
- Jangan sarankan tool X11
- Jangan tambah dependency tanpa izin
- Jangan ubah arsitektur tanpa izin
- Tab Pin harus **sorted terbaru → terlama**
- Jika tidak bisa edit langsung, berikan **command terminal siap pakai**
