# Nushell env.nu - runs before config.nu
# Generate cache files here so they exist when config.nu is parsed

# Oh-my-posh cache (must exist before prompt.nu is sourced)
let omp_cache = $"($env.HOME)/.cache/oh-my-posh.nu"
let omp_config = $"($env.HOME)/.config/oh-my-posh/default.omp.json"
if (which oh-my-posh | is-not-empty) and ($omp_config | path exists) {
    if (not ($omp_cache | path exists)) or ((ls $omp_config).0.modified > (ls $omp_cache).0.modified) {
        oh-my-posh init nu --config $omp_config --print | save --force $omp_cache
    }
}

# Carapace cache (must exist before config.nu sources it)
if (which carapace | is-not-empty) {
    let carapace_cache = $"($env.HOME)/.cache/carapace/init.nu"
    if not ($carapace_cache | path exists) {
        mkdir ($carapace_cache | path dirname)
        carapace _carapace nushell | save --force $carapace_cache
    }
}

# Zoxide cache (must exist before config.nu sources it)
if (which zoxide | is-not-empty) {
    let zoxide_cache = $"($env.HOME)/.zoxide.nu"
    if not ($zoxide_cache | path exists) {
        zoxide init nushell | save --force $zoxide_cache
    }
}
