![GitHub release (latest by date)](https://img.shields.io/badge/Version-2.0.0-success)

# Park Directories

## Introduction
Park Directories allows a user to navigate to any directory on their system
with the simplicity of the semantics of the _cd_ command.  Do you have a few directories in which you work commonly: the root to your _dev_ directory, _/var/log_, the root directory of your current project?  When you open your terminal, how do you jump to one of these?  Do you have aliases for them?  Do you have to type them out with tab completion a lot?  Does it get tedious?  When you want to jump to another part of your system and stay there for a  while, are you tempted to open a new terminal window or another tab, or another _tmux_ pane so that you can come back to where you are without having to navigate back tediously?

There are a few popular implementations that allow us to go back to the last directory easily using the command `cd -`.  This is really handy, but what happens when you need to navigate around the tree for a bit before going back to where you were?

With Park Directories, this is easy.  Park (_i.e._ bookmark or alias) the current directory by typing `pd -a NAME`.  Go wherever you'd like on your system.  When you're ready to return to where you were, type `pd NAME`, and you're back!

No need to park every frequently used directory.  Park a _home base_ and navigate to directories relative to the target of the reference name: `pd proj/src`.

You can use Bash's popular autocomplete feature to quickly access your parked directory aliases, directory paths relative to a target directory, short and long options, and more with the press of a `<tab>` or two.

Park Directories was designed with scriptability in mind.  You can perform multiple actions on the same line, and you can park any directory by providing the full path to the directory: `pd -a NAME FULL_PATH`.  This could be useful when you are getting ready to work on a project and want to park your project root, the debug build directory, the release build directory, the log directory, and maybe the deploy directory.  You could use the same generic names to reference all of these and use a script to set up your environment.  Something like the following:
```bash
#!/bin/bash

# Remove references, if they exist
pd -d proj -d dbg -d rel -d log -d dep

# Add references
# These could all be executed in the same invocation, but it's easier to read and understand
# on multiple lines.
pd -a proj /home/user/docs/dev/super-awesome-project  # project directory
pd -a dbg /home/user/docs/dev/super-awesome-project/bin/debug   # debug build directory
pd -a rel /home/user/docs/dev/super-awesome-project/bin/release   # debug build directory
pd -a log /home/user/log   # log directory
pd -a dep /var/www/html/super-awesome-project   # deploy directory
```
> **NOTE** &nbsp;Reference names may not contain a forward slash '/'.
> ```bash
> $ pd -a proj/build
> ERROR: Reference name may not contain '/'
The references persist across Bash sessions.

Easily remove a bookmark with `pd -d NAME`.  Show the list of all parked directories with `pd -l`, and when you want to totally clean house, just type `pd -c` and all of the references will be removed.

Park Directories is currently being developed as a Bash utility.  Keep an eye on the project's roadmap for more about what's coming next.

----
## Getting Started
It's easy to get started!
### Simple Installation
Download or clone the repository, and then install it.

```bash
git clone https://github.com/nb-twy/ParkDirectories.git
cd ParkDirectories
./install.sh
source ~/.bashrc
```

Without any switches, _install.sh_ will add the _pd_ command to the environment, place the Bash executable in your `$HOME` directory, and place the bootstrap code in the _.bashrc_ file.  Installation is fast!  Follow the instructions at the end of the installation and run `source ~/.bashrc` or restart your terminal to bootstrap the command.  

The first time you run _pd_ with any of its options (_e.g._ `pd -h` to see the help information), the data file (_.pd-data_ by default) will be created in the same directory as the executable.  The command is not complicated, so just run `pd -h` to see all of the options in a quick view.

```bash
# Navigate to a directory you'd like to park
> cd ~/home/dev
# Park your first directory
> pd -a dev
# Navigate around a bit
> cd /var/log
> cd /etc
> cd ~/.ssh
# Easily return to your dev directory
> pd dev
# Add a couple of your favorite directories with one command
> pd -a www /var/www/html/mysite -a pic ~/home/documents/pictures
# Quickly navigate to the root of your web site
> pd www
```
Read below to learn more about the features and functionality of Park Directories.

Have fun zooming around your system!

----
## Using Park Directories
Most of what you need to know to be successful with Park Directories is right in the help text.
```bash
$ pd -h
Park Directories
Park (bookmark) directories so that we can quickly navigate
to them from anywhere else using a short reference name.
The references persist across bash sessions.

usage: pd [REF[/RELPATH]] [OPTION {ARG} [OPTION {ARG} ...]]

-h, --help                           Display this help message
-a, --add NAME[ PATH]                Given just NAME, park the current directory with reference NAME
                                     Given NAME & PATH, park PATH with reference NAME
                                     Reference names may not start with - or contain /
-d, --del NAME                       Remove the directory referenced by NAME
-l, --list                           Display the entire list of parked directories
-c, --clear                          Clear the entire list of parked directories
-x, --expand NAME[/RELPATH]          Expand the referenced directory and relative path without
                                     navigating to it
-e, --export FILE_PATH               Export current list of parked directories to FILE_PATH
-i, --import                         Import list of parked directories from FILE_PATH
    [--append | --quiet] FILE_PATH   Use -i --append FILE_PATH to add entries to the existing list
                                     Use -i --quiet FILE_PATH to overwrite current entries quietly
-v, --version                        Display version

Examples:
    pd dev              Navigate to directory saved with the ref name dev
    pd dev/proj         Navigate to the proj subdirectory of the directory 
                        referenced by ref name dev
    pd -a dev           Park the current directory with the ref name dev
    pd -a log /var/log  Park /var/log with ref name log
    pd -d dev           Remove the directory referenced by the name dev from
                        the parked directories list
    
    Move the contents of the directory referenced by dev1 to the archive
    subdirectory of the directory referenced by repos:
        mv -v \$(pd -x dev1) \$(pd -x repos/archive/)
    
    A single invocation can take multiple options, performing multiple operations at once:
        pd -l -d dev -a dev -d log -a log /var/log -l
    This command will
      1) List all parked directories
      2) Remove the entry referenced by "dev", if one exists
      3) Park the current directory with the reference name "dev"
      4) Remove the entry referenced by "log", if one exists
      5) Park the /var/log directory with the reference name "log"
      6) List all parked directories

