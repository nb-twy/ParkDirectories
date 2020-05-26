#!/bin/bash

# The log file needs to be written in the same directory as install.sh & uninstall.sh.
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
            echo -e "ERROR: Unsupported flag $1 \n" >&2
            usage
            exit 11
        ;;
        *)              # No positional paramenters supported
            echo -e "ERROR: No positional parameters defined.\n" >&2
            usage
            exit 12
        ;;
    esac
done

function logfile_exists {
    # Check if the installation log file exists
    if [[ $INSTALLED -eq 0 && -f "$LOGFILE" ]]; then
        echo "[!] Installation log file (pd.log) exists from a previous install."
        INSTALLED=1
    fi
}

function bootstrap_in_bashrc {
    # Check for default installation
    local id_str="$1"
    if [[ $INSTALLED -eq 0 && -f "$BASHPROFILE" ]]; then
        local profile_installed=$(grep -c "$id_str" "$BASHPROFILE")
        if [[ $profile_installed -gt 0 ]]; then
            echo "[!] Park Directories bootstrap script found in $BASHPROFILE."
            INSTALLED=1
        fi
    fi
}

function bootstrap_in_bashprofile {
    # Check .bash_profile for identifying line
    local id_str="$1"
    if [[ $INSTALLED -eq 0 && -f "$BASHRC" ]]; then
        local bash_installed=$(grep -c "$id_str" "$BASHRC")
        if [[ $bash_installed -gt 0 ]]; then
            echo "[!] Park Directories bootstrap script found in $BASHRC."
            INSTALLED=1
        fi
    fi
}

function pd_exec_exists {
    # Check for default installation of executable
    if [[ $INSTALLED -eq 0 && -f "$HOME/pd.sh" ]]; then
        echo "[!] Park Directories is at least partially installed: $HOME/pd.sh exists."
        INSTALLED=1
    fi
}

function datafile_exists {
    # Check for default installation of data file
    if [[ $INSTALLED -eq 0 && -f "$HOME/.pd-data" ]]; then
        echo "[!] Park Directories is at least partially installed: $HOME/.pd-data exists."
        INSTALLED=1
    fi
}

function create_logfile {
    # Create the log file
    cat << EOF >> "$LOGFILE" || exit 50
path_to_executable $TARGET_DIR/$EXECUTABLE_DEST
path_to_data_file $TARGET_DIR/$DATA_FILE
profile $PROFILE
func_name $FUNC_NAME
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

## Parked Directories ##
# Load script
PD="$TARGET_DIR/$EXECUTABLE_DEST"
EOF
    cat << 'EOF' >> "$PROFILE" || exit 42
if [ -f "$PD" ]; then
    . "$PD"
fi
## End ##
EOF
}

function cleanup {
    ## Clean up
    # Remove temporary executable source
    rm "$EXECUTABLE_SOURCE"
}

function is_installed {
    INSTALLED=0
    local id_str="## Parked Directories ##"

    # Check if the installation log file exists
    logfile_exists

    # Check .bashrc for identifying line
    bootstrap_in_bashrc "$id_str"
    
    # Check .bash_profile for identifying line
    bootstrap_in_bashprofile "$id_str"
    
    # If the log file does not exist, check for the defaults
    # $HOME/pd.sh and $HOME/.pd-data
    pd_exec_exists
    datafile_exists
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

if [[ "$ACTION" == "INSTALL" ]]; then
    # Check for previous installation
    # If already installed, encourage user to run uninstall.sh
    # before running, install.sh again.
    is_installed
    if [[ $INSTALLED -eq 0 ]]; then
        # If PD is not installed, install it.
        install
    else
        echo -e "\nIt looks like Park Directories is already installed."
        echo "Please run uninstall.sh to uninstall Park Directories before running install.sh again."
        exit 13
    fi
fi

if [[ "$ACTION" == "UPDATE" ]]; then
    echo "Update Park Directories..."
fi
