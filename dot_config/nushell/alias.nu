##### CORE #####
alias core-ls = ls
alias core-cd = cd
alias core-vim = vim

##### CUSTOM REDEFINITIONS #####
def ls [] {
    core-ls -la | select name type mode user group size modified
}

alias cd = z


##### CUSTOM FUNCTIONS #####
#ef tms [] {
#   tmux new-session -d -s GoodSesh
#   tmux new-window -t GoodSesh:1 -n 'Terminal'
#   tmux new-window -t GoodSesh:2 -n 'Neovim'
#   tmux attach-session -t GoodSesh
#


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

alias kanata-restart = nu ~/.config/nushell/scripts/mac-kanata-restart.nu
alias kanata-start = nu ~/.config/nushell/scripts/mac-kanata-start.nu
alias kanata-stop = nu ~/.config/nushell/scripts/mac-kanata-stop.nu

alias modstat = nu ~/.config/nushell/scripts/modstat.nu
alias flatpak-alias = nu ~/.config/nushell/scripts/flatpak-alias.nu

#alias tmux-start = tmux new-session -d -s GoodSesh; tmux new-window -t GoodSesh::1 -n 'Terminal'; tmux new-window -t GoodSesh:2 -n 'Neovim'; tmux attach-session -t GoodSesh;

alias glols = git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat
