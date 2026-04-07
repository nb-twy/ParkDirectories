# Park Directories — Project Requirements Document

**Version**: 1.0  
**Status**: Draft  
**Last Updated**: 2026-04-06

---

## 1. Overview

Park Directories (`pd`) is a directory bookmarking tool for terminal users. It allows users to assign short, memorable names to frequently-visited directories and navigate to them instantly with a single command.

The project is being re-architected from a bash-only implementation to a cross-platform system supporting nushell, bash, and PowerShell.

---

## 2. Design Philosophy

The core design principle is **deliberate simplicity with zero cognitive load at point of use**. You type `pd myproject` and you are there. There is no inference engine to evaluate, no ranked list to scan, no ranked candidates to approve. You own your bookmark namespace completely.

This distinguishes `pd` from frecency-based tools like `zoxide`:

- Bookmarks are **explicit**: you create them, name them, and manage them yourself
- Navigation is **deterministic**: `pd myproject` always goes to the same place, every time
- The mental model is **stable**: bookmarks you added last year work identically today
- The namespace is **intentionally bounded**: a curated set of meaningful names is more useful than an exhaustive history, and tab completion handles discovery within that set

The tool is optimized for a user who keeps a working set of maybe a dozen to a few dozen frequently-visited directories. Bookmark names are chosen to be memorable, so navigation requires no lookup and no decision.

---

## 3. Target Platforms and Shells

### Priority 1 — Primary
- **Shell**: Nushell
- **Host**: Windows Terminal on Windows 11

### Priority 2 — Secondary
- **Shell**: Bash
- **Host**: SSH sessions to Linux servers (Fedora/RHEL and Ubuntu/Debian)

### Priority 3 — Tertiary
- **Shell**: PowerShell
- **Host**: Windows Terminal on Windows 11 (occasional use)

### Deferred
- macOS (any shell): the architecture must not preclude future support, but no active development effort

---

## 4. Features

### 4.1 Core Navigation

- `pd <name>` — Navigate to a bookmarked directory
- `pd <name>/<relpath>` — Navigate to a relative path under a bookmark
  - Example: `pd work/src/components` navigates to `<work bookmark>/src/components`
  - Multiple path levels are supported

### 4.2 Bookmark Management

- `pd -a <name>` — Bookmark the current directory under `<name>`
- `pd -a <name> <path>` — Bookmark a specific path under `<name>`
- `pd -d <name>` — Delete a bookmark
- `pd -l` — List all bookmarks
- `pd -c` — Clear all bookmarks

### 4.3 Scripting Support

- `pd -x <name>[/<relpath>]` — Print the resolved path to stdout without navigating; intended for use in scripts and pipelines

### 4.4 Import / Export

- `pd -e <file>` — Export bookmarks to a file
- `pd -i <file>` — Import bookmarks from a file (replaces current bookmarks; prompts before overwriting)
- `pd -i --append <file>` — Merge imported bookmarks with existing ones
- `pd -i --quiet <file>` — Non-interactive import; suppresses prompts

### 4.5 Shell Integration

- `pd init bash` — Print the bash shell initialization script to stdout
- `pd init nu` — Print the nushell initialization script to stdout
- `pd init pwsh` — Print the PowerShell initialization script to stdout

Users source the init output in their shell profile (one-time setup). The init script defines the shell-native `pd` command/function that wraps the binary and handles directory navigation.

### 4.6 Tab Completion

- Complete bookmark names when typing `pd <tab>`
- Complete relative paths after `pd <name>/<tab>` using the filesystem
- Complete flags after `pd -<tab>` and `pd --<tab>`
- Complete file/directory paths for the `-a`, `-i`, and `-e` options
- Completion must work natively in each target shell

### 4.7 Path Validation on Add

- When adding a bookmark, verify the target path exists
- If the path does not exist: warn the user and prompt for confirmation before adding
- `--force` flag suppresses the confirmation prompt (for scripting)

---

## 5. Non-Goals

The following are explicitly out of scope:

- **Automatic / frecency-based learning**: `pd` does not observe navigation history or learn from usage
- **Fuzzy matching**: Bookmark names are exact; tab completion is the discovery mechanism
- **macOS support**: Deferred; see Section 3
- **GUI or TUI**: Terminal only
- **Cloud sync**: Bookmark files are local; users may use their own sync tools
- **Directory history**: `pd` does not track where you have been, only what you have bookmarked
- **Chaining multiple operations in one invocation**: Removed in favor of clean subcommand design

---

## 6. Configuration

### 6.1 Bookmark File Location

| Platform | Default Path |
|----------|-------------|
| Linux | `~/.pd-data` |
| Windows | `%USERPROFILE%\.pd-data` |

Override priority (highest wins):
1. `--data-file <path>` flag on any invocation
2. `PD_DATA_FILE` environment variable
3. OS default path

### 6.2 Bookmark File Format

Plain text; one bookmark per line:

```
name /absolute/path/to/directory
```

- Name and path are separated by a single space
- The path is everything after the first space (supports paths with spaces)
- Blank lines are ignored
- Lines beginning with `#` are treated as comments and ignored
- The file must be human-readable and hand-editable

### 6.3 Cross-Shell Bookmark Sharing

By default, all shells share a single bookmark file. A bookmark added in nushell is immediately available in PowerShell (they read the same file — no synchronization required).

Per-shell isolated bookmark stores are a planned future feature (see backlog), not part of the initial release.

---

## 7. Constraints and Requirements

- The binary must be a single statically-linkable executable; no runtime dependencies beyond the OS
- The binary **cannot** change the parent shell's working directory — this is handled by the shell shim (see TDD)
- The user-facing command interface (`pd <args>`) must be consistent across all supported shells
- Bookmark file writes must be atomic to prevent data corruption
- All error messages go to stderr; data output (paths, listings, init scripts) goes to stdout
- The tool must work on Linux servers without requiring elevated privileges or package installation beyond placing the binary in `$PATH`
