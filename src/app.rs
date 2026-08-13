use crate::clipboard::cliphist::{self, CliphistItem};
use crate::clipboard::pin::PinStorage;
use crate::config::AppConfig;
use std::collections::HashSet;
use std::path::PathBuf;

#[derive(Debug, Clone, PartialEq)]
pub enum ActiveTab {
    Clipboard,
    Pin,
}

#[derive(Debug, Clone, PartialEq)]
pub enum AppMode {
    Normal,
    ConfirmDeleteAll,
    Help,
}

pub struct App {
    pub config: AppConfig,
    pub active_tab: ActiveTab,
    pub mode: AppMode,
    pub search_query: String,
    pub cursor_position: usize,
    pub clipboard_items: Vec<CliphistItem>,
    pub filtered_items: Vec<CliphistItem>,
    pub list_state_index: Option<usize>,
    pub marked_ids: HashSet<String>,
    pub pin_storage: PinStorage,
    pub pin_path: PathBuf,
    pub should_quit: bool,
}

impl App {
    pub fn new(config: AppConfig) -> Self {
        let pin_path = config.resolve_pin_storage();
        let pin_storage = PinStorage::load(&pin_path);
        let clipboard_items = cliphist::list_items(config.general.max_history);

        let mut app = App {
            config,
            active_tab: ActiveTab::Clipboard,
            mode: AppMode::Normal,
            search_query: String::new(),
            cursor_position: 0,
            clipboard_items,
            filtered_items: Vec::new(),
            list_state_index: None,
            marked_ids: HashSet::new(),
            pin_storage,
            pin_path,
            should_quit: false,
        };
        app.apply_filter();
        app
    }

    pub fn apply_filter(&mut self) {
        let query = self.search_query.clone();
        match self.active_tab {
            ActiveTab::Clipboard => {
                self.filtered_items = self
                    .clipboard_items
                    .iter()
                    .filter(|item| item.matches_search(&query))
                    .cloned()
                    .collect();
            }
            ActiveTab::Pin => {
                self.filtered_items = self
                    .pin_storage
                    .to_cliphist_items()
                    .into_iter()
                    .filter(|item| item.matches_search(&query))
                    .collect();
            }
        }

        if self.filtered_items.is_empty() {
            self.list_state_index = None;
        } else if let Some(idx) = self.list_state_index {
            if idx >= self.filtered_items.len() {
                self.list_state_index = Some(self.filtered_items.len() - 1);
            }
        } else {
            self.list_state_index = Some(0);
        }
    }

    pub fn refresh_clipboard(&mut self) {
        self.clipboard_items = cliphist::list_items(self.config.general.max_history);
        self.apply_filter();
    }

    pub fn switch_tab(&mut self) {
        self.active_tab = match self.active_tab {
            ActiveTab::Clipboard => ActiveTab::Pin,
            ActiveTab::Pin => ActiveTab::Clipboard,
        };
        self.marked_ids.clear();
        self.list_state_index = None;
        self.apply_filter();
    }

    pub fn move_selection_down(&mut self) {
        if self.filtered_items.is_empty() {
            return;
        }
        self.list_state_index = Some(match self.list_state_index {
            Some(idx) => {
                if idx >= self.filtered_items.len() - 1 {
                    0
                } else {
                    idx + 1
                }
            }
            None => 0,
        });
    }

    pub fn move_selection_up(&mut self) {
        if self.filtered_items.is_empty() {
            return;
        }
        self.list_state_index = Some(match self.list_state_index {
            Some(idx) => {
                if idx == 0 {
                    self.filtered_items.len() - 1
                } else {
                    idx - 1
                }
            }
            None => self.filtered_items.len() - 1,
        });
    }

    pub fn toggle_mark(&mut self) {
        if let Some(idx) = self.list_state_index {
            if let Some(item) = self.filtered_items.get(idx) {
                let id = item.id.clone();
                if self.marked_ids.contains(&id) {
                    self.marked_ids.remove(&id);
                } else {
                    self.marked_ids.insert(id);
                }
            }
        }
    }

    pub fn selected_item(&self) -> Option<&CliphistItem> {
        self.list_state_index
            .and_then(|idx| self.filtered_items.get(idx))
    }

