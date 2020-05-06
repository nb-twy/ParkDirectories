#!/bin/bash

# The log file needs to be written in the same directory as install.sh & uninstall.sh.
LOGFILE="pd.log"
BASHRC="$HOME/.bashrc"
BASHPROFILE="$HOME/.bash_profile"
PROFILE="$BASHPROFILE"
TARGET_DIR="$HOME"
PARKED_FILENAME=".pd-data"
FUNC_NAME="pd"

UNSET_FUNCS="usage"

function usage() {
    cat << EOF
Install Park Directories

usage: install [OPTIONS]

OPTIONS:
-h, --help      Display this help message and exit
--bashrc        Use .bashrc to load file (default: .bash_profile)
-d, --dir       Set the directory where the log file, data file,
                and executable will be written (default: $HOME)
-f, --file      Set the name of the file to be used to store the
                parked directory references (default: .pd-data)
--func          Set the command name (default: pd)
EOF
}

if [[ $# -gt 0 ]]; then
    case $1 in
        -h|--help)      # Display help and exit
            usage
        ;;
        --bashrc)       # Use .bashrc to load file instead of .bash_profile
            PROFILE="$BASHRC"
        ;;
        -d|--dir)       # Set the directory where the data file and executable will be written
            TARGET_DIR="$2"
            shift
        ;;
        -f|--file)      # Set the name of the file to be used to store the parked directory references
            PARKED_FILENAME="$2"
            shift
        ;;
        --func)         # Set the command name
            FUNC_NAME="$2"
            shift
        ;;
        *)              # Catch everything else
            echo "UNDEFINED - Not a defined option!"
    esac
fi


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

# If the log file does not exist, check for
# $HOME/pd.sh and $HOME/.pd-data

if [[ $INSTALLED -eq 0 && -f "$HOME/pd.sh" ]]; then
    echo "[!] Park Directories is at least partially installed: $HOME/pd.sh exists."
    INSTALLED=1
fi

if [[ $INSTALLED -eq 0 && -f "$HOME/.pd-data" ]]; then
    echo "[!] Park Directories is at least partially installed: $HOME/.pd-data exists."
    INSTALLED=1
fi

if [[ $INSTALLED -eq 0 ]]; then
    echo "Installing Park Directories..."
else
    echo "It looks like Park Directories is already installed."
    echo "Please run uninstall.sh to uninstall Park Directories before running install.sh again."
fi
# If we are confident that it is not installed,
# 1) Modify pd.sh, if necessary:
#   a) Update command name
#   b) Update data file path
# 1) Create the log file
# 2) Copy pd.sh to the target directory
# 3) Write the sourcing code into the specified profile script

# Remove all functions from the environment
eval "unset -f $UNSET_FUNCS"