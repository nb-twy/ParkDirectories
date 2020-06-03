#!/bin/bash

pdFile="$HOME/.pd-data"

pd() {
    if [[ $# -eq 0 ]]; then
        set -- "-h"
    fi
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)  # Show help
                cat << EOF
Park Directories
Park (bookmark) directories so that we can quickly navigate
to them from anywhere else using a short reference name.
The references persist across bash sessions.

usage: pd [REF] [OPTION {ARG} [OPTION {ARG} ...]]

-h, --help              Display this help message
-a, --add NAME [PATH]   Given just NAME, park the current directory with reference NAME
                        Given NAME & PATH, park PATH with reference NAME
                        Reference names may not contain /
-d, --del NAME          Remove the directory referenced by NAME
-l, --list              Display the entire list of parked directories
-c, --clear             Clear the entire list of parked directories

examples:
    pd dev              Navigate to directory saved with the ref name dev
    pd -a dev           Park the current directory with the ref name dev
    pd -a log /var/log  Park /var/log with ref name log
    pd -d dev           Remove the directory referenced by the name dev from
                        the parked directories list
    
    A single invocation can take multiple options, performing multiple operations at once:
        pd -l -d dev -a dev -d log -a log /var/log -l
    This command will
      1) List all parked directories
      2) Remove the entry referenced by "dev", if one exists
      3) Park the current directory with the reference name "dev"
      4) Remove the entry referenced by "log", if one exists
      5) Park the /var/log directory with the reference name "log"
      6) List all parked directories

Parked directories are stored in "$pdFile"
EOF
shift 1
                ;;
            -a|--add)   # Add a bookmarked directory
                # Park the current directory
                # Command format: pd -a|--add {unique name}
                # Park a directory by the full path
                # Command format: pd -a|--add {unique name} {full directory path}
                # Add it to $pdFile
                # Format {unique name} {full directory path}
                
                # 1) Option requires a single argument to park the current directory, or
                # 2) a pair of arguments to park a directory that is not the current directory.

                # Only continue if there is at least one argument after the option identifier
                if [[ $# -gt 1 ]]; then
                    # The first argument after the option identifier is the ref name
                    if [[ $2 != *"/"* ]]; then
                        ref="$2"
                    else
                        echo "ERROR: Reference name may not contain '/'"
                        return 11
                    fi

                    # If the second argument after the option identifier is not another option
                    # identifier, use it as the full path to the directory to park.
                    # Otherwise, use the current directory.
                    if [[ $# -gt 2 && $3 != -* ]]; then
                        ADD_TARGET="$3"
                        shift 3     # Shift out the option and both arguments
                    else
                        ADD_TARGET="$(pwd)"
                        shift 2     # Shift out the option and one argument
                    fi

                    if [[ $(grep -Pc "^$ref .*$" "$pdFile") -gt 0 ]]; then
                        echo "Name already used"
                    else
                        echo "$ref" "$ADD_TARGET" >> "$pdFile"
                        echo "Added: $ref --> $ADD_TARGET"
                    fi
                else
                    echo "ERROR: The add option takes one argument to park the current directory"
                    echo "       or two arguments to park a directory by its full path."
                    return 10
                fi
                ;;
            -d|--del)   # Delete a bookmarked directory
                if [[ $# -gt 1 && $2 != -* ]]; then
                    ref="$2"
                    # Remove the parked directory by name
                    # Command format: pd -d|--del {unique name}
                    DEL_TARGET=$(grep -P "^$ref .*$" "$pdFile")
                    if [[ "$DEL_TARGET" == $ref* && ${#DEL_TARGET} -gt ${#ref} ]]; then
                        sed -i "/^$ref .*$/d" "$pdFile"
                        echo "Removed: ${DEL_TARGET/ / --> }"
                    else
                        echo "$ref -- No parked directory with that name"
                    fi
                    shift 2
                else
                    echo "ERROR: The delete option requires one argument."
                    return 20
                fi
                ;;
            -l|--list)  # List all of the bookmarked directories
                # List all parked directories
                echo
                cat "$pdFile" || return 30
                echo
                shift 1
                ;;
            -c|--clear) # Clear the entire list of bookmarked directories
                # Clear all parked director entries
                # Command format: pd -c|--clear
                if : > "$pdFile"; then
                    echo "Removed all parked directories"
                else
                    echo "Could not remove all parked directories"
                    return 40
                fi
                shift 1
                ;;
            *)          # Positional argument
                ref="$1"
                # Change to the parked directory by name
                # Command format: pd {unique name}
                path=$(grep -P "^$ref .*$" "$pdFile" | cut -d' ' -f2)
                if [[ ${#path} -gt 0 ]]; then
                    cd "$path" || return 50
                else
                    echo "$ref -- No parked directory with that name"
                fi
                shift 1
                ;;
        esac
    done

    if [[ ! -f "$pdFile" ]]; then
        touch "$pdFile" || return 60
        chmod 660 "$pdFile" || return 61
    fi
}