    pub fn copy_selected_and_quit(&mut self) {
        if let Some(item) = self.selected_item() {
            let id = item.id.clone();
            let content = item.content.clone();
            let is_image = item.is_image;

            // FIX #2: Logika copy yang benar per tab
            let success = match self.active_tab {
                ActiveTab::Clipboard => {
                    // Dari clipboard history: selalu gunakan cliphist decode
                    cliphist::copy_to_clipboard(&id)
                }
                ActiveTab::Pin => {
                    if is_image {
                        // Image pin: harus decode dari cliphist (binary data)
                        cliphist::copy_to_clipboard(&id)
                    } else {
                        // Teks pin: gunakan content tersimpan (independen dari cliphist)
                        cliphist::copy_text_to_clipboard(&content)
                    }
                }
            };

            if success {
                self.should_quit = true;
            }
        }
    }

    pub fn pin_selected(&mut self) {
        let items_to_pin: Vec<CliphistItem> = if !self.marked_ids.is_empty() {
            self.filtered_items
                .iter()
                .filter(|item| self.marked_ids.contains(&item.id))
                .cloned()
                .collect()
        } else if let Some(item) = self.selected_item() {
            vec![item.clone()]
        } else {
            return;
        };

        for item in &items_to_pin {
            if self.pin_storage.is_pinned(&item.id) {
                self.pin_storage.unpin_item(&item.id);
            } else {
                self.pin_storage.pin_item(item);
            }
        }

        self.marked_ids.clear();
        let _ = self.pin_storage.save(&self.pin_path);
        self.apply_filter();
    }

    pub fn delete_selected(&mut self) {
        let items_to_delete: Vec<String> = if !self.marked_ids.is_empty() {
            self.marked_ids.iter().cloned().collect()
        } else if let Some(item) = self.selected_item() {
            vec![item.id.clone()]
        } else {
            return;
        };

        match self.active_tab {
            ActiveTab::Clipboard => {
                for id in &items_to_delete {
                    cliphist::delete_item(id);
                }
                self.refresh_clipboard();
            }
            ActiveTab::Pin => {
                self.pin_storage.remove_by_ids(&items_to_delete);
                let _ = self.pin_storage.save(&self.pin_path);
                self.apply_filter();
            }
        }

        self.marked_ids.clear();
    }

    pub fn confirm_delete_all(&mut self) {
        self.mode = AppMode::ConfirmDeleteAll;
    }

    pub fn execute_delete_all(&mut self) {
        match self.active_tab {
            ActiveTab::Clipboard => {
                cliphist::wipe_all();
                self.refresh_clipboard();
            }
            ActiveTab::Pin => {
                self.pin_storage.clear_all();
                let _ = self.pin_storage.save(&self.pin_path);
                self.apply_filter();
            }
        }
        self.marked_ids.clear();
        self.mode = AppMode::Normal;
    }

    pub fn cancel_dialog(&mut self) {
        self.mode = AppMode::Normal;
    }

    pub fn toggle_help(&mut self) {
        self.mode = if self.mode == AppMode::Help {
            AppMode::Normal
        } else {
            AppMode::Help
        };
    }

    pub fn insert_char(&mut self, c: char) {
        self.search_query.insert(self.cursor_position, c);
        self.cursor_position += c.len_utf8();
        self.apply_filter();
    }

    pub fn delete_char_before_cursor(&mut self) {
        if self.cursor_position > 0 {
            let prev = self.search_query[..self.cursor_position]
                .chars()
                .last()
                .map(|c| c.len_utf8())
                .unwrap_or(0);
            self.search_query
                .replace_range((self.cursor_position - prev)..self.cursor_position, "");
            self.cursor_position -= prev;
            self.apply_filter();
        }
    }

    pub fn delete_char_at_cursor(&mut self) {
        if self.cursor_position < self.search_query.len() {
            let next = self.search_query[self.cursor_position..]
                .chars()
                .next()
                .map(|c| c.len_utf8())
                .unwrap_or(0);
            self.search_query
                .replace_range(self.cursor_position..(self.cursor_position + next), "");
            self.apply_filter();
        }
    }

    pub fn move_cursor_left(&mut self) {
        if self.cursor_position > 0 {
            let prev = self.search_query[..self.cursor_position]
                .chars()
                .last()
                .map(|c| c.len_utf8())
                .unwrap_or(0);
            self.cursor_position -= prev;
        }
    }

    pub fn move_cursor_right(&mut self) {
        if self.cursor_position < self.search_query.len() {
            let next = self.search_query[self.cursor_position..]
                .chars()
                .next()
                .map(|c| c.len_utf8())
                .unwrap_or(0);
            self.cursor_position += next;
        }
    }

    pub fn is_item_pinned(&self, id: &str) -> bool {
        self.pin_storage.is_pinned(id)
    }
}
