##### CORE #####
alias core-ls = ls
alias core-cd = cd

##### CUSTOM REDEFINITIONS #####
def ls [] {
    core-ls -la | select name type mode user group size modified
}

# Use zoxide's z if available, otherwise fall back to core cd
def --env cd [path?: string] {
    if (which z | is-not-empty) {
        if ($path == null) { z ~ } else { z $path }
    } else {
        if ($path == null) { core-cd ~ } else { core-cd $path }
    }
}

##### TESTING #####
alias modhelp = cat ~/.local/share/chezmoi/shell/manpages/help_chmod.md

def greet [...names] {
    $names | each {
        |el|
        (echo $"Hello ($el)")
    }
}

##### ALIAS #####
alias cls = clear
alias l = eza -lhAF --color=auto --icons=always
alias exifall = exiftool -all=
alias exifkeepicc = exiftool -all= --icc_profile:all
alias safe-claude = claude
alias claude = claude --allow-dangerously-skip-permissions

alias vim = nvim
alias nv = nvim
alias n = nvim
alias se = sudoedit

alias k = kubectl
alias p = podman
alias pc = podman-compose

alias d = docker
alias dc = docker compose

alias mac-kanata = nu ~/.config/nushell/scripts/mac-kanata.nu

alias modstat = nu ~/.config/nushell/scripts/modstat.nu
alias flatpak-alias = nu ~/.config/nushell/scripts/flatpak-alias.nu

alias glols = git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat
