#!/bin/bash

# The log file needs to be written in the same directory as install.sh & uninstall.sh.
ORIGINAL_EX="pd.sh"
EXECUTABLE_SOURCE="pd-source.sh"
EXECUTABLE_DEST="pd.sh"
LOGFILE="pd.log"
BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"
PROFILE="$BASHPROFILE"
TARGET_DIR="$HOME"
DATA_FILE=".pd-data"
FUNC_NAME="pd"

CH_TARGET_DIR=0
CH_DATA_FILE=0
CH_FUNC_NAME=0

UNSET_FUNCS="usage"

function usage() {
    cat << EOF
Install Park Directories

usage: install [OPTIONS]

OPTIONS:
-h, --help      Display this help message and exit
--bashrc        Use .bashrc to load file (default: .bash_profile)
-d, --dir       Set the directory where the data file and executable
                will be written (default: $HOME)
-f, --file      Set the name of the file to be used to store the
                parked directory references (default: .pd-data)
--func          Set the command name (default: pd)
EOF
}

while (( "$#" )); do
    case "$1" in
        -h|--help)      # Display help and exit
            usage && exit 0
        ;;
        --bashrc)       # Use .bashrc to load file instead of .bash_profile
            PROFILE="$BASHRC"
            shift
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
        -*|--*=)   # unsupported flags
            echo -e "Error: Unsupported flag $1 \n" >&2
            usage
            exit 101
            ;;
        *)              # No positional paramenters supported
            echo -e "Error: No positional parameters defined.\n" >&2
            usage
            exit 102
            ;;
    esac
done

# Check for previous installation
# If already installed, encourage user to run uninstall.sh
# before running, install.sh again.

INSTALLED=0
id_str="## Parked Directories ##"

# Check if the installation log file exists
if [[ $INSTALLED -eq 0 && -f "$LOGFILE" ]]; then
    echo "[!] Installation log file (pd.log) exists from a previous install."
    INSTALLED=1
fi

# Check .bash_profile for identifying line
if [[ $INSTALLED -eq 0 && -f "$BASHRC" ]]; then
    bash_installed=$(grep -c "$id_str" "$BASHRC")
    if [[ $bash_installed -gt 0 ]]; then
        echo "[!] Park Directories bootstrap script found in $BASHRC."
        INSTALLED=1
    fi
fi

# Check .bashrc for identifying line
if [[ $INSTALLED -eq 0 && -f "$BASHPROFILE" ]]; then
    profile_installed=$(grep -c "$id_str" "$BASHPROFILE")
    if [[ $profile_installed -gt 0 ]]; then
        echo "[!] Park Directories bootstrap script found in $BASHPROFILE."
        INSTALLED=1
    fi
fi

# If the log file does not exist, check for the defaults
# $HOME/pd.sh and $HOME/.pd-data

if [[ $INSTALLED -eq 0 && -f "$HOME/pd.sh" ]]; then
    echo "[!] Park Directories is at least partially installed: $HOME/pd.sh exists."
    INSTALLED=1
fi

if [[ $INSTALLED -eq 0 && -f "$HOME/.pd-data" ]]; then
    echo "[!] Park Directories is at least partially installed: $HOME/.pd-data exists."
    INSTALLED=1
fi

# If we are confident that it is not installed,
# 1) Modify the executable, if necessary:
#   a) Update command name
#   b) Update data file path
# 2) Create the log file
# 3) Copy the executable to the target directory
# 4) Write the sourcing code into the specified profile script

if [[ $INSTALLED -eq 0 ]]; then
    echo "Installing Park Directories..."
    
    # Make a copy of the executable to protect the original
    cp "$ORIGINAL_EX" "$EXECUTABLE_SOURCE"

    if [[ $CH_TARGET_DIR -eq 1 ]]; then
        # Make sure the target directory exists
        if [[ ! -d "$TARGET_DIR" ]]; then
            mkdir -p "$TARGET_DIR" || exit 201
        fi
    fi
    
    # Create the log file
    cat << EOF >> "$LOGFILE"
path_to_executable "$TARGET_DIR/$EXECUTABLE_DEST"
path_to_data_file "$TARGET_DIR/$DATA_FILE"
profile "$PROFILE"
EOF
    # Change the location where the data file is stored
    # Write the output to a new file so that the original is not altered.
    if [[ $CH_TARGET_DIR -eq 1 || $CH_DATA_FILE -eq 1 ]]; then
        # Make a copy of the executable
        cp "$EXECUTABLE_SOURCE" tmp.sh || exit 301
        SOURCE="tmp.sh"
        sed -e "0,/^pdFile=.*$/ s||pdFile=$TARGET_DIR/$DATA_FILE|" "$SOURCE" > "$EXECUTABLE_SOURCE"
        # Remove the tmp file
        rm tmp.sh
    fi

    # Change the name of the function (default: pd), if necessary
    if [[ $CH_FUNC_NAME -eq 1 ]]; then
        # Make a copy of the executable
        cp "$EXECUTABLE_SOURCE" tmp.sh || exit 302
        SOURCE="tmp.sh"
        sed -r -e "s|pd\(\) \{|$FUNC_NAME\(\) \{|" -e "s|(usage: )pd|\1$FUNC_NAME|" -e "s|(\s+)pd( -?[ad]? ?dev)|\1$FUNC_NAME\2|" "$SOURCE" > "$EXECUTABLE_SOURCE"
        # Remove the tmp file
        rm tmp.sh
    fi
    
    # Copy the executable to target directory
    cp "$EXECUTABLE_SOURCE" "$TARGET_DIR/$EXECUTABLE_DEST" || exit 202
    # Write the sourcing code to the specified profile script
    cat << EOF >> "$PROFILE" || exit 203
## Parked Directories ##
# Load script
PD="$TARGET_DIR/$EXECUTABLE_DEST"
EOF
    cat << 'EOF' >> "$PROFILE" || exit 203
if [ -f "$PD" ]; then
    . "$PD"
fi
## End ##
EOF
    echo -e "\nInstallation complete!"
    echo "Please execute the following command to use Park Directories:"
    echo -e "\tsource $PROFILE"
else
    echo "It looks like Park Directories is already installed."
    echo "Please run uninstall.sh to uninstall Park Directories before running install.sh again."
    exit 103
fi

## Clean up
# Remove temporary executable source
rm "$EXECUTABLE_SOURCE"

# Remove all functions from the environment
eval "unset -f $UNSET_FUNCS"