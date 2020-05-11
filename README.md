# Park Directories
Park Directories allows a user to navigate to any directory on their system
with the simplicity of the semantics of the _cd_ command.  Do you have a a few directories in which you work commonly: the root to your _dev_ directory, _/var/log_, the root directory of your current project?  When you open your terminal, how do you jump to one of these?  Do you have aliased for them in _.bashrc_ or _.bash_profile_?  Do you have type them out with tab completion a lot?  Does it get tedious?  When you want to jump to another part of your system and stay there fora  while, are you tempted to open a new terminal window or another tab, or another _tmux_ pane so that you can come back to where you are without having to navigate back tediously?

There are a few popular implementations that allow us to go back to the last directory easily using the command `cmd -`.  This is really handy, but what happens when you need to navigate around the tree for a bit before going back to where you were?

With Park Directories, this is easy.  Park (_i.e._ bookmark) the current directory by typing `pd -a NAME`.  Go wherever you'd like on your system.  When you're ready to return to where you were, type `pd NAME`, and you're back!

The references persist across instances of the terminal and reboots.

Easily remove a bookmark with `pd -d NAME`.  Show the list of all parked directories with `pd -l`, and when you want to totally clear house, just type `pd -c` and all of the references will be removed.

Park Directories was written for Bash.  I would like to make it available for _zsh_ and _Mac OS_, as well, but we'll see what time allows.

## Getting Started
It's easy to get started!
### Simple Installation
Download or clone the repository, and then install it.

```bash
git clone https://github.com/nb-twy/ParkDirectories.git
cd ParkDirectories
./install.sh
source ~/.bash_profile
```

Without any switches, _.install.sh_ will add the _pd_ command to the environment, place the Bash executable in your `$HOME` directory, and place the bootstrap code in the _.bash_profile_ file.  Installation is fast!  Follow the instructions at the end of installation and run `source ~/.bash_profile` or restart your terminal to bootstrap the command.  

**WARNING**:  Installation creates a _pd.log_ file in the same directory as _install.sh_.  **DO NOT** delete this file.  It is necessary for _uninstall.sh_ to work correctly

The first time you run _pd_ with any of its options (_e.g._ `pd -h` to see the help information), the data file (_.pd-data_ by default) will be created in the same directory as the executable.  The command is not complicated, so just run `pd -h` to see all of the options in a quick view.

Read below for more details.

Have fun zooming around your system!

### Using Park Directories
Geting started is easy.  You can read everything you need to know from the command's help.
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

Let's park the root of your dev directory with the name _dev_.  First navigate to this directory.  Then execute
```bash
pd -a dev
```
You're working on a particular dev project, so you go there and park that directory.
```bash
cd my_project
pd -a proj
```
You app logs are stored in _/var/log/my_project/_.  Let's head there and park that directory.
```bash
cd /var/log/my_project
pd -a log
```
You're developing a website, so your output will go to _/var/www/html/my_project/_, so let's head there and park that, too.
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
Right, _proj_
```bash
pd proj
```
Something is going wrong, so you want to check out the logs for a bit.
```bash
pd log
```
It looks like there might be a deployment issue, so you want to take a look at what was deployed to _/var/www/html/my_project/_.
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

## Advanced Uninstall

## To Do
- [ ] Update README
  - [x] Introduction
  - [ ] Install
  - [ ] Uninstall
  - [ ] How to use
- [ ] Test with zsh
- [ ] Ensure compatibility with Mac OS
  
