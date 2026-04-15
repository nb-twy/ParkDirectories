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
    print!("{}", script.replace("{PD_VERSION}", env!("CARGO_PKG_VERSION")));
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

export PD_INIT_VERSION="{PD_VERSION}"

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

# Helper: complete a navigation/expand argument — bookmark names OR relative paths.
_pd_nav_complete() {
    local cur="$1"
    if [[ "$cur" == */* ]]; then
        # Relative-path completion: bookmarkname/partial/path
        local ref="${cur%%/*}"
        local relpath="${cur#*/}"
        local base
        base=$(command pd get "$ref" 2>/dev/null) || return
        [[ -z "$base" ]] && return
        local targets
        targets=$(compgen -d -- "$base/$relpath")
        # Guard against empty results to avoid a bare '/' completion.
        [[ -z "$targets" ]] && return
        # Replace the absolute base prefix with just the bookmark name.
        COMPREPLY=($(echo "$targets" | sed "s|^$base/|$ref/|" | sed 's|/*$|/|'))
    else
        local names
        names=$(command pd list 2>/dev/null | awk '{print $1}')
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
    fi
}

_pd_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local first="${COMP_WORDS[1]}"

    # Flags that expect a specific argument next
    case "$prev" in
        -d|--del)
            local names
            names=$(command pd list 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "$names" -- "$cur"))
            return ;;
        -x|--expand)
            _pd_nav_complete "$cur"
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
        del|-d|--del)
            if [[ $COMP_CWORD -eq 2 ]]; then
                local names
                names=$(command pd list 2>/dev/null | awk '{print $1}')
                COMPREPLY=($(compgen -W "$names" -- "$cur"))
            fi
            return ;;
        expand|-x|--expand)
            if [[ $COMP_CWORD -eq 2 ]]; then
                _pd_nav_complete "$cur"
            fi
            return ;;
        export|-e|--export|import|-i|--import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
        list|-l|--list|clear|-c|--clear)
            return ;;
    esac

    # First positional: navigation target or subcommand being typed
    _pd_nav_complete "$cur"
}

complete -o nospace -F _pd_completions pd
"#;

/// Standalone bash completion script (also included in BASH_INIT).
const BASH_COMPLETIONS: &str = r#"# Park Directories — bash tab completion
# Included automatically in 'pd init bash'.
# Source separately only if you defined the pd function another way.

_pd_nav_complete() {
    local cur="$1"
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

_pd_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local first="${COMP_WORDS[1]}"

    case "$prev" in
        -d|--del)
            local names
            names=$(command pd list 2>/dev/null | awk '{print $1}')
            COMPREPLY=($(compgen -W "$names" -- "$cur"))
            return ;;
        -x|--expand)
            _pd_nav_complete "$cur"
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
        del|-d|--del)
            if [[ $COMP_CWORD -eq 2 ]]; then
                local names
                names=$(command pd list 2>/dev/null | awk '{print $1}')
                COMPREPLY=($(compgen -W "$names" -- "$cur"))
            fi
            return ;;
        expand|-x|--expand)
            if [[ $COMP_CWORD -eq 2 ]]; then
                _pd_nav_complete "$cur"
            fi
            return ;;
        export|-e|--export|import|-i|--import)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
        list|-l|--list|clear|-c|--clear)
            return ;;
    esac

    _pd_nav_complete "$cur"
}

complete -o nospace -F _pd_completions pd
"#;

// ─── Nushell ─────────────────────────────────────────────────────────────────

/// Full nushell integration: navigation command + tab completion.
/// Add to env.nu:    ^pd init nu | save -f ~/.config/nushell/pd.nu
/// Add to config.nu: source ~/.config/nushell/pd.nu
const NU_INIT: &str = r#"# Park Directories — nushell integration
# Add to ~/.config/nushell/env.nu:
#   ^pd init nu | save -f ~/.config/nushell/pd.nu
# Add to ~/.config/nushell/config.nu:
#   source ~/.config/nushell/pd.nu

$env.PD_INIT_VERSION = "{PD_VERSION}"

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

