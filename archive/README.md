# Archive — Park Directories v2.x (bash-only implementation)

This directory preserves the original bash-only implementation of Park Directories,
which was the primary implementation through v2.1.0.

## Files

| File | Description |
|---|---|
| `pd.sh` | Main executable — the bash function and all command logic |
| `install.sh` | Installation script |
| `update.sh` | In-place update script |
| `uninstall.sh` | Uninstallation script |
| `common.sh` | Shared utility functions |
| `defaults.sh` | Default configuration values |
| `dothis.sh` | Command dispatch helpers |
| `todo.md` | Original development todo list |
| `pd-return-codes.md` | Original exit code documentation |

## Status

These files are **no longer maintained**. They are preserved for historical
reference only.

The v3.0.0 rewrite replaced this implementation with a compiled Rust binary
that supports nushell, bash, and PowerShell from a single cross-platform
executable. See the project README for current installation instructions.
