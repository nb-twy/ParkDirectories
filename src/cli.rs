use std::ffi::OsString;
use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser, Debug)]
#[command(
    name = "pd",
    version,
    about = "Park Directories — directory bookmarks for your terminal",
    long_about = None,
)]
pub struct Cli {
    /// Override the bookmark data file location
    #[arg(long, global = true, value_name = "PATH", env = "PD_DATA_FILE")]
    pub data_file: Option<PathBuf>,

    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand, Debug)]
pub enum Commands {
    /// Resolve a bookmark to its path; used by shell integration
    Get {
        /// Bookmark name, optionally with /relative/path suffix
        #[arg(allow_hyphen_values = true)]
        name: String,
    },
    /// Add a bookmark for a directory
    Add {
        /// Bookmark name
        #[arg(allow_hyphen_values = true)]
        name: String,
        /// Directory to bookmark (default: current directory)
        path: Option<PathBuf>,
        /// Skip confirmation prompts
        #[arg(long, short = 'f')]
        force: bool,
    },
    /// Delete a bookmark
    Del {
        /// Bookmark name to remove
        #[arg(allow_hyphen_values = true)]
        name: String,
    },
    /// List all bookmarks
    List,
    /// Clear all bookmarks
    Clear {
        /// Skip confirmation prompt
        #[arg(long, short = 'f')]
        force: bool,
    },
    /// Print the resolved path of a bookmark without navigating (for scripts)
    Expand {
        /// Bookmark name, optionally with /relative/path suffix
        #[arg(allow_hyphen_values = true)]
        name: String,
    },
    /// Export bookmarks to a file
    Export {
        /// Destination file path
        file: PathBuf,
    },
    /// Import bookmarks from a file
    Import {
        /// Source file path
        file: PathBuf,
        /// Merge with existing bookmarks instead of replacing
        #[arg(long)]
        append: bool,
        /// Non-interactive: replace without prompting
        #[arg(long)]
        quiet: bool,
        /// Skip confirmation prompts
        #[arg(long, short = 'f')]
        force: bool,
    },
    /// Print shell integration script to stdout
    Init {
        /// Target shell: bash, nu, or pwsh
        shell: String,
    },
    /// Print tab completion script to stdout
    Completions {
        /// Target shell: bash, nu, or pwsh
        shell: String,
    },
}

/// Normalize the user-facing short/long flag forms to subcommand names before
/// clap sees the arguments. For example, `["-a", "name"]` becomes `["add", "name"]`.
///
/// This keeps the clap definition clean (subcommands only) while giving users
/// the traditional flag-based interface. The binary owns both forms; the shell
/// shim passes arguments through unchanged.
pub fn normalize_args(mut args: Vec<OsString>) -> Vec<OsString> {
    if args.len() < 2 {
        return args;
    }

    let replacement: Option<&str> = match args[1].to_str().unwrap_or("") {
        "-a" | "--add"    => Some("add"),
        "-d" | "--del"    => Some("del"),
        "-l" | "--list"   => Some("list"),
        "-c" | "--clear"  => Some("clear"),
        "-x" | "--expand" => Some("expand"),
        "-e" | "--export" => Some("export"),
        "-i" | "--import" => Some("import"),
        // -v is the user-facing version flag; clap's built-in is -V/--version
        "-v"              => Some("--version"),
        _ => None,
    };

    if let Some(s) = replacement {
        args[1] = OsString::from(s);
    }

    args
}
