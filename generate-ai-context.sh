#!/usr/bin/env bash

# ============================================================================
# generate-ai-context.sh
# Script untuk membuat dan memperbarui AI_CONTEXT.md secara semi-otomatis
# Dibuat untuk: Arch Linux + Hyprland (Wayland) + Rust/Ratatui Projects
# chmod +x generate-ai-context.sh
# ============================================================================

set -euo pipefail

# ── Warna Terminal ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ── Variabel Global ────────────────────────────────────────────────────────
CONTEXT_FILE="AI_CONTEXT.md"
MANUAL_CACHE=".ai_context_manual.cache"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# Data auto-detect
AUTO_OS=""
AUTO_KERNEL=""
AUTO_WM=""
AUTO_DISPLAY_PROTOCOL=""
AUTO_SHELL=""
AUTO_TERMINAL=""
AUTO_USERNAME=""
AUTO_HOME=""
AUTO_HYPR_CONFIG=""
AUTO_HYPR_BINDINGS=""
AUTO_CLIPBOARD_TOOLS=""
AUTO_SUPPORT_TOOLS=""
AUTO_RUST_VERSION=""
AUTO_TUI_LIBRARY=""
AUTO_DEPENDENCIES=""
AUTO_PROJECT_STRUCTURE=""
AUTO_CARGO_DEPS=""

# Data manual (dari cache atau input user)
MANUAL_APP_PURPOSE=""
MANUAL_HARD_RULES=""
MANUAL_CODE_STYLE=""
MANUAL_EXTRA_NOTES=""

# ── Fungsi Utilitas ────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}  ${BOLD}🔧 AI Context Generator${NC}                                   ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC}  ${DIM}Membuat & Memperbarui AI_CONTEXT.md untuk proyek Anda${NC}      ${BLUE}║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${CYAN}── $1 ──────────────────────────────────────────${NC}"
}

print_detect() {
  echo -e "  ${GREEN}✔${NC} $1: ${BOLD}$2${NC}"
}

print_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "  ${RED}✘${NC} $1"
}

print_info() {
  echo -e "  ${DIM}ℹ $1${NC}"
}

# Fungsi untuk konfirmasi Yes/No (default Yes)
confirm() {
  local prompt="$1"
  local response
  read -r -p "$(echo -e "  ${YELLOW}?${NC} ${prompt} [Y/n]: ")" response
  response="${response:-y}"
  [[ "$response" =~ ^[Yy]$ ]]
}

# Fungsi untuk input teks dari user
ask_input() {
  local prompt="$1"
  local default="$2"
  local response
  if [[ -n "$default" ]]; then
    read -r -p "$(echo -e "  ${YELLOW}?${NC} ${prompt} [${DIM}${default}${NC}]: ")" response
    echo "${response:-$default}"
  else
    read -r -p "$(echo -e "  ${YELLOW}?${NC} ${prompt}: ")" response
    echo "$response"
  fi
}

# Fungsi untuk input multi-line
ask_multiline() {
  local prompt="$1"
  local default="$2"
  local lines=""
  local line

  if [[ -n "$default" ]]; then
    echo -e "  ${YELLOW}?${NC} ${prompt}"
    echo -e "  ${DIM}  (Nilai saat ini: lihat di bawah)${NC}"
    echo -e "  ${DIM}  ┌──────────────────────────────────────────${NC}"
    while IFS= read -r line; do
      echo -e "  ${DIM}  │ ${line}${NC}"
    done <<<"$default"
    echo -e "  ${DIM}  └──────────────────────────────────────────${NC}"
    if confirm "Gunakan nilai di atas tanpa perubahan?"; then
      echo "$default"
      return
    fi
  else
    echo -e "  ${YELLOW}?${NC} ${prompt}"
  fi

  echo -e "  ${DIM}  (Ketik jawaban Anda. Ketik baris kosong untuk selesai)${NC}"
  while true; do
    read -r -p "$(echo -e "  ${DIM}  │${NC} ")" line
    if [[ -z "$line" ]]; then
      break
    fi
    if [[ -n "$lines" ]]; then
      lines="${lines}\n${line}"
    else
      lines="$line"
    fi
  done
  echo -e "$lines"
}

# ── Deteksi Otomatis ───────────────────────────────────────────────────────

