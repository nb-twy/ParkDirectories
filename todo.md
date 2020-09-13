# Park Directories 2.0.0 - To Do
- [x] Sometimes autocomplete will replace the entire CWORD when it shouldn't
- [x] Sometimes autocomplete does not recognize that are many suggestions, 
      and instead, just replaced the entire CWORD with the prefix and not
      a resolved directory.
- [x] If pd -x exits with error, show error on new line
- [ ] Modify install and update to replace instances of the command name
      (i.e. pd) with the custom name

- [x] Autocomplete aliases
      * If the current word does not end with a /, search available aliases for possible matches.
      * If there is a single match, complete it and finish the string with / so that autocomplete
        can continue to work on the relative path.
- [ ] Autocomplete options

- [ ] When using pd -a ref /full/path
  * Should we check to make sure that the target path exists?
  * If we check and the target does not exist, we should prompt the user if they want to add the
    reference anyway.
  * If the user can add a non-existent target, we should have a -f|--force flag that allows the user to
    execute commands that would require user interaction without any user interaction, assuming the
    answer is "yes".

- [x] Do the return statements associated with error states have any value?
  * Because pd.sh is sourced, the return values do not serve a purpose.
  * I can remove them all.
  * If I want to manage the state, for example, detect an error, I need to use another feature, like a
    standard syntax, a log file, or an environment variable.

- [x] Remove all of the return statements from pd.sh
