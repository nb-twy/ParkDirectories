###################################################################################
# BSD 3-Clause License

# Copyright (c) 2020, Kurt J. Schoener
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###################################################################################

pd() {
    local pdFile="$HOME/.pd-data"
    local PD_VERSION="2.1.0"

    # Resolve the directory from the ref name
    # Expected input: REF
    # Sets PARKED_DIR
    local PARKED_DIR=""
    resolve_dir() {
        local REF="${1%%/*}"
        local RELPATH="${1##$REF}"    # If there is a relative path, it will begin with /
        PARKED_DIR="$(grep -P "^$REF .*$" "$pdFile" | cut -d' ' -f2-)"
        if [[ ${#PARKED_DIR} -gt 0 ]]; then
            if [[ -n "$RELPATH" ]]; then
                PARKED_DIR="${PARKED_DIR%/}$RELPATH"
            fi
        else
            echo "$REF -- No parked directory with that name"
        fi
    }
    
    if [[ $# -eq 0 ]]; then
        set -- "-h"
    fi

    if [[ ! -f "$pdFile" ]]; then
        touch "$pdFile" || return 10
        chmod 660 "$pdFile" || return 11
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)  # Show help
                cat << EOF
Park Directories
Park (bookmark) directories so that we can quickly navigate
to them from anywhere else using a short reference name.
The references persist across bash sessions.

usage: pd [REF[/RELPATH]] [OPTION {ARG} [OPTION {ARG} ...]]

-h, --help                           Display this help message
-a, --add NAME[ PATH]                Given just NAME, park the current directory with reference NAME
                                     Given NAME & PATH, park PATH with reference NAME
                                     Reference names may not start with - or contain /
-d, --del NAME                       Remove the directory referenced by NAME
-l, --list                           Display the entire list of parked directories
-c, --clear                          Clear the entire list of parked directories
-x, --expand NAME[/RELPATH]          Expand the referenced directory and relative path without
                                     navigating to it
-e, --export FILE_PATH               Export current list of parked directories to FILE_PATH
-i, --import                         Import parked directories entries from FILE_PATH
    [--append | --quiet] FILE_PATH   Use -i --append FILE_PATH to add entries to the existing list
                                     Use -i --quiet FILE_PATH to overwrite current entries quietly
-v, --version                        Display version

Examples:
    pd dev              Navigate to directory saved with the ref name dev
    pd dev/proj         Navigate to the proj subdirectory of the directory 
                        referenced by ref name dev
    pd -a dev           Park the current directory with the ref name dev
    pd -a log /var/log  Park /var/log with ref name log
    pd -d dev           Remove the directory referenced by the name dev from
                        the parked directories list
    
    Move the contents of the directory referenced by dev1 to the archive
    subdirectory of the directory referenced by repos:
        mv -v \$(pd -x dev1) \$(pd -x repos/archive/)
    
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
                        echo "[ERROR] Reference name may not contain '/' or begin with '-'"
                        return 20
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
                        echo "$ref" "$ADD_TARGET" >> "$pdFile" || return 21
                        echo "Added: $ref --> $ADD_TARGET"
                    fi
                else
                    echo "[ERROR] The add option takes one argument to park the current directory"
                    echo "       or two arguments to park a directory by its full path."
                    return 22
                fi
                ;;
            -d|--del)   # Delete a bookmarked directory
                if [[ $# -gt 1 && "$2" != -* ]]; then
                    ref="$2"
                    # Remove the parked directory by name
                    # Command format: pd -d|--del {unique name}
                    DEL_TARGET=$(grep -P "^$ref .*$" "$pdFile")
                    if [[ "$DEL_TARGET" == $ref* && ${#DEL_TARGET} -gt ${#ref} ]]; then
                        sed -i "/^$ref .*$/d" "$pdFile" || return 30
                        echo "Removed: ${DEL_TARGET/ / --> }"
                    else
                        echo "$ref -- No parked directory with that name"
                    fi
                    shift 2
                else
                    echo "[ERROR] The delete option requires one argument."
                    return 31
                fi
                ;;
            -l|--list)  # List all of the bookmarked directories
                # If the list is empty, tell the user.
                if [[ $(wc -l "$pdFile" | cut -d' ' -f1) -eq 0 ]]; then
                    echo "    No directories have been parked yet"
                else
                    # List all parked directories
                    echo
                    cat "$pdFile" || return 40
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
                    return 50
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
                        : > "$pdFile" || return 60
                        echo "Contents of data file cleared"
                        shift 1
                    fi
                else
                    echo "[ERROR] Import requires at least one argument"
                    return 61
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
                                    cp "$pdFile" "$DATA_BACKUP" || return 62
                                    echo "Data file backed up to $DATA_BACKUP"
                                    : > "$pdFile" || return 63
                                    echo "Contents of data file cleared"
                                    break
                                    ;;
                                c|C)  # Clear the contents of the data file and continue
                                    : > "$pdFile" || return 63 
                                    echo "Contents of data file cleared"
                                    break
                                    ;;
                                a|A)  # Abort import
                                    echo -e "Import aborted!"
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
                    # If one of the entries in the import file is incorrectly formatted or if the
                    # directory does not exist, display an error but do not stop processing the file.
                    # We would rather gracefully fail on one or more and properly import those that can
                    # be. 
                    # TO DO: Check for duplicate entries so that importing cannot create duplicate
                    # entries.
                    while IFS=' ' read -r ref path; do
                        if [[ "$ref" != -* && "$ref" != *"/"* ]]; then
                            if [[ -d "$path" ]]; then
                                # Write the entry to the data file
                                # Abort if the data file cannot be modified.
                                echo "$ref $path" >> "$pdFile" || return 64
                            else
                                echo "[ERROR] Directory must exist   $path"
                            fi
                        else
                            echo "[ERROR] Reference name may not start with '-' or include '/'   $ref"
                        fi
                    done < "$2"
                else
                    echo "[ERROR] Import requires a properly formatted file path"
                    return 65
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
                        echo "[ERROR] Failed to export list of parked directories"
                        return 70
                    fi
                else
                    echo "[ERROR] Export requires a valid path to the target file."
                    return 71
                fi
                shift 2
                ;;
            -v|--version) # Display version
                echo -e "Park Directories version $PD_VERSION"
                shift 1
                ;;
            -x|--expand)  # Expand named directory
                # Command format: pd -x|--expand {unique name}[/{relative path}]
                resolve_dir "$2"
                if [[ -n "$PARKED_DIR" ]]; then
                    echo "$PARKED_DIR"
                fi
                shift 2
                ;;
            --*|-*) # Catch any unknown arguments
                echo "$1  [ERROR] Unknown argument"
                shift 1
                ;;
            *)  # Navigate to parked directory
                resolve_dir "$1"
                if [[ -n "$PARKED_DIR" ]]; then
                    cd "$PARKED_DIR" || return 80
                fi
                shift 1
                ;;
        esac
    done

    unset -f resolve_dir
}

_pd_complete() {
# Alias the current word on the command line since we're going to be using it a lot
CWORD="${COMP_WORDS[$COMP_CWORD]}"
# Alias the previous word on the command line
PWORD="${COMP_WORDS[$COMP_CWORD - 1]}"

# If the previous word is an option (begins with a -), then perform autocomplete only
# for delete, expand, and import.  Otherwise, simply return.
## Perform ref name completion with delete and expand
# Autocomplete relative path
## Need more than one command line argument, it cannot be empty, it cannot begin with
## a - and must include a /.
if [[ ${#COMP_WORDS[@]} -gt 1 && \
    ! -z "$CWORD" && \
    "$CWORD" != -* && \
    "$CWORD" == */* && \
    "$PWORD" != -* && \
    "${COMP_WORDS[$COMP_CWORD -2]}" != *"-a"* ]]; then
    # Do not add a space after inserting a match
    compopt -o nospace -o filenames
    # Expand the parked name
    ## Split the argument at the last /
    ## Use the second token, if there is one, to match any directories
    local TARGET_REF="${CWORD%/*}"
    #echo -e "\nTARGET_REF: $TARGET_REF"
    local PREFIX="${CWORD##*/}"
    #echo -e "\nPREFIX: $PREFIX"
    ## Use PD to expand the first token to the target directory
    local STD_IFS=$' \t\n'
    local IFS=$'\n'
    local TARGET_DIR="$(pd -x "$TARGET_REF")"
    #echo -e "\nTARGET_DIR: $TARGET_DIR"
    # If the target directory could not be resolved, print message on a new line
    if [[ "$TARGET_DIR" == *"No parked directory"* ]]; then
        echo -e "\n$TARGET_DIR"
        return
    fi
    # Find directories in TARGET_DIR
    #echo -e "\nTARGET_DIR to search: $TARGET_DIR"
    local DIRS=($(find "${TARGET_DIR//\\/}" -mindepth 1 -maxdepth 1 -type d -iname "$PREFIX*"))
    #echo -e "\nDIRS: ${DIRS[@]}"
    IFS=$STD_IFS
    local NUM_DIRS=${#DIRS[@]}
    #echo -e "\nNUM_DIRS: $NUM_DIRS"
    # If there is only one match found, construct the suggestion from the original
    # TARGET_REF followed by the found directory.
    #echo -e "\nTARGET_REF: $TARGET_REF"
    if [[ $NUM_DIRS -eq 1 ]]; then
        COMPREPLY=("${TARGET_REF//\\/}/""${DIRS[0]##*/}/")
    else
        for i in $(seq 0 $((NUM_DIRS - 1))); do
            COMPREPLY+=("${TARGET_REF//\\/}/""${DIRS[$i]##*/}")
        done
    fi

# Use standard filedir completion from bash_completion script following -i|--import
elif [[ "$PWORD" == "-i" || "$PWORD" == "--import" ]]; then
    compopt -o filenames
    COMPREPLY=($(compgen -f -- "$CWORD"))

elif [[ $COMP_CWORD -gt 2 && "${COMP_WORDS[$COMP_CWORD -2]}" == *"-a"* && "$CWORD" == "~"* ]] || \
     [[ $COMP_CWORD -gt 2 && "${COMP_WORDS[$COMP_CWORD -2]}" == *"-a"* && "$CWORD" == *"/"* ]]; then
    compopt -o filenames
    COMPREPLY=($(compgen -d -- "$CWORD"))
 
# Autocomplete ref names
elif [[ "$CWORD" != -* ]]; then
    local REF_NAME_COMPOPTS=("-d" "--del" "-x" "--expand")
    local REF_NAME_COMPLETE=0
    if [[ "$PWORD" == "${COMP_WORDS[0]}" ]]; then
        REF_NAME_COMPLETE=1
    elif [[ "$PWORD" == -* ]]; then
        for opt in "${REF_NAME_COMPOPTS[@]}"; do
            if [[ "$PWORD" == "$opt" ]]; then
                REF_NAME_COMPLETE=1
            fi
        done
    fi

    if [[ $REF_NAME_COMPLETE -eq 1 ]]; then
        # Do not add a space after inserting a match
        compopt -o nospace
        local REFS=()
        while IFS=' ' read -r ref target; do
            if [[ -n "$ref" ]]; then
                # If the current word is empty, select all refs.
                if [[ -z "$CWORD" ]]; then
                    REFS+=("$ref")
                else
                    # If the current word is not empty, only select refs
                    # that begin with current word.
                    if [[ "$ref" == "$CWORD"* ]]; then
                        REFS+=("$ref")
                    fi
                fi
            fi
        done < <(pd -l)
        # If there is only one match, add it with a trailing / so that autocomplete
        # can continue for relative paths.
        if [[ ${#REFS[@]} -eq 1 ]]; then
            COMPREPLY=("${REFS[0]}/")
        else
            COMPREPLY+=("${REFS[@]}")
        fi
    fi

# Option Completion
## Begin with long option completion
elif [[ "$CWORD" == --* ]]; then
    local OPTIONS="--add --del --list --clear --expand --export --import --version --help"
    local IFS=$' \t\n'
    COMPREPLY+=($(compgen -W "$OPTIONS" -- "$CWORD"))
elif [[ "$CWORD" == -* ]]; then
    local OPTIONS="-a -d -l -c -x -e -i -v -h"
    local IFS=$' \t\n'
    COMPREPLY=($(compgen -W "$OPTIONS" -- "$CWORD"))
fi

}

complete -F _pd_complete pd
