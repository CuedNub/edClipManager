use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::widgets::{Block, Borders, BorderType, List, ListItem, ListState};
use ratatui::text::{Line, Span};

use crate::app::App;
use crate::config::theme::{hex_to_color, style_fg, style_fg_bg};

pub fn render(f: &mut Frame, app: &App, area: Rect) {
    let theme = &app.config.theme.list;

    let items: Vec<ListItem> = app
        .filtered_items
        .iter()
        .enumerate()
        .map(|(idx, item)| {
            let is_marked = app.marked_ids.contains(&item.id);
            let is_pinned = app.is_item_pinned(&item.id);
            let is_selected = app.list_state_index == Some(idx);

            let mut spans = Vec::new();

            // marker (2 chars)
            if is_marked {
                spans.push(Span::styled("✓ ", style_fg(&theme.marked_bg)));
            } else if is_selected {
                spans.push(Span::styled("► ", style_fg(&app.config.theme.tabs.active_bg)));
            } else {
                spans.push(Span::raw("  "));
            }

            // pin indicator (3 chars jika ada, 0 jika tidak)
            let pin_width: usize = if is_pinned {
                spans.push(Span::styled("📌 ", style_fg(&theme.pin_indicator)));
                3 // emoji + space (perkiraan visual width)
            } else {
                0
            };

            // FIX #7: hitung prefix width yang benar
            // 2 (border kiri+kanan) + 2 (marker) + pin_width + 4 (ellipsis "...")
            let prefix_overhead = 2 + 2 + pin_width + 4;
            let max_chars = (area.width as usize).saturating_sub(prefix_overhead);

            let display = item.display_text();
            let char_count = display.chars().count();
            let truncated = if char_count > max_chars {
                let s: String = display.chars().take(max_chars).collect();
                format!("{}...", s)
            } else {
                display
            };

            if item.is_image && !is_selected && !is_marked {
                spans.push(Span::styled(truncated, style_fg(&theme.image_label)));
            } else {
                spans.push(Span::raw(truncated));
            }

            let line = Line::from(spans);
            let list_item = ListItem::new(line);

            if is_marked && is_selected {
                list_item.style(style_fg_bg(&theme.marked_fg, &theme.marked_bg))
            } else if is_selected {
                list_item.style(style_fg_bg(&theme.selected_fg, &theme.selected_bg))
            } else if is_marked {
                list_item.style(style_fg_bg(&theme.marked_fg, &theme.marked_bg))
            } else {
                list_item.style(style_fg_bg(&theme.item_fg, &theme.item_bg))
            }
        })
        .collect();

    let count = app.filtered_items.len();
    let total = match app.active_tab {
        crate::app::ActiveTab::Clipboard => app.clipboard_items.len(),
        crate::app::ActiveTab::Pin => app.pin_storage.pins.len(),
    };

    let title = if app.search_query.is_empty() {
        format!(" {} items ", total)
    } else {
        format!(" {}/{} items ", count, total)
    };

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(ratatui::style::Style::default().fg(hex_to_color(&theme.border)))
        .title(Span::styled(
            title,
            style_fg(&app.config.theme.window.title_fg),
        ));

    let list_widget = List::new(items).block(block);

    let mut state = ListState::default();
    state.select(app.list_state_index);

    f.render_stateful_widget(list_widget, area, &mut state);
}
