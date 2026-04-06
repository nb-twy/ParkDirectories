# ADR-004: Binary Owns the Full CLI Interface

**Date**: 2026-04-06  
**Status**: Accepted

---

## Context

The binary uses subcommands internally (`pd get`, `pd add`, `pd del`, etc.), but the user-facing interface uses short flags (`pd -a`, `pd -d`, `pd -l`). The question is: which layer translates between the two?

Two options were considered:

1. **Shim translates**: The shell shim maps short flags to subcommands before calling the binary. The binary only understands subcommands.
2. **Binary translates**: The binary accepts both short flags and subcommands natively. The shim passes arguments through unchanged.

## Decision

The **binary accepts both forms** — short flags (`-a`, `-d`, `-l`, etc.) and long flags (`--add`, `--del`, `--list`, etc.) alongside the subcommand forms. The shell shim passes arguments through to the binary with minimal or no transformation.

The shim's only responsibility is:
1. Detect a navigation call (a single argument that is not a flag and not a known subcommand)
2. Call the binary with that argument, capture the path from stdout
3. Execute the shell's native directory-change command on that path

Everything else — argument parsing, validation, error messaging, flag translation — is handled by the binary.

## Rationale

- **Robustness**: The binary is directly usable from any context (scripts, other shells, CI) without the shim. Short flags work everywhere.
- **Minimal shim**: Shims contain no argument parsing logic. A shim that only intercepts navigation and passes everything else through is easier to write, easier to audit, and less likely to have shell-specific bugs.
- **Single source of truth for CLI behavior**: Help text, error messages, and flag definitions live in one place (the Rust binary) rather than being split across the binary and each shell's shim.
- **Simpler shim maintenance**: When the CLI grows (new flags, new subcommands), shims do not need to be updated — they already pass arguments through unchanged.

## Implementation Note

`clap` in Rust supports defining both subcommands and aliases. The short flags (`-a`, `-d`, etc.) will be implemented as top-level flags on the binary's root command, with logic that dispatches to the appropriate internal handler. Alternatively, they may be implemented as aliases for the subcommands — the exact `clap` wiring is an implementation detail.

## Consequences

- The binary's `clap` configuration is slightly more complex (it must handle both forms), but this complexity is bounded and well-supported by `clap`
- Shell shims are reduced to their minimum viable size — navigation detection + `cd` call
- Users who want to call the binary directly from scripts (without the shim) get the full, familiar interface
