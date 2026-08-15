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

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

STEP=0
TOTAL=9

info()    { echo -e "${CYAN}$1${NC}"; }
success() { echo -e "${GREEN}  ✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}  ⚠ $1${NC}"; }
fail()    { echo -e "${RED}  ✗ $1${NC}"; }

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

remove_block() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if ! grep -qF "$start_marker" "$file"; then
        return 1
    fi

    local tmp
    tmp="$(mktemp)"

    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { inblock = 1; next }
        inblock && $0 == end { inblock = 0; next }
        !inblock { print }
    ' "$file" > "$tmp"

    # Remove consecutive blank lines
    sed -i '/^$/N;/^\n$/d' "$tmp"

    mv "$tmp" "$file"
    return 0
}

detect_hypr_mode() {
    if [[ -f "$HYPR_AUTOSTART_LUA" || -f "$HYPR_BINDINGS_LUA" || -f "$HYPR_LOOKNFEEL_LUA" ]]; then
        HYPR_MODE="lua"
    else
        HYPR_MODE="conf"
    fi
}

echo ""
echo -e "${BOLD}${RED}=======================================${NC}"
echo -e "${BOLD}${RED}   $APP_NAME Uninstaller v1.1${NC}"
echo -e "${BOLD}${RED}=======================================${NC}"

# Step 1: Stop cliphist watchers
step_header "Stop cliphist watchers"
info "  Stopping any running cliphist watchers..."
if confirm "Stop cliphist watchers?"; then
    pkill -f 'wl-paste --type text --watch cliphist store' 2>/dev/null || true
    pkill -f 'wl-paste --type image --watch cliphist store' 2>/dev/null || true
    success "Watchers stopped"
else
    warn "Skipped"
fi

# Step 2: Remove binary
step_header "Remove binary"
if [[ -f "$BIN_DIR/$BINARY_NAME" ]]; then
    info "  $BIN_DIR/$BINARY_NAME"
    if confirm "Remove binary?"; then
        rm -f "$BIN_DIR/$BINARY_NAME"
        success "Binary removed"
    else
        warn "Skipped"
    fi
else
    success "Binary not found, nothing to remove"
fi

# Step 3: Remove watcher helper script
step_header "Remove watcher helper script"
if [[ -f "$WATCHER_SCRIPT" ]]; then
    info "  $WATCHER_SCRIPT"
    if confirm "Remove watcher helper script?"; then
        rm -f "$WATCHER_SCRIPT"
        success "Watcher helper removed"
    else
        warn "Skipped"
    fi
else
    success "Watcher helper not found, nothing to remove"
fi

# Step 4: Remove config directory
step_header "Remove config directory"
if [[ -d "$CONFIG_DIR" ]]; then
    info "  $CONFIG_DIR/"
    ls -la "$CONFIG_DIR/" 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        info "    $line"
    done
    if confirm "Remove config directory?"; then
        rm -rf "$CONFIG_DIR"
        success "Config directory removed"
    else
        warn "Skipped"
    fi
else
    success "Config directory not found, nothing to remove"
fi

# Step 5: Remove data directory
step_header "Remove data directory"
if [[ -d "$DATA_DIR" ]]; then
    info "  $DATA_DIR/"
    ls -la "$DATA_DIR/" 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        info "    $line"
    done
    warn "This will delete all pinned items!"
    if confirm "Remove data directory?"; then
        rm -rf "$DATA_DIR"
        success "Data directory removed"
    else
        warn "Skipped"
    fi
else
    success "Data directory not found, nothing to remove"
fi

# Step 6: Detect Hyprland config mode
step_header "Detect Hyprland configuration mode"
detect_hypr_mode
if [[ "$HYPR_MODE" == "lua" ]]; then
    success "Detected Lua-based Hyprland config (Omarchy)"
else
    success "Detected .conf-based Hyprland config"
fi

# Step 7: Remove Hyprland autostart entries
step_header "Remove Hyprland autostart entries"

AUTOSTART_REMOVED=false

# Try .lua first
if [[ -f "$HYPR_AUTOSTART_LUA" ]]; then
    if remove_block "$HYPR_AUTOSTART_LUA" "-- BEGIN-edClipManager-autostart" "-- END-edClipManager-autostart"; then
        info "  Removed block from: $HYPR_AUTOSTART_LUA"
        AUTOSTART_REMOVED=true
    fi
fi

# Try .conf
if [[ -f "$HYPR_AUTOSTART_CONF" ]]; then
    if remove_block "$HYPR_AUTOSTART_CONF" "# edClipManager-Begin" "# edClipManager-End"; then
        info "  Removed block from: $HYPR_AUTOSTART_CONF"
        AUTOSTART_REMOVED=true
    fi
fi

if [[ "$AUTOSTART_REMOVED" == true ]]; then
    success "Autostart entries removed"
else
    success "No autostart entries found"
fi

# Step 8: Remove Hyprland keybinding entries
step_header "Remove Hyprland keybinding entries"

BINDING_REMOVED=false

# Try .lua first
if [[ -f "$HYPR_BINDINGS_LUA" ]]; then
    if remove_block "$HYPR_BINDINGS_LUA" "-- edClipManager-Begin" "-- edClipManager-End"; then
        info "  Removed block from: $HYPR_BINDINGS_LUA"
        BINDING_REMOVED=true
    fi
fi

# Try .conf
if [[ -f "$HYPR_BINDINGS_CONF" ]]; then
    if remove_block "$HYPR_BINDINGS_CONF" "# edClipManager-Begin" "# edClipManager-End"; then
        info "  Removed block from: $HYPR_BINDINGS_CONF"
        BINDING_REMOVED=true
    fi
fi

if [[ "$BINDING_REMOVED" == true ]]; then
    success "Keybinding entries removed"
else
    success "No keybinding entries found"
fi

# Step 9: Remove Hyprland window rules
step_header "Remove Hyprland window rules"

RULES_REMOVED=false

# Try looknfeel.lua first (Omarchy)
if [[ -f "$HYPR_LOOKNFEEL_LUA" ]]; then
    if remove_block "$HYPR_LOOKNFEEL_LUA" "-- edClipManager-Begin" "-- edClipManager-End"; then
        info "  Removed block from: $HYPR_LOOKNFEEL_LUA"
        RULES_REMOVED=true
    fi
fi

# Try hyprland.conf
if [[ -f "$HYPR_MAIN_CONF" ]]; then
    if remove_block "$HYPR_MAIN_CONF" "# edClipManager-Begin" "# edClipManager-End"; then
        info "  Removed block from: $HYPR_MAIN_CONF"
        RULES_REMOVED=true
    fi
fi

if [[ "$RULES_REMOVED" == true ]]; then
    success "Window rules removed"
else
    success "No window rules found"
fi

echo ""
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo -e "${BOLD}${GREEN}   Uninstallation complete!${NC}"
echo -e "${BOLD}${GREEN}=======================================${NC}"
echo ""
info "  Reload Hyprland: hyprctl reload"
echo ""
