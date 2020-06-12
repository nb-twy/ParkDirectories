#!/bin/bash

declare -A DEFAULTS
DEFAULTS["executable_name"]="pd.sh"
DEFAULTS["target_dir"]="$HOME"
DEFAULTS["logfile"]="$HOME/.pd.log"
DEFAULTS["old_logfile"]="$(pwd)/pd.log"
DEFAULTS["profile"]="$HOME/.bashrc"
DEFAULTS["data_file"]=".pd-data"
DEFAULTS["data_file_init"]="/dev/null"
DEFAULTS["func_name"]="pd"