# Helper: complete a navigation/expand argument — bookmark names OR relative paths.
def _pd_nav_complete [cur: string] {
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
            ls --all $search_dir
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

    # Flags that expect a bookmark name (del) or bookmark name/relative path (expand) next
    if ($prev in ["-d" "--del"]) {
        return (_pd_bookmark_names)
    }
    if ($prev in ["-x" "--expand"]) {
        return (_pd_nav_complete $cur)
    }

    # export/import: complete files and directories
    if ($prev in ["-e" "--export" "-i" "--import"]) {
        let dir = if ($cur | is-empty) {
            "."
        } else if ($cur | str ends-with '\') or ($cur | str ends-with '/') {
            $cur
        } else {
            $cur | path dirname
        }
        return (try {
            ls --all $dir
            | get name
            | each { |p| $p | into string }
        } catch { [] })
    }

    # add: no completion for the name argument (path is handled position-aware below)
    if ($prev in ["-a" "--add"]) {
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
        _pd_nav_complete $cur
    } else if ($subcmd == "del") and $cur_pos == 1 {
        # Subcommand form: complete the bookmark name argument
        _pd_bookmark_names
    } else if ($subcmd == "expand") and $cur_pos == 1 {
        # Subcommand form: complete bookmark name or relative path
        _pd_nav_complete $cur
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
    } else if ($subcmd in ["export" "import"]) and $cur_pos == 1 {
        # Subcommand form of export/import: complete files and directories
        let dir = if ($cur | is-empty) {
            "."
        } else if ($cur | str ends-with '\') or ($cur | str ends-with '/') {
            $cur
        } else {
            $cur | path dirname
        }
        try {
            ls --all $dir
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

def _pd_nav_complete [cur: string] {
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
            ls --all $search_dir
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

    if ($prev in ["-d" "--del"]) {
        return (_pd_bookmark_names)
    }
    if ($prev in ["-x" "--expand"]) {
        return (_pd_nav_complete $cur)
    }
    if ($prev in ["-e" "--export" "-i" "--import"]) {
        let dir = if ($cur | is-empty) {
            "."
        } else if ($cur | str ends-with '\') or ($cur | str ends-with '/') {
            $cur
        } else {
            $cur | path dirname
        }
        return (try {
            ls --all $dir
            | get name
            | each { |p| $p | into string }
        } catch { [] })
    }
    if ($prev in ["-a" "--add"]) {
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
        _pd_nav_complete $cur
    } else if ($subcmd == "del") and $cur_pos == 1 {
        _pd_bookmark_names
    } else if ($subcmd == "expand") and $cur_pos == 1 {
        _pd_nav_complete $cur
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
    } else if ($subcmd in ["export" "import"]) and $cur_pos == 1 {
        let dir = if ($cur | is-empty) {
            "."
        } else if ($cur | str ends-with '\') or ($cur | str ends-with '/') {
            $cur
        } else {
            $cur | path dirname
        }
        try {
            ls --all $dir
            | get name
            | each { |p| $p | into string }
        } catch { [] }
    } else {
        []
    }
}
"#;

// ─── PowerShell ──────────────────────────────────────────────────────────────

/// PowerShell integration: navigation function + tab completion.
/// Add to $PROFILE:  & pd init pwsh | Out-String | Invoke-Expression
const PWSH_INIT: &str = r#"# Park Directories — PowerShell integration
# Add to $PROFILE:
#   & pd init pwsh | Out-String | Invoke-Expression

$env:PD_INIT_VERSION = "{PD_VERSION}"

# Resolve the binary path once at load time so the function can bypass itself.
$script:_pdBin = (Get-Command -Name 'pd' -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty Source)

function pd {
    # No arguments: list all bookmarks
    if ($args.Count -eq 0) {
        & $script:_pdBin list
        return
    }
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

# ── Tab completion ────────────────────────────────────────────────────────────
# Capture the binary path for use inside the completer closure.
$_pdBinPath = $script:_pdBin

Register-ArgumentCompleter -CommandName pd -ScriptBlock ({
    param($wordToComplete, $commandAst, $cursorPosition)

    # All tokens after 'pd', as plain strings
    $tokens = @($commandAst.CommandElements | Select-Object -Skip 1 |
                ForEach-Object { $_.ToString() })
    $n     = $tokens.Count
    $cur   = $wordToComplete
    $atNew = ($cur -eq '')

    # Last fully-typed token (before the current partial word)
    $prev = if ($atNew) {
                if ($n -ge 1) { $tokens[-1] } else { '' }
            } else {
                if ($n -ge 2) { $tokens[-2] } else { '' }
            }

    # Positional slot being completed (0 = first arg after 'pd')
    $curPos = if ($atNew) { $n } else { $n - 1 }
    $subcmd = if ($n -gt 0) { $tokens[0] } else { '' }

    # Shorthand: wrap a string as a CompletionResult
    $mkResult = [scriptblock] {
        param($t)
        [System.Management.Automation.CompletionResult]::new($t, $t, 'ParameterValue', $t)
    }

    # Fetch bookmark names from the binary
    $names = & $_pdBinPath list 2>$null |
             ForEach-Object { ($_ -split '\s+', 2)[0] } |
             Where-Object   { $_ -ne '' }

    # Helper: complete a navigation/expand argument — bookmark names OR relative paths.
    # Closes over $cur, $names, $mkResult, $_pdBinPath from the enclosing scope.
    $navComplete = {
        if ($cur -like '*/*') {
            $refName  = ($cur -split '/', 2)[0]
            $relTyped = ($cur -split '/', 2)[1]
            $rawBase  = & $_pdBinPath get $refName 2>$null
            $baseExit = $LASTEXITCODE
            $base     = if ($rawBase) { "$rawBase".Trim() } else { '' }
            if ($baseExit -ne 0 -or -not $base) { return }
            $searchDir = if ($relTyped -match '[/\\]') {
                $lastSep = [Math]::Max($relTyped.LastIndexOf('/'), $relTyped.LastIndexOf('\'))
                Join-Path $base $relTyped.Substring(0, $lastSep)
            } else { $base }
            $baseTrimmed = $base.TrimEnd('\', '/')
            Get-ChildItem -LiteralPath $searchDir -Directory -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $rel = $_.FullName.Substring($baseTrimmed.Length).TrimStart('\', '/')
                    "$refName/$($rel -replace '\\', '/')"
                } |
                Where-Object { $_ -like "$cur*" } |
                ForEach-Object { & $mkResult $_ }
        } else {
            $names | Where-Object { $_ -like "$cur*" } | ForEach-Object { & $mkResult $_ }
        }
    }

    # ── Prev-based dispatch ──────────────────────────────────────────────────

    # -d/--del expects a bookmark name; -x/--expand accepts a bookmark name or relative path
    if ($prev -in '-d', '--del') {
        $names | Where-Object { $_ -like "$cur*" } |
                 ForEach-Object { & $mkResult $_ }
        return
    }
    if ($prev -in '-x', '--expand') {
        & $navComplete
        return
    }

    # Flags that expect a file path — no custom completion offered
    if ($prev -in '-e', '--export', '-i', '--import') { return }

    # No-argument flags — nothing useful follows
    if ($prev -in '-l', '--list', '-c', '--clear', '-v', '--version', '-h', '--help') { return }

    # ── Flag completion ──────────────────────────────────────────────────────

    if ($cur -like '-*') {
        '-a', '--add', '-d', '--del', '-l', '--list', '-c', '--clear',
        '-x', '--expand', '-e', '--export', '-i', '--import',
        '-h', '--help', '-v', '--version' |
            Where-Object { $_ -like "$cur*" } |
            ForEach-Object { & $mkResult $_ }
        return
    }

    # ── Position-aware dispatch ──────────────────────────────────────────────

    if ($curPos -eq 0) {
        & $navComplete

    } elseif ($subcmd -eq 'del' -and $curPos -eq 1) {
        $names | Where-Object { $_ -like "$cur*" } | ForEach-Object { & $mkResult $_ }

    } elseif ($subcmd -eq 'expand' -and $curPos -eq 1) {
        & $navComplete

    } elseif ($subcmd -in 'add', '-a', '--add' -and $curPos -ge 2) {
        # Directory completion for the path argument of 'add'
        $dirBase = if ($cur -eq '') {
                       '.'
                   } elseif ($cur -like '*\' -or $cur -like '*/') {
                       $cur
                   } else {
                       $p = Split-Path -Parent $cur
                       if ($p) { $p } else { '.' }
                   }

        Get-ChildItem -LiteralPath $dirBase -Directory -Force -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName } |
            Where-Object   { $_ -like "$cur*" } |
            ForEach-Object { & $mkResult $_ }
    }
}.GetNewClosure())
"#;

/// Standalone PowerShell completion script.
/// The same completion definitions are already included in PWSH_INIT;
/// this is provided for users who sourced an older pd.ps1 and want
/// only the completion update.
const PWSH_COMPLETIONS: &str = r#"# Park Directories — PowerShell tab completion
# This is already included in 'pd init pwsh'.
# Source separately only if you need to refresh completions independently.

$_pdBinPath = (Get-Command -Name 'pd' -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty Source)

Register-ArgumentCompleter -CommandName pd -ScriptBlock ({
    param($wordToComplete, $commandAst, $cursorPosition)

    $tokens = @($commandAst.CommandElements | Select-Object -Skip 1 |
                ForEach-Object { $_.ToString() })
    $n     = $tokens.Count
    $cur   = $wordToComplete
    $atNew = ($cur -eq '')

    $prev = if ($atNew) {
                if ($n -ge 1) { $tokens[-1] } else { '' }
            } else {
                if ($n -ge 2) { $tokens[-2] } else { '' }
            }

    $curPos = if ($atNew) { $n } else { $n - 1 }
    $subcmd = if ($n -gt 0) { $tokens[0] } else { '' }

    $mkResult = [scriptblock] {
        param($t)
        [System.Management.Automation.CompletionResult]::new($t, $t, 'ParameterValue', $t)
    }

    $names = & $_pdBinPath list 2>$null |
             ForEach-Object { ($_ -split '\s+', 2)[0] } |
             Where-Object   { $_ -ne '' }

    $navComplete = {
        if ($cur -like '*/*') {
            $refName  = ($cur -split '/', 2)[0]
            $relTyped = ($cur -split '/', 2)[1]
            $rawBase  = & $_pdBinPath get $refName 2>$null
            $baseExit = $LASTEXITCODE
            $base     = if ($rawBase) { "$rawBase".Trim() } else { '' }
            if ($baseExit -ne 0 -or -not $base) { return }
            $searchDir = if ($relTyped -match '[/\\]') {
                $lastSep = [Math]::Max($relTyped.LastIndexOf('/'), $relTyped.LastIndexOf('\'))
                Join-Path $base $relTyped.Substring(0, $lastSep)
            } else { $base }
            $baseTrimmed = $base.TrimEnd('\', '/')
            Get-ChildItem -LiteralPath $searchDir -Directory -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $rel = $_.FullName.Substring($baseTrimmed.Length).TrimStart('\', '/')
                    "$refName/$($rel -replace '\\', '/')"
                } |
                Where-Object { $_ -like "$cur*" } |
                ForEach-Object { & $mkResult $_ }
        } else {
            $names | Where-Object { $_ -like "$cur*" } | ForEach-Object { & $mkResult $_ }
        }
    }

    if ($prev -in '-d', '--del') {
        $names | Where-Object { $_ -like "$cur*" } |
                 ForEach-Object { & $mkResult $_ }
        return
    }
    if ($prev -in '-x', '--expand') { & $navComplete; return }
    if ($prev -in '-e', '--export', '-i', '--import') { return }
    if ($prev -in '-l', '--list', '-c', '--clear', '-v', '--version', '-h', '--help') { return }

    if ($cur -like '-*') {
        '-a', '--add', '-d', '--del', '-l', '--list', '-c', '--clear',
        '-x', '--expand', '-e', '--export', '-i', '--import',
        '-h', '--help', '-v', '--version' |
            Where-Object { $_ -like "$cur*" } |
            ForEach-Object { & $mkResult $_ }
        return
    }

    if ($curPos -eq 0) {
        & $navComplete
    } elseif ($subcmd -eq 'del' -and $curPos -eq 1) {
        $names | Where-Object { $_ -like "$cur*" } | ForEach-Object { & $mkResult $_ }
    } elseif ($subcmd -eq 'expand' -and $curPos -eq 1) {
        & $navComplete
    } elseif ($subcmd -in 'add', '-a', '--add' -and $curPos -ge 2) {
        $dirBase = if ($cur -eq '') {
                       '.'
                   } elseif ($cur -like '*\' -or $cur -like '*/') {
                       $cur
                   } else {
                       $p = Split-Path -Parent $cur
                       if ($p) { $p } else { '.' }
                   }
        Get-ChildItem -LiteralPath $dirBase -Directory -Force -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName } |
            Where-Object   { $_ -like "$cur*" } |
            ForEach-Object { & $mkResult $_ }
    }
}.GetNewClosure())
"#;
