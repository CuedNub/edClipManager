mod app;
mod clipboard;
mod config;
mod event;
mod ui;

use std::io;
use crossterm::{
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;

use app::App;
use config::AppConfig;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = AppConfig::load();
    let mut app = App::new(config);

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let result = run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;

    if let Err(e) = result {
        eprintln!("Error: {}", e);
    }

    Ok(())
}

fn run_app(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
) -> Result<(), Box<dyn std::error::Error>> {
    // Drain any pending events from terminal buffer before starting
    use std::time::Duration;
    while crossterm::event::poll(Duration::from_millis(0))? {
        let _ = crossterm::event::read()?;
    }

    loop {
        terminal.draw(|f| ui::draw(f, app))?;

        event::handle_events(app)?;

        if app.should_quit {
            break;
        }
    }
    Ok(())
}
