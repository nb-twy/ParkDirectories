# Park Directories — Development Backlog

**Last Updated**: 2026-04-08

Status legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Phase 1: Rust Binary Core ✓

All bookmark logic implemented in Rust. No shell integration yet — this phase produces a working binary that can be tested directly from any shell via its subcommand interface.

### Project Setup
- [x] Initialize Cargo project (`cargo new pd --bin`)
- [x] Set up workspace structure (`src/`, `tests/`)
- [x] Add dependencies: `clap` (CLI), `dirs` (home dir), `thiserror` (errors)
- [x] Configure `Cargo.toml` with metadata (name, version, description, license)
- [x] Set up `.gitignore` additions for Rust artifacts (`/target`, `Cargo.lock`)

### Data Model and File I/O
- [x] Define `Bookmark` struct (`name: String`, `path: PathBuf`)
- [x] Implement bookmark file parser (handle blank lines, `#` comments, name + path format)
- [x] Implement bookmark file writer (atomic write via temp file + rename)
- [x] Resolve data file path (default by OS, `PD_DATA_FILE` env var, `--data-file` flag)
- [x] Create data file if it does not exist (with correct permissions on Unix)

### Subcommands
- [x] `pd get <name>[/<relpath>]` — resolve bookmark, print path to stdout
- [x] `pd add <name> [path]` — add or update bookmark
  - [x] Default path = current working directory
  - [x] Expand `~`; resolve relative to absolute path
  - [x] Validate bookmark name (no `/`, no leading `-`)
  - [x] Check if path exists; warn + prompt if not (respect `--force`)
  - [x] Check for existing bookmark with same name; prompt before overwriting (respect `--force`)
  - [x] Write updated bookmark file atomically
- [x] `pd del <name>` — delete bookmark
- [x] `pd list` — list all bookmarks (column-aligned output)
- [x] `pd clear` — delete all bookmarks (prompt for confirmation; respect `--force`)
- [x] `pd expand <name>[/<relpath>]` — same as `get`, for explicit scripting use
- [x] `pd export <file>` — write bookmark file to `<file>`
- [x] `pd import [--append] [--quiet] [--force] <file>` — import from file

### Error Handling
- [x] Define exit codes (0 success, 1 usage, 2 not found, 3 path missing, 4 I/O error, 5 invalid name)
- [x] All errors to stderr; data to stdout
- [x] Consistent error message style

### Short-Flag Normalization (ADR-004)
- [x] `normalize_args` maps `-a/--add`, `-d/--del`, `-l/--list`, `-c/--clear`, `-x/--expand`, `-e/--export`, `-i/--import`, `-v` to their subcommand equivalents before clap parsing

### Tests
- [x] Unit tests for bookmark file parser (blank lines, comments, spaces in paths, tab separator)
- [x] Unit tests for name validation
- [x] Unit tests for path resolution with relative suffixes and `..` normalization
- [x] Unit tests for `BookmarkStore` CRUD operations
- [x] Integration tests using a temporary data file for each subcommand

---

## Phase 2: Shell Init Script Generation ✓

The binary generates the shell shim code, making installation self-contained.

- [x] `pd init bash` — bash integration function + tab completion registration
- [x] `pd init nu` — nushell `def --env pd` command
- [x] `pd init pwsh` — PowerShell function with binary path resolution
- [x] Init script templates embedded in the binary as string constants
- [x] `pd completions bash` — bash completion script (full implementation)
- [x] `pd completions nu` — nushell completion script (stub; full support in Phase 3)
- [x] `pd completions pwsh` — PowerShell completion script (stub; full support in Phase 5)

---

## Phase 3: Nushell Integration (Windows — Primary Target) ✓

- [x] Test `pd init nu` output in a real nushell session
- [x] Verify navigation (`pd <name>`) changes directory in the calling shell
- [x] Verify all management commands work through the shim (required `--wrapped` fix)
- [x] Implement tab completion for nushell
  - [x] Complete bookmark names
  - [x] Complete relative paths after `<name>/`
  - [x] Complete flags (intentionally not implemented: `--wrapped` intercepts `-` input before `@_pd_completer` is called; `pd --help` covers flag discovery)
  - [x] Complete file paths for `-a` (directory completion implemented; hidden dirs included via `ls --all`)
- [x] Verify relative path navigation (`pd <name>/<relpath>`)
- [x] Verify tab completion in a live nushell session
- [x] Document nushell setup procedure in README

---

## Phase 4: Bash Integration (Linux Servers — Secondary Target) ✓

