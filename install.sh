#!/bin/bash

# >>>>> GLOBALS <<<<<
ACTION="INSTALL"
ORIGINAL_EX="pd.sh"
EXECUTABLE_SOURCE="pd-source.sh"
EXECUTABLE_DEST="pd.sh"
LOGFILE="pd.log"
BASHRC="$HOME/.bashrc"
PROFILE="$BASHRC"
TARGET_DIR="$HOME"
DATA_FILE=".pd-data"
FUNC_NAME="pd"

CH_TARGET_DIR=0
CH_DATA_FILE=0
CH_FUNC_NAME=0

declare -A INSTALLED_COMPS

### Characters ###
CHAR_SUCCESS="\xE2\x9C\x94"
CHAR_FAIL="\xE2\x9D\x8C"
# <<<<< END GLOBALS >>>>>>


function usage() {
    cat << EOF
Install Park Directories

usage: install [OPTIONS]

OPTIONS:
-h, --help      Display this help message and exit
-d, --dir       Set the directory where the data file and executable
                will be written (default: $HOME)
-p, --profile   Install the bootstrap code in the specified profile file
                Requires full path (e.g. ~/.bash_profile, ~/.bash_login)
                (default: ~/.bashrc)
-f, --file      Set the name of the file to be used to store the
                parked directory references (default: .pd-data)
--func          Set the command name (default: pd)
-u, --update    Perform an in-place update
EOF
}

function parse_logfile {
    # Extract all of the data from pd.log
    # Put it in a global dictionary called INSTALLED_COMPS
    if [[ -f pd.log ]]; then
        INSTALLED_COMPS["path_to_log_file"]="$(pwd)/pd.log"
        while IFS=' ' read -r key value; do
            INSTALLED_COMPS["$key"]="$value"
        done < pd.log
    else
        return 25
    fi
}

function bootstrap_in_profile {
    # Check for bootstrap code in profile file
    # local PROFILE=( "$HOME/.bash_profile" "$HOME/.bashrc" )
    local PROFILE=("$@")
    local id_str="## Park Directories ##"
    for PRF in "${PROFILE[@]}"; do
        if [[ -f "$PRF" ]]; then
            local profile_installed=$(grep -c "$id_str" "$PRF")
            if [[ $profile_installed -gt 0 ]]; then
                echo "$PRF"
                return 0
            fi
        fi
    done
    echo "NONE"
}

# >>>> TO DO <<<<
# 1) Convert this to use the INSTALLED_COMPS dictionary
# 2) Add each entry to INSTALLED_COMPS as it is completed in the installation process
# 3) Move creating of logfile to the end of the installation process
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

function ch_datafile_loc {
    # Change the location where the data file is stored
    # Write the output to a new file so that the original is not altered.
    if [[ $CH_TARGET_DIR -eq 1 || $CH_DATA_FILE -eq 1 ]]; then
        # Make a copy of the executable
        cp "$EXECUTABLE_SOURCE" tmp.sh || exit 30
        local SOURCE="tmp.sh"
        sed -e "0,/^pdFile=.*$/ s||pdFile=$TARGET_DIR/$DATA_FILE|" "$SOURCE" > "$EXECUTABLE_SOURCE"
        # Remove the tmp file
        rm tmp.sh
    fi
}

