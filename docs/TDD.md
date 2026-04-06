# Park Directories — Technical Design Document

**Version**: 1.0  
**Status**: Draft  
**Last Updated**: 2026-04-06

---

## 1. Architecture Overview

`pd` is implemented as a **hybrid system**: a compiled Rust binary that handles all bookmark logic, paired with a thin shell-native function/command in each supported shell that handles directory navigation.

```
┌─────────────────────────────────────────────────────────────┐
│                       User types:                            │
│                    pd myproject/src                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│            Shell-native `pd` function / command              │
│        (sourced into the current shell via init script)      │
│                                                              │
│  • For navigation calls: invoke binary, capture path, cd    │
│  • For all other calls: pass arguments through to binary     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Rust binary  (pd / pd.exe)                │
│                                                              │
│  • Bookmark CRUD (add, del, list, clear)                     │
│  • Path resolution (name → full path)                        │
│  • Import / export                                           │
│  • Shell init script generation  (pd init <shell>)           │
│  • Tab completion data generation                            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               Bookmark file  (~/.pd-data)                    │
│                                                              │
│   work    /home/kurt/projects/work                           │
│   rust    /home/kurt/projects/learning/rust                  │
│   dots    /home/kurt/.config                                 │
└─────────────────────────────────────────────────────────────┘
```

The key design insight: because a child process cannot modify its parent shell's working directory, the shell shim is unavoidable. But keeping it minimal (5–15 lines per shell) means the real logic lives entirely in Rust, which is compiled, tested, and consistent across all shells.

---

## 2. Rust Binary

### 2.1 Crate Structure

```
pd/                         (binary crate)
  src/
    main.rs                 entry point, CLI wiring
    cli.rs                  argument parsing (clap)
    bookmarks.rs            data model and file I/O
    resolve.rs              bookmark + relative path resolution
    init.rs                 shell init script generation
    completions.rs          completion data generation
    error.rs                error types and exit codes
  tests/
    integration/            integration tests against a temp data file
```

### 2.2 CLI Interface

The binary accepts **both** the subcommand form and the short/long flag form. The shell shim passes arguments through unchanged — it does no argument translation. See ADR-004.

**Subcommand form** (for direct scripting use and internal clarity):

| Subcommand | Meaning |
|---|---|
| `pd get <name>[/<relpath>]` | Resolve bookmark → print path to stdout |
| `pd add <name> [path]` | Add or update bookmark |
| `pd del <name>` | Delete bookmark |
| `pd list` | List all bookmarks |
| `pd clear` | Delete all bookmarks |
| `pd expand <name>[/<relpath>]` | Like `get`, but explicit — for scripting use |
| `pd export <file>` | Export bookmark file to `<file>` |
| `pd import [--append] [--quiet] <file>` | Import from `<file>` |
| `pd init <shell>` | Print init script for `bash`, `nu`, or `pwsh` |
| `pd completions <shell>` | Print completion script for given shell |

**Short/long flag form** (user-facing; identical behavior to the subcommand form):

| Short flag | Long flag | Equivalent subcommand |
|---|---|---|
| `pd -a <name> [path]` | `pd --add <name> [path]` | `pd add <name> [path]` |
| `pd -d <name>` | `pd --del <name>` | `pd del <name>` |
| `pd -l` | `pd --list` | `pd list` |
| `pd -c` | `pd --clear` | `pd clear` |
| `pd -x <name>` | `pd --expand <name>` | `pd expand <name>` |
| `pd -e <file>` | `pd --export <file>` | `pd export <file>` |
| `pd -i <file>` | `pd --import <file>` | `pd import <file>` |
| `pd -h` | `pd --help` | (built-in) |
| `pd -v` | `pd --version` | (built-in) |

**Navigation** (`pd <name>`) is not a flag form — it is a bare positional argument with no leading dash. The binary handles it by resolving the bookmark and printing the path; the shell shim then performs the `cd`.

Global flags available on all subcommands:
- `--data-file <path>` — override the bookmark file location
- `-V` / `--version` — print version
- `-h` / `--help` — print help

### 2.3 Shell Shim Responsibility

The shim's only job is navigation. It:

1. Detects a navigation call: a single argument with no leading `-`
2. Calls the binary: `pd get <name>`, captures stdout
3. Executes `cd <path>` (or the shell equivalent)

