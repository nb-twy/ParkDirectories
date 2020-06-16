#!/bin/bash

# Load defaults
source defaults.sh

# >>>>> GLOBALS <<<<<
ACTION="INSTALL"
ORIGINAL_EX="${DEFAULTS['executable_name']}"
EXECUTABLE_SOURCE="pd-source.sh"
EXECUTABLE_DEST="${DEFAULTS['executable_name']}"
LOGFILE="${DEFAULTS['logfile']}"
OLD_LOGFILE="${DEFAULTS['old_logfile']}"
BASHRC="$HOME/.bashrc"
PROFILE="${DEFAULTS['profile']}"
TARGET_DIR="${DEFAULTS['target_dir']}"
DATA_FILE="${DEFAULTS['data_file']}"
DATA_FILE_INIT="${DEFAULTS['data_file_init']}"
FUNC_NAME="${DEFAULTS['func_name']}"

CH_TARGET_DIR=0
CH_DATA_FILE=0
CH_FUNC_NAME=0

declare -A INSTALLED_COMPS

### Characters ### 
CHAR_SUCCESS="\xE2\x9C\x94"
CHAR_FAIL="\xE2\x9D\x8C"
# <<<<< END GLOBALS >>>>>>

# TODO: Determine if loading the functions can happen before declaring the global variables
# Load common functions
source common.sh


function usage() {
    cat << EOF

>>>> Install Park Directories <<<<

usage: install [OPTIONS]

OPTIONS:
-h, --help              Display this help message and exit
-d, --dir DIR           Set the directory where the data file and executable
                        will be written. Use a fully-qualified path or $HOME
                        will be used as the root path. (default: $HOME)
-p, --profile PROFILE   Install the bootstrap code in the specified profile file
                        Requires full path (e.g. ~/.bash_profile, ~/.bash_login)
                        (default: ~/.bashrc)
-f, --file FILE         Set the name of the file to be used to store the
                        parked directory references (default: .pd-data)
--func FUNC_NAME        Set the command name (default: pd)
-i, --import FILE       Initialize the list of parked directories with those in FILE
-u, --update            Perform an in-place update
--verify                Look for the installation components of Park Directories
                        and report on the health of the installation.

EOF
}

# >>>> TO DO <<<<
# 1) Convert this to use the INSTALLED_COMPS dictionary
# 2) Add each entry to INSTALLED_COMPS as it is completed in the installation process
# 3) Move creating of logfile to the end of the installation process
# <<<< END TO DO >>>>
function create_logfile {
    # Create the log file
    cat << EOF >> "$LOGFILE" || exit 50
path_to_executable $TARGET_DIR/$EXECUTABLE_DEST
path_to_data_file $TARGET_DIR/$DATA_FILE
profile $PROFILE
func_name $FUNC_NAME
EOF
}

# >>>> TO DO <<<<
# This is the new implementation that uses the INSTALLED_COMPS global dictionary.
# Remove create_logfile function when it is no longer necessary.
# <<<< END TO DO >>>>
function write_logfile {
    # If the log file already exists in the working directory, back it up.
    if [[ -f "$LOGFILE" ]]; then
        mv "$LOGFILE" ${LOGFILE%log}"$(date +%s).log"
    fi
    # Create the log file
    cat << EOF > "$LOGFILE" || exit 50
path_to_executable ${INSTALLED_COMPS["path_to_executable"]}
path_to_data_file ${INSTALLED_COMPS["path_to_data_file"]}
profile ${INSTALLED_COMPS["profile"]}
func_name ${INSTALLED_COMPS["func_name"]}
EOF
}

function write_bootstrap {
    # Write the sourcing code to the specified profile script
    cat << EOF >> "$PROFILE" || exit 41

## Park Directories ##
# Load script
PD="$TARGET_DIR/$EXECUTABLE_DEST"
FUNC_NAME="$FUNC_NAME"
EOF
    cat << 'EOF' >> "$PROFILE" || exit 42
if [ -f "$PD" ]; then
    . "$PD"
    export -f "$FUNC_NAME"
fi
unset PD FUNC_NAME
## End Park Directories ##
EOF
}

function cleanup {
    ## Clean up
    # Remove temporary executable source
    rm "$EXECUTABLE_SOURCE"
}

