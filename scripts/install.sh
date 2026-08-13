#!/usr/bin/env bash

set -e

APP_NAME="edClipManager"
BINARY_NAME="edclipmanager"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/$APP_NAME"
DATA_DIR="$HOME/.local/share/$APP_NAME"
HYPR_AUTOSTART="$HOME/.config/hypr/autostart.conf"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.conf"
HYPR_MAIN="$HOME/.config/hypr/hyprland.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

STEP=0
TOTAL=11

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
  [yY] | [yY][eE][sS]) return 0 ;;
  *) return 1 ;;
  esac
}

step_header() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${BOLD}[Step $STEP/$TOTAL] $1${NC}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${BOLD}${CYAN}=======================================${NC}"
echo -e "${BOLD}${CYAN}   $APP_NAME Installer v1.0${NC}"
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
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
  success "Wayland session detected"
else
  fail "Wayland session not detected (XDG_SESSION_TYPE=$XDG_SESSION_TYPE)"
  warn "This application requires Wayland"
  confirm "Continue anyway?" || exit 0
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
  info "  Or use your distribution's package manager"
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
    info "  Add this to your ~/.bashrc or ~/.zshrc:"
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
    echo '{"pins":[]}' >"$DATA_DIR/pins.json"
    success "pins.json initialized"
  else
    success "pins.json already exists"
  fi
  success "Data directory ready"
fi
confirm "Continue?" || exit 0

# Step 9: Hyprland autostart
step_header "Configuring Hyprland autostart"
info "  File: $HYPR_AUTOSTART"

AUTOSTART_BLOCK="# edClipManager-Begin
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
# edClipManager-End"

if [[ -f "$HYPR_AUTOSTART" ]] && grep -q "edClipManager-Begin" "$HYPR_AUTOSTART"; then
  warn "edClipManager block already exists in autostart.conf"
  success "Skipping"
else
  info "  Will add:"
  echo "$AUTOSTART_BLOCK" | while IFS= read -r line; do
    info "    $line"
  done
  if confirm "Add autostart entries?"; then
    mkdir -p "$(dirname "$HYPR_AUTOSTART")"
    touch "$HYPR_AUTOSTART"
    echo "" >>"$HYPR_AUTOSTART"
    echo "$AUTOSTART_BLOCK" >>"$HYPR_AUTOSTART"
    success "Autostart entries added"
  fi
fi
confirm "Continue?" || exit 0

# Step 10: Hyprland keybinding
step_header "Configuring Hyprland keybinding"
info "  File: $HYPR_BINDINGS"

BINDING_BLOCK="# edClipManager-Begin
unbind = SUPER CTRL, V
bind = SUPER CTRL, V, exec, kitty --class edClipManager --title edClipManager --override close_on_child_death=yes -e $BINARY_NAME
# edClipManager-End"

if [[ -f "$HYPR_BINDINGS" ]] && grep -q "edClipManager-Begin" "$HYPR_BINDINGS"; then
  warn "edClipManager block already exists in bindings.conf"
  success "Skipping"
else
  info "  Will add:"
  echo "$BINDING_BLOCK" | while IFS= read -r line; do
    info "    $line"
  done
  if confirm "Add keybinding?"; then
    mkdir -p "$(dirname "$HYPR_BINDINGS")"
    touch "$HYPR_BINDINGS"
    echo "" >>"$HYPR_BINDINGS"
    echo "$BINDING_BLOCK" >>"$HYPR_BINDINGS"
    success "Keybinding added"
  fi
fi

# Step 11: Hyprland window rules
step_header "Configuring Hyprland window rules"
info "  File: $HYPR_MAIN"

RULE_BLOCK="# edClipManager-Begin
windowrule = float on, match:title ^(edClipManager)$
windowrule = center on, match:title ^(edClipManager)$
windowrule = size 800 600, match:title ^(edClipManager)$
# edClipManager-End"

if [[ -f "$HYPR_MAIN" ]] && grep -q "edClipManager-Begin" "$HYPR_MAIN"; then
  warn "edClipManager block already exists in hyprland.conf"
  success "Skipping"
else
  info "  Will add:"
  echo "$RULE_BLOCK" | while IFS= read -r line; do
    info "    $line"
  done
  if confirm "Add window rules?"; then
    mkdir -p "$(dirname "$HYPR_MAIN")"
    touch "$HYPR_MAIN"
    echo "" >>"$HYPR_MAIN"
    echo "$RULE_BLOCK" >>"$HYPR_MAIN"
    success "Window rules added"
  fi
fi

echo ""
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo -e "${BOLD}${GREEN}   Installation complete!${NC}"
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo ""
info "  Reload Hyprland: hyprctl reload"
info "  Test: Press Super+Ctrl+V"
echo ""