All other invocations are passed to the binary unchanged. The shim contains no argument parsing, no flag translation, and no business logic.

### 2.4 Path Resolution

`pd get <ref>` and `pd expand <ref>` resolve a reference (optionally with a relative path suffix):

1. Split input on the first `/` → `(name, relpath)` where `relpath` may be empty
2. Search the bookmark file for a line beginning with `name ` (name followed by a space)
3. Extract the stored path (everything after the first space on that line)
4. Append `relpath` to the stored path if non-empty
5. Normalize the combined path (resolve `.`, `..` components)
6. On success: print the resolved path to stdout, exit 0
7. On failure: print an error to stderr, exit with the appropriate error code

### 2.5 Bookmark File I/O

- Read the entire file into memory; parse line by line
- Skip blank lines and lines beginning with `#`
- Line format: `<name> <path>` — name is the first whitespace-delimited token; path is the remainder of the line (preserving spaces in paths)
- **Writes are atomic**: write to a temp file in the same directory, then `rename()` to the final path — prevents data corruption if the process is interrupted
- **File permissions on Unix**: 600 (owner read/write only); set after creation

### 2.6 Path Validation on Add

When `pd add <name> [path]` is invoked:

1. Resolve the path:
   - If `path` is omitted, use the current working directory
   - Expand `~` and resolve relative paths to absolute
2. Check whether the resolved path exists and is a directory
3. If it does not exist:
   - Print a warning to stderr
   - If stdin is a TTY and `--force` is not set: prompt for confirmation
   - If `--force` is set or stdin is not a TTY: print warning and add anyway (or fail — TBD during implementation)
4. Check whether `name` is already bookmarked; if so, prompt before overwriting (unless `--force`)

Bookmark name validation:
- Must not contain `/` (used as the relative path separator)
- Must not begin with `-` (would be ambiguous with flags)

### 2.7 Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments or usage error |
| 2 | Bookmark name not found |
| 3 | Target path does not exist |
| 4 | Data file I/O error |
| 5 | Invalid bookmark name |

All diagnostic output goes to **stderr**. Stdout is reserved for data: resolved paths, bookmark listings, init scripts, completion scripts.

---

## 3. Shell Integration

### 3.1 Why a Shell Shim Is Required

An external process cannot modify its parent shell's working directory — this is a fundamental OS constraint. The shell shim is the minimal layer required to bridge this gap. The shim:

- Intercepts navigation invocations (no leading `-`)
- Calls the binary to resolve the bookmark to a path
- Executes the shell's native directory-change command (`cd`, `Set-Location`)
- Passes all other invocations straight through to the binary

The shim is generated by `pd init <shell>` and sourced in the user's shell profile.

### 3.2 Nushell

**Why `def --env`**: In nushell, a custom command runs in its own scope by default. The `--env` flag allows the command to propagate environment changes (including `$env.PWD`) back to the caller's scope. Without it, `cd` inside the command would have no effect on the user's working directory.

**`^pd` syntax**: The caret prefix in nushell explicitly calls an external executable, bypassing any custom command with the same name. This is how the shim calls the binary without infinite recursion.

**Generated init script** (`pd init nu`):

```nushell
# Park Directories — nushell integration
# Generated by pd init nu
# Source this file in your config.nu: source ~/.config/nushell/pd.nu

def --env pd [...args: string] {
    if ($args | is-empty) {
        ^pd list
        return
    }

    let first = $args.0

    # Navigation: single bare argument (no leading dash)
    if (($args | length) == 1) and (not ($first | str starts-with '-')) {
        let target = (^pd get $first | str trim)
        if not ($target | is-empty) {
            cd $target
        }
        return
    }

    # All other operations: pass through to the binary
    ^pd ...$args
}
```

Tab completion is added via a nushell `extern` declaration or a `@completer` annotation — exact form TBD during implementation.

**Profile setup** (one-time):

```nushell
# In ~/.config/nushell/config.nu
source ~/.config/nushell/pd.nu
```

Users generate `pd.nu` by running:
```
pd init nu | save -f ~/.config/nushell/pd.nu
```

### 3.3 Bash

**`command pd` syntax**: The `command` builtin in bash bypasses shell functions and aliases, calling the external binary directly. This prevents infinite recursion when the function and binary share the name `pd`.