Parked directories are stored in /home/user/.pd-data
Park Directories version 2.0.0
```
### Example Workflow
Let's park the root of your dev directory with the name _dev_.  First navigate to this directory.  Then execute
```bash
$ cd /home/user/nix0/mydocs/dev
$ pd -a dev
Added: dev --> /home/user/nix0/mydocs/dev
```
You're working on a particular dev project, so you go there and park that directory.
```bash
$ cd my_project
$ pd -a proj
Added: proj --> /home/user/nix0/mydocs/dev/my_project
```
Your app logs are stored in _/var/log/my_project_.  We don't have to go there.  Let's just park it from here.
```bash
$ pd -a log /var/log/my_project
Added: log --> /var/log/my_project
```
You're developing a website, so your output will go to _/var/www/html/my_project_, so let's park that, too, without traveling there.
```bash
$ pd -a html /var/www/html/my_project
Added: html --> /var/www/html/my_project
```
Let's head back and work on _my_project_ for a while.
What did we name the bookmark for _my_project_ code?
```bash
$ pd -l

  dev /home/jsmith/documents/dev
  proj /home/jsmith/documents/dev/my_project
  log /var/log/my_project
  html /var/www/html/my_project

```
Right, _proj_!
```bash
$ pd proj
```
Something is going wrong, so you want to check out the logs for a bit.
```bash
$ pd log
```
It looks like there might be a deployment issue, so you want to take a look at what was deployed to _/var/www/html/my_project_.  Did you park that directory as html or http?  Let's use autocomplete.
```bash
$ pd h<tab>
$ pd html   # That's right!  It was html.
```
You identify the problem and want to get back to your code.
```bash
$ pd proj
```
In a couple of weeks, you're done working on this project and don't need the bookmarks anymore.
```bash
# Note that the following command removes (-d) the references to proj, html, and log
# and then lists (-l) the remaining references. This is a good pattern when you're
# deleting more than one reference.
$ pd -d proj -d html -d log -l
Removed: proj --> /home/jsmith/documents/dev/my_project
Removed: html --> /var/www/html/my_project
Removed: log --> /var/log/my_project

  dev /home/jsmith/documents/dev

```
If you don't need any of the bookmarks anymore, you can clear the entire list quickly.
```bash
$ pd -c
  Removed all parked directories
