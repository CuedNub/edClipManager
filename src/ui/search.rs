use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::widgets::{Block, Borders, BorderType, Paragraph};
use ratatui::text::{Line, Span};

use crate::app::App;
use crate::config::theme::{hex_to_color, style_fg};

pub fn render(f: &mut Frame, app: &App, area: Rect) {
    let theme = &app.config.theme.search;

    let border_color = hex_to_color(&theme.border_active);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(ratatui::style::Style::default().fg(border_color))
        .title(Span::styled(
            " 🔍 Search ",
            style_fg(&app.config.theme.window.title_fg),
        ));

    let display_text = if app.search_query.is_empty() {
        Line::from(Span::styled(
            "Type to search...",
            style_fg(&theme.placeholder_fg),
        ))
    } else {
        Line::from(Span::styled(
            app.search_query.as_str(),
            style_fg(&theme.input_fg),
        ))
    };

    let paragraph = Paragraph::new(display_text).block(block);
    f.render_widget(paragraph, area);

    let cursor_x = area.x + app.cursor_position as u16 + 1;
    let cursor_y = area.y + 1;
    if cursor_x < area.x + area.width - 1 {
        f.set_cursor_position((cursor_x, cursor_y));
    }
}
