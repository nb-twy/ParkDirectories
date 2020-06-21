#!/bin/bash

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

# Get the directory where the executable is being run
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load common functions, globals, and defaults
source "$CWD/common.sh"

# >>>>> GLOBALS <<<<<
UPDATE=1    # Indicates that an in-place update will be performed
FUNC_NAME="${DEFAULTS["func_name"]}"
ORIGINAL_EX="${DEFAULTS['executable_name']}"

CH_FUNC_NAME=0
# <<<<< END GLOBALS >>>>>>

function usage() {
    cat << EOF

>>>> Update Park Directories <<<<
Perform an in-place update of Park Directories. If Park Directories
is not properly installed, the update will abort with information
about what needs to be fixed.  It is also possible to change the name
of the command with --func or --func-only.

usage: update.sh [OPTIONS]

OPTIONS:
-h, --help              Display this help message and exit
--func FUNC_NAME        Update to the latest version and change the name
                        of the command to FUNC_NAME (default: pd)
--func-only FUNC_NAME   Only change the name of the command to FUNC_NAME.
                        Does not execute any other update actions.                        

EOF
}

function cleanup {
    ## Clean up
    # Remove temporary executable source
    rm "$EXECUTABLE_SOURCE"
}

function update {
    if [[ UPDATE -eq 1 ]]; then
        # Perform an in-place update of Park Directories
        echo -e "Updating Park Directories...\n"
        echo -e "Checking for installed components..."
        is_installed

        # If Park Directories is installed properly, continue with the udpate.
        if [[ $INSTALLED_COMPS_CODE -eq $INSTALL_VALID ]]; then
            echo -e "Park Directories is installed properly."
            echo -e "Continuing with update..."

            # If old installation log file is still in use, remove it and write a new one in the new location.
            if [[ "${INSTALLED_COMPS['path_to_log_file']}" == "$OLD_LOGFILE" ]]; then
                mv "$OLD_LOGFILE" "$LOGFILE"
                echo -e "$CHAR_SUCCESS  Moved installation log file from $OLD_LOGFILE to $LOGFILE"
            fi

            TARGET_DIR="$(dirname ${INSTALLED_COMPS['path_to_data_file']})"
            DATA_FILE="$(basename ${INSTALLED_COMPS['path_to_data_file']})"
            
            # Make a copy of the executable to protect the original
            cp "$ORIGINAL_EX" "$EXECUTABLE_SOURCE"

            # If the data file is not installed in the default location,
            # Update the executable to use the custom location
            if [[ "${INSTALLED_COMPS['path_to_data_file']}" != \
                "${DEFAULTS['target_dir']}/${DEFAULTS['data_file']}" ]]; then
                ch_datafile_loc
            fi

            # If the function name of the active installation is not the default (pd), 
            # then update the executable to use the custom function name
            # Or if the user has chosen to update the name of the function during an in-place update,
            # use the function name provided by the user.
            if [[ $CH_FUNC_NAME -eq 1 || "${INSTALLED_COMPS['func_name']}" != "${DEFAULTS['func_name']}" ]]; then
                if [[ $CH_FUNC_NAME -eq 0 ]]; then
                    FUNC_NAME="${INSTALLED_COMPS['func_name']}"
                fi
                ch_func_name
                if [[ $CH_FUNC_NAME -eq 1 ]]; then
                    echo "Function name changed to $FUNC_NAME."
                fi
            fi

            # Copy the executable to the location of the executable recorded in the installation log file
            cp "$EXECUTABLE_SOURCE" "${INSTALLED_COMPS['path_to_executable']}" || exit 20
            echo -e "$CHAR_SUCCESS  Executable updated"

            ## Clean up
            cleanup
            echo -e "Update complete."
            echo "Please restart your terminal or run the following to get the latest features:"
            if [[ $CH_FUNC_NAME -eq 1 ]]; then
                echo "    unset -f ${INSTALLED_COMPS['func_name']}"
            fi
            echo "    source ${INSTALLED_COMPS['profile']}"
        # If Park Directories is only partially installed, report on the installed components and exit.
        elif [[ $INSTALLED_COMPS_CODE -gt $COMP_NONE && $INSTALLED_COMPS_CODE -lt $INSTALL_VALID ]]; then
            report_installed_comps
            echo -e "Cannot continue with update until Parked Directories is properly installed.\n"
            exit 21

        # If Park Directories is not installed, ask the user to install and exit.
        elif [[ $INSTALLED_COMPS_CODE -eq $COMP_NONE ]]; then
            echo -e "Park Directories is not yet installed."
            echo -e "Please run ./install.sh --help to review your installation options.\n"
            exit 22
        fi
    elif [[ $CH_FUNC_NAME -eq 1 ]]; then
        EXECUTABLE_SOURCE="${INSTALLED_COMPS['path_to_executable']}"
        ch_func_name
        echo "Function name changed to $FUNC_NAME."
        echo "Please restart your terminal or run the following:"
        echo "    unset -f ${INSTALLED_COMPS['func_name']}"
        echo "    source ${INSTALLED_COMPS['profile']}"
    fi
}


## Parse command line arguments
while (( "$#" )); do
    case "$1" in
        -h|--help)      # Display help and exit
            usage && exit 0
        ;;
        --func)         # Update & change the command name to FUNC_NAME
            FUNC_NAME="$2"
            CH_FUNC_NAME=1
            shift 2
        ;;
        --func-only)    # Only change the command name to FUNC_NAME
            FUNC_NAME="$2"
            CH_FUNC_NAME=1
            UPDATE=0
            shift 2
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

update