- [x] Refine bash tab completion (position-aware, matching nushell fixes)
  - [x] Complete bookmark names
  - [x] Complete relative paths after `<name>/`
  - [x] Complete flags (`pd -<Tab>`) — bash supports this natively unlike nushell
  - [x] Complete directory paths for `pd -a name <Tab>` (position-aware dispatch)
  - [x] No spurious completions after no-arg flags (`pd -l <Tab>`, etc.)
- [x] Add `pd` with no args → `pd list` (consistent with nushell shim)
- [x] Document bash setup procedure in README
- [x] Archive the original bash implementation to `archive/`
- [x] Test `pd init bash` output in a real bash session (Linux) — requires Linux environment
- [x] Verify navigation changes directory correctly — requires Linux environment
- [x] Verify relative path navigation — requires Linux environment
- [x] Verify all management commands — requires Linux environment
- [x] Test on Fedora/RHEL and Ubuntu/Debian — requires Linux environment

---

## Phase 5: PowerShell Integration (Windows — Tertiary Target)

- [x] Test `pd init pwsh` output in a real PowerShell session
- [x] Verify navigation and all management commands
- [x] Implement PowerShell tab completion (using `Register-ArgumentCompleter`)
- [x] Document PowerShell setup procedure in README

---

## Phase 6: CI, GitHub Releases, and cargo install

### CI and GitHub Releases
- [ ] Set up GitHub Actions CI
  - [ ] Build and test on Windows (x64)
  - [ ] Build and test on Linux x64 (musl for fully static binary)
  - [ ] Build on Linux ARM64 (musl)
- [ ] Automate GitHub Release creation on version tag push
  - [ ] Attach pre-built binaries for each target
  - [ ] Include SHA256 checksums
- [ ] Write installation guide in README (download binary, add to PATH, run `pd init`)
- [ ] Version the shell init scripts alongside the binary

### cargo install (crates.io)
- [ ] Verify crate name `pd` is available on crates.io; if not, use `park-directories` with `[[bin]] name = "pd"`
- [ ] Complete `Cargo.toml` metadata: `repository`, `keywords`, `categories`, `readme`
- [ ] `cargo publish` after CI is in place and confirms clean cross-platform builds

---

## Phase 7: Additional Shell Support

Target the two mainstream shells not yet covered. Both require only a new
`pd init <shell>` output string in `src/init.rs` — no binary logic changes.

### zsh
- [ ] Implement `pd init zsh` — navigation function (≈ bash shim, adapted for zsh)
- [ ] Implement `pd completions zsh` — bookmark name and relative path completion (`compdef`)
- [ ] Test in a real zsh session (macOS or Linux)
- [ ] Document zsh setup procedure in README

### fish
- [ ] Implement `pd init fish` — navigation function in fish syntax (`function pd … end`)
- [ ] Implement `pd completions fish` — bookmark name and relative path completion
- [ ] Test in a real fish session
- [ ] Document fish setup procedure in README

> **Scope note**: CMD is intentionally excluded. The `.exe`/`.cmd` PATH precedence
> conflict makes a reliable wrapper impractical, and CMD offers no tab completion.
> Elvish, xonsh, tcsh, and other niche shells are deferred unless there is
> demonstrated community interest.

---

## Phase 8: Package Manager Distribution

### Winget (Windows)
- [ ] Create winget package manifest YAML (requires a published GitHub Release with SHA256)
- [ ] Decide on publisher/package ID (e.g., `NbTwy.ParkDirectories`)
- [ ] Submit manifest PR to [winget-pkgs](https://github.com/microsoft/winget-pkgs)
- [ ] Automate future manifest updates with `wingetcreate` on each release

### dnf / apt (Linux)
- [ ] Write RPM spec file for Fedora/RHEL packaging
- [ ] Publish to a COPR repository for Fedora/RHEL (`dnf copr enable …`)
- [ ] Write Debian control files for Ubuntu/Debian packaging
- [ ] Publish to a Launchpad PPA for Ubuntu/Debian (`add-apt-repository ppa:…`)
- [ ] Add post-install note in both packages directing users to run `pd init bash`

---

## Phase 9: Refinements and Carry-over Items

- [x] Integration tests using a temporary data file for each subcommand (moved from Phase 1)
- [ ] `--force` flag behavior audit across all commands
- [ ] Improve `pd list` output formatting for very long names or paths (truncation/wrapping)
- [ ] `pd rename <old> <new>` — rename a bookmark without changing its path
- [ ] `pd edit` — open the bookmark file in `$EDITOR`

---

## Future / Deferred

- [ ] Per-shell bookmark stores as a first-class configuration option (beyond `PD_DATA_FILE` workaround)
- [ ] macOS support (requires testing; architecture already supports it)
- [ ] `pd check` — verify all bookmarks point to existing directories; report broken ones
- [ ] `pd update <name>` — update a bookmark's path to the current directory
