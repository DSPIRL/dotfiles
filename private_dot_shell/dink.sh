# dink - remote file sync utility
# Configure these in ~/.config/dink/hosts (one per line: user@host)
DINK_HOSTS=()
DINK_PATHS=()
DINK_COMMANDS=("sync" "dry" "hosts")

# Load hosts from config file if it exists
if [[ -f ~/.config/dink/hosts ]]; then
  while IFS= read -r line; do
    [[ -n "$line" && "$line" != \#* ]] && DINK_HOSTS+=("$line")
  done < ~/.config/dink/hosts
fi

# Load paths from config file if it exists
if [[ -f ~/.config/dink/paths ]]; then
  while IFS= read -r line; do
    [[ -n "$line" && "$line" != \#* ]] && DINK_PATHS+=("$line")
  done < ~/.config/dink/paths
fi

dink() {
  local cmd="$1"
  shift

  case "$cmd" in
  sync)
    if [ $# -ne 3 ]; then
      echo "Usage: dink sync <host> <remote_path> <local_dest>"
      return 1
    fi
    local host="$1"
    local remote_path="$2"
    local local_dest="$3"
    local escaped_path
    escaped_path=$(printf '%s' "$remote_path" | sed 's/[^a-zA-Z0-9/]/\\&/g')
    echo "Run this command:"
    echo "rsync -avhP --stats '$host:$escaped_path' '$local_dest'"
    ;;
  dry)
    if [ $# -ne 3 ]; then
      echo "Usage: dink dry <host> <remote_path> <local_dest>"
      return 1
    fi
    local host="$1"
    local remote_path="$2"
    local local_dest="$3"
    local escaped_path
    escaped_path=$(printf '%s' "$remote_path" | sed 's/[^a-zA-Z0-9/]/\\&/g')
    echo "Run this command (dry run):"
    echo "rsync -avhP --dry-run --stats '$host:$escaped_path' '$local_dest'"
    ;;
  hosts)
    echo "Available hosts:"
    printf "  %s\n" "${DINK_HOSTS[@]}"
    ;;
  *)
    echo "dink - remote file sync utility"
    echo ""
    echo "Usage: dink <command> [args]"
    echo ""
    echo "Commands:"
    echo "  sync <host> <remote_path> <local_dest>  Sync files from remote"
    echo "  dry  <host> <remote_path> <local_dest>  Dry run (preview changes)"
    echo "  hosts                                    List available hosts"
    return 1
    ;;
  esac
}

# Shell completion for dink (deferred to avoid autosuggestions conflict)
if [[ -n "$ZSH_VERSION" ]]; then
  dink_setup_completion() {
    _dink_complete() {
      case $CURRENT in
      2) compadd -- "${DINK_COMMANDS[@]}" ;;
      3)
        case "${words[2]}" in
        sync | dry) compadd -- "${DINK_HOSTS[@]}" ;;
        esac
        ;;
      4)
        case "${words[2]}" in
        sync | dry) compadd -- "${DINK_PATHS[@]}" ;;
        esac
        ;;
      5)
        case "${words[2]}" in
        sync | dry) _files -/ ;;
        esac
        ;;
      esac
    }
    compdef _dink_complete dink
    unfunction dink_setup_completion
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd dink_setup_completion
elif [[ -n "$BASH_VERSION" ]]; then
  _dink_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    case $COMP_CWORD in
    1) COMPREPLY=($(compgen -W "${DINK_COMMANDS[*]}" -- "$cur")) ;;
    2)
      case "${COMP_WORDS[1]}" in
      sync | dry) COMPREPLY=($(compgen -W "${DINK_HOSTS[*]}" -- "$cur")) ;;
      esac
      ;;
    3)
      case "${COMP_WORDS[1]}" in
      sync | dry) COMPREPLY=($(compgen -W "${DINK_PATHS[*]}" -- "$cur")) ;;
      esac
      ;;
    4)
      case "${COMP_WORDS[1]}" in
      sync | dry) COMPREPLY=($(compgen -d -- "$cur")) ;;
      esac
      ;;
    esac
  }
  complete -F _dink_complete dink
fi
