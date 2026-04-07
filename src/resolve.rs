use std::path::{Component, Path, PathBuf};

use crate::bookmarks::BookmarkStore;
use crate::error::PdError;

/// Resolve a bookmark reference to an absolute path.
///
/// Input format: `name` or `name/relative/path`
///
/// Splits the input on the first `/`, looks up the name in the store,
/// then joins the stored path with any relative suffix.
pub fn resolve(store: &BookmarkStore, input: &str) -> Result<PathBuf, PdError> {
    let (name, relpath) = match input.split_once('/') {
        Some((name, rest)) => (name, Some(rest)),
        None => (input, None),
    };

    let bookmark = store
        .get(name)
        .ok_or_else(|| PdError::NotFound(name.to_string()))?;

    let path = match relpath {
        Some(rel) if !rel.is_empty() => bookmark.path.join(rel),
        _ => bookmark.path.clone(),
    };

    Ok(normalize(&path))
}

/// Normalize a path by resolving `.` and `..` components without hitting the filesystem.
fn normalize(path: &Path) -> PathBuf {
    let mut result = PathBuf::new();
    for component in path.components() {
        match component {
            Component::CurDir => {}
            Component::ParentDir => {
                result.pop();
            }
            c => result.push(c),
        }
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bookmarks::BookmarkStore;

    fn make_store(entries: &[(&str, &str)]) -> BookmarkStore {
        let mut store = BookmarkStore::empty(PathBuf::from("/tmp/.pd-test"));
        for (name, path) in entries {
            store.upsert(name.to_string(), PathBuf::from(path));
        }
        store
    }

    #[test]
    fn resolve_bare_name() {
        let store = make_store(&[("work", "/home/user/work")]);
        assert_eq!(
            resolve(&store, "work").unwrap(),
            PathBuf::from("/home/user/work")
        );
    }

    #[test]
    fn resolve_with_single_level_relpath() {
        let store = make_store(&[("work", "/home/user/work")]);
        assert_eq!(
            resolve(&store, "work/src").unwrap(),
            PathBuf::from("/home/user/work/src")
        );
    }

    #[test]
    fn resolve_with_multi_level_relpath() {
        let store = make_store(&[("work", "/home/user/work")]);
        assert_eq!(
            resolve(&store, "work/src/components/ui").unwrap(),
            PathBuf::from("/home/user/work/src/components/ui")
        );
    }

    #[test]
    fn resolve_normalizes_dotdot() {
        let store = make_store(&[("work", "/home/user/work")]);
        assert_eq!(
            resolve(&store, "work/../docs").unwrap(),
            PathBuf::from("/home/user/docs")
        );
    }

    #[test]
    fn resolve_not_found() {
        let store = make_store(&[]);
        assert!(matches!(
            resolve(&store, "missing"),
            Err(PdError::NotFound(_))
        ));
    }

    #[test]
    fn normalize_resolves_dots() {
        assert_eq!(
            normalize(Path::new("/a/b/../c")),
            PathBuf::from("/a/c")
        );
        assert_eq!(
            normalize(Path::new("/a/./b")),
            PathBuf::from("/a/b")
        );
    }
}
