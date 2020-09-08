# Park Directories 2.0.0 - To Do
- [ ] If pd -x exits with error, show error on new line
- [ ] Modify install and update to replace instances of the command name
      (i.e. pd) with the custom name

- [ ] Autocomplete aliases
- [ ] Autocomplete options

- [ ] When using pd -a ref /full/path
  * Should we check to make sure that the target path exists?
  * If we check and the target does not exist, we should prompt the user if they want to add the
    reference anyway.
  * If the user can add a non-existent target, we should have a -f|--force flag that allows the user to
    execute commands that would require user interaction without any user interaction, assuming the
    answer is "yes".


