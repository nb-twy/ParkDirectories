use std::fs;
use std::io::{BufWriter, Write};
use std::path::{Path, PathBuf};

use crate::error::PdError;

#[derive(Debug, Clone)]
pub struct Bookmark {
    pub name: String,
    pub path: PathBuf,
}

pub struct BookmarkStore {
    file_path: PathBuf,
    bookmarks: Vec<Bookmark>,
}

impl BookmarkStore {
    /// Load bookmarks from a file, creating it if it does not exist.
    pub fn load(file_path: PathBuf) -> Result<Self, PdError> {
        if !file_path.exists() {
            if let Some(parent) = file_path.parent() {
                if !parent.as_os_str().is_empty() {
                    fs::create_dir_all(parent)?;
                }
            }
            fs::File::create(&file_path)?;
            set_permissions(&file_path)?;
            return Ok(Self {
                file_path,
                bookmarks: Vec::new(),
            });
        }

        let content = fs::read_to_string(&file_path)?;
        let bookmarks = content.lines().filter_map(parse_line).collect();

        Ok(Self { file_path, bookmarks })
    }

    /// Create an in-memory store pointing at a file path (file is not read or created).
    pub fn empty(file_path: PathBuf) -> Self {
        Self {
            file_path,
            bookmarks: Vec::new(),
        }
    }

    /// Write bookmarks to disk atomically: write to a temp file, then rename.
    pub fn save(&self) -> Result<(), PdError> {
        let parent = self
            .file_path
            .parent()
            .filter(|p| !p.as_os_str().is_empty())
            .unwrap_or_else(|| Path::new("."));

        let tmp_path = parent.join(format!(".pd.tmp.{}", std::process::id()));

        {
            let file = fs::File::create(&tmp_path)?;
            let mut w = BufWriter::new(file);
            for b in &self.bookmarks {
                writeln!(w, "{} {}", b.name, b.path.display())?;
            }
            w.flush()?;
        }

        fs::rename(&tmp_path, &self.file_path)?;
        set_permissions(&self.file_path)?;

        Ok(())
    }

    pub fn get(&self, name: &str) -> Option<&Bookmark> {
        self.bookmarks.iter().find(|b| b.name == name)
    }

    /// Add a new bookmark or replace an existing one with the same name.
    /// Returns `true` if an existing entry was overwritten.
    pub fn upsert(&mut self, name: String, path: PathBuf) -> bool {
        if let Some(existing) = self.bookmarks.iter_mut().find(|b| b.name == name) {
            existing.path = path;
            true
        } else {
            self.bookmarks.push(Bookmark { name, path });
            false
        }
    }

    /// Remove a bookmark by name. Returns `true` if the bookmark was found and removed.
    pub fn remove(&mut self, name: &str) -> bool {
        let before = self.bookmarks.len();
        self.bookmarks.retain(|b| b.name != name);
        self.bookmarks.len() < before
    }

    pub fn list(&self) -> &[Bookmark] {
        &self.bookmarks
    }

    pub fn clear(&mut self) {
        self.bookmarks.clear();
    }

    pub fn is_empty(&self) -> bool {
        self.bookmarks.is_empty()
    }

    pub fn len(&self) -> usize {
        self.bookmarks.len()
    }

    #[allow(dead_code)]
    pub fn file_path(&self) -> &Path {
        &self.file_path
    }
}

/// Parse a single line from the data file into a Bookmark.
/// Returns `None` for blank lines and comment lines (starting with `#`).
pub(crate) fn parse_line(line: &str) -> Option<Bookmark> {
    let line = line.trim();
    if line.is_empty() || line.starts_with('#') {
        return None;
    }
    let (name, rest) = line.split_once(|c: char| c.is_whitespace())?;
    let path_str = rest.trim_start();
    if path_str.is_empty() {
        return None;
    }
    Some(Bookmark {
        name: name.to_string(),
        path: PathBuf::from(path_str),
    })
}

