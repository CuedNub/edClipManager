use ratatui::style::{Color, Style};

pub fn hex_to_color(hex: &str) -> Color {
    let hex = hex.trim_start_matches('#');
    if hex.len() != 6 {
        return Color::White;
    }
    let r = u8::from_str_radix(&hex[0..2], 16).unwrap_or(255);
    let g = u8::from_str_radix(&hex[2..4], 16).unwrap_or(255);
    let b = u8::from_str_radix(&hex[4..6], 16).unwrap_or(255);
    Color::Rgb(r, g, b)
}

pub fn style_fg(hex: &str) -> Style {
    Style::default().fg(hex_to_color(hex))
}

pub fn style_fg_bg(fg_hex: &str, bg_hex: &str) -> Style {
    Style::default()
        .fg(hex_to_color(fg_hex))
        .bg(hex_to_color(bg_hex))
}

