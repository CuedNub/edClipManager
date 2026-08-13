use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::widgets::{Block, Borders, BorderType, Tabs as RatatuiTabs};
use ratatui::text::Line;

use crate::app::{ActiveTab, App};
use crate::config::theme::{hex_to_color, style_fg_bg};

pub fn render(f: &mut Frame, app: &App, area: Rect) {
    let theme = &app.config.theme.tabs;

    let titles = vec![
        Line::from(" Clipboard "),
        Line::from(" 📌 Pin "),
    ];

    let selected = match app.active_tab {
        ActiveTab::Clipboard => 0,
        ActiveTab::Pin => 1,
    };

    let tabs = RatatuiTabs::new(titles)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .border_style(
                    ratatui::style::Style::default()
                        .fg(hex_to_color(&app.config.theme.window.border)),
                ),
        )
        .select(selected)
        .highlight_style(style_fg_bg(&theme.active_fg, &theme.active_bg))
        .style(style_fg_bg(&theme.inactive_fg, &theme.inactive_bg));

    f.render_widget(tabs, area);
}
