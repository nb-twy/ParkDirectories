#!/bin/bash

## Load defaults
source "$CWD/defaults.sh"

## Functions & globals that can be used in install.sh, update.sh, and uninstall.sh
# <<<< GLOBALS >>>>
EXECUTABLE_SOURCE="${DEFAULTS["executable_source"]}"
EXECUTABLE_DEST="${DEFAULTS['executable_name']}"
LOGFILE="${DEFAULTS['logfile']}"
OLD_LOGFILE="${DEFAULTS['old_logfile']}"
TARGET_DIR="${DEFAULTS['target_dir']}"
DATA_FILE="${DEFAULTS['data_file']}"
FUNC_NAME="${DEFAULTS['func_name']}"

declare -A INSTALLED_COMPS

### Characters ### 
CHAR_SUCCESS="\xE2\x9C\x94"
CHAR_FAIL="\xE2\x9D\x8C"
# >>>> END GLOBALS <<<<

function parse_logfile {
    # >>> Support for old log file location ends Sept. 1, 2020 <<<
    # Until then, check for old log file and use it if the new log file does not exist.
    if [[ -f "$LOGFILE" ]]; then
        local CUR_LOGFILE="$LOGFILE"
    elif [[ -f "$OLD_LOGFILE" ]]; then
        local CUR_LOGFILE="$OLD_LOGFILE"
    else
        return 25
    fi

    # Extract all of the data from the installation log file
    # Put it in a global dictionary called INSTALLED_COMPS
    INSTALLED_COMPS["path_to_log_file"]="$CUR_LOGFILE"
    while IFS=' ' read -r key value; do
        INSTALLED_COMPS["$key"]="$value"
    done < "$CUR_LOGFILE"
}

function bootstrap_in_profile {
    # Check for bootstrap code in profile file
    # local PROFILE=( "$HOME/.bash_profile" "$HOME/.bashrc" )
    local PROFILE=("$@")
    local id_str="## Park Directories ##"
    for PRF in "${PROFILE[@]}"; do
        if [[ -f "$PRF" ]]; then
            local profile_installed=$(grep -c "^$id_str" "$PRF")
            if [[ $profile_installed -gt 0 ]]; then
                echo "$PRF"
                return 0
            fi
        fi
    done
    echo "NONE"
}

function ch_datafile_loc {
    # Change the location where the data file is stored
    # Write the output to a new file so that the original is not altered.
    # Make a copy of the executable
    local TMP="tmp-$(date +%s).sh"
    cp "$EXECUTABLE_SOURCE" "$TMP" || exit 30
    sed -e "s|local pdFile=.*$|local pdFile=$TARGET_DIR/$DATA_FILE|" "$TMP" > "$EXECUTABLE_SOURCE"
    # Remove the tmp file
    rm "$TMP"
}

function ch_func_name {
    # Change the name of the function (default: pd), if necessary
    # Make a copy of the executable
    local TMP="tmp-$(date +%s).sh"
    cp "$EXECUTABLE_SOURCE" "$TMP" || exit 31
    sed -r -e "s|pd\(\) \{|$FUNC_NAME\(\) \{|" -e "s|(usage: )pd|\1$FUNC_NAME|" -e "s|pd |$FUNC_NAME |" "$TMP" > "$EXECUTABLE_SOURCE"
    # Remove the tmp file
    rm "$TMP"
}