detect_system() {
  print_section "Mendeteksi Lingkungan Sistem"

  # OS
  if command -v lsb_release &>/dev/null; then
    AUTO_OS="$(lsb_release -ds 2>/dev/null | tr -d '"')"
  elif [[ -f /etc/os-release ]]; then
    AUTO_OS="$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
  else
    AUTO_OS="Linux (tidak terdeteksi distro)"
  fi
  print_detect "OS" "$AUTO_OS"

  # Kernel
  AUTO_KERNEL="$(uname -r)"
  print_detect "Kernel" "$AUTO_KERNEL"

  # Display Protocol
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    AUTO_DISPLAY_PROTOCOL="Wayland"
  elif [[ -n "${DISPLAY:-}" ]]; then
    AUTO_DISPLAY_PROTOCOL="X11"
  else
    AUTO_DISPLAY_PROTOCOL="Tidak terdeteksi (TTY?)"
  fi
  print_detect "Display Protocol" "$AUTO_DISPLAY_PROTOCOL"

  # Window Manager
  AUTO_WM=""
  if [[ "$AUTO_DISPLAY_PROTOCOL" == "Wayland" ]]; then
    if pgrep -x "Hyprland" &>/dev/null || pgrep -x "hyprland" &>/dev/null; then
      AUTO_WM="Hyprland"
      # Cek versi Hyprland
      if command -v hyprctl &>/dev/null; then
        local hypr_ver
        hypr_ver="$(hyprctl version 2>/dev/null | grep 'Tag:' | awk '{print $2}' || echo '')"
        if [[ -n "$hypr_ver" ]]; then
          AUTO_WM="Hyprland ${hypr_ver}"
        fi
      fi
    elif pgrep -x "sway" &>/dev/null; then
      AUTO_WM="Sway"
    fi
  fi
  if [[ -z "$AUTO_WM" ]]; then
    AUTO_WM="${XDG_CURRENT_DESKTOP:-tidak terdeteksi}"
  fi
  print_detect "Window Manager" "$AUTO_WM"

  # Shell
  AUTO_SHELL="$(basename "$SHELL")"
  print_detect "Shell" "$AUTO_SHELL"

  # Terminal Emulator
  AUTO_TERMINAL=""
  # Cek dari environment variable
  if [[ -n "${TERM_PROGRAM:-}" ]]; then
    AUTO_TERMINAL="$TERM_PROGRAM"
  elif [[ "${TERM:-}" == "xterm-kitty" ]]; then
    AUTO_TERMINAL="Kitty"
  elif [[ -n "${KITTY_PID:-}" ]]; then
    AUTO_TERMINAL="Kitty"
  elif [[ -n "${ALACRITTY_SOCKET:-}" ]]; then
    AUTO_TERMINAL="Alacritty"
  elif [[ -n "${WEZTERM_EXECUTABLE:-}" ]]; then
    AUTO_TERMINAL="WezTerm"
  fi
  if [[ -z "$AUTO_TERMINAL" ]]; then
    # Fallback: cek proses yang sedang jalan
    for term in kitty alacritty foot wezterm konsole gnome-terminal; do
      if pgrep -x "$term" &>/dev/null; then
        AUTO_TERMINAL="$term"
        break
      fi
    done
  fi
  AUTO_TERMINAL="${AUTO_TERMINAL:-tidak terdeteksi}"
  print_detect "Terminal" "$AUTO_TERMINAL"

  # Username & Home
  AUTO_USERNAME="$(whoami)"
  AUTO_HOME="$HOME"
  print_detect "User" "${AUTO_USERNAME} (${AUTO_HOME})"
}

