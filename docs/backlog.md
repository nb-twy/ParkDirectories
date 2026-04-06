# Park Directories — Development Backlog

**Last Updated**: 2026-04-06

Status legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Phase 1: Rust Binary Core

All bookmark logic implemented in Rust. No shell integration yet — this phase produces a working binary that can be tested directly from any shell via its subcommand interface.

### Project Setup
- [ ] Initialize Cargo project (`cargo new pd --bin`)
- [ ] Set up workspace structure (`src/`, `tests/`)
- [ ] Add dependencies: `clap` (CLI), `dirs` (home dir), `thiserror` or `anyhow` (errors)
- [ ] Configure `Cargo.toml` with metadata (name, version, description, license)
- [ ] Set up `.gitignore` additions for Rust artifacts (`/target`, `Cargo.lock` policy)

### Data Model and File I/O
- [ ] Define `Bookmark` struct (`name: String`, `path: PathBuf`)
- [ ] Implement bookmark file parser (handle blank lines, `#` comments, name + path format)
- [ ] Implement bookmark file writer (atomic write via temp file + rename)
- [ ] Resolve data file path (default by OS, `PD_DATA_FILE` env var, `--data-file` flag)
- [ ] Create data file if it does not exist (with correct permissions on Unix)

### Subcommands
- [ ] `pd get <name>[/<relpath>]` — resolve bookmark, print path to stdout
  - [ ] Split input on first `/` to extract name and relative path
  - [ ] Look up name in bookmark file
  - [ ] Join stored path with relative path suffix
  - [ ] Normalize the result (resolve `.` and `..`)
  - [ ] Print to stdout on success; error to stderr + non-zero exit on failure
- [ ] `pd add <name> [path]` — add or update bookmark
  - [ ] Default path = current working directory
  - [ ] Expand `~`; resolve relative to absolute path
  - [ ] Validate bookmark name (no `/`, no leading `-`)
  - [ ] Check if path exists; warn + prompt if not (respect `--force`)
  - [ ] Check for existing bookmark with same name; prompt before overwriting (respect `--force`)
  - [ ] Write updated bookmark file atomically
- [ ] `pd del <name>` — delete bookmark
  - [ ] Error if name not found
  - [ ] Write updated file
- [ ] `pd list` — list all bookmarks
  - [ ] Print in `name  path` format, aligned for readability
  - [ ] Print message if no bookmarks exist
- [ ] `pd clear` — delete all bookmarks
  - [ ] Prompt for confirmation unless `--force`
  - [ ] Truncate data file (preserve comments if any)
- [ ] `pd expand <name>[/<relpath>]` — same as `get`, for explicit scripting use
- [ ] `pd export <file>` — copy bookmark file to `<file>`
  - [ ] Error if destination is not writable
- [ ] `pd import [--append] [--quiet] <file>` — import from file
  - [ ] Default (no flags): prompt before replacing; backup existing file
  - [ ] `--append`: merge imported bookmarks, skip duplicate names
  - [ ] `--quiet`: non-interactive; replace without prompting
  - [ ] Validate import file format before writing

### Error Handling
- [ ] Define exit codes (0 success, 1 usage, 2 not found, 3 path missing, 4 I/O error, 5 invalid name)
- [ ] All errors to stderr; data to stdout
- [ ] Consistent error message style

### Tests
- [ ] Unit tests for bookmark file parser (blank lines, comments, spaces in paths)
- [ ] Unit tests for name/path validation
- [ ] Unit tests for path resolution with relative suffixes
- [ ] Integration tests using a temporary data file for each subcommand
- [ ] Test atomic write behavior (temp file + rename)

---

## Phase 2: Shell Init Script Generation

The binary gains the ability to generate the shell shim code, making installation self-contained.

- [ ] `pd init bash` — print bash integration function + completion registration
- [ ] `pd init nu` — print nushell `def --env pd` command + completion definition
- [ ] `pd init pwsh` — print PowerShell function
- [ ] Embed init script templates in the binary (use `include_str!` macros)
- [ ] `pd completions bash` — print bash completion script
- [ ] `pd completions nu` — print nushell completion definitions
- [ ] `pd completions pwsh` — print PowerShell tab completion registration

---

## Phase 3: Nushell Integration (Windows — Primary Target)

- [ ] Test `pd init nu` output in a real nushell session
- [ ] Verify navigation (`pd <name>`) changes directory in the calling shell
- [ ] Verify relative path navigation (`pd <name>/<relpath>`)
- [ ] Verify all management commands work through the shim
- [ ] Implement and test tab completion for nushell
  - [ ] Complete bookmark names
  - [ ] Complete relative paths after `<name>/`
  - [ ] Complete flags
  - [ ] Complete file paths for `-a`, `-i`, `-e`
- [ ] Document nushell setup procedure in README

---

## Phase 4: Bash Integration (Linux Servers — Secondary Target)

- [ ] Test `pd init bash` output in a real bash session (Linux)
- [ ] Verify navigation changes directory correctly
- [ ] Verify relative path navigation
- [ ] Verify all management commands
- [ ] Implement and test bash tab completion
  - [ ] Complete bookmark names
  - [ ] Complete relative paths after `<name>/`
  - [ ] Complete flags
  - [ ] Complete file paths for `-a`, `-i`, `-e`
- [ ] Test on a Linux server (Ubuntu/Debian)
- [ ] Document bash setup procedure in README

---

## Phase 5: PowerShell Integration (Windows — Tertiary Target)

- [ ] Test `pd init pwsh` output in a real PowerShell session
- [ ] Verify navigation and all management commands
- [ ] Implement and test PowerShell tab completion (using `Register-ArgumentCompleter`)
- [ ] Document PowerShell setup procedure in README

---

## Phase 6: Build and Distribution

- [ ] Set up GitHub Actions CI
  - [ ] Build and test on Windows (x64)
  - [ ] Build and test on Linux (x64, musl)
  - [ ] Build on Linux ARM64
- [ ] Automate GitHub Release creation on version tag push
  - [ ] Attach pre-built binaries for each target
  - [ ] Include SHA256 checksums
- [ ] Write installation guide in README (download binary, add to PATH, run `pd init`)
- [ ] Version the shell init scripts alongside the binary

---

## Phase 7: Refinements and Carry-over Items

Items from the original bash `todo.md` that are still relevant, plus new ideas:

- [ ] When adding a bookmark, check if target path exists; prompt if not (captured in Phase 1 but listed here for visibility)
- [ ] `--force` flag to suppress all interactive prompts
- [ ] Improve `pd list` output formatting (align columns, handle long names/paths)
- [ ] `pd rename <old> <new>` — rename a bookmark without changing its path
- [ ] `pd edit` — open the bookmark file in `$EDITOR`

---

## Future / Deferred

- [ ] Per-shell bookmark stores as a first-class configuration option (beyond `PD_DATA_FILE` workaround)
- [ ] macOS support (requires testing; architecture already supports it)
- [ ] Shell init for fish shell
- [ ] `pd check` — verify all bookmarks point to existing directories; report broken ones
- [ ] `pd update <name>` — update a bookmark's path to the current directory