function report_installed_comps {

    # Installation log file
    if [[ $(( INSTALLED_COMPS_CODE & COMP_LOG_FILE )) -eq $COMP_LOG_FILE ]]; then
        if [[ ${INSTALLED_COMPS['path_to_log_file']} == "$OLD_LOGFILE" ]]; then
            echo -e "$CHAR_FAIL  Old installation log file is stil in use @ ${INSTALLED_COMPS['path_to_log_file']}"
            echo -e "    Please run ./instlal.sh -u to use the new log file location."
        fi
        if [[ ${INSTALLED_COMPS['path_to_log_file']} == "$LOGFILE" ]]; then
            echo -e "$CHAR_SUCCESS  Installation log file located @ ${INSTALLED_COMPS['path_to_log_file']}"
        fi
        if [[ ${#INSTALLED_COMPS[@]} -eq 5 ]]; then
            echo -e "$CHAR_SUCCESS  Installation log file parsed."
        fi
    else
        echo -e "$CHAR_FAIL  Installation log file missing. Expected location: $LOGFILE"
    fi
    
    # Executable
    if [[ $(( INSTALLED_COMPS_CODE & COMP_EXEC )) -eq $COMP_EXEC ]]; then
        echo -e "$CHAR_SUCCESS  Executable @ ${INSTALLED_COMPS['path_to_executable']}"
    else
        echo -en "$CHAR_FAIL  Executable could not be located."
        if [[ ${#INSTALLED_COMPS[@]} -eq 5 ]]; then
            echo -e " Expected @ ${INSTALLED_COMPS['path_to_executable']}"
        else
            echo -e " Default: $HOME/pd.sh"
        fi
    fi

    # Function
    if [[ $(( INSTALLED_COMPS_CODE & COMP_FUNC )) -eq $COMP_FUNC ]]; then
        echo -e "$CHAR_SUCCESS  Function active: ${INSTALLED_COMPS['func_name']}"
    else
        echo -en "$CHAR_FAIL  Expected function not in user environment."
        if [[ ${#INSTALLED_COMPS[@]} -eq 5 ]]; then
            echo -e " Expected function name: ${INSTALLED_COMPS['func_name']}"
        else
            echo -e " Default function name: pd"
        fi
    fi

    # Data file
    if [[ $(( INSTALLED_COMPS_CODE & COMP_DATA_FILE )) -eq $COMP_DATA_FILE ]]; then
        echo -e "$CHAR_SUCCESS  Data file @ ${INSTALLED_COMPS['path_to_data_file']}"
    else
        echo -en "$CHAR_FAIL  Data file could not be located."
        if [[ ${#INSTALLED_COMPS[@]} -eq 5 ]]; then
            echo -e " Expected @ ${INSTALLED_COMPS['path_to_data_file']}"
        else
            echo -e " Default @ $HOME/.pd-data"
        fi
    fi

    # Bootstrap code
    if [[ $(( INSTALLED_COMPS_CODE & COMP_BOOTSTRAP )) -eq $COMP_BOOTSTRAP ]]; then
        echo -e "$CHAR_SUCCESS  Bootstrap code located in ${INSTALLED_COMPS['profile']}"
    else
        echo -en "$CHAR_FAIL  Could not locate bootstrap code in profile scripts."
        if [[ ${#INSTALLED_COMPS[@]} -eq 5 ]]; then
            echo -e " Expected in ${INSTALLED_COMPS['profile']}"
        else
            echo -e " Default: $HOME/.bashrc"
        fi
    fi

    # Final assessment
    if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
        echo -e "All components are installed as expected.\n"
    elif [[ $INSTALLED_COMPS_CODE -gt $COMP_NONE && $INSTALLED_COMPS_CODE -lt $INSTALL_VALID ]]; then
        echo -e "Park Directories is only partially installed."
        echo -e "Please review the list above and refer to the README for possible solutions.\n"
    elif [[ $INSTALLED_COMPS_CODE -eq $COMP_NONE ]]; then
        echo -e "No components of Park Directories could be found."
        echo -e "It looks like Park Directories is not installed.\n"
    fi
}

function fix_install {
    echo -e "Searching for installed components and reconstituting installation log file..."

    # Look for installed components using command line arguments and default values
    ## 1) Look for the executable
    if [[ -f "$TARGET_DIR/$EXECUTABLE_DEST" ]]; then
        echo -e "$CHAR_SUCCESS  Executable @ $TARGET_DIR/$EXECUTABLE_DEST"
        (( INSTALLED_COMPS_CODE += COMP_EXEC ))
        INSTALLED_COMPS["path_to_executable"]="$TARGET_DIR/$EXECUTABLE_DEST"
    elif [[ "$TARGET_DIR/$EXECUTABLE_DEST" != "$HOME/pd.sh" && -f "$HOME/pd.sh" ]]; then
        echo -e "$CHAR_SUCCESS  Executable @ $HOME/pd.sh"
        (( INSTALLED_COMPS_CODE += COMP_EXEC ))
        INSTALLED_COMPS["path_to_executable"]="$HOME/pd.sh"
    else
        echo -e "$CHAR_FAIL  Could not locate executable"
    fi

    ## 2) Look for the function in the environment
    if command -v "$FUNC_NAME" > /dev/null; then
        echo -e "$CHAR_SUCCESS  Function active: $FUNC_NAME"
        (( INSTALLED_COMPS_CODE += COMP_FUNC ))
        INSTALLED_COMPS["func_name"]="$FUNC_NAME"
    elif [[ "$FUNC_NAME" != "pd" ]] && command -v "pd" > /dev/null; then
        echo -e "$CHAR_SUCCESS  Function active: pd"
        (( INSTALLED_COMPS_CODE += COMP_FUNC ))
        INSTALLED_COMPS["func_name"]="pd"
    else
        echo -e "$CHAR_FAIL  Could not locate active function"
    fi

    ## 3) Look fo the data file
    if [[ -f "$TARGET_DIR/$DATA_FILE" ]]; then
        echo -e "$CHAR_SUCCESS  Data file @ $TARGET_DIR/$DATA_FILE"
        (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
        INSTALLED_COMPS["path_to_data_file"]="$TARGET_DIR/$DATA_FILE"
    elif [[ "$TARGET_DIR/$DATA_FILE" != "$HOME/.pd-data" && -f "$HOME/.pd-data" ]]; then
        echo -e "$CHAR_SUCCESS  Data file @ $HOME/.pd-data"
        (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
        INSTALLED_COMPS["path_to_data_file"]="$HOME/.pd-data"
    else
        echo -e "$CHAR_FAIL  Could not locate data file"
    fi

    ## 4) Look for the profile file with the bootstrap code
    local VER_PROFILE="NONE"
    local SEARCH_PROFILES=( "$HOME/.bashrc $HOME/.bash_profile $HOME/profile" )
    local VER_PROFILE=$(bootstrap_in_profile "${SEARCH_PROFILES[@]}")
    if [[ "$VER_PROFILE" != "NONE" ]]; then
        echo -e "$CHAR_SUCCESS  Bootstrap code in $VER_PROFILE"
        (( INSTALLED_COMPS_CODE += COMP_BOOTSTRAP ))
        INSTALLED_COMPS["profile"]="$VER_PROFILE"
    else
        echo -e "$CHAR_FAIL  Could not locate profile file with bootstrap code"
    fi
}

function install {
    # If we are confident that it is not installed,
    # 1) Modify the executable, if necessary:
    #   a) Update command name
    #   b) Update data file path
    # 2) Create the log file
    # 3) Copy the executable to the target directory
    # 4) Write the sourcing code into the specified profile script

    echo "Installing Park Directories..."
    
    echo -e "\nChecking for installed components..."
    is_installed
    if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
        echo -e "Park Directories is already fully installed."
        echo -e "You can uninstall using the ./uninstall.sh script,"
        echo -e "or you may want to perform an in-place upgrade with ./install.sh -u.\n"
        exit 21
    fi

    # If Park Directories is only partially installed, report the problem and exit.
    if [[ $INSTALLED_COMPS_CODE -gt $COMP_NONE && $INSTALLED_COMPS_CODE -lt $INSTALL_VALID ]]; then
        report_installed_comps
        echo -e "Installation cannot continue!\n"
        exit 22
    fi

    # Only continue with new installation if no components are found
    if [[ $INSTALLED_COMPS_CODE -eq $COMP_NONE ]]; then
        # Make a copy of the executable to protect the original
        cp "$ORIGINAL_EX" "$EXECUTABLE_SOURCE"

        if [[ $CH_TARGET_DIR -eq 1 ]]; then
            # Make sure the target directory exists
            if [[ ! -d "$TARGET_DIR" ]]; then
                mkdir -p "$TARGET_DIR" || exit 20
            fi
        fi
            
        # Create the log file
        create_logfile

        # Change the location where the data file is stored
        # Write the output to a new file so that the original is not altered.
        if [[ $CH_TARGET_DIR -eq 1 || $CH_DATA_FILE -eq 1 ]]; then
            ch_datafile_loc
        fi

        # Change the name of the function (default: pd), if necessary
        if [[ $CH_FUNC_NAME -eq 1 ]]; then
            ch_func_name
        fi

        # Copy the executable to target directory
        cp "$EXECUTABLE_SOURCE" "$TARGET_DIR/$EXECUTABLE_DEST" || exit 40
        
        # Write the sourcing code to the specified profile script
        write_bootstrap

        # Initialize data file
        cp "$DATA_FILE_INIT" "$TARGET_DIR/$DATA_FILE" 
        echo "Initiatlized data file with $DATA_FILE_INIT"

        # Clean up
        cleanup
        
        echo -e "\nInstallation complete!"
        echo "Please execute the following command to use Park Directories:"
        echo -e "\tsource $PROFILE"
    fi
}

function update {
    # Perform an in-place update of Park Directories
    echo -e "Updating Park Directories...\n"
    echo -e "Checking for installed components..."
    is_installed

    # If Park Directories is installed properly, continue with the udpate.
    if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
        echo -e "Park Directories seems to be installed properly."
        echo -e "Continuing with update..."

        # If old installation log file is still in use, remove it and write a new one in the new location.
        if [[ ${INSTALLED_COMPS['path_to_log_file']} == "$OLD_LOGFILE" ]]; then
            mv "$OLD_LOGFILE" "$LOGFILE"
            echo -e "$CHAR_SUCCESS  Moved installation log file from $OLD_LOGFILE to $LOGFILE"
        fi

        # Make a copy of the executable to protect the original
        cp "$ORIGINAL_EX" "$EXECUTABLE_SOURCE"
        # Copy the executable to the location of the executable recorded in the installation log file
        cp "$EXECUTABLE_SOURCE" "${INSTALLED_COMPS['path_to_executable']}" || exit 40
        echo -e "$CHAR_SUCCESS  Executable updated"

        ## Clean up
        cleanup
        echo -e "Update complete."
        echo -e "Please run source ${INSTALLED_COMPS['profile']} or restart your terminal to get the latest features.\n"

    # If Park Directories is only partially installed, report on the installed components and exit.
    elif [[ $INSTALLED_COMPS_CODE -gt $COMP_NONE && $INSTALLED_COMPS_CODE -lt $INSTALL_VALID ]]; then
        report_installed_comps
        echo -e "Cannot continue with update until Parked Directories is properly installed.\n"
        exit 60

    # If Park Directories is not installed, ask the user to install and exit.
    elif [[ $INSTALLED_COMPS_CODE -eq $COMP_NONE ]]; then
        echo -e "Park Directories is not yet installed."
        echo -e "Please run ./install.sh --help to review your installation options.\n"
        exit 61
    fi
}

function verify {
    # Check installation and report findings without attempting any changes
    echo -e "Checking for installed components of Park Directories..."

    is_installed

    report_installed_comps
}

## Parse command line arguments
while (( "$#" )); do
    case "$1" in
        -h|--help)      # Display help and exit
            usage && exit 0
        ;;
        -p|--profile)       # Install the bootstrap code in the user-specified file
            PROFILE="$2"
            # Make sure the profile file exists.  If it doesn't raise error and exit.
            if [[ ! -f "$PROFILE" ]]; then
                echo "ERROR: The specified profile file does not exist."
                exit 10
            fi
            shift 2
        ;;
        -d|--dir)       # Set the directory where the data file and executable will be written
            TARGET_DIR="${2%/}"  # Remove a trailing / if present
            if [[ "$1" != /* ]]; then
                TARGET_DIR="$HOME/$TARGET_DIR"
            fi
            CH_TARGET_DIR=1
            shift 2
        ;;
        -f|--file)      # Set the name of the file to be used to store the parked directory references
            DATA_FILE="$2"
            CH_DATA_FILE=1
            shift 2
        ;;
        --func)         # Set the command name
            FUNC_NAME="$2"
            CH_FUNC_NAME=1
            shift 2
        ;;
        -i|--import)    # Initialize data file with contents of specified file
            if [[ -f "$2" ]]; then
                DATA_FILE_INIT="$2"
            else
                echo -e "ERROR: Data file to import does not exist."
                exit 13
            fi
            shift 2
        ;;
        -u|--update)    # Perform an in-place update
            ACTION="UPDATE"
            shift 1
        ;;
        --verify)   # verify installation
            ACTION="VERIFY"
            shift 1
        ;;
        -*|--*=)   # unsupported flags
            echo -e "ERROR: Unsupported flag $1 " >&2
            usage
            exit 11
        ;;
        *)              # No positional paramenters supported
            echo -e "ERROR: No positional parameters defined." >&2
            usage
            exit 12
        ;;
    esac
done

# Install or Update
if [[ "$ACTION" == "INSTALL" ]]; then
    install
fi

if [[ "$ACTION" == "VERIFY" ]]; then
    verify
fi

if [[ "$ACTION" == "UPDATE" ]]; then
    update
fi
