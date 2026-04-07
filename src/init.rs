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

/// Nushell integration command.
/// Generate with: pd init nu | save -f ~/.config/nushell/pd.nu
/// Source in config.nu with: source ~/.config/nushell/pd.nu
const NU_INIT: &str = r#"# Park Directories — nushell integration
# Generate this file with: pd init nu | save -f ~/.config/nushell/pd.nu
# Add to ~/.config/nushell/config.nu:
#   source ~/.config/nushell/pd.nu

# def --env: allows this command to modify the caller's environment (including $env.PWD)
# ^pd: the caret explicitly calls the external binary, bypassing this custom command
def --env --wrapped pd [...args: string] {
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

/// Nushell completion script (stub — full support in a future release).
const NU_COMPLETIONS: &str = r#"# Park Directories — nushell tab completion
# TODO: full completion support is planned for a future release.
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
