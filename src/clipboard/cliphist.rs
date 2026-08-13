use std::process::Command;

#[derive(Debug, Clone)]
pub struct CliphistItem {
    pub id: String,
    pub content: String,
    pub is_image: bool,
    pub image_size: Option<String>,
}

impl CliphistItem {
    pub fn display_text(&self) -> String {
        if self.is_image {
            if let Some(ref size) = self.image_size {
                format!("[image - {}]", size)
            } else {
                "[image]".to_string()
            }
        } else {
            self.content
                .replace('\n', "⏎ ")
                .replace('\t', "→ ")
        }
    }

    pub fn matches_search(&self, query: &str) -> bool {
        if query.is_empty() {
            return true;
        }
        let lower_query = query.to_lowercase();
        if self.is_image {
            "image".contains(&lower_query)
        } else {
            self.content.to_lowercase().contains(&lower_query)
        }
    }
}

pub fn list_items(max_items: usize) -> Vec<CliphistItem> {
    let output = match Command::new("cliphist").arg("list").output() {
        Ok(o) => o,
        Err(_) => return Vec::new(),
    };

    if !output.status.success() {
        return Vec::new();
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut items = Vec::new();

    for line in stdout.lines() {
        if items.len() >= max_items {
            break;
        }

        let Some((id, rest)) = line.split_once('\t') else {
            continue;
        };

        let id = id.trim().to_string();
        let content = rest.to_string();

        let is_image = content.starts_with("[[ binary data")
            || content.contains("image/png")
            || content.contains("image/jpeg")
            || content.contains("image/")
            || (content.len() > 2 && content.as_bytes()[0] == 0x89);

        let image_size = if is_image {
            get_item_size(&id)
        } else {
            None
        };

        items.push(CliphistItem {
            id,
            content,
            is_image,
            image_size,
        });
    }

    items
}

/// Decode full content dari cliphist (teks utuh, bukan preview).
/// Mengembalikan None jika id tidak valid atau decode gagal.
pub fn decode_text(id: &str) -> Option<String> {
    let output = Command::new("cliphist")
        .arg("decode")
        .arg(id)
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    String::from_utf8(output.stdout).ok()
}

fn get_item_size(id: &str) -> Option<String> {
    // FIX #3: hindari shell injection — gunakan cliphist decode langsung
    let decode_output = Command::new("cliphist")
        .arg("decode")
        .arg(id)
        .output()
        .ok()?;

    if !decode_output.status.success() {
        return None;
    }

    let bytes = decode_output.stdout.len() as u64;
    Some(format_bytes(bytes))
}

fn format_bytes(bytes: u64) -> String {
    if bytes >= 1_048_576 {
        format!("{:.1}MB", bytes as f64 / 1_048_576.0)
    } else if bytes >= 1024 {
        format!("{:.1}KB", bytes as f64 / 1024.0)
    } else {
        format!("{}B", bytes)
    }
}

pub fn copy_to_clipboard(id: &str) -> bool {
    // FIX #4: hindari shell injection — gunakan pipe langsung tanpa sh -c
    use std::io::Write;
    use std::process::Stdio;

    let decode = match Command::new("cliphist")
        .arg("decode")
        .arg(id)
        .output()
    {
        Ok(o) if o.status.success() => o.stdout,
        _ => return false,
    };

    let mut wl_copy = match Command::new("wl-copy")
        .stdin(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return false,
    };

    if let Some(mut stdin) = wl_copy.stdin.take() {
        if stdin.write_all(&decode).is_err() {
            return false;
        }
    }

    matches!(wl_copy.wait(), Ok(s) if s.success())
}

pub fn copy_text_to_clipboard(content: &str) -> bool {
    use std::io::Write;
    use std::process::Stdio;

    let mut child = match Command::new("wl-copy")
        .stdin(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return false,
    };

    if let Some(mut stdin) = child.stdin.take() {
        if stdin.write_all(content.as_bytes()).is_err() {
            return false;
        }
    }

    matches!(child.wait(), Ok(s) if s.success())
}

pub fn delete_item(id: &str) -> bool {
    // FIX #5: hindari shell injection — gunakan stdin pipe seperti yang diharapkan cliphist
    use std::io::Write;
    use std::process::Stdio;

    // cliphist delete membaca dari stdin dalam format "id\t..."
    let mut child = match Command::new("cliphist")
        .arg("delete")
        .stdin(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return false,
    };

    if let Some(mut stdin) = child.stdin.take() {
        // cliphist delete mengharapkan baris lengkap dari "cliphist list"
        // Minimal format: "ID\tcontent"
        let line = format!("{}\t", id);
        if stdin.write_all(line.as_bytes()).is_err() {
            return false;
        }
    }

    matches!(child.wait(), Ok(s) if s.success())
}

pub fn wipe_all() -> bool {
    let status = Command::new("cliphist").arg("wipe").status();
    matches!(status, Ok(s) if s.success())
}
