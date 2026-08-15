#!/usr/bin/env bash

set -euo pipefail

APP_NAME="edClipManager"
BINARY_NAME="edclipmanager"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/$APP_NAME"
DATA_DIR="$HOME/.local/share/$APP_NAME"
WATCHER_SCRIPT="$BIN_DIR/edclipmanager-cliphist-watch"

HYPR_DIR="$HOME/.config/hypr"
HYPR_AUTOSTART_CONF="$HYPR_DIR/autostart.conf"
HYPR_BINDINGS_CONF="$HYPR_DIR/bindings.conf"
HYPR_MAIN_CONF="$HYPR_DIR/hyprland.conf"

HYPR_AUTOSTART_LUA="$HYPR_DIR/autostart.lua"
HYPR_BINDINGS_LUA="$HYPR_DIR/bindings.lua"
HYPR_LOOKNFEEL_LUA="$HYPR_DIR/looknfeel.lua"

HYPR_MODE=""
HYPR_AUTOSTART=""
HYPR_BINDINGS=""
HYPR_RULES=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

STEP=0
TOTAL=15

info() { echo -e "${CYAN}$1${NC}"; }
success() { echo -e "${GREEN}  ✓ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
fail() { echo -e "${RED}  ✗ $1${NC}"; }

confirm() {
  local msg="$1"
  echo -en "${BOLD}  $msg [Y/n] ${NC}"
  read -r answer
  answer="${answer:-y}"
  case "$answer" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

step_header() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${BOLD}[Step $STEP/$TOTAL] $1${NC}"
}

show_block() {
  local block="$1"
  while IFS= read -r line; do
    info "    $line"
  done <<< "$block"
}

upsert_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local block_content="$4"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  local tmp
  tmp="$(mktemp)"

  awk -v start="$start_marker" -v end="$end_marker" -v block="$block_content" '
    BEGIN {
      inblock = 0
      replaced = 0
      n = split(block, lines, "\n")
    }
    $0 == start {
      if (!replaced) {
        for (i = 1; i <= n; i++) print lines[i]
        replaced = 1
      }
      inblock = 1
      next
    }
    inblock {
      if ($0 == end) inblock = 0
      next
    }
    {
      print
    }
    END {
      if (!replaced) {
        if (NR > 0) print ""
        for (i = 1; i <= n; i++) print lines[i]
      }
    }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

detect_hypr_mode() {
  if [[ -f "$HYPR_AUTOSTART_LUA" || -f "$HYPR_BINDINGS_LUA" || -f "$HYPR_LOOKNFEEL_LUA" ]]; then
    HYPR_MODE="lua"
    HYPR_AUTOSTART="$HYPR_AUTOSTART_LUA"
    HYPR_BINDINGS="$HYPR_BINDINGS_LUA"
    HYPR_RULES="$HYPR_LOOKNFEEL_LUA"
  else
    HYPR_MODE="conf"
    HYPR_AUTOSTART="$HYPR_AUTOSTART_CONF"
    HYPR_BINDINGS="$HYPR_BINDINGS_CONF"
    HYPR_RULES="$HYPR_MAIN_CONF"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${BOLD}${CYAN}=======================================${NC}"
echo -e "${BOLD}${CYAN}   $APP_NAME Installer v1.1${NC}"
echo -e "${BOLD}${CYAN}=======================================${NC}"

# Step 1: Check OS
step_header "Checking operating system"
if [[ "$(uname -s)" == "Linux" ]]; then
  success "Linux detected"
else
  fail "This application only supports Linux"
  exit 1
fi
confirm "Continue?" || exit 0

# Step 2: Check Wayland
step_header "Checking display server"
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
  success "Wayland session detected"
else
  fail "Wayland session not detected (XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unset})"
  warn "This application requires Wayland"
  confirm "Continue anyway?" || exit 1
fi
confirm "Continue?" || exit 0

# Step 3: Check required commands
step_header "Checking required packages"
MISSING=()
for cmd in wl-copy wl-paste cliphist kitty hyprctl; do
  if command -v "$cmd" &>/dev/null; then
    success "$cmd found ($(command -v "$cmd"))"
  else
    fail "$cmd not found"
    MISSING+=("$cmd")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  warn "Missing packages: ${MISSING[*]}"
  warn "Please install them before continuing"
  info "  Arch: sudo pacman -S wl-clipboard cliphist kitty hyprland"
  confirm "Continue anyway?" || exit 1
fi
confirm "Continue?" || exit 0

# Step 4: Check Rust toolchain
step_header "Checking Rust toolchain"
if command -v cargo &>/dev/null; then
  success "cargo found ($(cargo --version))"
else
  fail "cargo not found"
  if confirm "Install Rust via rustup?"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
    if command -v cargo &>/dev/null; then
      success "Rust installed successfully ($(cargo --version))"
    else
      fail "Rust installation failed"
      exit 1
    fi
  else
    fail "Rust is required to build this application"
    exit 1
  fi
fi
confirm "Continue?" || exit 0

# Step 5: Build
step_header "Building $APP_NAME"
info "  Running: cargo build --release"
if confirm "Start build?"; then
  cd "$PROJECT_DIR"
  cargo build --release
  if [[ -f "target/release/$BINARY_NAME" ]]; then
    success "Build successful"
  else
    fail "Build failed - binary not found"
    exit 1
  fi
else
  exit 0
fi
confirm "Continue?" || exit 0

# Step 6: Install binary
step_header "Installing binary"
info "  From: $PROJECT_DIR/target/release/$BINARY_NAME"
info "  To: $BIN_DIR/$BINARY_NAME"
if confirm "Install binary?"; then
  mkdir -p "$BIN_DIR"
  cp "$PROJECT_DIR/target/release/$BINARY_NAME" "$BIN_DIR/$BINARY_NAME"
  chmod +x "$BIN_DIR/$BINARY_NAME"
  success "Binary installed"

  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "$BIN_DIR is not in your PATH"
    info "  Add this to your shell profile:"
    info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  else
    success "$BIN_DIR is in PATH"
  fi
else
  warn "Skipped binary installation"
fi
confirm "Continue?" || exit 0

# Step 7: Install config
step_header "Installing config"
info "  To: $CONFIG_DIR/config.toml"
if [[ -f "$CONFIG_DIR/config.toml" ]]; then
  warn "Config file already exists"
  if confirm "Overwrite existing config?"; then
    mkdir -p "$CONFIG_DIR"
    cp "$PROJECT_DIR/config/config.toml" "$CONFIG_DIR/config.toml"
    success "Config overwritten"
  else
    success "Existing config preserved"
  fi
else
  if confirm "Install default config?"; then
    mkdir -p "$CONFIG_DIR"
    cp "$PROJECT_DIR/config/config.toml" "$CONFIG_DIR/config.toml"
    success "Config installed"
  fi
fi
confirm "Continue?" || exit 0

# Step 8: Create data directory
step_header "Creating data directory"
info "  Path: $DATA_DIR"
if confirm "Create data directory?"; then
  mkdir -p "$DATA_DIR"
  if [[ ! -f "$DATA_DIR/pins.json" ]]; then
    echo '{"pins":[]}' > "$DATA_DIR/pins.json"
    success "pins.json initialized"
  else
    success "pins.json already exists"
  fi
  success "Data directory ready"
fi
confirm "Continue?" || exit 0

# Step 9: Detect Hyprland config mode
step_header "Detecting Hyprland configuration mode"
detect_hypr_mode
if [[ "$HYPR_MODE" == "lua" ]]; then
  success "Detected Lua-based Hyprland config"
  info "  Autostart : $HYPR_AUTOSTART"
  info "  Bindings  : $HYPR_BINDINGS"
  info "  Rules     : $HYPR_RULES"
else
  success "Detected .conf-based Hyprland config"
  info "  Autostart : $HYPR_AUTOSTART"
  info "  Bindings  : $HYPR_BINDINGS"
  info "  Rules     : $HYPR_RULES"
fi
confirm "Continue?" || exit 0

# Step 10: Install cliphist watcher helper
step_header "Installing cliphist watcher helper"
info "  To: $WATCHER_SCRIPT"
if confirm "Install watcher helper script?"; then
  mkdir -p "$BIN_DIR"
  cat << 'WATCHER_EOF' > "$WATCHER_SCRIPT"
#!/usr/bin/env bash
pkill -f 'wl-paste --type text --watch cliphist store' 2>/dev/null || true
pkill -f 'wl-paste --type image --watch cliphist store' 2>/dev/null || true

nohup wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
nohup wl-paste --type image --watch cliphist store >/dev/null 2>&1 &
WATCHER_EOF
  chmod +x "$WATCHER_SCRIPT"
  success "Watcher helper installed"
else
  warn "Skipped watcher helper installation"
fi
confirm "Continue?" || exit 0

# Step 11: Hyprland autostart
step_header "Configuring Hyprland autostart"
info "  File: $HYPR_AUTOSTART"

if [[ "$HYPR_MODE" == "lua" ]]; then
  AUTOSTART_START="-- BEGIN-edClipManager-autostart"
  AUTOSTART_END="-- END-edClipManager-autostart"
  AUTOSTART_BLOCK=$(cat <<AUTOSTART_EOF
-- BEGIN-edClipManager-autostart
o.launch_on_start("$WATCHER_SCRIPT")
-- END-edClipManager-autostart
AUTOSTART_EOF
)
else
  AUTOSTART_START="# edClipManager-Begin"
  AUTOSTART_END="# edClipManager-End"
  AUTOSTART_BLOCK=$(cat <<AUTOSTART_EOF
# edClipManager-Begin
exec-once = $WATCHER_SCRIPT
# edClipManager-End
AUTOSTART_EOF
)
fi

info "  Will write block:"
show_block "$AUTOSTART_BLOCK"

if confirm "Write autostart block?"; then
  upsert_block "$HYPR_AUTOSTART" "$AUTOSTART_START" "$AUTOSTART_END" "$AUTOSTART_BLOCK"
  success "Autostart block written"
fi
confirm "Continue?" || exit 0

# Step 12: Hyprland keybinding
step_header "Configuring Hyprland keybinding"
info "  File: $HYPR_BINDINGS"

if [[ "$HYPR_MODE" == "lua" ]]; then
  BINDING_START="-- edClipManager-Begin"
  BINDING_END="-- edClipManager-End"
  BINDING_BLOCK=$(cat <<BINDING_EOF
-- edClipManager-Begin
hl.unbind("SUPER + CTRL + V")
hl.bind(
    "SUPER + CTRL + V",
    hl.dsp.exec_cmd("kitty --class edclipmanager-float --override close_on_child_death=yes -e $BIN_DIR/$BINARY_NAME")
)
-- edClipManager-End
BINDING_EOF
)
else
  BINDING_START="# edClipManager-Begin"
  BINDING_END="# edClipManager-End"
  BINDING_BLOCK=$(cat <<BINDING_EOF
# edClipManager-Begin
unbind = SUPER CTRL, V
bind = SUPER CTRL, V, exec, kitty --class edClipManager --title edClipManager --override close_on_child_death=yes -e $BIN_DIR/$BINARY_NAME
# edClipManager-End
BINDING_EOF
)
fi

info "  Will write block:"
show_block "$BINDING_BLOCK"

if confirm "Write keybinding block?"; then
  upsert_block "$HYPR_BINDINGS" "$BINDING_START" "$BINDING_END" "$BINDING_BLOCK"
  success "Keybinding block written"
fi
confirm "Continue?" || exit 0

# Step 13: Hyprland window rules
step_header "Configuring Hyprland window rules"
info "  File: $HYPR_RULES"

if [[ "$HYPR_MODE" == "lua" ]]; then
  RULE_START="-- edClipManager-Begin"
  RULE_END="-- edClipManager-End"
  RULE_BLOCK=$(cat <<RULE_EOF
-- edClipManager-Begin
hl.window_rule({
    name = "EdClipManager Floating TUI",
    match = {
        class = "edclipmanager-float",
    },
    float = true,
    size = { 900, 600 },
    center = true,
    dim_around = true,
    stay_focused = true,
})
-- edClipManager-End
RULE_EOF
)
else
  RULE_START="# edClipManager-Begin"
  RULE_END="# edClipManager-End"
  RULE_BLOCK=$(cat <<RULE_EOF
# edClipManager-Begin
windowrule = float on, match:title ^(edClipManager)$
windowrule = center on, match:title ^(edClipManager)$
windowrule = size 800 600, match:title ^(edClipManager)$
# edClipManager-End
RULE_EOF
)
fi

info "  Will write block:"
show_block "$RULE_BLOCK"

if confirm "Write window-rules block?"; then
  upsert_block "$HYPR_RULES" "$RULE_START" "$RULE_END" "$RULE_BLOCK"
  success "Window-rules block written"
fi
confirm "Continue?" || exit 0

# Step 14: Start cliphist watchers now
step_header "Starting cliphist watchers now"
info "  Running: $WATCHER_SCRIPT"
if confirm "Start cliphist watchers now?"; then
  "$WATCHER_SCRIPT"
  sleep 1
  success "cliphist watchers started"
fi
confirm "Continue?" || exit 0

# Step 15: Reload Hyprland
step_header "Reloading Hyprland"
if confirm "Run hyprctl reload now?"; then
  if hyprctl reload; then
    success "Hyprland reloaded"
  else
    warn "hyprctl reload failed"
  fi
else
  warn "Skipped Hyprland reload"
fi

echo ""
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo -e "${BOLD}${GREEN}   Installation complete!${NC}"
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo ""
info "  Binary          : $BIN_DIR/$BINARY_NAME"
info "  Watcher helper  : $WATCHER_SCRIPT"
info "  Test            : Press Super+Ctrl+V"
echo ""
