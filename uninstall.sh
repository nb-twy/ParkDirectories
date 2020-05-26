#!/bin/bash

UNINSTALL=0
LOG_FILE="pd.log"

# Check if log file exists
# If so, extract configured data.
# If not, ask if we should attempt to uninstall default configuration.
if [[ -f "$LOG_FILE" ]]; then
    # Extract configurations from log file
    EXEC=$(grep "path_to_executable" "$LOG_FILE" | cut -d' ' -f2)
    DATA=$(grep "path_to_data_file" "$LOG_FILE" | cut -d' ' -f2)
    PROFILE=( $(grep "profile" "$LOG_FILE" | cut -d' ' -f2) )
    FUNC_NAME=$(grep "func_name" "$LOG_FILE" | cut -d' ' -f2)
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
        sed -i "/## Parked Directories ##/,+7d" "$PRF"
        echo "Removed sourcing script from $PRF."
    done

    # Remove log file
    if [[ -f "$LOG_FILE" ]]; then
        rm "$LOG_FILE" || exit 32
        echo "Removed installation log file: $LOG_FILE"
    fi

    # Remove directory if it is empty -- ask first
    DIR=$(dirname "$DATA")
    if [[ ! "$(ls -A $DIR)" ]]; then
        echo -e "\nThe directory where the executable and data files were stored,"
        echo "$DIR, is now empty."
        
        while true; do
            read -n1 -p "Would you like to delete this directory? (y/n) " DEL_DIR
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