# edClipManager

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Rust](https://img.shields.io/badge/Rust-2021-orange?logo=rust)
![Platform](https://img.shields.io/badge/platform-Linux-1793D1?logo=linux)
![Display](https://img.shields.io/badge/display-Wayland-6E56CF)
![WM](https://img.shields.io/badge/WM-Hyprland-00D9FF)
![UI](https://img.shields.io/badge/UI-Ratatui-8A2BE2)
![Backend](https://img.shields.io/badge/backend-cliphist-2ea44f)

A terminal UI clipboard manager for Wayland using `cliphist`, built with Rust + Ratatui and designed to integrate cleanly with Hyprland.

Supports both:

- traditional Hyprland `.conf` configs
- Lua-based Hyprland configs such as **Omarchy**

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
- 🔄 Hyprland integration for both `.conf` and `.lua`

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
| `kitty` | Yes | Floating terminal launcher |
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
- install a helper watcher script for `cliphist`
- install default config to `~/.config/edClipManager/config.toml`
- create pin storage at `~/.local/share/edClipManager/pins.json`
- detect Hyprland config mode (`.conf` or `.lua`)
- write managed Hyprland blocks
- start `cliphist` watchers immediately
- reload Hyprland

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

Default launcher:

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
| Watcher helper | `~/.local/bin/edclipmanager-cliphist-watch` |
| Config | `~/.config/edClipManager/config.toml` |
| Pin storage | `~/.local/share/edClipManager/pins.json` |
| Cliphist database | `~/.cache/cliphist/db` |

### Hyprland integration targets

| Item | `.conf` mode | `.lua` mode |
|---|---|---|
| Autostart | `~/.config/hypr/autostart.conf` | `~/.config/hypr/autostart.lua` |
| Keybinding | `~/.config/hypr/bindings.conf` | `~/.config/hypr/bindings.lua` |
| Window rules | `~/.config/hypr/hyprland.conf` | `~/.config/hypr/looknfeel.lua` |

---

## 🪟 Hyprland Integration

The installer writes **managed blocks** so re-install and uninstall stay clean.

### `.conf` mode

Markers:

```text
# edClipManager-Begin
# edClipManager-End
```

<details>
<summary><strong>Autostart block (.conf)</strong></summary>

```conf
# edClipManager-Begin
exec-once = /home/USER/.local/bin/edclipmanager-cliphist-watch
# edClipManager-End
```

</details>

<details>
<summary><strong>Keybinding block (.conf)</strong></summary>

```conf
# edClipManager-Begin
unbind = SUPER CTRL, V
bind = SUPER CTRL, V, exec, kitty --class edClipManager --title edClipManager --override close_on_child_death=yes -e /home/USER/.local/bin/edclipmanager
# edClipManager-End
```

</details>

<details>
<summary><strong>Window rules block (.conf)</strong></summary>

```conf
# edClipManager-Begin
windowrule = float on, match:title ^(edClipManager)$
windowrule = center on, match:title ^(edClipManager)$
windowrule = size 800 600, match:title ^(edClipManager)$
# edClipManager-End
```

</details>

### `.lua` mode / Omarchy

Markers:

```text
-- BEGIN-edClipManager-autostart
-- END-edClipManager-autostart
-- edClipManager-Begin
-- edClipManager-End
```

<details>
<summary><strong>Autostart block (.lua)</strong></summary>

```lua
-- BEGIN-edClipManager-autostart
o.launch_on_start("/home/USER/.local/bin/edclipmanager-cliphist-watch")
-- END-edClipManager-autostart
```

</details>

<details>
<summary><strong>Keybinding block (.lua)</strong></summary>

```lua
-- edClipManager-Begin
hl.unbind("SUPER + CTRL + V")
hl.bind(
    "SUPER + CTRL + V",
    hl.dsp.exec_cmd("kitty --class edclipmanager-float --override close_on_child_death=yes -e /home/USER/.local/bin/edclipmanager")
)
-- edClipManager-End
```

</details>

<details>
<summary><strong>Window rules block (.lua)</strong></summary>

```lua
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
```

</details>

> **Important:** Keybindings are written to `bindings.conf` or `bindings.lua`, never to `hyprland.conf`.

Reload Hyprland after install/uninstall:

```bash
hyprctl reload
```

---

## 🧠 How It Works

- `cliphist list` provides clipboard entries
- `cliphist decode` restores full item contents
- `wl-copy` writes data back to the Wayland clipboard
- a helper watcher script runs `wl-paste --watch cliphist store`
- pinned items are stored in JSON via `serde_json`
- UI state is managed centrally in `src/app.rs`
- keyboard events are handled in `src/event.rs`
- rendering is split into dedicated UI modules under `src/ui/`

> **Omarchy note:** Omarchy ships its own clipboard watcher plugin, but it does not feed `cliphist` directly for this app's needs. `edClipManager` installs a dedicated `cliphist` watcher alongside it.

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
- watcher helper script
- config directory
- data directory
- Hyprland autostart block
- Hyprland keybinding block
- Hyprland window rule block

It checks both `.conf` and `.lua` Hyprland layouts.

After uninstall:

```bash
hyprctl reload
```

---

## 📝 Notes

- Linux only
- Wayland only
- designed for Hyprland integration
- `cliphist` is required for clipboard history features
- pinned text entries are stored with full text content in JSON
- image pins still depend on the original `cliphist` item ID for clipboard restoration
- Omarchy users need the dedicated `cliphist` watcher installed by this project

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
| `.lua` / Omarchy support | Included |

---

## 🤝 Contributing

Issues and improvements are welcome. When proposing changes, keep these constraints in mind:

- stay compatible with Wayland
- preserve Hyprland keybinding integration
- support both `.conf` and `.lua` Hyprland configurations
- avoid unnecessary external dependencies
- keep the TUI workflow fast and keyboard-first
