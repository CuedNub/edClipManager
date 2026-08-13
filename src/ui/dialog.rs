use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::widgets::{Block, Borders, BorderType, Clear, Paragraph};
use ratatui::text::{Line, Span};

use crate::app::{ActiveTab, App};
use crate::config::theme::{hex_to_color, style_fg};

pub fn render(f: &mut Frame, app: &App) {
    let theme = &app.config.theme.dialog;

    let area = centered_rect(50, 7, f.area());

    f.render_widget(Clear, area);

    let tab_name = match app.active_tab {
        ActiveTab::Clipboard => "clipboard",
        ActiveTab::Pin => "pin",
    };

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(ratatui::style::Style::default().fg(hex_to_color(&theme.border)))
        .title(Span::styled(
            " Confirm ",
            style_fg(&theme.title_fg),
        ))
        .style(
            ratatui::style::Style::default().bg(hex_to_color(&theme.background)),
        );

    let message = Line::from(vec![
        Span::styled(
            format!("Delete all {} items? ", tab_name),
            style_fg(&theme.message_fg),
        ),
    ]);

    let options = Line::from(vec![
        Span::styled("[", style_fg(&theme.message_fg)),
        Span::styled("y", style_fg(&theme.yes_fg)),
        Span::styled("]es  ", style_fg(&theme.message_fg)),
        Span::styled("[", style_fg(&theme.message_fg)),
        Span::styled("n", style_fg(&theme.no_fg)),
        Span::styled("]o", style_fg(&theme.message_fg)),
    ]);

    let paragraph = Paragraph::new(vec![
        Line::from(""),
        message,
        Line::from(""),
        options,
    ])
    .block(block)
    .alignment(ratatui::layout::Alignment::Center);

    f.render_widget(paragraph, area);
}

fn centered_rect(percent_x: u16, height: u16, area: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length((area.height.saturating_sub(height)) / 2),
            Constraint::Length(height),
            Constraint::Min(0),
        ])
        .split(area);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}
