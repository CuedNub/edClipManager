use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;

use crate::app::App;
use crate::config::theme::{hex_to_color, style_fg};

pub fn render(f: &mut Frame, app: &App, area: Rect) {
    let theme = &app.config.theme.statusbar;
    let bg = hex_to_color(&theme.background);

    let bracket_style = style_fg(&theme.bracket_fg);
    let key_style = style_fg(&theme.key_fg);
    let label_style = style_fg(&theme.label_fg);
    let sep_style = style_fg(&theme.separator_fg);

    let marked_count = app.marked_ids.len();
    let mut spans_line1 = vec![
        Span::styled("C-", label_style),
        Span::styled("[", bracket_style),
        Span::styled("j/k", key_style),
        Span::styled("]", bracket_style),
        Span::styled(" nav", label_style),
        Span::styled("  ", sep_style),
        Span::styled("[", bracket_style),
        Span::styled("↓↑", key_style),
        Span::styled("]", bracket_style),
        Span::styled(" nav", label_style),
        Span::styled("  ", sep_style),
        // FIX #9: label sesuai keybinding sebenarnya (C-Space)
        Span::styled("C-", label_style),
        Span::styled("[", bracket_style),
        Span::styled("Space", key_style),
        Span::styled("]", bracket_style),
        Span::styled(" mark", label_style),
        Span::styled("  ", sep_style),
        Span::styled("C-", label_style),
        Span::styled("[", bracket_style),
        Span::styled("p", key_style),
        Span::styled("]", bracket_style),
        Span::styled("in", label_style),
    ];

    if marked_count > 0 {
        spans_line1.push(Span::styled("  ", sep_style));
        spans_line1.push(Span::styled("[", bracket_style));
        // FIX #8: hapus orphan Span yang tidak di-push
        spans_line1.push(Span::styled(format!("{}", marked_count), key_style));
        spans_line1.push(Span::styled(" marked", label_style));
        spans_line1.push(Span::styled("]", bracket_style));
    }

    let spans_line2 = vec![
        Span::styled("C-", label_style),
        Span::styled("[", bracket_style),
        Span::styled("d", key_style),
        Span::styled("]", bracket_style),
        Span::styled("elete", label_style),
        Span::styled("  ", sep_style),
        Span::styled("C-A-", label_style),
        Span::styled("[", bracket_style),
        Span::styled("d", key_style),
        Span::styled("]", bracket_style),
        Span::styled("el all", label_style),
        Span::styled("  ", sep_style),
        Span::styled("[", bracket_style),
        Span::styled("Tab", key_style),
        Span::styled("]", bracket_style),
        Span::styled(" switch", label_style),
        Span::styled("  ", sep_style),
        Span::styled("[", bracket_style),
        Span::styled("Ent", key_style),
        Span::styled("]", bracket_style),
        Span::styled(" copy", label_style),
        Span::styled("  ", sep_style),
        Span::styled("[", bracket_style),
        Span::styled("Esc", key_style),
        Span::styled("]", bracket_style),
        Span::styled(" quit", label_style),
        Span::styled("  ", sep_style),
        Span::styled("C-", label_style),
        Span::styled("[", bracket_style),
        Span::styled("h", key_style),
        Span::styled("]", bracket_style),
        Span::styled("elp", label_style),
    ];

    let line1 = Line::from(spans_line1);
    let line2 = Line::from(spans_line2);

    let paragraph = Paragraph::new(vec![line1, line2])
        .style(ratatui::style::Style::default().bg(bg));

    f.render_widget(paragraph, area);
}
