//! This example shows how to detect if the terminal uses
//! a dark-on-light or a light-on-dark theme.

use terminal_colorsaurus::{foreground_color, background_color, Error, QueryOptions};

fn main() -> Result<(), display::DisplayAsDebug<Error>> {
//     let colors = color_palette(QueryOptions::default())?;
//
//     let theme = match colors.color_scheme() {
//         ColorScheme::Dark => "dark",
//         ColorScheme::Light => "light",
//     };

    let fg = foreground_color(QueryOptions::default())?;
    let bg = background_color(QueryOptions::default())?;

    println!(
        "{:04x}/{:04x}/{:04x};{:04x}/{:04x}/{:04x}",
         fg.r, fg.g, fg.b,
         bg.r, bg.g, bg.b
   );

    Ok(())
}

#[path = "../lib/display.rs"]
mod display;