**Generated init script** (`pd init bash`):

```bash
# Park Directories — bash integration
# Generated by pd init bash
# Add to ~/.bashrc: eval "$(pd init bash)"

pd() {
    # Navigation: single bare argument (no leading dash)
    if [[ $# -eq 1 && "${1:0:1}" != "-" ]]; then
        local _pd_target
        _pd_target=$(command pd get "$1") || return $?
        [[ -n "$_pd_target" ]] && cd "$_pd_target"
        return
    fi
    # All other operations: pass through to the binary
    command pd "$@"
}

# Tab completion
_pd_completions() {
    # ... generated completion function ...
}
complete -F _pd_completions pd
```

**Profile setup** (one-time):

```bash
# In ~/.bashrc
eval "$(pd init bash)"
```

### 3.4 PowerShell

**`& pd.exe` syntax**: The call operator `&` invokes an external command by path or name. This bypasses the PowerShell function of the same name.

**Generated init script** (`pd init pwsh`):

```powershell
# Park Directories — PowerShell integration
# Generated by pd init pwsh
# Add to $PROFILE: Invoke-Expression (& pd init pwsh)

function pd {
    # Navigation: single bare argument (no leading dash)
    if ($args.Count -eq 1 -and -not $args[0].StartsWith('-')) {
        $target = & pd.exe get $args[0]
        if ($target) { Set-Location $target }
        return
    }
    # All other operations: pass through to the binary
    & pd.exe @args
}
```

**Profile setup** (one-time):

```powershell
# In $PROFILE
Invoke-Expression (& pd init pwsh)
```

---

## 4. Data Storage

### 4.1 Default File Location

The binary determines the default data file path at runtime:

| Platform | Default |
|----------|---------|
| Linux / macOS | `$HOME/.pd-data` |
| Windows | `%USERPROFILE%\.pd-data` |

### 4.2 Override Mechanism

Priority (highest wins):
1. `--data-file <path>` flag
2. `PD_DATA_FILE` environment variable
3. OS default path

The `PD_DATA_FILE` environment variable enables the future per-shell store feature: each shell profile can export a different value.

### 4.3 File Format Details

```
# This is a comment — ignored by pd
# Blank lines are also ignored

work   /home/kurt/projects/work
rust   /home/kurt/projects/learning/rust
dots   /home/kurt/.config
media  /mnt/nas/media/videos
```

- Separator between name and path is one or more spaces or a tab — parser uses `splitn(2, char::is_whitespace)`... actually it should split on the first whitespace sequence, so `name` = first token, `path` = trimmed remainder
- Paths containing spaces are supported (path is everything after the first whitespace sequence)
- The file is sorted by insertion order (not alphabetically); `pd list` displays in file order

---

## 5. Build and Distribution

### 5.1 Cargo Workspace Layout (anticipated)

```
ParkDirectories/
  Cargo.toml          (workspace root)
  Cargo.lock
  src/                (binary crate, or pd/ subdirectory)
  tests/
  docs/
  shells/             (generated init script templates, embedded in binary)
```

### 5.2 Target Platforms and Triples

| Platform | Rust Target Triple | Notes |
|----------|--------------------|-------|
| Windows x64 | `x86_64-pc-windows-msvc` | Primary development target |
| Linux x64 (glibc) | `x86_64-unknown-linux-gnu` | For servers with modern glibc |
| Linux x64 (musl) | `x86_64-unknown-linux-musl` | Fully static; best for older servers |
| Linux ARM64 | `aarch64-unknown-linux-gnu` | For ARM-based servers |
| macOS (future) | `x86_64-apple-darwin`, `aarch64-apple-darwin` | Deferred |

Prefer the musl target for Linux distribution — a fully static binary has no glibc version dependency and works on any Linux distribution without additional libraries.

### 5.3 Distribution

- GitHub Releases with pre-built binaries for each platform
- Single binary, no installer required
- User places binary somewhere in `$PATH`, then runs `pd init <shell>` and sources the output in their profile

### 5.4 Dependencies (anticipated)

| Crate | Purpose |
|-------|---------|
| `clap` | CLI argument parsing |
| `dirs` | Cross-platform home directory resolution |
| `anyhow` or `thiserror` | Error handling |

Aim to keep dependencies minimal — this is a small, focused tool.
