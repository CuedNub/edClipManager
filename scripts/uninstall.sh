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
TOTAL=6

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

echo ""
echo -e "${BOLD}${RED}=======================================${NC}"
echo -e "${BOLD}${RED}   $APP_NAME Uninstaller v1.0${NC}"
echo -e "${BOLD}${RED}=======================================${NC}"

# Step 1: Remove binary
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

# Step 2: Remove config
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

# Step 3: Remove data
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

# Step 4: Remove Hyprland autostart entries
step_header "Remove Hyprland autostart entries"
if [[ -f "$HYPR_AUTOSTART" ]] && grep -q "edClipManager-Begin" "$HYPR_AUTOSTART"; then
    info "  File: $HYPR_AUTOSTART"
    info "  Will remove edClipManager block"
    if confirm "Remove autostart entries?"; then
        sed -i '/# edClipManager-Begin/,/# edClipManager-End/d' "$HYPR_AUTOSTART"
        sed -i '/^$/N;/^\n$/d' "$HYPR_AUTOSTART"
        success "Autostart entries removed"
    else
        warn "Skipped"
    fi
else
    success "No autostart entries found"
fi

# Step 5: Remove Hyprland keybinding
step_header "Remove Hyprland keybinding"
if [[ -f "$HYPR_BINDINGS" ]] && grep -q "edClipManager-Begin" "$HYPR_BINDINGS"; then
    info "  File: $HYPR_BINDINGS"
    info "  Will remove edClipManager block"
    if confirm "Remove keybinding?"; then
        sed -i '/# edClipManager-Begin/,/# edClipManager-End/d' "$HYPR_BINDINGS"
        sed -i '/^$/N;/^\n$/d' "$HYPR_BINDINGS"
        success "Keybinding removed"
    else
        warn "Skipped"
    fi
else
    success "No keybinding entries found"
fi

# Step 6: Remove Hyprland window rules
step_header "Remove Hyprland window rules"
if [[ -f "$HYPR_MAIN" ]] && grep -q "edClipManager-Begin" "$HYPR_MAIN"; then
    info "  File: $HYPR_MAIN"
    info "  Will remove edClipManager block"
    if confirm "Remove window rules?"; then
        sed -i '/# edClipManager-Begin/,/# edClipManager-End/d' "$HYPR_MAIN"
        sed -i '/^$/N;/^\n$/d' "$HYPR_MAIN"
        success "Window rules removed"
    else
        warn "Skipped"
    fi
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
