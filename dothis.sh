dothis() {
    echo "You want me to do $1."
}

_dothis_complete() {
    sugs=("hello" "world" "we" "love" "you" "yellow" "lilac" "harrow")
    num_sugs=${#sugs[@]}
    for i in $(seq 0 $((num_sugs - 1))); do
        if [[ ${#COMP_WORDS[@]} -gt 1 && -n "${COMP_WORDS[$COMP_CWORD]}" ]]; then
            if [[ "${sugs[$i]}" == "${COMP_WORDS[$COMP_CWORD]}"* ]]; then
                COMPREPLY+=("${sugs[$i]}")
            fi
        else
            COMPREPLY+=(${sugs[$i]})
        fi
    done
}

complete -F _dothis_complete dothis

