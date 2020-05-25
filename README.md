# Park Directories
Park Directories allows a user to navigate to any directory on their system
with the simplicity of the semantics of the _cd_ command.  Do you have a a few directories in which you work commonly: the root to your _dev_ directory, _/var/log_, the root directory of your current project?  When you open your terminal, how do you jump to one of these?  Do you have aliases for them?  Do you have to type them out with tab completion a lot?  Does it get tedious?  When you want to jump to another part of your system and stay there for a  while, are you tempted to open a new terminal window or another tab, or another _tmux_ pane so that you can come back to where you are without having to navigate back tediously?

There are a few popular implementations that allow us to go back to the last directory easily using the command `cd -`.  This is really handy, but what happens when you need to navigate around the tree for a bit before going back to where you were?

With Park Directories, this is easy.  Park (_i.e._ bookmark) the current directory by typing `pd -a NAME`.  Go wherever you'd like on your system.  When you're ready to return to where you were, type `pd NAME`, and you're back!

The references persist across instances of the terminal and reboots.

Easily remove a bookmark with `pd -d NAME`.  Show the list of all parked directories with `pd -l`, and when you want to totally clean house, just type `pd -c` and all of the references will be removed.

Park Directories was written for Bash.  I would like to make it available for _zsh_ and _Mac OS_, as well, but we'll see what time allows.

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

Without any switches, _.install.sh_ will add the _pd_ command to the environment, place the Bash executable in your `$HOME` directory, and place the bootstrap code in the _.bashrc_ file.  Installation is fast!  Follow the instructions at the end of installation and run `source ~/.bashrc` or restart your terminal to bootstrap the command.  

**WARNING**:  Installation creates a _pd.log_ file in the same directory as _install.sh_.  **DO NOT** delete this file.  It is necessary for _uninstall.sh_ to work correctly.

The first time you run _pd_ with any of its options (_e.g._ `pd -h` to see the help information), the data file (_.pd-data_ by default) will be created in the same directory as the executable.  The command is not complicated, so just run `pd -h` to see all of the options in a quick view.

Read below for more details.

Have fun zooming around your system!

### Using Park Directories
You can read everything you need to know from the command's help.
```bash
pd -h
Park Directories
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

Parked directories are stored in "/your/home/directory/.pd-data"
```
### Example
Let's park the root of your dev directory with the name _dev_.  First navigate to this directory.  Then execute
```bash
pd -a dev
```
You're working on a particular dev project, so you go there and park that directory.
```bash
cd my_project
pd -a proj
```
Your app logs are stored in _/var/log/my_project_.  Let's head there and park that directory.
```bash
cd /var/log/my_project
pd -a log
```
You're developing a website, so your output will go to _/var/www/html/my_project_, so let's head there and park that, too.
```bash
cd /var/www/html/my_project
pd -a html
```
Let's head back and work on _my_project_ for a while.
What did we name the bookmark for _my_project_ code?
```bash
pd -l
  dev /home/jsmith/documents/dev
  proj /home/jsmith/documents/dev/my_project
  log /var/log/my_project
  html /var/www/html/my_project
```
Right, _proj_!
```bash
pd proj
```
Something is going wrong, so you want to check out the logs for a bit.
```bash
pd log
```
It looks like there might be a deployment issue, so you want to take a look at what was deployed to _/var/www/html/my_project_.
```bash
pd html
```
You identify the problem and want to get back to your code.
```bash
pd proj
```
In a couple of weeks, you're done working on this project and don't need the bookmarks anymore.
```bash
pd -d proj
pd -d html
pd -d log
pd -l
  dev /home/jsmith/documents/dev
```
If you don't need any of the bookmarks anymore, you can clear the entire list quickly.
```bash
pd -c
  Removed all parked directories
```

## Advanced Install
The install script, _install.sh_, has several options that allow you to customize your installation.  Let's walk through each of these options.

**Bootstrap from a Specific Profile File**  
The default behavior is to append the bootstrap code in your `$HOME/.bashrc` script.  This code checks that the executable, _pd.sh_, exists and runs it.  If you'd like to have this code appended to another one of the profile scripts, use the `-p, --profile` flag:
```bash
./install.sh -p ~/.bash_profile
```

**Location of the Executable and Data Files**  
_pd.sh_ and _.pd-data_ are placed in your `$HOME` directory, by default.  Some might find it cleaner to place both in a different directory, maybe in `$HOME/pd` or in `$HOME/.local/bin`, perhaps.  Whatever your fancy, use the `-d|--dir` option to choose where you'd like the files placed.  The entire directory tree will be created automatically if it doesn't exist.
```bash
./install.sh -d $HOME/scripts/pd
```

**Name of the Function**  
The function name, _pd_ by default, becomes a part of your environment every time your terminal loads.  With a short name like _pd_, it is possible to collide with another piece of software, function, or alias with the name _pd_.  In addition to being the initials of the name of the software (**p**ark **d**irectories), _pd_ was also chosen because the letters are typed from both hands, making it convenient and comfortable to type over and over.  You might like to use _kd_, for example, because it keeps your hands on the home keys.  Or maybe you use a different keyboard layout or speak a different language where a different mnemonic makes sense. For these reasons, among others, you can choose the name of the function by using the `--func` option.
```bash
./install.sh --func kd
```

**Name of the Data File**  
The default name of the file used to store the nickname and full path pairs is _.pd-data_.  If you'd like to pick a different name for that file, use the `-f|--file` option.  There is rarely a strong need for this, as choosing a custom location solves most concerns, but if, for example, you prefer to call the file _.savedDirs_, you can.  Please note that the option only takes the **name** of the file, NOT a full path.
```bash
./install.sh -f .savedDirs
```

**Use as Many Options as You'd Like**  
You can mix and match as many of the options as you'd like.  We can place the bootstrap code in `$HOME/.bashrc`, the executable in `$HOME/savedDirs`, rename the data file _.savedDirs_, and use _sd_ as the function name.
```bash
./install.sh -p $HOME/.bash_profile -d $HOME/savedDirs -f .savedDirs --func sd
```

## Advanced Uninstall
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

If `pd.log` is missing, the script will ask if it should attempt to uninstall using the default configuration.  If you say, "yes", it will attempt to uninstall Park Directories as if it had been installed with the default configuration.  If you say, "no", it will exit, and you will have to try and clean it up on your own.  All hope is not lost, though.  Run `pd -h` (or use the custom command you chose).  At the end of the help text, it tells you where the data file is located.  That's where the executable is, too.  Go delete them and the directory they are in, if it was a custom directory and is empty.  The bootstrap code is most likey in `$HOME/.bashrc`, most likely at the end.  It's easy to find because the section begins with `## Parked Directories ##`, ends with `## End ##`, and is only 7 lines long.  If `pd.log` exists but is corrupt, delete it.