detect_hyprland_config() {
  print_section "Mendeteksi Konfigurasi Hyprland"

  local hypr_dir="$HOME/.config/hypr"

  # Config utama
  if [[ -f "${hypr_dir}/hyprland.conf" ]]; then
    AUTO_HYPR_CONFIG="${hypr_dir}/hyprland.conf"
    print_detect "Config utama" "$AUTO_HYPR_CONFIG"
  else
    AUTO_HYPR_CONFIG=""
    print_warn "hyprland.conf tidak ditemukan di ${hypr_dir}/"
  fi

  # Keybinding - cek beberapa kemungkinan
  AUTO_HYPR_BINDINGS=""
  local binding_candidates=(
    "${hypr_dir}/bindings.conf"
    "${hypr_dir}/keybindings.conf"
    "${hypr_dir}/keybinds.conf"
    "${hypr_dir}/binds.conf"
  )

  for candidate in "${binding_candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      AUTO_HYPR_BINDINGS="$candidate"
      print_detect "Keybinding file" "$AUTO_HYPR_BINDINGS"
      break
    fi
  done

  if [[ -z "$AUTO_HYPR_BINDINGS" ]]; then
    print_warn "File keybinding terpisah tidak ditemukan"
    print_info "Kandidat yang dicari: ${binding_candidates[*]}"

    # Cek apakah hyprland.conf melakukan source ke file lain
    if [[ -n "$AUTO_HYPR_CONFIG" ]]; then
      echo -e "  ${DIM}  File yang di-source dari hyprland.conf:${NC}"
      grep -E "^\s*source\s*=" "$AUTO_HYPR_CONFIG" 2>/dev/null | while read -r line; do
        echo -e "  ${DIM}    → ${line}${NC}"
      done
    fi

    AUTO_HYPR_BINDINGS="$(ask_input "Masukkan path file keybinding Hyprland Anda" "${hypr_dir}/bindings.conf")"
  fi

  # Deteksi semua file conf yang di-source
  if [[ -n "$AUTO_HYPR_CONFIG" ]]; then
    print_info "File yang di-source dari hyprland.conf:"
    grep -E "^\s*source\s*=" "$AUTO_HYPR_CONFIG" 2>/dev/null | while read -r line; do
      local sourced_file
      sourced_file="$(echo "$line" | sed 's/.*=\s*//' | sed 's/\s*$//' | envsubst 2>/dev/null || echo "$line")"
      echo -e "    ${DIM}→ ${sourced_file}${NC}"
    done
  fi
}

detect_tools() {
  print_section "Mendeteksi Tools yang Terpasang"

  # Clipboard tools
  AUTO_CLIPBOARD_TOOLS=""
  local clip_tools=("cliphist" "wl-copy" "wl-paste" "xclip" "xsel" "copyq")
  for tool in "${clip_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      local version=""
      case "$tool" in
      cliphist)
        version="$(cliphist version 2>/dev/null || echo '')"
        ;;
      wl-copy | wl-paste)
        version="(wl-clipboard)"
        ;;
      esac
      if [[ -n "$AUTO_CLIPBOARD_TOOLS" ]]; then
        AUTO_CLIPBOARD_TOOLS="${AUTO_CLIPBOARD_TOOLS}, ${tool} ${version}"
      else
        AUTO_CLIPBOARD_TOOLS="${tool} ${version}"
      fi
      print_detect "Clipboard" "${tool} ${version}"
    fi
  done
  AUTO_CLIPBOARD_TOOLS="${AUTO_CLIPBOARD_TOOLS:-tidak ada yang terdeteksi}"

  # Support tools
  AUTO_SUPPORT_TOOLS=""
  local support_tools=("rofi" "wofi" "fuzzel" "dmenu" "bemenu" "tofi" "notify-send" "dunstify" "hyprctl" "wlr-randr" "grim" "slurp" "swappy")
  for tool in "${support_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      if [[ -n "$AUTO_SUPPORT_TOOLS" ]]; then
        AUTO_SUPPORT_TOOLS="${AUTO_SUPPORT_TOOLS}, ${tool}"
      else
        AUTO_SUPPORT_TOOLS="${tool}"
      fi
    fi
  done
  if [[ -n "$AUTO_SUPPORT_TOOLS" ]]; then
    print_detect "Support tools" "$AUTO_SUPPORT_TOOLS"
  fi
  AUTO_SUPPORT_TOOLS="${AUTO_SUPPORT_TOOLS:-tidak ada yang terdeteksi}"
}

