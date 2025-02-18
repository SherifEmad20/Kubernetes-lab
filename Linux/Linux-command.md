# Linux Commands Guide

## Chapter 2

### Terminal Management
- `tty` → Shows how many terminals are open

### User Management
- `passwd` → Changes the user password
- `passwd <username>` → Changes the password for the specified user

### Command Location
- `which <command>` → Tells where the command is located in the directories

### File Content Analysis
- `wc <file>` → Prints the number of lines (-l), words (-w), and characters (-c) in a file
- `head <file> -<num>` → Prints the first 10 lines by default; `-num` specifies a different number
- `tail <file> -<num>` → Prints the last 10 lines by default; `-num` specifies a different number

### File Editing
- `nano <file>` → Edits a file using Nano editor

### Command History
- `history` → Prints the command history
- `cat <file>` → Prints file contents

### Command Help
- `<command> --help` → Displays instructions for the command

### Networking
- `ip addr` → Displays the IP address for localhost

### File Type Identification
- `file <file>` → Displays the type of content in a given file

---

## Chapter 3

### Directory and File Management
- `pwd` → Shows the current path
- `ls` → Lists files in the directory
- `mkdir <dir>` → Creates a new directory
- `rmdir <dir>` → Removes a directory
- `touch <file>` → Creates a new file
- `rm <file>` → Removes a file
- `touch file{1..6}` → Creates six files (file1 to file6)
- `cd <dir>` → Changes the directory
- `cp <src> <dest>` → Copies a file or directory
- `mv <src> <dest>` → Moves a file or directory
- `ln <file>` → Creates a hard link to a file

---

## Chapter 4

### Manual Pages
- `man <command>` → Displays detailed instructions for a command
- `file <file>` → Shows the type of a file

---

## Chapter 5

### Vim Editor
- `vim <file>` → Opens a file in Vim
- `i` → Insert mode
- `shift+V` → Visual line mode
- `v` → Visual mode
- `ctrl+v` → Visual block mode
- `esc + :wq` → Save and exit
- `esc + :w` → Save
- `esc + :q` → Exit without saving

### Redirection and Pipelines
- `echo "message"` → Prints a message on the screen
- `command | tee <file>` → Outputs to a file and prints on the screen
- `command > <file>` → Redirects output to a file
- `command 2> <file>` → Redirects errors to a file

---

## Chapter 6

### User and Group Management
- `id` → Gets UID, GID, and groups of the current user
- `useradd <username>` → Adds a new user
- `userdel -r <username>` → Deletes a user
- `groupadd <groupname>` → Creates a new group
- `groupdel <groupname>` → Deletes a group
- `sudo <command>` → Runs a command with root permissions
- `su <username>` → Switches to another user
- `less <file>` → Shows the content of a file page by page

### Superuser Privileges
- `vim /etc/sudoers.d/<username>` → Grants superuser privileges
- `sudo vim /etc/login.defs` → Modifies user and group security policies

---

## Chapter 7

### File and Directory Permissions
- `chown <user> <file>` → Changes the ownership of a file
- `chown :<group>` → Changes the group ownership
- `ls -l` → Displays file permissions
- `chmod u+rwx <file>` → Grants owner read, write, execute permissions
- `chmod 755 <file>` → Sets permissions (Owner: rwx, Group: r-x, Others: r-x)
- `umask` → Shows default file permissions

---

## Chapter 8

### Process Management
- `top` → Shows running processes
- `ps aux` → Lists all running processes
- `pkill -SIGSTOP <process>` → Suspends a process
- `pkill -SIGCONT <process>` → Resumes a process
- `pkill <process>` → Terminates a process
- `kill <PID>` → Kills a process by ID
- `netstat -nlp | grep :<port>` → Finds the process using a specific port

---

## Chapter 9

### Service Management
- `systemctl list-units` → Lists active system units
- `systemctl status <service>` → Shows service status
- `systemctl start <service>` → Starts a service
- `systemctl stop <service>` → Stops a service
- `systemctl restart <service>` → Restarts a service
- `systemctl enable <service>` → Enables service auto-start
- `systemctl disable <service>` → Disables service auto-start

---

## Chapter 10

### SSH Commands
- `ssh <user>@<server>` → Connects to a remote server
- `ssh-keygen` → Generates SSH keys
- `ssh-copy-id -i ~/.ssh/key.pub <user>@<host>` → Copies the SSH key to a remote system

---

## Chapter 11

### Logging and Debugging
- `logger -p <file> "message"` → Sends a log message
- `journalctl -n <num>` → Shows the last `num` log entries
- `journalctl --since today` → Lists logs from today
- `journalctl -f` → Displays live logs

---

## Chapter 12

### Network Management
- `ip link` → Shows network settings
- `ip addr` → Shows machine IP address
- `ping -c3 <address>` → Verifies network connectivity
- `tracepath <address>` → Traces hops between machines
- `hostnamectl set-hostname <name>` → Sets a new hostname

---

## Chapter 13

### File Archiving and Synchronization
- `tar -czf /tmp/etc.tar.gz /etc` → Creates a compressed archive
- `scp -r <user>@<server>:/path ~/backup` → Copies files from a remote server
- `rsync -av <user>@<server>:/path ~/backup` → Synchronizes directories

---

## Chapter 14

### Package Management
- `rpm -q <package>` → Queries installed packages
- `yum list` → Lists available packages
- `yum search <keyword>` → Searches for packages
- `yum install <package>` → Installs a package
- `yum remove <package>` → Removes a package

---

## Chapter 15

### Disk and Storage Management
- `df -h` → Shows disk usage in human-readable format
- `du -h` → Shows disk usage per file/folder
- `mount /dev/<device> /mnt` → Mounts a filesystem
- `umount /mnt` → Unmounts a filesystem

---

### Script Execution
- `chmod +x <script.sh>` → Makes a script executable
- `./<script.sh>` → Executes a script

---

### System Logs
- `/var/log` → System log directory
- `echo $?` → Checks the exit status of the last executed command

---

This Markdown file provides a structured guide to essential Linux commands.