function is_installed {
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

    # INSTALLED_COMPS:
    #   logfile = location
    #   exec = location
    #   func_name = name
    #   datafile = location
    #   profile = location

    # >>>> Globals associated with installation interrogation <<<<
    COMP_NONE=0
    COMP_LOG_FILE=1
    COMP_EXEC=2
    COMP_FUNC=4
    COMP_DATA_FILE=8
    COMP_BOOTSTRAP=16
    INSTALL_VALID=31
    # >>>> End Globals <<<<

    # Use the installation log file to determine if the regular install is complete and valid
    INSTALLED_COMPS_CODE=0
    if parse_logfile; then
        # If the log file was parsed successfully, then we know it exists and is formatted as expected.
        (( INSTALLED_COMPS_CODE += COMP_LOG_FILE ))

        # 2) Check that the executable exists
        if [[ -f "${INSTALLED_COMPS['path_to_executable']}" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_EXEC ))
        fi

        # 3) Check that the function exists in the environment
        if command -v "${INSTALLED_COMPS['func_name']}" > /dev/null; then
            (( INSTALLED_COMPS_CODE += COMP_FUNC ))
        fi

        # 4) Check that the data file exists
        if [[ -f "${INSTALLED_COMPS['path_to_data_file']}" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
        fi

        # 5) Check that the bootstrap code is where it is supposed to be
        local VER_PROFILE="NONE"
        local VER_PROFILE=$(bootstrap_in_profile "${INSTALLED_COMPS["profile"]}")
        if [[ "$VER_PROFILE" != "NONE" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_BOOTSTRAP ))
        fi
    else
        # If the log file does not exist, we have to look for a partial installation 
        # so that a new installation isn't mangled by an existing partial installation.

        # Look for installed components using command line arguments and default values
        ## 1) Look for the executable
        local DEFAULT_EXEC="${DEFAULTS[target_dir]}/${DEFAULTS[executable_name]}"
        if [[ -f "$TARGET_DIR/$EXECUTABLE_DEST" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_EXEC ))
            INSTALLED_COMPS["path_to_executable"]="$TARGET_DIR/$EXECUTABLE_DEST"
        elif [[ "$TARGET_DIR/$EXECUTABLE_DEST" != "$DEFAULT_EXEC" && -f "$DEFAULT_EXEC" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_EXEC ))
            INSTALLED_COMPS["path_to_executable"]="$DEFAULT_EXEC"
        fi

        ## 2) Look for the function in the environment
        if command -v "$FUNC_NAME" > /dev/null; then
            (( INSTALLED_COMPS_CODE += COMP_FUNC ))
            INSTALLED_COMPS["func_name"]="$FUNC_NAME"
        elif [[ "$FUNC_NAME" != "${DEFAULTS[func_name]}" ]] && command -v "${DEFAULTS[func_name]}" > /dev/null; then
            (( INSTALLED_COMPS_CODE += COMP_FUNC ))
            INSTALLED_COMPS["func_name"]="${DEFAULTS[func_name]}"
        fi

        ## 3) Look fo the data file
        local DEFAULT_DATA_FILE="${DEFAULTS[target_dir]}/${DEFAULTS[data_file]}"
        if [[ -f "$TARGET_DIR/$DATA_FILE" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
            INSTALLED_COMPS["path_to_data_file"]="$TARGET_DIR/$DATA_FILE"
        elif [[ "$TARGET_DIR/$DATA_FILE" != "$DEFAULT_DATA_FILE" && -f "$DEFAULT_DATA_FILE" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
            INSTALLED_COMPS["path_to_data_file"]="$DEFAULT_DATA_FILE"
        fi

        ## 4) Look for the profile file with the bootstrap code
        local VER_PROFILE="NONE"
        local SEARCH_PROFILES=( "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/profile" )
        local VER_PROFILE=$(bootstrap_in_profile "${SEARCH_PROFILES[@]}")
        if [[ "$VER_PROFILE" != "NONE" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_BOOTSTRAP ))
            INSTALLED_COMPS["profile"]="$VER_PROFILE"
        fi
    fi
}

function report_installed_comps {

    # Installation log file
    if [[ $(( INSTALLED_COMPS_CODE & COMP_LOG_FILE )) -eq $COMP_LOG_FILE ]]; then
        if [[ ${INSTALLED_COMPS['path_to_log_file']} == "$OLD_LOGFILE" ]]; then
            echo -e "$CHAR_FAIL  Old installation log file is stil in use @ ${INSTALLED_COMPS['path_to_log_file']}"
            echo -e "    Please run ./update.sh to use the new log file location."
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
            echo -e " Default: ${DEFAULTS['target_dir']}/${DEFAULTS['executable_name']}"
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
            echo -e " Default function name: ${DEFAULTS['func_name']}"
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
            echo -e " Default @ ${DEFAULTS['target_dir']}/${DEFAULTS['data_file']}"
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
            echo -e " Default: ${DEFAULTS['profile']}"
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
