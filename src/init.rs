use crate::error::PdError;

pub fn print_init(shell: &str) -> Result<(), PdError> {
    let script = match shell {
        "bash" => BASH_INIT,
        "nu" | "nushell" => NU_INIT,
        "pwsh" | "powershell" => PWSH_INIT,
        other => {
            return Err(PdError::Other(format!(
                "unknown shell '{other}'; supported shells: bash, nu, pwsh"
            )))
        }
    };
    print!("{script}");
    Ok(())
}

pub fn print_completions(shell: &str) -> Result<(), PdError> {
    let script = match shell {
        "bash" => BASH_COMPLETIONS,
        "nu" | "nushell" => NU_COMPLETIONS,
        "pwsh" | "powershell" => PWSH_COMPLETIONS,
        other => {
            return Err(PdError::Other(format!(
                "unknown shell '{other}'; supported shells: bash, nu, pwsh"
            )))
        }
    };
    print!("{script}");
    Ok(())
}

// ─── Bash ────────────────────────────────────────────────────────────────────

/// Bash integration function + tab completion.
/// Sourced via:  eval "$(pd init bash)"
const BASH_INIT: &str = r#"# Park Directories — bash integration
# Add to ~/.bashrc:
#   eval "$(pd init bash)"

pd() {
    # No arguments: list all bookmarks (consistent with nushell shim)
    if [[ $# -eq 0 ]]; then
        command pd list
        return
    fi
    # Navigation: single bare argument with no leading dash
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
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local first="${COMP_WORDS[1]}"

    # Flags that expect a bookmark name next
    case "$prev" in
        -d|--del|-x|--expand)
            local names
            names=$(command pd list 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "$names" -- "$cur"))
            return ;;
        # No-argument flags: nothing follows
        -l|--list|-c|--clear|-v|--version|-h|--help)
            return ;;
    esac

    # Flag completion
    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W \
            "-a --add -d --del -l --list -c --clear -x --expand -e --export -i --import -h --help -v --version" \
            -- "$cur"))
        return
    fi

    # Position-aware dispatch based on the subcommand/flag at position 1
    case "$first" in
        add|-a|--add)
            # Position 2 = name (no useful completion); position 3+ = directory path.
            # Read the actual typed word from COMP_LINE rather than COMP_WORDS[COMP_CWORD]
            # because COMP_WORDBREAKS may split a path like /var/log at '/' into separate
            # tokens, making $cur contain only the last component instead of the full path.
            if [[ $COMP_CWORD -ge 3 ]]; then
                local typed="${COMP_LINE:0:$COMP_POINT}"
                typed="${typed##* }"
                COMPREPLY=($(compgen -d -- "$typed"))
            fi
            return ;;
        del|-d|--del|expand|-x|--expand)
            if [[ $COMP_CWORD -eq 2 ]]; then
                local names
                names=$(command pd list 2>/dev/null | awk '{print $1}')
                COMPREPLY=($(compgen -W "$names" -- "$cur"))
            fi
            return ;;
        export|-e|--export|import|-i|--import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
        list|-l|--list|clear|-c|--clear)
            return ;;
    esac

    # First positional: navigation target or subcommand being typed
    if [[ "$cur" == */* ]]; then
        # Relative-path completion: bookmarkname/partial/path
        local ref="${cur%%/*}"
        local relpath="${cur#*/}"
        local base
        base=$(command pd get "$ref" 2>/dev/null) || return
        [[ -z "$base" ]] && return
        local targets
        targets=$(compgen -d -- "$base/$relpath")
        # Guard against empty results: an empty $targets piped through the sed
        # trailing-slash substitution would produce a bare '/' completion.
        [[ -z "$targets" ]] && return
        # Replace the absolute base prefix with just the bookmark name so that
        # deeper paths (e.g. dev/sub/deep) are not doubled by including both
        # the base path and the already-relative prefix.
        COMPREPLY=($(echo "$targets" | sed "s|^$base/|$ref/|" | sed 's|/*$|/|'))
    else
        local names
        names=$(command pd list 2>/dev/null | awk '{print $1}')
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
    fi
}

