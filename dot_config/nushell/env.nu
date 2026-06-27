# Nushell env.nu - runs before config.nu
# Generate cache files here so they exist when config.nu is parsed

# Oh-my-posh cache (must exist before prompt.nu is sourced)
let omp_cache = $"($env.HOME)/.cache/oh-my-posh.nu"
let omp_cache_dir = $"($env.HOME)/.cache/oh-my-posh"
let omp_config = $"($env.HOME)/.config/oh-my-posh/wallust.omp.json"
let omp_binary = (which oh-my-posh | get path.0?)
if ($omp_binary | is-not-empty) and ($omp_config | path exists) {
  mut refresh_omp_cache = not ($omp_cache | path exists)

  if (not $refresh_omp_cache) and ((ls $omp_config).0.modified > (ls $omp_cache).0.modified) {
    $refresh_omp_cache = true
  }

  if (not $refresh_omp_cache) and ((ls $omp_binary).0.modified > (ls $omp_cache).0.modified) {
    $refresh_omp_cache = true
  }

  if not $refresh_omp_cache {
    let cached_executable = (
      open $omp_cache
      | lines
      | where $it =~ '^let _omp_executable: string = '
      | first 1
      | parse 'let _omp_executable: string = (echo "{path}")'
      | get path.0?
    )

    if ($cached_executable | is-empty) or (not ($cached_executable | path exists)) {
      $refresh_omp_cache = true
    }
  }

  if not $refresh_omp_cache {
    let session_id = (
      open $omp_cache
      | lines
      | where $it =~ '^\$env\.POSH_SESSION_ID = '
      | first 1
      | parse '$env.POSH_SESSION_ID = "{id}"'
      | get id.0?
    )
    let session_cache = $"($omp_cache_dir)/nu.($session_id).omp.cache"

    if ($session_id | is-empty) or (not ($session_cache | path exists)) {
      $refresh_omp_cache = true
    }
  }

  if $refresh_omp_cache {
    mkdir ($omp_cache | path dirname)
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

# MISE-EN-PLACE
if (which mise | is-not-empty) {
  let mise_dir = $"($env.HOME)/.cache/nushell"
  if (not ($mise_dir | path exists)) {
    mkdir $mise_dir
  }

  let mise_activation = $"($env.HOME)/.cache/nushell/mise.nu"
  if (not ($mise_activation | path exists)) {
    mise activate nu --shims | save --force $mise_activation
  }
}

# WORKTRUNK
if (which wt | is-not-empty) {
  let worktrunk_dir = $"($env.HOME)/.cache/nushell"
  if (not ($worktrunk_dir | path exists)) {
    mkdir $worktrunk_dir
  }

  let worktrunk_integration = $"($env.HOME)/.cache/nushell/mise.nu"
  if (not ($worktrunk_integration | path exists)) {
    wt config shell init nu | save --force $worktrunk_integration
  }
}