```
### Navigate to Path Relative to Parked Directory
A big time saver is the ability to navigate to a directory relative to the parked directory.  For example, you are working on a software application called _MyApp_ with top-level directories _docs_, _src_, and _tests_.

```bash
# Park the app root directory
> pd -a app
Added: app --> /home/user/dev/apps/MyApp
# At some point, you're deep in the docs folder structure
> pwd
/home/user/dev/apps/MyApp/docs/getting_started/install
# You want to go look at the files in the src directory
> pd app/src
> pwd
/home/user/dev/apps/MyApp/src
```

### Autocomplete Parked Directory Ref Names
Use tab completion to quickly find the ref name you're looking for.  This works with navigation (`pd REF`), deletion (`pd -d REF`), and expansion (`pd -x REF`).
```bash
> pd d<tab><tab>
dev dlp docs
> pd do<tab>
> pd docs/
> pwd
/home/user/documents
```

### Autocomplete Relative Paths
Use tab completion to quickly navigate to directories relative to the target directory of the parked reference.
```bash
> pd d<tab><tab>
dev dlp docs
> pd de<tab>
> pd dev/<tab><tab>
experiments   foo   projA   projB   projC   projD
> pd dev/p<tab>
> pd dev/proj<tab><tab>
projA   projB   projC   projD
> pd dev/projB/
> pwd
/home/user/dev/my_ui_project_B
```
### Autocomplete File and Directory Names
If you are using the import feature (`pd -i MAPPING_FILE`) or parking a directory with the path (`pd -a REF PATH`), you can use autocomplete to easily find the file or directory.

```bash
# Look for a file to import
> pd -i <tab><tab>
httpd.conf.bck   ssh.conf.bck   park-directories.bck
> pd -i p<tab>
> pd -i park-directories.bck

# Look for a directory to park
> pd -a logs /var/log/<tab><tab>
apt   my_app1_logs   my_app2_logs   ssh_logs
> pd -a logs /var/log/my<tab>
> pd -a logs /var/log/my_app<tab><tab>
my_app1_logs   my_app2_logs
> pd -a logs /var/log/my_app2<tab>
> pd -a logs /var/log/my_app2_logs/
Added: logs --> /var/log/my_app2_logs
```

### Autocomplete Short and Long Options
If you can't remember one of the actions/options, just type `-` or `--` and then let autocomplete do the rest.  If you can't remember what each option does, don't forget `pd -h` or `pd --help`.
```bash
> pd -<tab><tab>
-a  -c  -d  -e  -h  -i  -l  -v  -x
> pd --<tab><tab>
--add   --clear   --del   --expand   --export   --help   --import   --list   --version
```
### Export List of Parked Directories
If you want to backup your list of parked directories or want to automate configuring another system, you can easily export your list of parked directories to a file using the `-e|--export` option.
```bash
$ pd -e my-parked-directories.txt
List of parked directories exported to my-parked-directories.txt
```
### Import List of Parked Directories
If you have exported a list of parked directories, created your own by hand, or received a file from a friend, you can import your list.  You can either overwrite the current list or append the new entries to the current list.

**Append to List**  
You append to the list by using the `-i --append FILE_PATH` option.  You can append entries and check that they were added all in one go by adding the `-l` option to the end of the command.
```bash
$ pd -i --append my-parked.directories.txt -l
Import complete

dev /home/user/docs/dev
pd /home/user/docs/dev/ParkDirectories

```

**Interactive Overwrite**  
When you import entries without a second option, the current contents will be overwritten, but you will have the chance to decide what to do first.  You can
1. backup the current contents
2. overwrite without a backup
3. abort the import

```bash
$ pd -i my-parked-directories.txt
WARNING: Import will replace the current list of parked directories!
Please choose from the following options:
  (b)ackup current list and continue
  (c)ontinue without backing up
  (a)bort import
[b/c/a]: a
Import aborted!
```
```bash
$ pd -i my-parked-directories.txt
WARNING: Import will replace the current list of parked directories!
Please choose from the following options:
  (b)ackup current list and continue
  (c)ontinue without backing up
  (a)bort import
[b/c/a]: b
Data file backed up to /home/user/.pd-data-1591339470.bck
Contents of data file cleared
Import complete

```
```bash
$ pd -i my-parked-directories.txt
WARNING: Import will replace the current list of parked directories!
Please choose from the following options:
  (b)ackup current list and continue
  (c)ontinue without backing up
  (a)bort import