complete -o nospace -F _pd_completions pd
"#;

/// Standalone bash completion script (also included in BASH_INIT).
const BASH_COMPLETIONS: &str = r#"# Park Directories — bash tab completion
# Included automatically in 'pd init bash'.
# Source separately only if you defined the pd function another way.

_pd_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local first="${COMP_WORDS[1]}"

    case "$prev" in
        -d|--del|-x|--expand)
            local names
            names=$(command pd list 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "$names" -- "$cur"))
            return ;;
        -l|--list|-c|--clear|-v|--version|-h|--help)
            return ;;
    esac

    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W \
            "-a --add -d --del -l --list -c --clear -x --expand -e --export -i --import -h --help -v --version" \
            -- "$cur"))
        return
    fi

    case "$first" in
        add|-a|--add)
            if [[ $COMP_CWORD -ge 3 ]]; then
                local typed="${COMP_LINE:0:$COMP_POINT}"
                typed="${typed##* }"
                COMPREPLY=($(compgen -d -- "$typed"))
            fi
            return ;;
        del|-d|--del|expand|-x|--expand)
            if [[ $COMP_CWORD -eq 2 ]]; then
                local names
                names=$(command pd list 2>/dev/null | awk '{print $1}')
                COMPREPLY=($(compgen -W "$names" -- "$cur"))
            fi
            return ;;
        export|-e|--export|import|-i|--import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
        list|-l|--list|clear|-c|--clear)
            return ;;
    esac

    if [[ "$cur" == */* ]]; then
        local ref="${cur%%/*}"
        local relpath="${cur#*/}"
        local base
        base=$(command pd get "$ref" 2>/dev/null) || return
        [[ -z "$base" ]] && return
        local targets
        targets=$(compgen -d -- "$base/$relpath")
        [[ -z "$targets" ]] && return
        COMPREPLY=($(echo "$targets" | sed "s|^$base/|$ref/|" | sed 's|/*$|/|'))
    else
        local names
        names=$(command pd list 2>/dev/null | awk '{print $1}')
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
    fi
}

complete -o nospace -F _pd_completions pd
"#;

// ─── Nushell ─────────────────────────────────────────────────────────────────

/// Full nushell integration: navigation command + tab completion.
/// Generate with: pd init nu | save -f ~/.config/nushell/pd.nu
/// Source in config.nu with: source ~/.config/nushell/pd.nu
const NU_INIT: &str = r#"# Park Directories — nushell integration
# Generate this file with:
#   pd init nu | save -f ~/.config/nushell/pd.nu
# Add to ~/.config/nushell/config.nu:
#   source ~/.config/nushell/pd.nu

# ── Internal helpers ─────────────────────────────────────────────────────────

# Return all bookmark names as a list of strings.
def _pd_bookmark_names [] {
    try {
        ^pd list
        | lines
        | where { |l| not ($l | is-empty) }
        | each { |l|
            $l | str trim | split row ' ' | where { |t| not ($t | is-empty) } | first
        }
    } catch { [] }
}