/// Validate a bookmark name.
/// Names must be non-empty, must not start with `-`, and must not contain `/`.
pub fn validate_name(name: &str) -> Result<(), PdError> {
    if name.is_empty() {
        return Err(PdError::InvalidName {
            name: name.to_string(),
            reason: "name cannot be empty".to_string(),
        });
    }
    if name.starts_with('-') {
        return Err(PdError::InvalidName {
            name: name.to_string(),
            reason: "name cannot begin with '-'".to_string(),
        });
    }
    if name.contains('/') {
        return Err(PdError::InvalidName {
            name: name.to_string(),
            reason: "name cannot contain '/' (used as relative path separator)".to_string(),
        });
    }
    Ok(())
}

#[cfg(unix)]
fn set_permissions(path: &Path) -> Result<(), PdError> {
    use std::os::unix::fs::PermissionsExt;
    fs::set_permissions(path, fs::Permissions::from_mode(0o600))?;
    Ok(())
}

#[cfg(not(unix))]
fn set_permissions(_path: &Path) -> Result<(), PdError> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_simple_line() {
        let b = parse_line("work /home/user/work").unwrap();
        assert_eq!(b.name, "work");
        assert_eq!(b.path, PathBuf::from("/home/user/work"));
    }

    #[test]
    fn parse_path_with_spaces() {
        let b = parse_line("docs /home/user/My Documents").unwrap();
        assert_eq!(b.name, "docs");
        assert_eq!(b.path, PathBuf::from("/home/user/My Documents"));
    }

    #[test]
    fn parse_tab_separated() {
        let b = parse_line("work\t/home/user/work").unwrap();
        assert_eq!(b.name, "work");
        assert_eq!(b.path, PathBuf::from("/home/user/work"));
    }

    #[test]
    fn parse_skips_blank_lines() {
        assert!(parse_line("").is_none());
        assert!(parse_line("   ").is_none());
        assert!(parse_line("\t").is_none());
    }

    #[test]
    fn parse_skips_comments() {
        assert!(parse_line("# this is a comment").is_none());
        assert!(parse_line("  # indented comment").is_none());
    }

    #[test]
    fn validate_accepts_valid_names() {
        assert!(validate_name("work").is_ok());
        assert!(validate_name("my-project").is_ok());
        assert!(validate_name("proj_123").is_ok());
        assert!(validate_name("a").is_ok());
    }

    #[test]
    fn validate_rejects_empty() {
        assert!(validate_name("").is_err());
    }

    #[test]
    fn validate_rejects_leading_dash() {
        assert!(validate_name("-bad").is_err());
        assert!(validate_name("--worse").is_err());
    }

    #[test]
    fn validate_rejects_slash() {
        assert!(validate_name("bad/name").is_err());
        assert!(validate_name("a/b/c").is_err());
    }

    #[test]
    fn upsert_adds_new() {
        let mut store = BookmarkStore::empty(PathBuf::from("/tmp/test"));
        let replaced = store.upsert("work".to_string(), PathBuf::from("/home/user/work"));
        assert!(!replaced);
        assert_eq!(store.len(), 1);
    }

    #[test]
    fn upsert_replaces_existing() {
        let mut store = BookmarkStore::empty(PathBuf::from("/tmp/test"));
        store.upsert("work".to_string(), PathBuf::from("/old/path"));
        let replaced = store.upsert("work".to_string(), PathBuf::from("/new/path"));
        assert!(replaced);
        assert_eq!(store.len(), 1);
        assert_eq!(store.get("work").unwrap().path, PathBuf::from("/new/path"));
    }

    #[test]
    fn remove_existing() {
        let mut store = BookmarkStore::empty(PathBuf::from("/tmp/test"));
        store.upsert("work".to_string(), PathBuf::from("/home/user/work"));
        assert!(store.remove("work"));
        assert!(store.is_empty());
    }

    #[test]
    fn remove_missing_returns_false() {
        let mut store = BookmarkStore::empty(PathBuf::from("/tmp/test"));
        assert!(!store.remove("nonexistent"));
    }
}