detect_project() {
  print_section "Mendeteksi Detail Proyek: ${PROJECT_NAME}"

  # Cek apakah ini proyek Rust
  if [[ ! -f "Cargo.toml" ]]; then
    print_error "Cargo.toml tidak ditemukan di $(pwd)"
    print_error "Pastikan Anda menjalankan script ini dari root folder proyek Rust Anda!"
    exit 1
  fi

  # Rust version
  if command -v rustc &>/dev/null; then
    AUTO_RUST_VERSION="$(rustc --version)"
    print_detect "Rust" "$AUTO_RUST_VERSION"
  else
    AUTO_RUST_VERSION="tidak terdeteksi"
    print_error "rustc tidak ditemukan!"
  fi

  # Cargo edition
  local cargo_edition
  cargo_edition="$(grep -E '^edition\s*=' Cargo.toml 2>/dev/null | head -1 | sed 's/.*=\s*"//' | sed 's/".*//' || echo '')"
  if [[ -n "$cargo_edition" ]]; then
    print_detect "Rust Edition" "$cargo_edition"
  fi

  # Dependencies dari Cargo.toml
  AUTO_CARGO_DEPS=""
  AUTO_TUI_LIBRARY=""
  if [[ -f "Cargo.toml" ]]; then
    print_info "Dependencies dari Cargo.toml:"
    local in_deps=0
    while IFS= read -r line; do
      # Mulai section dependencies
      if [[ "$line" =~ ^\[dependencies\] ]] || [[ "$line" =~ ^\[dependencies\. ]]; then
        in_deps=1
        continue
      fi
      # Keluar dari section dependencies jika ketemu section baru
      if [[ "$line" =~ ^\[.+\] ]] && [[ "$in_deps" -eq 1 ]]; then
        in_deps=0
        continue
      fi
      # Parse dependency
      if [[ "$in_deps" -eq 1 ]] && [[ "$line" =~ ^[a-zA-Z] ]]; then
        local dep_name
        dep_name="$(echo "$line" | cut -d'=' -f1 | tr -d ' ')"
        local dep_ver
        dep_ver="$(echo "$line" | cut -d'=' -f2- | tr -d ' "' | head -c 50)"

        if [[ -n "$dep_name" ]]; then
          echo -e "    ${DIM}→ ${dep_name} = ${dep_ver}${NC}"
          if [[ -n "$AUTO_CARGO_DEPS" ]]; then
            AUTO_CARGO_DEPS="${AUTO_CARGO_DEPS}, ${dep_name}"
          else
            AUTO_CARGO_DEPS="${dep_name}"
          fi

          # Deteksi TUI library
          case "$dep_name" in
          ratatui | tui | cursive | termion | crossterm)
            if [[ -n "$AUTO_TUI_LIBRARY" ]]; then
              AUTO_TUI_LIBRARY="${AUTO_TUI_LIBRARY}, ${dep_name}"
            else
              AUTO_TUI_LIBRARY="${dep_name}"
            fi
            ;;
          esac
        fi
      fi
    done <Cargo.toml
  fi
  AUTO_TUI_LIBRARY="${AUTO_TUI_LIBRARY:-tidak terdeteksi}"
  print_detect "TUI Library" "$AUTO_TUI_LIBRARY"

  # Struktur proyek
  print_info "Struktur proyek:"
  AUTO_PROJECT_STRUCTURE=""
  if command -v tree &>/dev/null; then
    AUTO_PROJECT_STRUCTURE="$(tree -I 'target|.git|repomix-output*' --charset=utf-8 -a 2>/dev/null || echo 'gagal generate tree')"
    echo "$AUTO_PROJECT_STRUCTURE" | head -30 | while IFS= read -r line; do
      echo -e "    ${DIM}${line}${NC}"
    done
    local total_lines
    total_lines="$(echo "$AUTO_PROJECT_STRUCTURE" | wc -l)"
    if [[ "$total_lines" -gt 30 ]]; then
      echo -e "    ${DIM}... (${total_lines} baris total, dipotong)${NC}"
    fi
  else
    AUTO_PROJECT_STRUCTURE="$(find . -not -path './target/*' -not -path './.git/*' -not -name 'repomix-output*' | sort)"
    echo "$AUTO_PROJECT_STRUCTURE" | head -20 | while IFS= read -r line; do
      echo -e "    ${DIM}${line}${NC}"
    done
    print_warn "'tree' tidak terinstall. Install dengan: sudo pacman -S tree"
  fi

  # System dependencies yang dibutuhkan (deteksi dari source code)
  print_info "Mendeteksi system dependencies dari source code..."
  AUTO_DEPENDENCIES=""
  local sys_deps_found=()

  # Cari referensi ke command eksternal di source code
  if [[ -d "src" ]]; then
    local src_content
    src_content="$(cat src/*.rs src/**/*.rs 2>/dev/null || cat src/*.rs 2>/dev/null || echo '')"

    local potential_deps=("cliphist" "wl-copy" "wl-paste" "notify-send" "hyprctl" "rofi" "wofi" "pkill" "systemctl" "wl-clipboard")
    for dep in "${potential_deps[@]}"; do
      if echo "$src_content" | grep -q "$dep" 2>/dev/null; then
        sys_deps_found+=("$dep")
      fi
    done
  fi

  # Cari juga di scripts/
  if [[ -d "scripts" ]]; then
    local scripts_content
    scripts_content="$(cat scripts/*.sh 2>/dev/null || echo '')"

    local potential_deps=("cliphist" "wl-copy" "wl-paste" "cargo" "rustc" "notify-send" "hyprctl" "systemctl" "pacman")
    for dep in "${potential_deps[@]}"; do
      if echo "$scripts_content" | grep -q "$dep" 2>/dev/null; then
        # Hindari duplikat
        local already_found=0
        for existing in "${sys_deps_found[@]:-}"; do
          if [[ "$existing" == "$dep" ]]; then
            already_found=1
            break
          fi
        done
        if [[ "$already_found" -eq 0 ]]; then
          sys_deps_found+=("$dep")
        fi
      fi
    done
  fi

  if [[ ${#sys_deps_found[@]} -gt 0 ]]; then
    AUTO_DEPENDENCIES="$(
      IFS=', '
      echo "${sys_deps_found[*]}"
    )"
    print_detect "System deps (dari kode)" "$AUTO_DEPENDENCIES"
  else
    AUTO_DEPENDENCIES="tidak terdeteksi dari source code"
    print_info "Tidak menemukan referensi ke command eksternal di source code"
  fi
}

# ── Cache Manual Data ──────────────────────────────────────────────────────

load_manual_cache() {
  if [[ -f "$MANUAL_CACHE" ]]; then
    # shellcheck disable=SC1090
    source "$MANUAL_CACHE"
    return 0
  fi
  return 1
}

save_manual_cache() {
  cat >"$MANUAL_CACHE" <<CACHE_EOF
# AI Context Manual Cache
# Dibuat oleh generate-ai-context.sh
# Terakhir diperbarui: $(date '+%Y-%m-%d %H:%M:%S')

MANUAL_APP_PURPOSE=$(printf '%q' "$MANUAL_APP_PURPOSE")
MANUAL_HARD_RULES=$(printf '%q' "$MANUAL_HARD_RULES")
MANUAL_CODE_STYLE=$(printf '%q' "$MANUAL_CODE_STYLE")
MANUAL_EXTRA_NOTES=$(printf '%q' "$MANUAL_EXTRA_NOTES")
CACHE_EOF
  print_info "Data manual disimpan ke ${MANUAL_CACHE}"
}

# ── Input Manual dari User ─────────────────────────────────────────────────

collect_manual_input() {
  print_section "Input Manual (Data yang tidak bisa di-auto-detect)"

  local has_cache=0
  if load_manual_cache; then
    has_cache=1
    print_info "Ditemukan data manual sebelumnya dari cache"
  fi

  # Tujuan aplikasi
  echo ""
  if [[ "$has_cache" -eq 1 ]] && [[ -n "$MANUAL_APP_PURPOSE" ]]; then
    MANUAL_APP_PURPOSE="$(ask_multiline "Tujuan utama aplikasi ${PROJECT_NAME}:" "$MANUAL_APP_PURPOSE")"
  else
    echo -e "  ${YELLOW}?${NC} Tujuan utama aplikasi ${BOLD}${PROJECT_NAME}${NC}:"
    echo -e "  ${DIM}  (Contoh: Aplikasi TUI untuk mengelola clipboard history menggunakan cliphist)${NC}"
    MANUAL_APP_PURPOSE="$(ask_multiline "Jelaskan tujuan aplikasi:" "")"
  fi

  # Hard rules
  echo ""
  if [[ "$has_cache" -eq 1 ]] && [[ -n "$MANUAL_HARD_RULES" ]]; then
    MANUAL_HARD_RULES="$(ask_multiline "Aturan keras (DILARANG) untuk AI:" "$MANUAL_HARD_RULES")"
  else
    echo -e "  ${YELLOW}?${NC} Aturan keras ${BOLD}(DILARANG)${NC} untuk AI:"
    echo -e "  ${DIM}  (Contoh: Jangan gunakan xdotool, jangan edit hyprland.conf untuk keybinding)${NC}"
    MANUAL_HARD_RULES="$(ask_multiline "Tuliskan larangan untuk AI:" "")"
  fi

  # Code style
  echo ""
  if [[ "$has_cache" -eq 1 ]] && [[ -n "$MANUAL_CODE_STYLE" ]]; then
    MANUAL_CODE_STYLE="$(ask_multiline "Gaya penulisan kode yang diinginkan:" "$MANUAL_CODE_STYLE")"
  else
    echo -e "  ${YELLOW}?${NC} Gaya penulisan kode yang diinginkan:"
    echo -e "  ${DIM}  (Contoh: Rust idiomatik, komentar bahasa Inggris, kode modular)${NC}"
    MANUAL_CODE_STYLE="$(ask_multiline "Tuliskan preferensi gaya kode:" "")"
  fi

  # Catatan tambahan
  echo ""
  if [[ "$has_cache" -eq 1 ]] && [[ -n "$MANUAL_EXTRA_NOTES" ]]; then
    MANUAL_EXTRA_NOTES="$(ask_multiline "Catatan tambahan (opsional):" "$MANUAL_EXTRA_NOTES")"
  else
    MANUAL_EXTRA_NOTES="$(ask_multiline "Catatan tambahan untuk AI (opsional, kosongkan jika tidak ada):" "")"
  fi

  save_manual_cache
}

# ── Konfirmasi Data Auto-Detect ────────────────────────────────────────────

confirm_detected_data() {
  print_section "Konfirmasi Data Auto-Detect"

  echo ""
  echo -e "  ${BOLD}Ringkasan hasil deteksi:${NC}"
  echo -e "  ─────────────────────────────────────────"
  echo -e "  OS              : ${BOLD}$AUTO_OS${NC}"
  echo -e "  Kernel          : ${BOLD}$AUTO_KERNEL${NC}"
  echo -e "  WM              : ${BOLD}$AUTO_WM${NC}"
  echo -e "  Display         : ${BOLD}$AUTO_DISPLAY_PROTOCOL${NC}"
  echo -e "  Shell           : ${BOLD}$AUTO_SHELL${NC}"
  echo -e "  Terminal        : ${BOLD}$AUTO_TERMINAL${NC}"
  echo -e "  User            : ${BOLD}${AUTO_USERNAME} (${AUTO_HOME})${NC}"
  echo -e "  Hypr Config     : ${BOLD}$AUTO_HYPR_CONFIG${NC}"
  echo -e "  Hypr Bindings   : ${BOLD}$AUTO_HYPR_BINDINGS${NC}"
  echo -e "  Clipboard Tools : ${BOLD}$AUTO_CLIPBOARD_TOOLS${NC}"
  echo -e "  Support Tools   : ${BOLD}$AUTO_SUPPORT_TOOLS${NC}"
  echo -e "  Rust            : ${BOLD}$AUTO_RUST_VERSION${NC}"
  echo -e "  TUI Library     : ${BOLD}$AUTO_TUI_LIBRARY${NC}"
  echo -e "  Cargo Deps      : ${BOLD}$AUTO_CARGO_DEPS${NC}"
  echo -e "  System Deps     : ${BOLD}$AUTO_DEPENDENCIES${NC}"
  echo -e "  ─────────────────────────────────────────"
  echo ""

  if ! confirm "Apakah semua data di atas sudah benar?"; then
    echo ""
    print_info "Anda bisa mengedit langsung di file ${CONTEXT_FILE} setelah di-generate."
    print_info "Atau jalankan ulang script ini setelah memperbaiki konfigurasi sistem."
    echo ""
    if ! confirm "Lanjutkan generate dengan data di atas?"; then
      echo -e "${RED}Dibatalkan.${NC}"
      exit 0
    fi
  fi
}

# ── Generate AI_CONTEXT.md ─────────────────────────────────────────────────

generate_context_file() {
  print_section "Membuat ${CONTEXT_FILE}"

  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  # Format hard rules sebagai list
  local formatted_rules=""
  if [[ -n "$MANUAL_HARD_RULES" ]]; then
    while IFS= read -r rule; do
      if [[ -n "$rule" ]]; then
        formatted_rules="${formatted_rules}- ❌ ${rule}\n"
      fi
    done <<<"$(echo -e "$MANUAL_HARD_RULES")"
  fi

  # Format code style sebagai list
  local formatted_style=""
  if [[ -n "$MANUAL_CODE_STYLE" ]]; then
    while IFS= read -r style; do
      if [[ -n "$style" ]]; then
        formatted_style="${formatted_style}- ${style}\n"
      fi
    done <<<"$(echo -e "$MANUAL_CODE_STYLE")"
  fi

  # Format extra notes
  local formatted_notes=""
  if [[ -n "$MANUAL_EXTRA_NOTES" ]]; then
    formatted_notes="
## 📝 Catatan Tambahan
$(echo -e "$MANUAL_EXTRA_NOTES")
"
  fi

  # Tulis file
  cat >"$CONTEXT_FILE" <<CONTEXT_EOF
# 🤖 AI CONTEXT — ${PROJECT_NAME}
> **WAJIB DIBACA SEBELUM MEMBERIKAN SARAN, KODE, ATAU KONFIGURASI**
>
> File ini di-generate otomatis oleh \`generate-ai-context.sh\`
> Terakhir diperbarui: ${timestamp}

---

## 1. 🖥️ Lingkungan Sistem

| Komponen | Detail |
|---|---|
| **OS** | ${AUTO_OS} |
| **Kernel** | ${AUTO_KERNEL} |
| **Window Manager** | ${AUTO_WM} |
| **Display Protocol** | ${AUTO_DISPLAY_PROTOCOL} |
| **Shell** | ${AUTO_SHELL} |
| **Terminal** | ${AUTO_TERMINAL} |
| **User** | \`${AUTO_USERNAME}\` |
| **Home Directory** | \`${AUTO_HOME}\` |

---

## 2. ⚙️ Konfigurasi Hyprland

| Item | Path |
|---|---|
| **Config Utama** | \`${AUTO_HYPR_CONFIG}\` |
| **File Keybinding** | \`${AUTO_HYPR_BINDINGS}\` |

### ⚠️ ATURAN KEYBINDING:
- Jika ada fitur yang memerlukan shortcut/keybinding Hyprland, keybinding tersebut **HANYA BOLEH** ditulis di:
  \`${AUTO_HYPR_BINDINGS}\`
- **DILARANG** menyarankan penulisan keybinding di \`${AUTO_HYPR_CONFIG}\` karena akan menyebabkan error.

---

## 3. 🛠️ Tools yang Tersedia di Sistem

### Clipboard Tools:
${AUTO_CLIPBOARD_TOOLS}

### Support Tools:
${AUTO_SUPPORT_TOOLS}

---

## 4. 🦀 Tech Stack Proyek

| Komponen | Detail |
|---|---|
| **Bahasa** | ${AUTO_RUST_VERSION} |
| **TUI Library** | ${AUTO_TUI_LIBRARY} |
| **Cargo Dependencies** | ${AUTO_CARGO_DEPS} |
| **System Dependencies** | ${AUTO_DEPENDENCIES} |

---

## 5. 🎯 Tujuan Aplikasi

$(echo -e "$MANUAL_APP_PURPOSE")

---

## 6. 📂 Struktur Proyek

\`\`\`
${AUTO_PROJECT_STRUCTURE}
\`\`\`

---

## 7. 🚫 ATURAN KERAS (HARD RULES) — DILARANG DILANGGAR

$(echo -e "$formatted_rules")
### Aturan Umum Wajib:
- ❌ **DILARANG** menyarankan tools berbasis X11 (seperti \`xdotool\`, \`xprop\`, \`xclip\`) karena sistem ini menggunakan **Wayland**.
- ❌ **DILARANG** merombak ulang arsitektur proyek tanpa izin eksplisit dari user.
- ❌ **DILARANG** menambahkan dependency baru tanpa konfirmasi terlebih dahulu.
- ✅ Jika ragu, **TANYAKAN** sebelum membuat perubahan.

---

## 8. ✍️ Gaya Penulisan Kode

$(echo -e "$formatted_style")

---
${formatted_notes}
## 📋 Instruksi untuk AI

1. **BACA** seluruh konteks di atas sebelum memberikan saran apapun.
2. **PAHAMI** bahwa proyek ini sudah berjalan (v1). Tugas Anda adalah memperbaiki/mengembangkan, BUKAN membangun ulang.
3. **PATUHI** semua aturan keras di Bagian 7.
4. **GUNAKAN** hanya tools yang tersedia di Bagian 3.
5. **SESUAIKAN** path konfigurasi dengan yang tertulis di Bagian 2.
6. Jika ada konflik antara pengetahuan umum Anda dengan konteks di file ini, **IKUTI FILE INI**.
CONTEXT_EOF

  print_detect "File berhasil dibuat" "$CONTEXT_FILE"

  # Tampilkan ukuran file
  local file_size
  file_size="$(wc -c <"$CONTEXT_FILE")"
  local file_lines
  file_lines="$(wc -l <"$CONTEXT_FILE")"
  print_info "Ukuran: ${file_size} bytes, ${file_lines} baris"
}

# ── Update .gitignore ──────────────────────────────────────────────────────

update_gitignore() {
  # Tambahkan cache file ke .gitignore
  if [[ -f ".gitignore" ]]; then
    if ! grep -q "$MANUAL_CACHE" .gitignore 2>/dev/null; then
      echo "$MANUAL_CACHE" >>.gitignore
      print_info "Menambahkan ${MANUAL_CACHE} ke .gitignore"
    fi
    if ! grep -q "repomix-output" .gitignore 2>/dev/null; then
      echo "repomix-output.*" >>.gitignore
      print_info "Menambahkan repomix-output.* ke .gitignore"
    fi
  fi
}

# ── Mode Update ────────────────────────────────────────────────────────────

check_update_mode() {
  if [[ -f "$CONTEXT_FILE" ]]; then
    echo ""
    echo -e "${YELLOW}⚠ File ${CONTEXT_FILE} sudah ada!${NC}"
    echo ""
    echo -e "  ${BOLD}Pilih mode:${NC}"
    echo -e "  ${CYAN}1)${NC} Update   — Auto-detect ulang + pertahankan data manual dari cache"
    echo -e "  ${CYAN}2)${NC} Reset    — Buat ulang semuanya dari awal"
    echo -e "  ${CYAN}3)${NC} Batalkan — Tidak melakukan apa-apa"
    echo ""
    local choice
    read -r -p "$(echo -e "  ${YELLOW}?${NC} Pilihan Anda [1/2/3]: ")" choice

    case "$choice" in
    1)
      echo -e "  ${GREEN}→ Mode Update${NC}"
      return 0 # update
      ;;
    2)
      echo -e "  ${GREEN}→ Mode Reset${NC}"
      rm -f "$MANUAL_CACHE"
      return 0 # reset (cache dihapus)
      ;;
    3)
      echo -e "  ${RED}→ Dibatalkan${NC}"
      exit 0
      ;;
    *)
      echo -e "  ${RED}Pilihan tidak valid. Dibatalkan.${NC}"
      exit 1
      ;;
    esac
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────

main() {
  print_header

  # Cek apakah di folder proyek Rust
  if [[ ! -f "Cargo.toml" ]]; then
    print_error "Cargo.toml tidak ditemukan!"
    print_error "Jalankan script ini dari root folder proyek Rust Anda."
    echo -e "  ${DIM}Contoh: cd ~/projects/edClipManager && bash generate-ai-context.sh${NC}"
    exit 1
  fi

  # Cek mode (baru / update / reset)
  check_update_mode

  # Auto-detect
  detect_system
  detect_hyprland_config
  detect_tools
  detect_project

  # Konfirmasi
  confirm_detected_data

  # Input manual
  collect_manual_input

  # Generate file
  generate_context_file

  # Update .gitignore
  update_gitignore

  # Selesai
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}  ${BOLD}✅ AI_CONTEXT.md berhasil dibuat!${NC}                           ${GREEN}║${NC}"
  echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}  Langkah selanjutnya:                                        ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}  ${CYAN}1.${NC} Jalankan repomix:                                        ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}     ${BOLD}repomix${NC}                                                   ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}  ${CYAN}2.${NC} Copy hasilnya:                                            ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}     ${BOLD}wl-copy < repomix-output.xml${NC}                              ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}  ${CYAN}3.${NC} Paste ke chat AI B                                        ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}  Untuk ${BOLD}memperbarui${NC} setelah ada perubahan kode:                ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}     ${BOLD}bash generate-ai-context.sh${NC}                               ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}     → Pilih opsi ${CYAN}1) Update${NC}                                    ${GREEN}║${NC}"
  echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

main "$@"
