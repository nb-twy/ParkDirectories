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

    # After -d/--del or -x/--expand: complete bookmark names
    case "$prev" in
        -d|--del|-x|--expand)
            local names
            names=$(command pd list 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "$names" -- "$cur"))
            return ;;
        # After -a/--add, -e/--export, -i/--import: complete file paths
        -a|--add|-e|--export|-i|--import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
    esac

    # Complete flags
    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W \
            "-a --add -d --del -l --list -c --clear -x --expand -e --export -i --import -h --help -v --version" \
            -- "$cur"))
        return
    fi

    # Complete bookmark names, or subdirectories after name/
    if [[ "$cur" == */* ]]; then
        local ref="${cur%%/*}"
        local prefix="${cur%/*}/"
        local relpath="${cur#*/}"
        local base
        base=$(command pd get "$ref" 2>/dev/null) || return
        local targets
        targets=$(compgen -d -- "$base/$relpath")
        COMPREPLY=($(echo "$targets" | sed "s|^$base/|$prefix|" | sed 's|/*$|/|'))
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

    case "$prev" in
        -d|--del|-x|--expand)
            local names
            names=$(command pd list 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "$names" -- "$cur"))
            return ;;
        -a|--add|-e|--export|-i|--import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
    esac

    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W \
            "-a --add -d --del -l --list -c --clear -x --expand -e --export -i --import -h --help -v --version" \
            -- "$cur"))
        return
    fi

    if [[ "$cur" == */* ]]; then
        local ref="${cur%%/*}"
        local prefix="${cur%/*}/"
        local relpath="${cur#*/}"
        local base
        base=$(command pd get "$ref" 2>/dev/null) || return
        local targets
        targets=$(compgen -d -- "$base/$relpath")
        COMPREPLY=($(echo "$targets" | sed "s|^$base/|$prefix|" | sed 's|/*$|/|'))
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

    if ($prev in ["-d" "--del" "-x" "--expand"]) {
        # These flags expect a bookmark name next
        _pd_bookmark_names

    } else if ($prev in ["-a" "--add" "-e" "--export" "-i" "--import"]) {
        # These flags expect a file/directory path — return empty so nushell
        # falls back to its built-in file completer
        []

    } else if (not ($cur | str starts-with '-')) and ($cur | str contains '/') {
        # Relative-path completion: "bookmarkname/partial/path<TAB>"
        let ref_name = ($cur | split row '/' | first)
        let rel_typed = ($cur | str replace $"($ref_name)/" "")

        # Resolve the bookmark without printing an error if not found
        let get_result = (do { ^pd get $ref_name } | complete)
        if $get_result.exit_code != 0 { return [] }
        let base = ($get_result.stdout | str trim)
        if ($base | is-empty) { return [] }

        # List directories inside the appropriate level of the hierarchy
        let search_dir = (
            if ($rel_typed | is-empty) or (not ($rel_typed | str contains '/')) {
                $base
            } else {
                $"($base)/($rel_typed | path dirname)"
            }
        )

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
        # Default: complete bookmark names (navigation or first positional)
        _pd_bookmark_names
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
        _pd_bookmark_names
    } else if ($prev in ["-a" "--add" "-e" "--export" "-i" "--import"]) {
        []
    } else if (not ($cur | str starts-with '-')) and ($cur | str contains '/') {
        let ref_name = ($cur | split row '/' | first)
        let rel_typed = ($cur | str replace $"($ref_name)/" "")
        let get_result = (do { ^pd get $ref_name } | complete)
        if $get_result.exit_code != 0 { return [] }
        let base = ($get_result.stdout | str trim)
        if ($base | is-empty) { return [] }
        let search_dir = (
            if ($rel_typed | is-empty) or (not ($rel_typed | str contains '/')) {
                $base
            } else {
                $"($base)/($rel_typed | path dirname)"
            }
        )
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