function ch_func_name {
    # Change the name of the function (default: pd), if necessary
    if [[ $CH_FUNC_NAME -eq 1 ]]; then
        # Make a copy of the executable
        cp "$EXECUTABLE_SOURCE" tmp.sh || exit 31
        local SOURCE="tmp.sh"
        sed -r -e "s|pd\(\) \{|$FUNC_NAME\(\) \{|" -e "s|(usage: )pd|\1$FUNC_NAME|" -e "s|(\s+)pd( -?[ad]? ?dev)|\1$FUNC_NAME\2|" "$SOURCE" > "$EXECUTABLE_SOURCE"
        # Remove the tmp file
        rm tmp.sh
    fi
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

function report_installation {
    # Report if installation is complete or not
    # and report where any pieces of an installation are.
    local INSTALL_CODE=$INSTALLED
    if [[ $INSTALL_CODE -eq $STANDARD_INSTALL_VALID ]]; then
        echo -e "\nInstallation complete and valid!"
    else
        echo -e "\nPartial installation detected."
    fi
    echo -e "\nPD elements are installed as follows."

    # Report on pd.log file
    if [[ $((INSTALL_CODE & 1)) -eq 1 ]]; then
        echo "[+] Installation log file (pd.log) in current directory"
    else
        echo "[-] Installation log file (pd.log) missing."
    fi
    (( INSTALL_CODE >> 1 ))
    # Report on executable location
    if [[ $((INSTALL_CODE & 1)) -eq 1 ]]; then
        echo "[+] pd.log in current directory"
    fi
    (( INSTALL_CODE >> 1 ))
    # Report on command name
    if [[ $((INSTALL_CODE & 1)) -eq 1 ]]; then
        echo "[+] pd.log in current directory"
    fi
    (( INSTALL_CODE >> 1 ))
    # Report on data file location
    if [[ $((INSTALL_CODE & 1)) -eq 1 ]]; then
        echo "[+] pd.log in current directory"
    fi
    (( INSTALL_CODE >> 1 ))
    # Report on bootstrap location
    if [[ $((INSTALL_CODE & 1)) -eq 1 ]]; then
        echo "[+] pd.log in current directory"
    fi
}

function is_installed {
    # First check if the standard installation is correct
    # 1) Check if the installation log file exists
    #    INSTALLED_COMPS_CODE += 1
    #    If it does, 
    #    2) Check that the executable is where the log file indicates.
    #       INSTALLED_COMPS_CODE += 2
    #    3) Check that the command stipiluated in the log is present in the environment
    #       INSTALLED_COMPS_CODE += 4
    #    4) Check that the data file is where the log file indicates.
    #       INSTALLED_COMPS_CODE += 8
    #    5) Check that the bootstrap code is in the profile file indicated.
    #       INSTALLED_COMPS_CODE += 16
    # If everything checks out, INSTALLED_COMPS_CODE = 31

    # >>>>  Use global associative array, instead of flag-based code <<<<
    # This will require Bash > 4
    # INSTALLED_COMPS:
    #   logfile = location
    #   exec = location
    #   func_name = name
    #   datafile = location
    #   profile = location

    # >>>> Put all of the installation interrogation logic into the same function so that
    # when it is done, all of the desired information is in one place and complete and so that
    # the logic doesn't have to be spread out.
    # Make INSTALL_VALID a global whose value is set in this function so that it can be referenced
    # elsewhere but not without first calling the function.  This allows the value to change
    # over time, if necessary, without the rest of the application having to change.
    COMP_LOG_FILE=1
    COMP_EXEC=2
    COMP_FUNC=4
    COMP_DATA_FILE=8
    COMP_BOOTSTRAP=16
    INSTALL_VALID=31

    echo -e "\nChecking for installed components..."
    # Use the installation log file to determine if the regular install is complete and valid
    INSTALLED_COMPS_CODE=0
    if parse_logfile; then
        # If the log file was parsed successfully, then we know it exists and is formatted as expected.
        echo -e "$CHAR_SUCCESS  Installation log file parsed @ ${INSTALLED_COMPS['path_to_log_file']}"
        (( INSTALLED_COMPS_CODE += COMP_LOG_FILE ))

        # 2) Check that the executable exists
        if [[ -f "${INSTALLED_COMPS['path_to_executable']}" ]]; then
            echo -e "$CHAR_SUCCESS  Executable @ ${INSTALLED_COMPS['path_to_executable']}"
            (( INSTALLED_COMPS_CODE += COMP_EXEC ))
        fi

        # 3) Check that the function exists in the environment
        if command -v "${INSTALLED_COMPS['func_name']}" > /dev/null; then
            echo -e "$CHAR_SUCCESS  Function active: ${INSTALLED_COMPS['func_name']}"
            (( INSTALLED_COMPS_CODE += COMP_FUNC ))
        fi

        # 4) Check that the data file exists
        if [[ -f "${INSTALLED_COMPS['path_to_data_file']}" ]]; then
            echo -e "$CHAR_SUCCESS  Data file @ ${INSTALLED_COMPS['path_to_data_file']}"
            (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
        fi

        # 5) Check that the bootstrap code is where it is supposed to be
        local VER_PROFILE="NONE"
        local VER_PROFILE=$(bootstrap_in_profile "${INSTALLED_COMPS["profile"]}")
        if [[ "$VER_PROFILE" != "NONE" ]]; then
            echo -e "$CHAR_SUCCESS  Bootstrap code in $VER_PROFILE"
            (( INSTALLED_COMPS_CODE += COMP_BOOTSTRAP ))
        fi
    else
        echo -e "$CHAR_FAIL  Log file not found in $(pwd)"
    fi

    if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
        echo -e "All components are installed as expected.\n"
        return 0
    elif [[ $INSTALLED_COMPS_CODE -eq 0 ]]; then
        echo -e "\nThe installation log file is missing."
    fi

    echo -e "Parked Directories is not installed correctly.\n"
    return 55
    # LOGFILE_MSG="[!] Installation log file (pd.log) exists from a previous install."
    # PROFILE_MSG=
    # EXEC_MSG="[!] Park Directories is at least partially installed: $HOME/pd.sh exists."
    # DATAFILE_MSG="[!] Park Directories is at least partially installed: $HOME/.pd-data exists."

    # INSTALLED=0

    

    # If the log file does not exist, check for the defaults
    # $HOME/pd.sh and $HOME/.pd-data
    # pd_exec_exists
    # datafile_exists
}

function fix_install {
    echo -e "Searching for installed components and reconstituting pd.log..."

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
    
    is_installed
    if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
        echo -e "Park Directories is already installed."
        echo -e "You can uninstall using the ./uninstall.sh script,"
        echo -e "or you may want to perform an in-place upgrade with ./install.sh -u.\n"
        exit 21
    fi

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
    ch_datafile_loc

    # Change the name of the function (default: pd), if necessary
    ch_func_name
    
    # Copy the executable to target directory
    cp "$EXECUTABLE_SOURCE" "$TARGET_DIR/$EXECUTABLE_DEST" || exit 40
    
    # Write the sourcing code to the specified profile script
    write_bootstrap

    echo -e "\nInstallation complete!"
    echo "Please execute the following command to use Park Directories:"
    echo -e "\tsource $PROFILE"
    
    ## Clean up
    cleanup
}

function update {
    # Perform an in-place update of Park Directories
    echo -e "Updating Park Directories..."

    is_installed

    if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
        echo -e "Continue with update."
    else
        echo -e "Park Directories is not installed correctly!"
        echo -e "Please fix the current installation before trying to upgrade.\n"
        exit 60
    fi
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
            TARGET_DIR="${2%/}"  # Remove a trailing / if there
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
        -u|--update)    # Perform an in-place update
            ACTION="UPDATE"
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

if [[ "$ACTION" == "UPDATE" ]]; then
    update
fi
