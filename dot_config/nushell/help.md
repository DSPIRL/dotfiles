# Nushell setup
1. install Nushell.
2. install carapace from AUR
3. 

# Nushell Configuration
Files are loaded in the following order...
1. env.nu
2. config.nu
3. login.nu

Key differences:
config.nu: Primary file for all Nushell configurations, commands, and settings 
env.nu: Legacy file, best practice is to use config.nu instead 
login.nu: Only runs when Nushell starts as a login shell, primarily for setting environment variables that will be inherited by subshells and other processes 

Best Practices:
Put most configurations in config.nu
Use login.nu only for environment variables needed by other applications when Nushell is your login shell
Avoid using env.nu for new configurations (it's maintained for historical reasons) 

## config.nu (Primary configuration file):
```shell
# Main configuration settings
$env.config = {
    show_banner: false    # General Nushell settings
    shell_integration: true
    buffer_editor: "code" # Editor settings
}

# Custom commands, aliases, and general startup tasks
alias ll = ls -l
```


## env.nu (Historical/Legacy):
- Historically was used for environment variables
- Current best practice is to put all configurations in config.nu instead 
- Only loaded before config.nu for historical reasons 


## login.nu (Login shell specific):
```shell
# Environment variables needed by other applications
$env.LANG = "en_US.UTF-8"
$env.EDITOR = "vim"
$env.VISUAL = "code"

# System paths
$env.PATH = ($env.PATH | split row (char esep) | append "~/.local/bin")

# Application-specific variables
$env.CARGO_HOME = "~/.cargo"
```