[b/c/a]: c
Contents of data file cleared
Import complete

```
Useful for scripted configurations is the ability to overwrite without any user interaction.
```bash
$ pd -i --quiet my-parked-directories.txt
Contents of data file cleared
Import complete

```

----
## Advanced Install
The install script, _install.sh_, has several options that allow you to customize your installation.  Let's walk through each of these options.

```bash
>>>> Install Park Directories <<<<

usage: install.sh [OPTIONS]

OPTIONS:
-h, --help              Display this help message and exit
-d, --dir DIR           Set the directory where the data file and executable
                        will be written. Use a fully-qualified path or /home/user
                        will be used as the root path. (default: /home/user)
-p, --profile PROFILE   Install the bootstrap code in the specified profile file
                        Requires full path (e.g. ~/.bash_profile, ~/.bash_login)
                        (default: ~/.bashrc)
-f, --file FILE         Set the name of the file to be used to store the
                        parked directory references (default: .pd-data)
--func FUNC_NAME        Set the command name (default: pd)
-i, --import FILE       Initialize the list of parked directories with those in FILE
--verify                Look for the installation components of Park Directories
                        and report on the health of the installation.
```

### Bootstrap from a Specific Profile File
The default behavior is to append the bootstrap code in your `$HOME/.bashrc` script.  This code checks that the executable, _pd.sh_, exists and runs it.  If you'd like to have this code appended to another one of the profile scripts, use the `-p, --profile` flag:
```bash
# Put the bootstrap code in .bash_profile
$ ./install.sh -p ~/.bash_profile
```

### Location of the Executable and Data Files
The executable and data file (defaults: _pd.sh_ and _.pd-data_) are placed in your `$HOME` directory, by default.  Some might find it cleaner to place both in a different directory, maybe in `$HOME/pd` or in `$HOME/local/bin`, perhaps.  Whatever your fancy, use the `-d|--dir` option to choose where you'd like the files placed.  The entire directory tree will be created automatically if it doesn't exist.
```bash
# Put the executable and data file in $HOME/scripts/pd
$ ./install.sh -d $HOME/scripts/pd
```

### Name of the Function
The function name, _pd_ by default, becomes a part of your environment every time your terminal loads.  With a short name like _pd_, it is possible to collide with another piece of software, function, or alias with the name _pd_.  In addition to being the initials of the name of the software (**p**ark **d**irectories), _pd_ was also chosen because the letters are typed from both hands, making it convenient and comfortable to type over and over.  You might like to use _kd_, for example, because it keeps your hands on the home keys.  Or maybe you use a different keyboard layout or speak a different language where a different mnemonic makes sense. For these reasons, among others, you can choose the name of the function by using the `--func` option.  Unlike creating an alias, this sets the name in the script that is registered in the environment.
```bash
# Set active function name to kd
$ ./install.sh --func kd
```

### Name of the Data File
The default name of the file used to store the nickname and full path pairs is _.pd-data_.  If you'd like to pick a different name for that file, use the `-f|--file` option.  There is rarely a strong need for this, as choosing a custom location solves most concerns, but if, for example, you prefer to call the file _.savedDirs_, you can.  Please note that the option only takes the **name** of the file, NOT a full path.
```bash
# Store the parked directory mappings in a file named .savedDirs
$ ./install.sh -f .savedDirs
```

### Initialize Data File on Install
The data file is empty by default.  You can use an exported list of parked directories to initialize the data file by using the `-i|--import FILE_PATH` option.

Let's say you were working on a project on one VM or container or host and had a set of directories parked that were useful for that project.  Then you need to move to a different system to continue working on your project, and you'd like to bring your parked directories with you.

```bash
# Export your parked directories list from Host 1
user@host1 $ pd -l

dev /home/user/docs/dev
proj /home/user/docs/dev/my-project
dbg /home/user/docs/dev/my-project/bin/debug/
rel /home/user/docs/dev/my-project/bin/release

user@host1 $ pd -e my-parked-directories.txt
List of parked directories exported to my-parked-directories.txt

# Transfer the exported file to Host 2
# Then install Park Directories and initialize the mappings
user@host2 $ ./install.sh -i my-parked-directories.txt
Installing Park Directories...

Checking for installed components...
Initiatlized data file with /home/user2/docs/my-parked-directories.txt

