#!/bin/bash

pd() {
    local pdFile="$HOME/.pd-data"
    local PD_VERSION="1.7.0"

    if [[ $# -eq 0 ]]; then
        set -- "-h"
    fi

    if [[ ! -f "$pdFile" ]]; then
        touch "$pdFile" || return 60
        chmod 660 "$pdFile" || return 61
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

-h, --help                           Display this help message
-a, --add NAME [PATH]                Given just NAME, park the current directory with reference NAME
                                     Given NAME & PATH, park PATH with reference NAME
                                     Reference names may not start with - or contain /
-d, --del NAME                       Remove the directory referenced by NAME
-l, --list                           Display the entire list of parked directories
-c, --clear                          Clear the entire list of parked directories
-e, --export FILE_PATH               Export current list of parked directories to FILE_PATH
-i, --import                         Import park directories entries from FILE_PATH
    [--append | --quiet] FILE_PATH   Use -i --append FILE_PATH to add entries to the existing list
                                     Use -i --quiet FILE_PATH to overwrite current entries quietly
-v, --version                        Display version

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

Parked directories are stored in $pdFile
Park Directories version $PD_VERSION
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
                    if [[ $2 != *"/"* && "$2" != -* ]]; then
                        ref="$2"
                    else
                        echo "ERROR: Reference name may not contain '/' or begin with '-'"
                        return 11
                    fi

                    # If the second argument after the option identifier is not another option
                    # identifier, use it as the full path to the directory to park.
                    # Otherwise, use the current directory.
                    if [[ $# -gt 2 && "$3" != -* ]]; then
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
                if [[ $# -gt 1 && "$2" != -* ]]; then
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
                # If the list is empty, tell the user.
                if [[ $(wc -l "$pdFile" | cut -d' ' -f1) -eq 0 ]]; then
                    echo "    No directories have been parked yet"
                else
                    # List all parked directories
                    echo
                    cat "$pdFile" || return 30
                    echo
                fi
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
            -i|--import) # Import parked directories from file
                # Command overwrite mode: pd -i|--import PATH_TO_FILE
                # Command append mode: pd -i|--import --append PATH_TO_FILE
                local IMPORT_OVERWRITE=0   # Clear the current contents in the data file and import the new entries
                local IMPORT_OVERWRITE_QUIET=1   # Do not warn the user before overwriting (useful in scripts)
                local IMPORT_APPEND=2   # Append new entries to existing content
                local IMPORT_ACTION=$IMPORT_OVERWRITE   # Overwrite with warning by default

                # If the first argument is --append, set IMPORT_ACTION=IMPORT_APPEND and shift out an argument
                if [[ $# -gt 1 ]]; then
                    if [[ "$2" == "--append" ]]; then
                        IMPORT_ACTION=$IMPORT_APPEND  # Append entries to data file
                        shift 1
                    elif [[ "$2" == "--quiet" ]]; then
                        IMPORT_ACTION=$IMPORT_OVERWRITE_QUIET  # Overwrite without warning
                        : > "$pdFile" || return 73
                        echo "Contents of data file cleared"
                        shift 1
                    fi
                else
                    echo "ERROR: Import requires at least one argument"
                    return 71
                fi
                if [[ $# -gt 1 && "$2" != -* && -f "$2" ]]; then
                    # If the import is set to overwrite the data file, warn the user
                    # and ask if the data file should be backed up.
                    if [[ $IMPORT_ACTION -eq $IMPORT_OVERWRITE ]]; then
                        local CHOICE
                        echo "WARNING: Import will replace the current list of parked directories!"
                        echo "Please choose from the following options:"
                        echo "  (b)ackup current list and continue"
                        echo "  (c)ontinue without backing up"
                        echo "  (a)bort import"
                        while true; do
                            read -n1 -p "[b/c/a]: " CHOICE
                            echo
                            case $CHOICE in
                                b|B)  # Backup data file, clear the contents, and continue
                                    local DATA_BACKUP="$pdFile-$(date +%s).bck"
                                    cp "$pdFile" "$DATA_BACKUP" || return 72
                                    echo "Data file backed up to $DATA_BACKUP"
                                    : > "$pdFile" || return 73
                                    echo "Contents of data file cleared"
                                    break
                                    ;;
                                c|C)  # Clear the contents of the data file and continue
                                    : > "$pdFile" || return 73
                                    echo "Contents of data file cleared"
                                    break
                                    ;;
                                a|A)  # Return with exit code 74
                                    echo -e "Import aborted!"
                                    return 74
                                    ;;
                                *)
                                    echo -e "[!] Please answer [b/c/a]"
                                    ;;
                            esac
                        done
                    fi
                    # Parse the file and check each entry before adding them to the list of parked directories
                    # Ref names cannot contain / or start with -
                    # Directories must exist
                    while IFS=' ' read -r ref path; do
                        if [[ "$ref" != -* && "$ref" != *"/"* ]]; then
                            if [[ -d "$path" ]]; then
                                # Write the entry to the data file
                                echo "$ref $path" >> "$pdFile"
                            else
                                echo "ERROR: Directory must exist   $path"
                            fi
                        else
                            echo "ERROR: Reference name may not start with '-' or include '/'   $ref"
                        fi
                    done < "$2"
                else
                    echo "ERROR: Import requires a properly formatted file path"
                    return 70
                fi
                echo -e "Import complete\n"
                shift 2
                ;;
            -e|--export) # Export current list of parked directories to specified file
                # Treats next argument as a full qualified file path
                # The directory structure must exist, though the file does not.
                # Entries are appended to the target file, if it exists.
                # Command format: pd -e|--export PATH_TO_FILE
                if [[ $# -gt 1 && "$2" != -* ]]; then
                    if cat "$pdFile" >> "$2"; then
                        echo "List of parked directories exported to $2"
                    else
                        echo "ERROR: Failed to export list of parked directories"
                        return 60
                    fi
                else
                    echo "ERROR: Export requires a valid path to the target file."
                    return 61
                fi
                shift 2
                ;;
            -v|--version) # Display version
                echo -e "Park Directories version $PD_VERSION"
                shift 1
                ;;
            -*|--*) # Catch any unknown arguments
                echo "$1  ERROR: Unknown argument"
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
}

