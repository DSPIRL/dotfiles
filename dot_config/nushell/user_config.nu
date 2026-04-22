# Nushell PATH Configuration

# Helper to add paths (checks existence before adding)
def --env add-path [path: string, --prepend] {
    let expanded = ($path | path expand)
    if ($expanded | path exists) {
        if $prepend {
            $env.PATH = ($env.PATH | prepend $expanded)
        } else {
            $env.PATH = ($env.PATH | append $expanded)
        }
    }
}

##### PLATFORM-SPECIFIC #####
if ((sys host | get name | str contains --ignore-case "Linux")) {
    $env.VISUAL = "/usr/bin/nvim"

    ##### SSH AUTH SOCKET (Linux) #####
    $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent.socket"

    # DOTNET
    if ($"($env.HOME)/.dotnet" | path exists) {
        $env.DOTNET_ROOT = "/usr/local/share/dotnet"
        add-path $env.DOTNET_ROOT
        add-path $"($env.HOME)/.dotnet/tools"
    }

    # EMACS
    add-path $"($env.HOME)/.config/emacs/bin" --prepend

    # XDG
    $env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
    $env.XDG_DATA_DIRS = $"($env.HOME)/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"

} else if ((sys host | get name | str contains --ignore-case "Darwin")) {
    $env.VISUAL = "/opt/homebrew/bin/nvim"
    $env.config.buffer_editor = "/opt/homebrew/bin/nvim"
}

##### GLOBAL #####
$env.MANPAGER = "nvim +Man!"

add-path $"($env.HOME)/.local/bin" --prepend
add-path $"($env.HOME)/.local/scripts" --prepend

# RUST
if ($"($env.HOME)/.cargo" | path exists) {
    $env.CARGO_HOME = $"($env.HOME)/.cargo"
    add-path $"($env.CARGO_HOME)/bin" --prepend
}

# FZF
if (which fzf | is-not-empty) {
  $env.FZF_DEFAULT_OPTS_FILE = $"($env.HOME)/.config/fzf/.fzfrc"
  # $env.FZF_DEFAULT_OPTS = "--style full --height 80% --popup center,40% --layout reverse --border top --extended --multi --preview 'cat {}'"
  $env.FZF_CTRL_T_OPTS = "--preview='less {}' --bind shift-up:preview-page-up,shift-down:preview-page-down"
  $env.FZF_CTRL_T_COMMAND = "fd --hidden --ignore-case"
  # $env.FZF_ALT_C_COMMAND = ""
}

# MISE-EN-PLACE
if (which mise | is-not-empty) {
  let mise_activation = $"($env.HOME)/.cache/nushell/mise.nu"
  if (not ($mise_activation | path exists)) {
    mise activate nu | save -f ~/.cache/nushell/mise.nu
  }
}

