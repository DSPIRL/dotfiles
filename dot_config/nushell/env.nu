##### ZOXIDE #####
# zoxide init nushell | save -f ~/.zoxide.nu

##### CARAPACE #####
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu

##### CUSTOM ENVIRONMENT VARIABLES #####
$env.DOTS = $"($env.HOME)/.local/share/chezmoi"
$env.DOTS_CONFIG = $"($env.DOTS)/dot_config"
