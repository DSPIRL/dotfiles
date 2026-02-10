# Commands

|   modstat |   Displays mode decimal of stdin file     |

# Scopes

|   Scope   |   Description                     |
|   User    |   The owner of the file           |
|   Group   |   Has one of more members         |
|   Other   |   The category for everyone else  |

# Permissions

|   Permission          |   Description |
|   r (read)            |   For a normal file, this allows a user to view the contents of the file. For a directory, it allows a user to view the names of files in the directory.  |
|   w (write)           |   For a normal file, this allows a user to modify and delete the file. For a directory, it allows a user to create, rename, and delete files inthe directory. |
|   x (execute)         |   For a normal file, this allows a user to execute the file if the user also has read permissions on it. For a directory, it allows a user to access file information in the directory, effectively permitting them to change into it (cd) or list its contents (ls). |
|   s                   |   is the setuid/setgid permission applied to an executable file. A user running it inherits the effective privileges of the owner or group of the file.   |
|   t                   |   is the sticky bit, which is only relevant for directories. If set, it prevents nonroot users from deleting files in it, unless said user owns the directory/file.   |
|   See also, chattr    |   Change attribute    |

# Decimal permissions

|Pattern    |   Decimal representation  |
|   0       |   ---                     |
|   1       |   --x                     |
|   2       |   -w-                     |
|   3       |   -wx                     |
|   4       |   r--                     |
|   5       |   r-x                     |
|   6       |   rw-                     |
|   7       |   rwx                     |

# Shell conditionals

## File test operators for conditional checks

-f: File exists and is a regular file
-d: File exists and is a directory
-e: File exists (any type)
-r: File exists and is readable
-w: File exists and is writable
-x: File exists and is executable
-s: File exists and has size greater than zero
-L: File exists and is a symbolic link
-b: File is a block special device
-c: File is a character special device
String test operators:

-z: String length is zero
-n: String length is non-zero
= or ==: Strings are equal
!=: Strings are not equal
Numeric comparison operators:

-eq: Equal to
-ne: Not equal to
-lt: Less than
-gt: Greater than
-le: Less than or equal to
-ge: Greater than or equal to
Logical operators:

!: Logical NOT
&&: Logical AND
||: Logical OR

These operators are commonly used in conditional expressions like if, while, and test constructs (test, [ ], or [[ ]]).

## Legacy shell

If using [ ], -a and -o are used for logical AND/OR operators.The differences between [ ] (single brackets) and [[ ]] (double brackets) are significant:

[ ] (Single brackets)

A regular command/program (equivalent to the test command)
POSIX-compliant and works in virtually all shells
Requires careful quoting of variables to prevent word splitting
Uses -a for AND and -o for OR
Limited pattern matching capabilities
More prone to errors with empty variables
[[ ]] (Double brackets)

A shell keyword (Bash, Zsh, Ksh specific)
Not available in all POSIX-compliant shells
Prevents word splitting and pathname expansion automatically
Uses && for AND and || for OR
Supports pattern matching with wildcards
Handles empty variables more safely
Allows use of == for string comparison
Supports regex matching with =~ operator

Example comparison:

```sh

# Single brackets (less safe)
if [ -f "$file" -a "$var" = "value" ]; then

# Double brackets (safer, more powerful)
if [[ -f $file && $var == value ]]; then
```

Double brackets are generally preferred in modern shell scripts when portability isn't a concern, as they provide more features and are less error-prone.

## VIM Remote Editing

Mounting the remote folder as a file-system using `sshfs`. To do this, first some pre-requisites:

- Issue all these cmds on local machine

```sh
sudo apt-get install sshfs
sudo adduser <username> fuse #Not required for new Linux versions (including Ubuntu > 18.04)
```

Now, do the mounting process:

```sh
mkdir ~/remoteserv
sshfs -o idmap=user <username>@<ipaddress>:/remotepath ~/remoteserv
```

After this, just go into the mounted folder and use your own local customized vim.