# Custom completer called by nushell on every <Tab> press.
# Receives the full command-line context string and the cursor offset.
def _pd_completer [context: string, offset: int] {
    # Tokenize the context (skip the leading "pd" token itself)
    let args_tokens = (
        $context
        | split row ' '
        | where { |t| not ($t | is-empty) }
        | skip 1   # drop "pd"
    )
    let n = ($args_tokens | length)
    let ends_with_space = ($context | str ends-with ' ')

    # The token currently being typed (may be a partial string)
    let cur = if $ends_with_space { "" } else if $n > 0 { $args_tokens | last } else { "" }

    # The last fully-typed token before cur
    let prev = if $ends_with_space {
        if $n >= 1 { $args_tokens | last } else { "" }
    } else {
        if $n >= 2 { $args_tokens | get ($n - 2) } else { "" }
    }

    # Flags that expect a bookmark name next
    if ($prev in ["-d" "--del" "-x" "--expand"]) {
        return (_pd_bookmark_names)
    }

    # Flags that expect a file/dir path next — return empty so nushell
    # falls back to its built-in file completer
    if ($prev in ["-a" "--add" "-e" "--export" "-i" "--import"]) {
        return []
    }

    # No-argument flags — nothing follows
    if ($prev in ["-l" "--list" "-c" "--clear" "-v" "--version" "-h" "--help"]) {
        return []
    }

    # Partial flag being typed — no completion
    if ($cur | str starts-with '-') {
        return []
    }

    # Position of the token being typed (0 = first positional after "pd")
    let cur_pos = if $ends_with_space { $n } else if $n > 0 { $n - 1 } else { 0 }
    let subcmd = if $n > 0 { $args_tokens.0 } else { "" }

    if $cur_pos == 0 {
        if ($cur | str contains '/') {
            # Relative-path completion: "bookmarkname/partial/path<TAB>"
            let ref_name = ($cur | split row '/' | first)
            let rel_typed = ($cur | str replace $"($ref_name)/" "")

            # Resolve the bookmark without printing an error if not found
            let get_result = (do { ^pd get $ref_name } | complete)
            if $get_result.exit_code != 0 { return [] }
            let base = ($get_result.stdout | str trim)
            if ($base | is-empty) { return [] }

            # Determine which directory to list.
            # Strip the partial name being typed (everything after the last '/')
            # so "Aletheia42/sub_par" and "Aletheia42/" both search in "$base/Aletheia42".
            let search_dir = if ($rel_typed | is-empty) or (not ($rel_typed | str contains '/')) {
                $base
            } else {
                let dir_part = ($rel_typed | str replace --regex '[^/]*$' '' | str trim --right --char '/')
                if ($dir_part | is-empty) { $base } else { $"($base)/($dir_part)" }
            }

            try {
                ls $search_dir
                | where type == dir
                | get name
                | each { |p|
                    # Normalize OS path separators to '/' for the completion string
                    let p_norm = ($p | into string | str replace --all '\' '/')
                    let base_norm = ($base | str replace --all '\' '/')
                    let rel = ($p_norm | str replace $"($base_norm)/" "")
                    $"($ref_name)/($rel)"
                }
            } catch { [] }
        } else {
            # Complete bookmark names (navigation target or subcommand being typed)
            _pd_bookmark_names
        }
    } else if ($subcmd in ["del" "expand"]) and $cur_pos == 1 {
        # Subcommand form: complete the bookmark name argument
        _pd_bookmark_names
    } else if ($subcmd in ["add" "-a" "--add"]) and $cur_pos >= 2 {
        # Path argument of add: complete directories.
        # When cur ends with a separator the user wants to list inside that
        # directory, not its parent. Use --all so hidden directories such as
        # AppData appear as completions.
        let dir = if ($cur | is-empty) {
            "."
        } else if ($cur | str ends-with '\') or ($cur | str ends-with '/') {
            $cur
        } else {
            $cur | path dirname
        }
        try {
            ls --all $dir
            | where type == dir
            | get name
            | each { |p| $p | into string }
        } catch { [] }
    } else {
        # All other positions: no useful completion
        []
    }
}

# ── pd command ───────────────────────────────────────────────────────────────

# def --env : propagates environment changes (including $env.PWD) to the caller
# --wrapped : passes unrecognized flags through as string args instead of erroring
# ^pd       : the caret calls the external binary, bypassing this custom command
def --env --wrapped pd [...args: string@_pd_completer] {
    if ($args | is-empty) {
        ^pd list
        return
    }

    let first = $args.0

    # Navigation: single bare argument with no leading dash
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
"#;

/// Standalone nushell completion script.
/// The same completion definitions are already included in NU_INIT;
/// this is provided for users who sourced an older pd.nu and want
/// only the completion update.
const NU_COMPLETIONS: &str = r#"# Park Directories — nushell tab completion
# This is already included in 'pd init nu'.
# Source separately only if you need to refresh completions independently.

def _pd_bookmark_names [] {
    try {
        ^pd list
        | lines
        | where { |l| not ($l | is-empty) }
        | each { |l|
            $l | str trim | split row ' ' | where { |t| not ($t | is-empty) } | first
        }
    } catch { [] }
}

def _pd_completer [context: string, offset: int] {
    let args_tokens = (
        $context
        | split row ' '
        | where { |t| not ($t | is-empty) }
        | skip 1
    )
    let n = ($args_tokens | length)
    let ends_with_space = ($context | str ends-with ' ')
    let cur = if $ends_with_space { "" } else if $n > 0 { $args_tokens | last } else { "" }
    let prev = if $ends_with_space {
        if $n >= 1 { $args_tokens | last } else { "" }
    } else {
        if $n >= 2 { $args_tokens | get ($n - 2) } else { "" }
    }

    if ($prev in ["-d" "--del" "-x" "--expand"]) {
        return (_pd_bookmark_names)
    }
    if ($prev in ["-a" "--add" "-e" "--export" "-i" "--import"]) {
        return []
    }
    if ($prev in ["-l" "--list" "-c" "--clear" "-v" "--version" "-h" "--help"]) {
        return []
    }
    if ($cur | str starts-with '-') {
        return []
    }

    let cur_pos = if $ends_with_space { $n } else if $n > 0 { $n - 1 } else { 0 }
    let subcmd = if $n > 0 { $args_tokens.0 } else { "" }

    if $cur_pos == 0 {
        if ($cur | str contains '/') {
            let ref_name = ($cur | split row '/' | first)
            let rel_typed = ($cur | str replace $"($ref_name)/" "")
            let get_result = (do { ^pd get $ref_name } | complete)
            if $get_result.exit_code != 0 { return [] }
            let base = ($get_result.stdout | str trim)
            if ($base | is-empty) { return [] }
            let search_dir = if ($rel_typed | is-empty) or (not ($rel_typed | str contains '/')) {
                $base
            } else {
                let dir_part = ($rel_typed | str replace --regex '[^/]*$' '' | str trim --right --char '/')
                if ($dir_part | is-empty) { $base } else { $"($base)/($dir_part)" }
            }
            try {
                ls $search_dir
                | where type == dir
                | get name
                | each { |p|
                    let p_norm = ($p | into string | str replace --all '\' '/')
                    let base_norm = ($base | str replace --all '\' '/')
                    let rel = ($p_norm | str replace $"($base_norm)/" "")
                    $"($ref_name)/($rel)"
                }
            } catch { [] }
        } else {
            _pd_bookmark_names
        }
    } else if ($subcmd in ["del" "expand"]) and $cur_pos == 1 {
        _pd_bookmark_names
    } else if ($subcmd in ["add" "-a" "--add"]) and $cur_pos >= 2 {
        let dir = if ($cur | is-empty) {
            "."
        } else if ($cur | str ends-with '\') or ($cur | str ends-with '/') {
            $cur
        } else {
            $cur | path dirname
        }
        try {
            ls --all $dir
            | where type == dir
            | get name
            | each { |p| $p | into string }
        } catch { [] }
    } else {
        []
    }
}
"#;

// ─── PowerShell ──────────────────────────────────────────────────────────────

/// PowerShell integration function.
/// Add to $PROFILE:  Invoke-Expression (& pd init pwsh)
const PWSH_INIT: &str = r#"# Park Directories — PowerShell integration
# Add to $PROFILE:
#   Invoke-Expression (& pd init pwsh)

# Resolve the binary path once at load time so the function can bypass itself.
$script:_pdBin = (Get-Command -Name 'pd' -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty Source)

function pd {
    # Navigation: single bare argument with no leading dash
    if ($args.Count -eq 1 -and -not $args[0].ToString().StartsWith('-')) {
        $target = & $script:_pdBin get $args[0]
        if ($LASTEXITCODE -eq 0 -and $target) {
            Set-Location $target
        }
        return
    }
    # All other operations: pass through to the binary
    & $script:_pdBin @args
}
"#;

/// PowerShell completion script (stub — full support in a future release).
const PWSH_COMPLETIONS: &str = r#"# Park Directories — PowerShell tab completion
# TODO: full completion support is planned for a future release.
"#;
