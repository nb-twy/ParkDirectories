# Park Directories
Park (bookmark) directories so that we can quickly navigate
to them from anywhere else using a short reference name.
The references persist across bash sessions.

usage: pd [OPTION] [REF]

-h, --help      Display this help message
-a, --add NAME  Park a directory referenced by NAME
-d, --del NAME  Remove the directory referenced by NAME
-l, --list      Display the entire list of parked directories
-c, --clear     Clear the entire list of parked directories

examples:
    pd dev      Navigate to directory saved with the ref name dev
    pd -a dev   Park the current directory with the ref name dev
    pd -d dev   Remove the directory referenced by the name dev from
                the parked directories list

Parked directories are stored in $HOME/.pd-data by default.

## Installation

## To Do
- [ ] Add automated install script  
    - [ ] Copy pd.sh to home directory  
    - [ ] Place sourcing in .bash_profile (default)  
    - [ ] Log (mostly for uninstall purposes)
        1. Location of pd.sh
        2. Full path to data file
        3. Where it's sourced: .bashrc or .bash_profile
    - [ ] Option: place sourcing in .bashrc (--bashrc)  
    - [ ] Option: change the name of the function to user's choice (--cmd NAME)  
    - [ ] Option: copy pd.sh to user chosen destination (--dir FULL-PATH)  
    - [ ] Option: store parked directories in user chosen file (--file FULL-PATH)  
- [ ] Add automated uninstall script  
  - [ ] Remove data file
  - [ ] Remove sourcing from .bashrc or .bash_profile
  - [ ] Remove pd.sh
