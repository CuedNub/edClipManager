pub mod search;
pub mod list;
pub mod tabs;
pub mod statusbar;
pub mod dialog;
pub mod help;

use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout};

use crate::app::{App, AppMode};

pub fn draw(f: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // search box
            Constraint::Length(3), // tabs
            Constraint::Min(5),   // list
            Constraint::Length(2), // status bar
        ])
        .split(f.area());

    search::render(f, app, chunks[0]);
    tabs::render(f, app, chunks[1]);
    list::render(f, app, chunks[2]);
    statusbar::render(f, app, chunks[3]);

    if app.mode == AppMode::ConfirmDeleteAll {
        dialog::render(f, app);
    }

    if app.mode == AppMode::Help {
        help::render(f, app);
    }
}
