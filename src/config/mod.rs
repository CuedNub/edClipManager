pub mod theme;

use serde::Deserialize;
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Deserialize, Clone)]
pub struct AppConfig {
    pub general: GeneralConfig,
    pub theme: ThemeConfig,
}

#[derive(Debug, Deserialize, Clone)]
#[allow(dead_code)]
pub struct GeneralConfig {
    pub max_history: usize,
    pub pin_storage: String,
    pub image_label_format: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ThemeConfig {
    pub window: WindowTheme,
    pub search: SearchTheme,
    pub tabs: TabsTheme,
    pub list: ListTheme,
    pub statusbar: StatusbarTheme,
    pub dialog: DialogTheme,
}

#[derive(Debug, Deserialize, Clone)]
#[allow(dead_code)]
pub struct WindowTheme {
    pub background: String,
    pub border: String,
    pub title_fg: String,
    pub title_bg: String,
}

#[derive(Debug, Deserialize, Clone)]
#[allow(dead_code)]
pub struct SearchTheme {
    pub border_active: String,
    pub border_inactive: String,
    pub input_fg: String,
    pub input_bg: String,
    pub placeholder_fg: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct TabsTheme {
    pub active_fg: String,
    pub active_bg: String,
    pub inactive_fg: String,
    pub inactive_bg: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ListTheme {
    pub item_fg: String,
    pub item_bg: String,
    pub selected_fg: String,
    pub selected_bg: String,
    pub marked_fg: String,
    pub marked_bg: String,
    pub pin_indicator: String,
    pub image_label: String,
    pub border: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct StatusbarTheme {
    pub background: String,
    pub bracket_fg: String,
    pub key_fg: String,
    pub label_fg: String,
    pub separator_fg: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DialogTheme {
    pub border: String,
    pub title_fg: String,
    pub message_fg: String,
    pub background: String,
    pub yes_fg: String,
    pub no_fg: String,
}

impl AppConfig {
    pub fn load() -> Self {
        let config_path = Self::config_path();
        if config_path.exists() {
            match fs::read_to_string(&config_path) {
                Ok(content) => match toml::from_str(&content) {
                    Ok(config) => return config,
                    Err(e) => eprintln!("Config parse error: {}, using defaults", e),
                },
                Err(e) => eprintln!("Config read error: {}, using defaults", e),
            }
        }
        Self::default()
    }

    fn config_path() -> PathBuf {
        dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("~/.config"))
            .join("edClipManager")
            .join("config.toml")
    }

    pub fn resolve_pin_storage(&self) -> PathBuf {
        let path = self.general.pin_storage.replace(
            "~",
            &dirs::home_dir()
                .unwrap_or_else(|| PathBuf::from("/tmp"))
                .to_string_lossy(),
        );
        PathBuf::from(path)
    }

    fn default() -> Self {
        let default_toml = include_str!("../../config/config.toml");
        toml::from_str(default_toml).expect("Default config must be valid")
    }
}
