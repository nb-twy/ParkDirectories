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
    ### Discussion ###
    # We want to know if Park Directories is already installed for the following reasons:
    # 1) We do not want to break an existing installation.
    # 2) We do not want to overwrite the parked directories list.
    # 3) We need to know that PD is installed correctly if we want to complete an in-place update.
    #
    # Knowing that PD is installed correctly starts with checking that each of the five major components
    # are present: the installation log file exists, the executable (pd.sh), the function in memory, 
    # the data file, and the bootstrap code in a profile script.
    #
    # A complete verification would involve the following:
    # 1) Does the installation log file exist?
    # 2) Can it be parsed successfully?
    # 3) Does the indicated executable exist?
    # 4) Does that executable use the data file indicated in the log file?
    # 5) Does the data file exist?
    # 6) Does the data file parse successfully (i.e. is it formatted properly)?
    # 7) Does the indicated executable reference the function name indicated in the log file?
    # 8) Is that function present in the user's environment?
    # 9) Does the profile script indicated in the log file include bootstrap code?
    # 10) Does that bootstrap code reference the executable indicated in the log file?
    # 11) Does that bootstrap code reference the function indicated in the log file?
    # Certain aspects of this may be dependent on the version of PD that is installed.
    # We have to be careful that the new version can uninstall and upgrade an older version.
    #
    # We need to segregate verification and reporting.
    # 1) If we call is_installed when we are trying to install PD for the first time,
    #    it should report that nothing is installed and that the installation can continue,
    #    if it reports anything at all.
    # 2) If we call is_installed when we are trying to install PD and there are already some
    #    components installed, we want to report which are installed, which are not, and that
    #    this is an error state that needs to be rectified before a proper installation can
    #    continue.
    # 3) If we call is_installed when we are trying to perform an in-place update, we want
    #    is_installed to tell us that everything is properly installed.  This is a good thing
    #    and allows the update to continue.  If something is not installed correctly, this is
    #    an error state that needs to be corrected.
    #
    # If is_installed performs the tests and creates the globals INSTALLED_COMPS_CODE and
    # INSTALLED_COMPS, then we can leave reporting up to the caller and can have 
    # abstracted functions that can report appropriately.
    #
    ### End Discussion ###
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
        if [[ -f "$TARGET_DIR/$EXECUTABLE_DEST" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_EXEC ))
            INSTALLED_COMPS["path_to_executable"]="$TARGET_DIR/$EXECUTABLE_DEST"
        elif [[ "$TARGET_DIR/$EXECUTABLE_DEST" != "$HOME/pd.sh" && -f "$HOME/pd.sh" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_EXEC ))
            INSTALLED_COMPS["path_to_executable"]="$HOME/pd.sh"
        fi

        ## 2) Look for the function in the environment
        if command -v "$FUNC_NAME" > /dev/null; then
            (( INSTALLED_COMPS_CODE += COMP_FUNC ))
            INSTALLED_COMPS["func_name"]="$FUNC_NAME"
        elif [[ "$FUNC_NAME" != "pd" ]] && command -v "pd" > /dev/null; then
            (( INSTALLED_COMPS_CODE += COMP_FUNC ))
            INSTALLED_COMPS["func_name"]="pd"
        fi

        ## TODO: Use data from DEFAULTS dictionary when testing for default configurations
        ## 3) Look fo the data file
        if [[ -f "$TARGET_DIR/$DATA_FILE" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
            INSTALLED_COMPS["path_to_data_file"]="$TARGET_DIR/$DATA_FILE"
        elif [[ "$TARGET_DIR/$DATA_FILE" != "$HOME/.pd-data" && -f "$HOME/.pd-data" ]]; then
            (( INSTALLED_COMPS_CODE += COMP_DATA_FILE ))
            INSTALLED_COMPS["path_to_data_file"]="$HOME/.pd-data"
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

