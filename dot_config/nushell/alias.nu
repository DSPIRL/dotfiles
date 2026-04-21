##### CORE #####
alias core-ls = ls
alias core-cd = cd

##### CUSTOM REDEFINITIONS #####
def --wrapped ls [...rest] {
    let listing = if ($rest | is-empty) {
        core-ls -la
    } else {
        core-ls ...$rest
    }
    let preferred_columns = [name type mode user group size modified]
    let available_columns = if ($listing | is-empty) {
        []
    } else {
        $listing | columns | where {|column| $column in $preferred_columns }
    }

    if ($available_columns | is-empty) {
        $listing
    } else {
        $listing | select ...$available_columns
    }
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

# Command wrappers with runtime checks

def --wrapped l [...rest] {
    if (which eza | is-not-empty) {
        ^eza -lhAF --color=auto --icons=always ...$rest
    } else {
        ^ls ...$rest
    }
}

def --wrapped exifall [...rest] {
    if (which exiftool | is-not-empty) {
        ^exiftool -all= ...$rest
    } else {
        error make { msg: "exiftool is not installed" }
    }
}

def --wrapped exifkeepicc [...rest] {
    if (which exiftool | is-not-empty) {
        ^exiftool -all= --icc_profile:all ...$rest
    } else {
        error make { msg: "exiftool is not installed" }
    }
}

def --wrapped claude-unsafe [...rest] {
    if (which claude | is-not-empty) {
        ^claude --allow-dangerously-skip-permissions ...$rest
    } else {
        error make { msg: "claude is not installed" }
    }
}

def --wrapped okta [...rest] {
    if (which okta-aws-cli | is-not-empty) {
        ^okta-aws-cli ...$rest
    } else {
        error make { msg: "claude is not installed" }
    }
}

def --wrapped vim [...rest] {
    if (which nvim | is-not-empty) {
        ^nvim ...$rest
    } else {
        error make { msg: "nvim is not installed" }
    }
}

def --wrapped nv [...rest] {
    if (which nvim | is-not-empty) {
        ^nvim ...$rest
    } else {
        error make { msg: "nvim is not installed" }
    }
}

def --wrapped n [...rest] {
    if (which nvim | is-not-empty) {
        ^nvim ...$rest
    } else {
        error make { msg: "nvim is not installed" }
    }
}

def --wrapped se [...rest] {
    if (which sudoedit | is-not-empty) {
        ^sudoedit ...$rest
    } else {
        error make { msg: "sudoedit is not installed" }
    }
}

def --wrapped k [...rest] {
    if (which kubectl | is-not-empty) {
        ^kubectl ...$rest
    } else {
        error make { msg: "kubectl is not installed" }
    }
}

def --wrapped p [...rest] {
    if (which podman | is-not-empty) {
        ^podman ...$rest
    } else {
        error make { msg: "podman is not installed" }
    }
}

def --wrapped pc [...rest] {
    if (which podman-compose | is-not-empty) {
        ^podman-compose ...$rest
    } else {
        error make { msg: "podman-compose is not installed" }
    }
}

def --wrapped d [...rest] {
    if (which docker | is-not-empty) {
        ^docker ...$rest
    } else {
        error make { msg: "docker is not installed" }
    }
}

def --wrapped dc [...rest] {
    if (which docker | is-not-empty) {
        ^docker compose ...$rest
    } else {
        error make { msg: "docker is not installed" }
    }
}

def --wrapped glols [...rest] {
    if (which git | is-not-empty) {
        ^git log --graph '--pretty=%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat ...$rest
    } else {
        error make { msg: "git is not installed" }
    }
}

alias mac-kanata = nu ~/.config/nushell/scripts/mac-kanata.nu
alias modstat = nu ~/.config/nushell/scripts/modstat.nu
alias flatpak-alias = nu ~/.config/nushell/scripts/flatpak-alias.nu
