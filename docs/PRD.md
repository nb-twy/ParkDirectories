# Park Directories — Project Requirements Document

**Version**: 1.1  
**Status**: Draft  
**Last Updated**: 2026-04-08

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

---

## 8. Distribution

The goal is to make `pd` installable through the native package managers of each target platform, reducing friction for users who prefer not to build from source or manage binaries manually.

### 8.1 Cargo Install (crates.io)

**Target audience**: Users already in the Rust ecosystem who have `cargo` available.

**Mechanism**: `cargo install pd` (subject to crate name availability; see note below).

**Requirements**:
- Publish the crate to [crates.io](https://crates.io)
- `Cargo.toml` must include all required metadata: `repository`, `keywords`, `categories`, `readme`
- Builds cleanly on all target platforms from source (validated by Phase 6 CI)

**Considerations**:
- The crate name `pd` may already be claimed on crates.io. If so, an alternative such as `park-directories` can be used as the crate name while keeping `pd` as the installed binary name via `[[bin]] name = "pd"`
- `cargo install` compiles from source, so users need the Rust toolchain; this is not a barrier for the intended audience of this channel
- Easiest distribution channel to set up: a single `cargo publish` after CI is in place

**Prerequisite**: Phase 6 CI must confirm clean builds on all targets before publishing.

---

### 8.2 Winget (Windows)

**Target audience**: Windows users on the primary (nushell) and tertiary (PowerShell) target platforms who prefer a standard Windows installation experience.

**Mechanism**: `winget install pd` (exact package ID TBD at submission time).

**Requirements**:
- A published GitHub Release with an attached, pre-built Windows x64 binary (prerequisite: Phase 6 CI and release automation)
- A stable, versioned download URL — GitHub Releases provides this automatically
- SHA256 checksum of the binary, included in the package manifest
- A winget package manifest (YAML) submitted to the [winget-pkgs](https://github.com/microsoft/winget-pkgs) community repository
- Microsoft's automated review and validation pipeline must pass before the package is publicly available

**Considerations**:
- The manifest submission is a pull request to a public GitHub repository; turnaround is typically a few days
- The package ID follows the pattern `Publisher.ApplicationName` (e.g., `NbTwy.ParkDirectories`); the publisher name must be consistent across all future submissions
- Winget requires the download to be a proper installer or a `.zip`/standalone binary; a standalone `.exe` is acceptable
- Each new release requires an updated manifest PR — this can be automated with tools like `wingetcreate`

**Prerequisite**: Phase 6 GitHub Releases automation with an attached Windows x64 binary and SHA256 checksums.

---

### 8.3 dnf and apt (Linux)

**Target audience**: Linux server users on Fedora/RHEL (dnf) and Ubuntu/Debian (apt) who want to install and upgrade `pd` through their distribution's standard package management tooling.

**Mechanism**:
- Fedora/RHEL: `dnf copr enable <repo>/pd && dnf install pd` via a COPR repository, or a direct `.rpm` for manual install
- Ubuntu/Debian: `add-apt-repository ppa:<owner>/pd && apt install pd` via a Launchpad PPA, or a direct `.deb` for manual install

**Requirements**:
- Pre-built Linux binaries, statically linked via musl for maximum portability across distributions and kernel versions (prerequisite: Phase 6 CI building `x86_64-unknown-linux-musl` and `aarch64-unknown-linux-musl`)
- **Fedora/RHEL**: An RPM spec file defining package metadata, file placement, and the `%post` install note directing users to run `pd init bash`
- **Ubuntu/Debian**: Debian packaging control files (`control`, `rules`, `changelog`, etc.) with equivalent post-install guidance
- A COPR project (Fedora) or Launchpad PPA (Ubuntu) to host the packages and serve repository metadata

**Considerations**:
- Native package management is the most complex distribution channel: each distro family has its own packaging conventions, and maintaining packages for both RPM and DEB formats is ongoing work
- COPR (Fedora) and Launchpad PPA (Ubuntu) are community-hosted repositories — they lower the bar compared to official inclusion in Fedora or Debian/Ubuntu, which requires satisfying each distribution's full packaging policy
- Official distribution inclusion (Fedora package review, Debian mentors process) is a longer-term goal if community interest warrants it
- For technically capable users, a static musl binary placed in `$PATH` is always a fully supported alternative that bypasses native packaging entirely; the package manager route primarily benefits discoverability and automated upgrades
- ARM64 binaries are required for the growing number of ARM-based Linux servers (Ampere, Graviton, etc.)

**Prerequisite**: Phase 6 GitHub Releases automation with Linux x64 and ARM64 musl binaries and SHA256 checksums.
