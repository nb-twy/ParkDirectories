mod bookmarks;
mod cli;
mod commands;
mod error;
mod init;
mod resolve;

use std::ffi::OsString;
use std::path::PathBuf;

use clap::Parser;

use cli::{Cli, Commands};
use error::PdError;

fn main() {
    let raw_args: Vec<OsString> = std::env::args_os().collect();
    let args = cli::normalize_args(raw_args);

    let cli = Cli::parse_from(args);

    let data_file = match resolve_data_file(cli.data_file) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("pd: {e}");
            std::process::exit(e.exit_code());
        }
    };

    let result = match cli.command {
        Commands::Get { name } => commands::cmd_get(&data_file, &name),
        Commands::Add { name, path, force } => commands::cmd_add(&data_file, &name, path, force),
        Commands::Del { name } => commands::cmd_del(&data_file, &name),
        Commands::List => commands::cmd_list(&data_file),
        Commands::Clear { force } => commands::cmd_clear(&data_file, force),
        Commands::Expand { name } => commands::cmd_expand(&data_file, &name),
        Commands::Export { file } => commands::cmd_export(&data_file, &file),
        Commands::Import {
            file,
            append,
            quiet,
            force,
        } => commands::cmd_import(&data_file, &file, append, quiet, force),
        Commands::Init { shell } => init::print_init(&shell),
        Commands::Completions { shell } => init::print_completions(&shell),
    };

    if let Err(e) = result {
        eprintln!("pd: {e}");
        std::process::exit(e.exit_code());
    }
}

fn resolve_data_file(override_path: Option<PathBuf>) -> Result<PathBuf, PdError> {
    match override_path {
        Some(path) => Ok(path),
        None => {
            let home = dirs::home_dir().ok_or(PdError::NoHomeDir)?;
            Ok(home.join(".pd-data"))
        }
    }
}