Installation complete!
Please execute the following command to use Park Directories:
        source /home/user/.bashrc

user@host2 $ source /home/user/.bashrc
user@host2 $ pd -l

dev /home/user/docs/dev
proj /home/user/docs/dev/my-project
dbg /home/user/docs/dev/my-project/bin/debug/
rel /home/user/docs/dev/my-project/bin/release

user@host2 $
```

### Verify Installation
If you would just like to check that all the components of Park Directories are installed correctly, you can run `./install.sh --verify`.  It will check for the components and report their status.  The report for a proper installation looks like this.

```bash
$ ./install.sh --verify
Checking for installed components of Park Directories...
✔  Installation log file located @ /home/user/.pd.log
✔  Installation log file parsed.
✔  Executable @ /home/user/pd.sh
✔  Function active: pd
✔  Data file @ /home/user/.pd-data
✔  Bootstrap code located in /home/user/.bashrc
All components are installed as expected.
```

If components are missing, the report looks like this.
```bash
$ ./install.sh --verify
Checking for installed components of Park Directories...
✔  Installation log file located @ /home/user/.pd.log
✔  Installation log file parsed.
❌  Executable could not be located. Expected @ /home/user/pd.sh
✔  Function active: pd
❌  Data file could not be located. Expected @ /home/user/.pd-data
✔  Bootstrap code located in /home/user/.bashrc
Park Directories is only partially installed.
Please review the list above and refer to the README for possible solutions.
```

**Use as Many Options as You'd Like**  
You can mix and match as many of the options as you'd like, where it makes sense.  We can place the bootstrap code in `$HOME/.bash_profile`, the executable in `$HOME/savedDirs`, rename the data file _.savedDirs_, and use _sd_ as the function name.
```bash
$ ./install.sh -p $HOME/.bash_profile -d $HOME/savedDirs -f .savedDirs --func sd
```

`--verify` does not support any of the other options.

----
## Update Park Directories
As new features are added, enhancements made, and bugs fixed, you'll want to update Park Directories without having to uninstall and re-install.  Use the `update.sh` script for all in-place updates.  Here's the help text:
```bash
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
```

### Update Version & Change the Function Name
When you're ready to upgrade to a newer version of Park Directories, you might want to change the function name.  Use the `--func FUNC_NAME` option to perform an in-place upgrade **and** change the function name.

```bash
## Upgrade to the latest version and change the function name from pd to kd
> ./update.sh --func kd
Verifying current installation...
Park Directories is installed properly.
✔ Function name changed to kd.
✔  Executable updated
Update complete.
Please restart your terminal or run the following:
    unset -f pd
    source /home/user/.bashrc
```
>Do not forget to follow the instructions after the upgrade to either restart the terminal or to run `unset` and source your profile script.

### Change the Function Name Only
You can change the function name without upgrading the application version by using the `--func-only FUNC_NAME` option.

```bash
## Change the function name back to pd without updating the application version
> ./update.sh --func-only pd
Verifying current installation...
Park Directories is installed properly.
✔ Function name changed to pd.
Please restart your terminal or run the following:
    unset -f kd
    source /home/user/.bashrc
```
>Do not forget to follow the instructions after the upgrade to either restart the terminal or to run `unset` and source your profile script.

### Update Will Abort if Installation Incorrect
```bash
> ./update.sh
Verifying current installation...
✔  Installation log file located @ /home/user/.pd.log
✔  Installation log file parsed.
❌  Executable could not be located. Expected @ /home/user/pd.sh
✔  Function active: pd
❌  Data file could not be located. Expected @ /home/user/.pd-data
✔  Bootstrap code located in /home/user/.bashrc
Park Directories is only partially installed.
Please review the list above and refer to the README for possible solutions.

