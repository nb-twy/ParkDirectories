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

UNINSTALL=0

# Check if log file exists
# If so, extract configured data.
# If not, ask if we should attempt to uninstall default configuration.
## TODO: Use parse_log_file from common.sh
if [[ -f "$LOGFILE" ]]; then
    # Extract configurations from log file
    EXEC=$(grep "path_to_executable" "$LOGFILE" | cut -d' ' -f2)
    DATA=$(grep "path_to_data_file" "$LOGFILE" | cut -d' ' -f2)
    PROFILE=( $(grep "profile" "$LOGFILE" | cut -d' ' -f2) )
    FUNC_NAME=$(grep "func_name" "$LOGFILE" | cut -d' ' -f2)
    UNINSTALL=1
else
    echo -e "\nThe installation log file is missing."
    while true; do
        read -n1 -p "Attempt to uninstall using defaults? (y/n) " USE_DEFAULTS
        case $USE_DEFAULTS in
            y|Y)
                EXEC="$HOME/pd.sh"
                DATA="$HOME/.pd-data"
                PROFILE=( "$HOME/.bash_profile" "$HOME/.bashrc" )
                FUNC_NAME="pd"
                UNINSTALL=1
                break
                ;;
            n|N)
                echo -e "Uninstall aborted!"
                exit 20
                ;;
            *)
                echo "[!] Please answer y or n."
                ;;
        esac
    done
fi

if [[ $UNINSTALL -eq 1 ]]; then
    # Uninstall Parked Directories
    echo -e "\nUninstalling Parked Directories...\n"

    # Remove executable
    rm "$EXEC" || exit 30
    echo "Removed executable: $EXEC."

    # Remove data file
    rm "$DATA" || exit 31
    echo "Removed data file: $DATA."

    # Remove sourcing from profile script
    for PRF in "${PROFILE[@]}"; do
        sed -i "/## Park Directories ##/,/## End Park Directories ##/d" "$PRF"
        echo "Removed sourcing script from $PRF."
    done

    # Remove log file
    if [[ -f "$LOGFILE" ]]; then
        rm "$LOGFILE" || exit 32
        echo "Removed installation log file: $LOGFILE"
    fi

    # Remove directory if it is empty -- ask first
    DIR=$(dirname "$DATA")
    if [[ ! "$(ls -A $DIR)" ]]; then
        echo -e "\nThe directory where the executable and data files were stored,"
        echo "$DIR, is now empty."
        
        while true; do
            read -n1 -p "Would you like to delete this directory? (y/n)" DEL_DIR
            case $DEL_DIR in
                y|Y)
                    rmdir "$DIR" || exit 33
                    echo -e "$DIR removed\n"
                    break
                    ;;
                n|N)
                    echo -e "Leaving empty directory: $DIR\n"
                    break
                    ;;
                *)
                    echo "[!] Please answer y or n."
                    ;;
            esac
        done
    fi

    echo -e "\nUninstall complete"
    echo -e "Run\n\tunset -f $FUNC_NAME\nor close terminal to remove function from the environment."
fi
