if ((sys host | get name | str contains --ignore-case "Linux")) {
##### LINUX #####
    # EDITOR #
    $env.VISUAL = "/usr/bin/nvim"

    # C# PATH #
    if ("~/.dotnet" | path exists) {
        $env.DOTNET_ROOT = "/usr/local/share/dotnet"
        load-env {
            "PATH": ($env.PATH | append $env.DOTNET_ROOT | append $"($env.HOME)/.dotnet/tools")
        }
    }

    # EMACS #
    if ("~/.config/emacs/bin" | path exists) {
        $env.PATH = ($env.PATH | prepend $"($env.HOME)/.config/emacs/bin")
    }

    # XDG #
    $env.XDG_CONFIG_HOME = $"($env.HOME)/.config"

    $env.XDG_DATA_DIRS = $"($env.HOME)/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
} else if ((sys host | get name | str contains --ignore-case "Darwin")) {
##### MACOS #####
    $env.VISUAL = "/opt/homebrew/bin/nvim"
    $env.config.buffer_editor = "/opt/homebrew/bin/nvim"

}


##### GLOBAL #####
# MANPAGER #
$env.MANPAGER = "nvim +Man!"

# PATH + VARS #
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/scripts")

# RUST PATH #
if ("~/.cargo" | path exists) {
    $env.CARGO_HOME = $"($env.HOME)/.cargo"
    load-env {
        "PATH": ($env.PATH | prepend $"($env.CARGO_HOME)/bin")
    }
}
