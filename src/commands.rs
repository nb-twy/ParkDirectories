use std::fs;
use std::io::{self, BufWriter, IsTerminal, Write};
use std::path::{Path, PathBuf};

use crate::bookmarks::{self, validate_name, BookmarkStore};
use crate::error::PdError;
use crate::resolve;

pub fn cmd_get(data_file: &Path, name: &str) -> Result<(), PdError> {
    print_resolved_path(data_file, name)
}

pub fn cmd_expand(data_file: &Path, name: &str) -> Result<(), PdError> {
    print_resolved_path(data_file, name)
}

fn print_resolved_path(data_file: &Path, name: &str) -> Result<(), PdError> {
    let store = BookmarkStore::load(data_file.to_path_buf())?;
    let path = resolve::resolve(&store, name)?;
    println!("{}", path.display());
    Ok(())
}

pub fn cmd_add(
    data_file: &Path,
    name: &str,
    path: Option<PathBuf>,
    force: bool,
) -> Result<(), PdError> {
    validate_name(name)?;

    let target = match path {
        Some(p) if p.is_absolute() => p,
        Some(p) => std::env::current_dir()?.join(p),
        None => std::env::current_dir()?,
    };

    if !target.exists() {
        eprintln!("pd: warning: path does not exist: {}", target.display());
        if !force {
            if is_interactive() {
                eprint!("Add bookmark anyway? [y/N] ");
                io::stderr().flush()?;
                if !read_yes()? {
                    return Ok(());
                }
            } else {
                return Err(PdError::PathNotFound(target));
            }
        }
    }

    let mut store = BookmarkStore::load(data_file.to_path_buf())?;

    if let Some(existing) = store.get(name) {
        if !force {
            eprintln!(
                "pd: bookmark '{}' already exists: {}",
                name,
                existing.path.display()
            );
            if is_interactive() {
                eprint!("Overwrite? [y/N] ");
                io::stderr().flush()?;
                if !read_yes()? {
                    return Ok(());
                }
            }
            // Non-interactive without --force: overwrite silently
        }
    }

    store.upsert(name.to_string(), target);
    store.save()
}

pub fn cmd_del(data_file: &Path, name: &str) -> Result<(), PdError> {
    let mut store = BookmarkStore::load(data_file.to_path_buf())?;
    if !store.remove(name) {
        return Err(PdError::NotFound(name.to_string()));
    }
    store.save()
}

pub fn cmd_list(data_file: &Path) -> Result<(), PdError> {
    let store = BookmarkStore::load(data_file.to_path_buf())?;
    let bookmarks = store.list();
    if bookmarks.is_empty() {
        eprintln!("No bookmarks.");
        return Ok(());
    }
    let col_width = bookmarks.iter().map(|b| b.name.len()).max().unwrap_or(0);
    for b in bookmarks {
        println!("{:<width$}  {}", b.name, b.path.display(), width = col_width);
    }
    Ok(())
}

pub fn cmd_clear(data_file: &Path, force: bool) -> Result<(), PdError> {
    let mut store = BookmarkStore::load(data_file.to_path_buf())?;
    if store.is_empty() {
        eprintln!("No bookmarks to clear.");
        return Ok(());
    }
    if !force && is_interactive() {
        let n = store.len();
        eprint!(
            "Clear all {} bookmark{}? [y/N] ",
            n,
            if n == 1 { "" } else { "s" }
        );
        io::stderr().flush()?;
        if !read_yes()? {
            return Ok(());
        }
    }
    store.clear();
    store.save()
}

pub fn cmd_export(data_file: &Path, dest: &Path) -> Result<(), PdError> {
    let store = BookmarkStore::load(data_file.to_path_buf())?;
    let file = fs::File::create(dest)?;
    let mut w = BufWriter::new(file);
    for b in store.list() {
        writeln!(w, "{} {}", b.name, b.path.display())?;
    }
    w.flush()?;
    Ok(())
}

pub fn cmd_import(
    data_file: &Path,
    src: &Path,
    append: bool,
    quiet: bool,
    force: bool,
) -> Result<(), PdError> {
    let imported = parse_import_file(src)?;

    if append {
        let mut store = BookmarkStore::load(data_file.to_path_buf())?;
        for (name, path) in imported {
            if store.get(&name).is_none() {
                store.upsert(name, path);
            }
        }
        store.save()
    } else {
        if !quiet && !force && is_interactive() {
            let store = BookmarkStore::load(data_file.to_path_buf())?;
            if !store.is_empty() {
                let n = store.len();
                eprint!(
                    "This will replace {} existing bookmark{}. Continue? [y/N] ",
                    n,
                    if n == 1 { "" } else { "s" }
                );
                io::stderr().flush()?;
                if !read_yes()? {
                    return Ok(());
                }
            }
        }

        let mut new_store = BookmarkStore::empty(data_file.to_path_buf());
        for (name, path) in imported {
            new_store.upsert(name, path);
        }
        new_store.save()
    }
}

/// Parse a bookmark import file into a list of (name, path) pairs.
/// Reuses the same line format as the main data file.
fn parse_import_file(src: &Path) -> Result<Vec<(String, PathBuf)>, PdError> {
    let content = fs::read_to_string(src)?;
    let entries = content
        .lines()
        .filter_map(bookmarks::parse_line)
        .map(|b| (b.name, b.path))
        .collect();
    Ok(entries)
}

pub fn cmd_help() {
    print!(
        "\
Park Directories — directory bookmarks for your terminal

NAVIGATION  (requires shell integration via `pd init <shell>`)
  pd <name>                Change to the bookmarked directory
  pd <name>/<relpath>      Change to a subdirectory of a bookmark

COMMANDS
  pd add <name> [<path>]   Bookmark a directory (default: current directory)
  pd del <name>            Delete a bookmark
  pd list                  List all bookmarks
  pd clear                 Delete all bookmarks
  pd expand <name>         Print the resolved path without navigating
  pd export <file>         Export bookmarks to a file
  pd import <file>         Import bookmarks from a file

SHORT FLAGS
  -a <name> [<path>]       Same as: add
  -d <name>                Same as: del
  -l                       Same as: list
  -c                       Same as: clear
  -x <name>                Same as: expand
  -e <file>                Same as: export
  -i <file>                Same as: import
  -v                       Same as: --version

SETUP
  pd init <shell>          Print shell integration script (bash, nu, pwsh)
  pd completions <shell>   Print tab completion script

OPTIONS
  --data-file <path>       Override bookmark data file location
                           (env: PD_DATA_FILE; default: ~/.pd-data)

Run `pd <subcommand> --help` for subcommand details.
Run `pd init <shell>` to install navigation support in your shell.
"
    );
}

fn is_interactive() -> bool {
    io::stdin().is_terminal()
}

fn read_yes() -> Result<bool, PdError> {
    let mut answer = String::new();
    io::stdin().read_line(&mut answer)?;
    Ok(answer.trim().eq_ignore_ascii_case("y"))
}
