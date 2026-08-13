use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use std::time::Duration;

use crate::app::{App, AppMode};

pub fn handle_events(app: &mut App) -> Result<(), Box<dyn std::error::Error>> {
    if !event::poll(Duration::from_millis(50))? {
        return Ok(());
    }

    if let Event::Key(key) = event::read()? {
        match app.mode {
            AppMode::Normal => handle_normal_mode(app, key),
            AppMode::ConfirmDeleteAll => handle_confirm_mode(app, key),
            AppMode::Help => handle_help_mode(app, key),
        }
    }

    Ok(())
}

fn handle_normal_mode(app: &mut App, key: KeyEvent) {
    let ctrl = key.modifiers.contains(KeyModifiers::CONTROL);
    let alt = key.modifiers.contains(KeyModifiers::ALT);

    match key.code {
        KeyCode::Esc => {
            app.should_quit = true;
        }

        KeyCode::Tab => {
            app.switch_tab();
        }

        KeyCode::Enter => {
            app.copy_selected_and_quit();
        }

        KeyCode::Down => {
            app.move_selection_down();
        }

        KeyCode::Up => {
            app.move_selection_up();
        }

        KeyCode::Char('j') if ctrl => {
            app.move_selection_down();
        }

        KeyCode::Char('k') if ctrl => {
            app.move_selection_up();
        }

        KeyCode::Char(' ') if ctrl => {
            app.toggle_mark();
        }

        KeyCode::Char('p') if ctrl => {
            app.pin_selected();
        }

        KeyCode::Char('h') if ctrl => {
            app.toggle_help();
        }

        KeyCode::Char('d') if ctrl && alt => {
            app.confirm_delete_all();
        }

        KeyCode::Char('d') if ctrl => {
            app.delete_selected();
        }

        KeyCode::Backspace => {
            app.delete_char_before_cursor();
        }

        KeyCode::Delete => {
            app.delete_char_at_cursor();
        }

        KeyCode::Left => {
            app.move_cursor_left();
        }

        KeyCode::Right => {
            app.move_cursor_right();
        }

        KeyCode::Char(c) if !ctrl && !alt => {
            app.insert_char(c);
        }

        _ => {}
    }
}

fn handle_confirm_mode(app: &mut App, key: KeyEvent) {
    match key.code {
        KeyCode::Char('y') | KeyCode::Char('Y') => {
            app.execute_delete_all();
        }
        KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
            app.cancel_dialog();
        }
        _ => {}
    }
}

fn handle_help_mode(app: &mut App, key: KeyEvent) {
    match key.code {
        KeyCode::Esc | KeyCode::Char('q') => {
            app.cancel_dialog();
        }
        KeyCode::Char('h') if key.modifiers.contains(KeyModifiers::CONTROL) => {
            app.cancel_dialog();
        }
        _ => {}
    }
}
