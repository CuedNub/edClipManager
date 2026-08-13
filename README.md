# edClipManager

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Rust](https://img.shields.io/badge/Rust-2021-orange?logo=rust)
![Platform](https://img.shields.io/badge/platform-Linux-1793D1?logo=linux)
![Display](https://img.shields.io/badge/display-Wayland-6E56CF)
![WM](https://img.shields.io/badge/WM-Hyprland-00D9FF)
![UI](https://img.shields.io/badge/UI-Ratatui-8A2BE2)
![Backend](https://img.shields.io/badge/backend-cliphist-2ea44f)

A terminal UI clipboard manager for Wayland using `cliphist`, built with Rust + Ratatui and designed to integrate cleanly with Hyprland.

---

## ✨ Features

- 🔎 Real-time search/filter
- 📋 Browse clipboard history from `cliphist`
- 📌 Pin important entries
- 🖼️ Text and image item support
- ✅ Multi-select with batch actions
- 🗑️ Delete selected items or wipe all items in the active tab
- 🪟 Floating Kitty window integration for Hyprland
- 🎨 Theme and behavior configuration via TOML
- ❓ Built-in help screen
- 🧹 Installer and uninstaller scripts included

---

## 🧰 Tech Stack

| Component | Value |
|---|---|
| Language | Rust 2021 |
| TUI | Ratatui `0.29` |
| Terminal backend | Crossterm `0.28` |
| Clipboard backend | `cliphist` |
| Clipboard I/O | `wl-copy`, `wl-paste` |
| Config format | TOML |
| Pin storage | JSON |

---

## 📦 Requirements

| Dependency | Required | Purpose |
|---|---:|---|
| `cliphist` | Yes | Clipboard history backend |
| `wl-copy` | Yes | Copy data back to Wayland clipboard |
| `wl-paste` | Yes | Watch clipboard changes for `cliphist store` |
| `kitty` | Yes | Floating terminal window launcher |
| `hyprctl` | Yes | Reload Hyprland after config changes |
| `cargo` | Build only | Build the Rust binary |

### Arch Linux packages

```bash
sudo pacman -S wl-clipboard cliphist kitty hyprland
```

If Rust is not installed:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

---

## 🚀 Installation

### Option 1 — Installer script

From the project root:

```bash
bash scripts/install.sh
```

The installer will:

- check Linux + Wayland session
- check required commands
- check or install Rust toolchain
- build the release binary
- install the binary to `~/.local/bin/edclipmanager`
- install default config to `~/.config/edClipManager/config.toml`
- create pin storage in `~/.local/share/edClipManager/pins.json`
- add Hyprland autostart entries
- add Hyprland keybinding
- add Hyprland window rules

### Option 2 — Manual build

```bash
cargo build --release
```

Binary output:

```bash
target/release/edclipmanager
```

---

## ▶️ Usage

### Launch manually

```bash
edclipmanager
```

### Launch via Hyprland keybinding

After installation, the default launcher is:

- `Super + Ctrl + V`

This opens the app in a floating Kitty window.

---

## ⌨️ Keybindings

### Global Hyprland binding

| Key | Action |
|---|---|
| `Super + Ctrl + V` | Open `edclipmanager` in Kitty |

### In-app controls

| Key | Action |
|---|---|
| `Ctrl + j` / `Ctrl + k` | Move down / up |
| `↓` / `↑` | Move down / up |
| `Enter` | Copy selected item to clipboard and quit |
| `Ctrl + Space` | Toggle mark |
| `Ctrl + p` | Pin / unpin selected item or all marked items |
| `Ctrl + d` | Delete selected item or all marked items |
| `Ctrl + Alt + d` | Delete all items in active tab |
| `Tab` | Switch between Clipboard / Pin tabs |
| `Ctrl + h` | Toggle help |
| `Esc` / `q` | Quit or close dialog/help |
| `←` / `→` | Move search cursor |
| `Backspace` | Delete char before cursor |
| `Delete` | Delete char at cursor |
| Type any character | Search immediately |

---

## ⚙️ Configuration

Config file path:

```text
~/.config/edClipManager/config.toml
```

### Main options

| Key | Description |
|---|---|
| `general.max_history` | Maximum clipboard history items to load |
| `general.pin_storage` | JSON file used to store pinned items |
| `general.image_label_format` | Label format for image entries |
| `theme.*` | Colors for UI components |

<details>
<summary><strong>Default config</strong></summary>

```toml
[general]
max_history = 750
pin_storage = "~/.local/share/edClipManager/pins.json"
image_label_format = "[{mime} - {size}]"

[theme.window]
background = "#1e1e2e"
border = "#89b4fa"
title_fg = "#cdd6f4"
title_bg = "#1e1e2e"

[theme.search]
border_active = "#f9e2af"
border_inactive = "#45475a"
input_fg = "#cdd6f4"
input_bg = "#1e1e2e"
placeholder_fg = "#6c7086"

[theme.tabs]
active_fg = "#1e1e2e"
active_bg = "#89b4fa"
inactive_fg = "#a6adc8"
inactive_bg = "#313244"

[theme.list]
item_fg = "#f9e2af"
item_bg = "#1e1e2e"
selected_fg = "#000000"
selected_bg = "#89dceb"
marked_fg = "#1e1e2e"
marked_bg = "#cba6f7"
pin_indicator = "#a6e3a1"
image_label = "#fab387"
border = "#45475a"

[theme.statusbar]
background = "#181825"
bracket_fg = "#585b70"
key_fg = "#f9e2af"
label_fg = "#a6adc8"
separator_fg = "#45475a"

[theme.dialog]
border = "#f38ba8"
title_fg = "#f38ba8"
message_fg = "#cdd6f4"
background = "#1e1e2e"
yes_fg = "#a6e3a1"
no_fg = "#f38ba8"
```

</details>

---

## 🗂️ Paths

| Item | Path |
|---|---|
| Binary | `~/.local/bin/edclipmanager` |
| Config | `~/.config/edClipManager/config.toml` |
| Pin storage | `~/.local/share/edClipManager/pins.json` |
| Cliphist database | `~/.cache/cliphist/db` |
| Hyprland keybinding | `~/.config/hypr/bindings.conf` |
| Hyprland autostart | `~/.config/hypr/autostart.conf` |
| Hyprland window rules | `~/.config/hypr/hyprland.conf` |

---

## 🪟 Hyprland Integration

The installer adds three managed blocks marked with:

```text
# edClipManager-Begin
# edClipManager-End
```

### Autostart block

```conf
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```

### Keybinding block

```conf
unbind = SUPER CTRL, V
bind = SUPER CTRL, V, exec, kitty --class edClipManager --title edClipManager --override close_on_child_death=yes -e edclipmanager
```

### Window rules block

```conf
windowrule = float on, match:title ^(edClipManager)$
windowrule = center on, match:title ^(edClipManager)$
windowrule = size 800 600, match:title ^(edClipManager)$
```

> **Important:** keybindings are written to `~/.config/hypr/bindings.conf`.

Reload Hyprland after install/uninstall:

```bash
hyprctl reload
```

---

## 🧠 How It Works

- `cliphist list` provides clipboard entries
- `cliphist decode <id>` restores full item contents
- `wl-copy` writes data back to the Wayland clipboard
- Pinned items are stored in JSON via `serde_json`
- UI state is managed centrally in `src/app.rs`
- Keyboard events are handled in `src/event.rs`
- Rendering is split into dedicated UI modules under `src/ui/`

---

## 📁 Project Structure

<details>
<summary><strong>Repository layout</strong></summary>

```text
config/
  config.toml

scripts/
  install.sh
  uninstall.sh

src/
  clipboard/
    cliphist.rs
    mod.rs
    pin.rs
  config/
    mod.rs
    theme.rs
  ui/
    dialog.rs
    help.rs
    list.rs
    mod.rs
    search.rs
    statusbar.rs
    tabs.rs
  app.rs
  event.rs
  main.rs

.gitignore
Cargo.toml
```

</details>

<details>
<summary><strong>Module overview</strong></summary>

| File | Purpose |
|---|---|
| `src/main.rs` | App entry point, terminal setup, main loop |
| `src/app.rs` | Application state and business logic |
| `src/event.rs` | Keyboard input handling by app mode |
| `src/clipboard/cliphist.rs` | `cliphist` / `wl-copy` process integration |
| `src/clipboard/pin.rs` | Pin storage load/save and pin operations |
| `src/config/mod.rs` | Config loading and path resolution |
| `src/config/theme.rs` | Hex-to-color/theme helpers |
| `src/ui/*.rs` | UI widgets and layout rendering |
| `scripts/install.sh` | Guided installer |
| `scripts/uninstall.sh` | Guided uninstaller |

</details>

---

## 🗑️ Uninstall

```bash
bash scripts/uninstall.sh
```

The uninstaller can remove:

- installed binary
- config directory
- data directory
- Hyprland autostart block
- Hyprland keybinding block
- Hyprland window rule block

Then reload Hyprland:

```bash
hyprctl reload
```

---

## 📝 Notes

- Linux only
- Wayland only
- Designed for Hyprland integration
- `cliphist` is required for clipboard history features
- Pinned text entries are stored with full text content in JSON
- Image pins still depend on the original `cliphist` item ID for clipboard restoration

---

## 🛠️ Development

### Build

```bash
cargo build
```

### Release build

```bash
cargo build --release
```

### Run from source

```bash
cargo run
```

---

## ✅ Current Behavior Summary

| Area | Behavior |
|---|---|
| Clipboard history | Loaded from `cliphist` |
| Search | Always active |
| Tabs | Clipboard / Pin |
| Multi-select | Supported via mark toggle |
| Delete selected | Supported |
| Delete all | Supported with confirmation |
| Help screen | Built-in |
| Theming | TOML-based |
| Hyprland launcher | Included |

---

## 🤝 Contributing

Issues and improvements are welcome. When proposing changes, keep these constraints in mind:

- stay compatible with Wayland
- preserve Hyprland keybinding integration in `bindings.conf`
- avoid introducing unnecessary external dependencies
- keep the TUI workflow fast and keyboard-first
