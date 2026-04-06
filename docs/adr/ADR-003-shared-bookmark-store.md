# ADR-003: Shared Bookmark Store Across Shells (Default)

**Date**: 2026-04-06  
**Status**: Accepted

---

## Context

When a user runs nushell and PowerShell simultaneously in different Windows Terminal tabs, they may add or use bookmarks in either session. The question is whether those bookmarks should be visible across sessions, or isolated per shell.

Two options were considered:

1. **Shared store (default)**: All shells read from and write to the same bookmark file (`~/.pd-data`). A bookmark added in nushell is immediately visible in PowerShell.
2. **Per-shell stores**: Each shell maintains its own isolated bookmark file (e.g., `~/.pd-data-nu`, `~/.pd-data-pwsh`, `~/.pd-data-bash`).

## Decision

**Shared store is the default**. All shells use the same bookmark file unless the user explicitly overrides the file location.

Per-shell isolation will be supported as a **future configuration option** via the `PD_DATA_FILE` environment variable — a user who wants isolation can set `PD_DATA_FILE` to a shell-specific path in each shell's profile.

## Rationale

- The primary use case is a user running nushell and PowerShell in different Windows Terminal tabs who wants their bookmarks to be the same in both — shared store is the right default for this
- Sharing requires no synchronization: both shells read the same file from the filesystem; the file is always current
- Per-shell isolation adds complexity for a use case that is not the common case
- The `PD_DATA_FILE` environment variable override (which must be implemented anyway to allow `--data-file` functionality) provides per-shell isolation at no additional implementation cost — users set different values in each shell's profile

## Consequences

- Concurrent writes from two shells (extremely unlikely in practice, but theoretically possible) are safe because all writes are atomic (write to temp file, rename)
- The default data file path is the same regardless of which shell invokes the binary
- Per-shell isolation is achievable by the user today via `PD_DATA_FILE` without additional features
- A future configuration system may formalize per-shell stores as a first-class feature
