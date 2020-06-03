#!/bin/bash

pdFile="$HOME/.pd-data"

pd() {
    case $1 in
        -h|--help)  # Show help
            cat << EOF
Park Directories
Park (bookmark) directories so that we can quickly navigate
to them from anywhere else using a short reference name.
The references persist across bash sessions.

usage: pd [OPTION] [REF]

-h, --help              Display this help message
-a, --add NAME [PATH]   Given just NAME, park the current directory with reference NAME
                        Given NAME & PATH, park PATH with reference NAME
-d, --del NAME          Remove the directory referenced by NAME
-l, --list              Display the entire list of parked directories
-c, --clear             Clear the entire list of parked directories

examples:
    pd dev              Navigate to directory saved with the ref name dev
    pd -a dev           Park the current directory with the ref name dev
    pd -a log /var/log  Park /var/log with ref name log
    pd -d dev           Remove the directory referenced by the name dev from
                        the parked directories list

Parked directories are stored in "$pdFile"
EOF
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
                ref="$2"

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
            ref="$2"
            # Remove the parked directory by name
            # Command format: pd -d|--del {unique name}
            DEL_TARGET=$(grep -P "^$ref .*$" "$pdFile")
            if [[ "$DEL_TARGET" == $ref* && ${#DEL_TARGET} -gt ${#ref} ]]; then
                sed -i "/^$ref .*$/d" "$pdFile"
                echo "Removed: ${DEL_TARGET/ / --> }"
            else
                echo "No parked directory with that name"
            fi
            ;;
        -l|--list)  # List all of the bookmarked directories
            # List all parked directories
            echo
            cat "$pdFile" || return 30
            echo
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
            ;;
        *)          # Positional argument
            ref="$1"
            # Change to the parked directory by name
            # Command format: pd {unique name}
            path=$(grep -P "^$ref .*$" "$pdFile" | cut -d' ' -f2)
            if [[ ${#path} -gt 0 ]]; then
                cd "$path" || return 50
            else
                echo "No parked directory with that name"
            fi
            ;;
    esac
}

if [[ ! -f "$pdFile" ]]; then
    touch "$pdFile" || return 60
    chmod 660 "$pdFile" || return 61
fi

