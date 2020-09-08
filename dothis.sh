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

_dothis_complete2() {
    # Alias the current word on the command line since we're going to be using it a lot
    CWORD="${COMP_WORDS[$COMP_CWORD]}"
    if [[ ${#COMP_WORDS[@]} -gt 1 && \
        ! -z "$CWORD" && \
        "$CWORD" != -* && \
        "$CWORD" == */* ]]; then
        # Do not add a space after inserting a match
        compopt -o nospace
        # Expand the parked name
        ## Split the argument at the last /
        ## Use the second token, if there is one, to match any directories
        local TARGET_REF="${CWORD%/*}"
        local PREFIX="${CWORD##*/}"
        #echo -e "\n[.] TARGET_REF: $TARGET_REF -- PREFIX: $PREFIX" 1>&2
        ## Use PD to expand the first token to the target directory
        local TARGET_DIR="$(pd -x "$TARGET_REF")"
        #echo -e "\n[.] TARGET_DIR: $TARGET_DIR" 1>&2
        # Find directories in TARGET_DIR
        local DIRS=($(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -iname "$PREFIX*"))
        local NUM_DIRS=${#DIRS[@]}
        # If there is only one match found, construct the suggestion from the original
        # TARGET_REF followed by the found directory.
        if [[ $NUM_DIRS -eq 1 ]]; then
            COMPREPLY=("$TARGET_REF/""${DIRS[0]##*/}/")
        else
            for i in $(seq 0 $((NUM_DIRS - 1))); do
                COMPREPLY+=("${DIRS[$i]##*/}")
            done
        fi
    fi

}

complete -F _dothis_complete2 dothis