Cannot continue with update until Parked Directories is properly installed.
```

-----
## Fixing Partial Installation
Park Directories is not a complicated application.  A proper installation consists of the following:

1. The executable
1. The installation log file
1. The data file
1. Bootstrap code in a profile script
1. The active function in the environment

You can try using `uninstall.sh` to clean up.  As described below, it will try to use the installation log file to remove a proper installation.  It will also attempt to remove any of the components it can find through locating defaults and matching signatures.  If the automatic uninstall does not clean things up for a fresh new installation, then follow the instructions to perform a [manual uninstall](#uninstalling-park-directories).

### Step-by-Step Investigation
If you don't want to try to uninstall Park Directories and reinstall it to fix a broken installation, you can diagnose the problem and try to fix it manually with the following information.  

**Installation Log File**  
When Park Directories is installed, the installation details are stored in the installation log file.  By default, this file is located at `$HOME/.pd.log`.  Its contents look like this:
```bash
path_to_executable /home/user/pd.sh
path_to_data_file /home/user/.pd-data
profile /home/user/.bashrc
func_name pd
```
It tells `install.sh`, `update.sh`, and `uninstall.sh` 
1. the location of the executable
1. the location of the data file
1. which profile script contains the bootstrap code
1. and the name of the function that is registered in the environment.

These scripts create, modify, and remove the installation log file.  Unless something has gone horribly wrong, this file should not be modified manually.  However, if the application is saying that something is missing, it is because this log file is missing or includes the wrong information.

If the file is missing, but the rest of the application components are present, you can recreate the log file by copying the example file contents shown above and replacing the values to the right of the space with the proper information.

**Executable**  
By default, the executable is called `pd.sh` and is located in the user's `$HOME` directory.  If you believe that Park Directories is installed but `pd.sh` is not in your home directory or at the location indicated in the installation log file, you can always search for it.
```bash
> find ~ -type f -name "pd.sh"
```
The installation script allows you to put the executable anywhere you'd like.  If you can't find it, it is probably best to continue to clean up the rest of the application assets and reinstall.  If your data file exists and you want to keep the current list of parked directories, you can rename the file (_e.g. _.pd-data.bck_) and use it with the `-i, --import` option of the `install.sh` script.  You can also just leave it alone and reinstall.

**Data File**  
If the data file is not located where the installation log file says it should be, the active function will recreate the data file the next time you use it.  If you know that the data file is somewhere else, you can either move it to where the installation log file says it should be or edit the log file with the correct location of the data file.

**Profile Script**  
The installation log file records which profile script contains the bootstrap code.  If the bootstrap code was moved manually to another profile script, you should update the log file with the correct location of the profile script.  The proper way to change which profile script is used to bootstrap Park Directories is to uninstall it and reinstall it with the `-p, --profile` option.

**Active Function**  
By default, the active function is called `pd`.  The function name is set in the bootstrap code located in the profile script, default is `$HOME/.bashrc`.  The name of the function in `pd.sh` and the name in the bootstrap code need to match.  If they do not, for some reason, update the information in the bootstrap code to match what is in `pd.sh`.  Normally, uninstalling and reinstalling would fix this problem automatically.


## Uninstalling Park Directories
I don't know why you'd ever want to uninstall Park Directories, but if you must... ;)  
Just run `./uninstall.sh`.  
There are no options for this command, but let's talk about what it will do in case something goes wrong.  The command needs to

1. remove the executable and data files
2. remove the directory these are in, if it is empty
3. remove the bootstrap code from the profile file
4. remove `pd.log`.

If `pd.log` exists and is not corrupted, everything will go smoothly.  The script uses `pd.log` to know

1. where the executable and data files are located
2. if we used a custom name for the data file
3. in which profile script the bootstrap code was placed
4. the name of the function.

If the executable and data files were placed in a custom directory and after removing them the directory is empty, `uninstall.sh` will ask if you want to remove the directory.

When `uninstall.sh` runs successfully, it will tell you that you can either restart your terminal or run `unset -f {command_name}` to remove the command from your environment.  This is not entirely necessary, but it is the last bit of housekeeping necessary.

If `pd.log` is missing, the script will ask if it should attempt to uninstall using the default configuration.  If you say, "yes", it will attempt to uninstall Park Directories as if it had been installed with the default configuration.  If you say, "no", it will exit, and you will have to try and clean it up on your own.  All hope is not lost, though.  Run `pd -h` (or use the custom command you chose).  At the end of the help text, it tells you where the data file is located.  That's where the executable is, too.  Go delete them and the directory they are in, if it was a custom directory and is empty.  The bootstrap code is most likey in `$HOME/.bashrc`, most likely at the end.  It's easy to find because the section begins with `## Parked Directories ##`, ends with `## End ##`, and is only 9 lines long.  If `pd.log` exists but is corrupt, delete it.

For more information about manual clean up, refer to the section [Fixing Partial Installation](#fixing-partial-installation).
