#!/bin/bash

# Get the directory where the executable is being run
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load common functions, globals, and defaults
source "$CWD/common.sh"

# >>>>> GLOBALS <<<<<
ACTION="INSTALL"
ORIGINAL_EX="${DEFAULTS['executable_name']}"
BASHRC="$HOME/.bashrc"
PROFILE="${DEFAULTS['profile']}"
DATA_FILE_INIT="${DEFAULTS['data_file_init']}"

CH_TARGET_DIR=0
CH_DATA_FILE=0
CH_FUNC_NAME=0

# <<<<< END GLOBALS >>>>>>


function usage() {
    cat << EOF

>>>> Install Park Directories <<<<

usage: install.sh [OPTIONS]

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

# Install
if [[ "$ACTION" == "INSTALL" ]]; then
    install
fi

if [[ "$ACTION" == "VERIFY" ]]; then
    verify
fi
