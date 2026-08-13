use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::widgets::{Block, Borders, BorderType, Clear, Paragraph, Wrap};
use ratatui::text::{Line, Span};

use crate::app::App;
use crate::config::theme::{hex_to_color, style_fg};

pub fn render(f: &mut Frame, app: &App) {
    let theme = &app.config.theme.dialog;
    let list_theme = &app.config.theme.list;
    let sb_theme = &app.config.theme.statusbar;

    let area = centered_rect(80, 90, f.area());

    f.render_widget(Clear, area);

    let bracket = |s: &str| Span::styled(s.to_string(), style_fg(&sb_theme.bracket_fg));
    let key = |s: &str| Span::styled(s.to_string(), style_fg(&sb_theme.key_fg));
    let label = |s: &str| Span::styled(s.to_string(), style_fg(&sb_theme.label_fg));
    let heading = |s: &str| Span::styled(s.to_string(), style_fg(&list_theme.pin_indicator));
    let path_style = |s: &str| Span::styled(s.to_string(), style_fg(&list_theme.image_label));
    let normal = |s: &str| Span::styled(s.to_string(), style_fg(&theme.message_fg));

    let mut lines: Vec<Line> = Vec::new();

    lines.push(Line::from(vec![heading("── Navigation ──")]));
    lines.push(Line::from(vec![
        label("  C-"), bracket("["), key("j"), bracket("]"), label(" / C-"),
        bracket("["), key("k"), bracket("]"), label("           Move selection down / up"),
    ]));
    lines.push(Line::from(vec![
        bracket("  ["), key("↓"), bracket("]"), label(" / "),
        bracket("["), key("↑"), bracket("]"), label("               Move selection down / up"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![heading("── Actions ──")]));
    lines.push(Line::from(vec![
        bracket("  ["), key("Enter"), bracket("]"),
        label("                 Copy selected to clipboard & exit"),
    ]));
    lines.push(Line::from(vec![
        label("  C-"), bracket("["), key("Space"), bracket("]"),
        label("               Toggle mark (multi-select)"),
    ]));
    lines.push(Line::from(vec![
        label("  C-"), bracket("["), key("p"), bracket("]"),
        label("                   Pin / unpin selected (or all marked)"),
    ]));
    lines.push(Line::from(vec![
        label("  C-"), bracket("["), key("d"), bracket("]"),
        label("                   Delete selected (or all marked)"),
    ]));
    lines.push(Line::from(vec![
        label("  C-A-"), bracket("["), key("d"), bracket("]"),
        label("                 Delete all items in active tab"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![heading("── Tabs & Search ──")]));
    lines.push(Line::from(vec![
        bracket("  ["), key("Tab"), bracket("]"),
        label("                   Switch between Clipboard / Pin tabs"),
    ]));
    lines.push(Line::from(vec![
        normal("  Type anywhere            "), label("Search filter (always active)"),
    ]));
    lines.push(Line::from(vec![
        bracket("  ["), key("←"), bracket("]"), label(" / "),
        bracket("["), key("→"), bracket("]"), label("               Move search cursor"),
    ]));
    lines.push(Line::from(vec![
        bracket("  ["), key("Backspace"), bracket("]"), label(" / "),
        bracket("["), key("Del"), bracket("]"),
        label("     Delete char in search"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![heading("── Application ──")]));
    lines.push(Line::from(vec![
        label("  C-"), bracket("["), key("h"), bracket("]"),
        label("                   Toggle this help"),
    ]));
    lines.push(Line::from(vec![
        bracket("  ["), key("Esc"), bracket("]"), label(" / "),
        bracket("["), key("q"), bracket("]"),
        label("               Quit (or close dialog)"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![heading("── System Paths ──")]));
    lines.push(Line::from(vec![
        label("  Binary       : "), path_style("~/.local/bin/edclipmanager"),
    ]));
    lines.push(Line::from(vec![
        label("  Config       : "), path_style("~/.config/edClipManager/config.toml"),
    ]));
    lines.push(Line::from(vec![
        label("  Pin storage  : "), path_style("~/.local/share/edClipManager/pins.json"),
    ]));
    lines.push(Line::from(vec![
        label("  Clipboard DB : "), path_style("~/.cache/cliphist/db"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![heading("── Modified Hyprland Files ──")]));
    lines.push(Line::from(vec![
        label("  Keybinding   : "), path_style("~/.config/hypr/bindings.conf"),
    ]));
    lines.push(Line::from(vec![
        label("  Autostart    : "), path_style("~/.config/hypr/autostart.conf"),
    ]));
    lines.push(Line::from(vec![
        label("  Window rules : "), path_style("~/.config/hypr/hyprland.conf"),
    ]));
    lines.push(Line::from(vec![
        normal("  All blocks marked with "), path_style("# edClipManager-Begin/End"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![heading("── External Dependencies ──")]));
    lines.push(Line::from(vec![
        label("  cliphist   : "), normal("clipboard history backend"),
    ]));
    lines.push(Line::from(vec![
        label("  wl-copy    : "), normal("send data to Wayland clipboard"),
    ]));
    lines.push(Line::from(vec![
        label("  wl-paste   : "), normal("monitor clipboard (via cliphist store)"),
    ]));
    lines.push(Line::from(vec![
        label("  kitty      : "), normal("terminal emulator for floating window"),
    ]));
    lines.push(Line::from(""));

    lines.push(Line::from(vec![
        normal("Press "), bracket("["), key("Esc"), bracket("]"),
        normal(" or "), label("C-"), bracket("["), key("h"), bracket("]"),
        normal(" to close this help"),
    ]));

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(ratatui::style::Style::default().fg(hex_to_color(&theme.border)))
        .title(Span::styled(
            " Help — edClipManager ",
            style_fg(&theme.title_fg),
        ))
        .style(ratatui::style::Style::default().bg(hex_to_color(&theme.background)));

    let paragraph = Paragraph::new(lines)
        .block(block)
        .wrap(Wrap { trim: false });

    f.render_widget(paragraph, area);
}

fn centered_rect(percent_x: u16, percent_y: u16, area: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
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
