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

-h, --help      Display this help message
-a, --add NAME  Park a directory referenced by NAME
-d, --del NAME  Remove the directory referenced by NAME
-l, --list      Display the entire list of parked directories
-c, --clear     Clear the entire list of parked directories

examples:
    pd dev      Navigate to directory saved with the ref name dev
    pd -a dev   Park the current directory with the ref name dev
    pd -d dev   Remove the directory referenced by the name dev from
                the parked directories list

Parked directories are stored in "$pdFile"
EOF
            ;;
        -a|--add)   # Add a bookmarked directory
            ref="$2"
            # Park a directory by name
            # Command format: pd -a|--add {unique name}
            # Add it to $pdFile
            # Format {unique name} {full directory path}
            if [[ $(grep -Pc "^$ref .*$" "$pdFile") -gt 0 ]]; then
                echo "Name already used"
            else
                ADD_TARGET=$(pwd)
                echo "$ref" "$ADD_TARGET" >> "$pdFile" || exit 201
                echo "Added: $ref --> $ADD_TARGET"
            fi
            ;;
        -d|--del)   # Delete a bookmarked directory
            ref="$2"
            # Remove the parked directory by name
            # Command format: pd -d|--del {unique name}
            DEL_TARGET=$(grep -P "^$ref .*$" $pdFile)
            if [[ "$DEL_TARGET" == $ref* && ${#DEL_TARGET} -gt ${#ref} ]]; then
                sed -i "/^$ref .*$/d" "$pdFile" || exit 301
                echo "Removed: ${DEL_TARGET/ / --> }"
            else
                echo "No parked directory with that name"
            fi
            ;;
        -l|--list)  # List all of the bookmarked directories
            # List all parked directories
            cat "$pdFile"
            ;;
        -c|--clear) # Clear the entire list of bookmarked directories
            # Clear all parked director entries
            # Command format: pd -c|--clear
            if : > "$pdFile"; then
                echo "Removed all parked directories"
            else
                echo "Could not remove all parked directories"
            fi
            ;;
        *)          # Positional argument
            ref="$1"
            # Change to the parked directory by name
            # Command format: pd {unique name}
            path=$(grep -P "^$ref .*$" "$pdFile" | cut -d' ' -f2)
            if [[ ${#path} -gt 0 ]]; then
                cd "$path" || exit 101
            else
                echo "No parked directory with that name"
            fi
            ;;
    esac
}

if [[ ! -f "$pdFile" ]]; then
    touch "$pdFile"
    chmod 660 "$pdFile"
fi

