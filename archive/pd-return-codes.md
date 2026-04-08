# Park Directories Return Codes

| Return Code | Action | Meaning |
| ----------- | ------ | ------- |
| 10 | Any | Could not create data file |
| 11 | Any | Could not set data file permissions to 660 |
| 20 | Add | Reference name contains '/' or '-' |
| 21 | Add | Failed to append mapping to data file |
| 22 | Add | Not enough arguments |
| 30 | Delete | Failed to remove mapping from data file using sed |
| 31 | Delete | Not enough arguments |
| 40 | List | Failed to cat data file |
| 50 | Clear | Failed to empty data file |
| 60 | Import | Failed to empty data file |
| 61 | Import | Not enough arguments |
| 62 | Import | Failed to backup data file before import |
| 63 | Import | Failed to empty data file before import |
| 64 | Import | Failed to add mapping to data file |
| 65 | Import | Bad file path |
| 70 | Export | Failed to export data from data file to destination file |
| 71 | Export | Not a valid target file path |
| 80 | Navigate | Failed to change directory to target |

