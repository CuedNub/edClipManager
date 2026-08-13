use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

use super::cliphist::{self, CliphistItem};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PinnedItem {
    pub cliphist_id: String,
    pub content: String,
    pub is_image: bool,
    pub image_size: Option<String>,
    pub pinned_at: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PinStorage {
    pub pins: Vec<PinnedItem>,
}

impl PinStorage {
    pub fn load(path: &PathBuf) -> Self {
        if path.exists() {
            match fs::read_to_string(path) {
                Ok(content) => match serde_json::from_str(&content) {
                    Ok(storage) => return storage,
                    Err(_) => {}
                },
                Err(_) => {}
            }
        }
        PinStorage { pins: Vec::new() }
    }

    pub fn save(&self, path: &PathBuf) -> Result<(), String> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|e| format!("Failed to create dir: {}", e))?;
        }
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| format!("Failed to serialize: {}", e))?;
        fs::write(path, json).map_err(|e| format!("Failed to write: {}", e))?;
        Ok(())
    }

    pub fn pin_item(&mut self, item: &CliphistItem) {
        if self.is_pinned(&item.id) {
            return;
        }

        // FIX #1: Untuk teks, decode konten asli dari cliphist
        // karena item.content dari "cliphist list" hanya preview terpotong.
        let content = if item.is_image {
            item.content.clone()
        } else {
            cliphist::decode_text(&item.id).unwrap_or_else(|| item.content.clone())
        };

        self.pins.push(PinnedItem {
            cliphist_id: item.id.clone(),
            content,
            is_image: item.is_image,
            image_size: item.image_size.clone(),
            pinned_at: chrono::Local::now().to_rfc3339(),
        });
    }

    pub fn unpin_item(&mut self, cliphist_id: &str) {
        self.pins.retain(|p| p.cliphist_id != cliphist_id);
    }

    pub fn is_pinned(&self, cliphist_id: &str) -> bool {
        self.pins.iter().any(|p| p.cliphist_id == cliphist_id)
    }

    pub fn to_cliphist_items(&self) -> Vec<CliphistItem> {
        self.pins
            .iter()
            .map(|p| CliphistItem {
                id: p.cliphist_id.clone(),
                content: p.content.clone(),
                is_image: p.is_image,
                image_size: p.image_size.clone(),
            })
            .collect()
    }

    pub fn clear_all(&mut self) {
        self.pins.clear();
    }

    pub fn remove_by_ids(&mut self, ids: &[String]) {
        self.pins.retain(|p| !ids.contains(&p.cliphist_id));
    }
}
