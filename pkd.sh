#!/bin/bash

pkdFile="$HOME/.savedDirs"

pd() {
    # Display help if -h passed as first argument
    if [[ "$1" == "-h" ]]; then
        cat << EOF
Parking Directories
pd -h       Display this help message
pd NAME     Park a directory referenced by NAME
pdc NAME    Change to the directory referenced by NAME
pdr NAME    Remove the parked directory referenced by NAME
pdx         Remove all parked directories
pdl         List all parked directories

Parked directories are stored in "$pkdFile"
EOF
    else
        # Park a directory by name
        # Command format: pkd {unique name}
        # Add it to $HOME/.savedDirs
        # Format {unique name} {full directory path}
        if [[ $(grep -Pc "^$1 .*$" "$pkdFile") -gt 0 ]]; then
            echo "Name already used"
        else
            echo "$1" "$(pwd)" >> "$pkdFile"
        fi
    fi
}

pdc() {
    # Change to the parked directory by name
    # Command format: cpd {unique name}
    path=$(grep -P "^$1 .*$" "$pkdFile" | cut -d' ' -f2)
    if [[ ${#path} -gt 0 ]]; then
        cd "$path" || exit
    else
        echo "No parked directory with that name"
    fi
}

pdr() {
    # Remove the parked directory by name
    # Command format: rmpd {unique name}
    if [[ $(grep -Pc "^$1 .*$" "$pkdFile") -gt 0 ]]; then
        sed -i "/^$1 .*$/d" "$pkdFile"
    else
        echo "No parked directory with that name"
    fi

}

pdx() {
    # Clear all parked director entries
    # Command format: pdx
    if : > "$pkdFile"; then
        echo "Removed all parked directories"
    else
        echo "Could not remove all parked directories"
    fi
}
    
pdl() {
    # List all parked directories
    cat "$pkdFile"
}


if [[ ! -f "$pkdFile" ]]; then
    touch "$pkdFile"
    chmod 660 "$pkdFile"
fi

