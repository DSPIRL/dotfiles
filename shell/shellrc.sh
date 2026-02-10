export XDG_CONFIG_HOME="${HOME}/.config"

if [[ $(uname -s) = "Linux" ]]; then
  export XDG_DATA_DIRS
  XDG_DATA_DIRS="${new_dirs:+${new_dirs}:}${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
fi

##### RUST #####
if [[ -d $HOME/.cargo ]]; then
  . "${HOME}/.cargo/env"
  export CARGO_HOME="${HOME}/.cargo"
  export PATH="$CARGO_HOME/bin:$PATH"
fi

##### LM STUDIO #####
if [[ -d $HOME/.lmstudio ]]; then export PATH="$PATH:$HOME/.lmstudio/bin"; fi

##### ALIASES #####
source "${DOTS_SHELL}/aliases.sh"

##### FUNCTIONS #####
source "${DOTS_SHELL}/custom_functions.sh"

##### BUN #####
# bun completions
[ -s "${HOME}.bun/_bun" ] && source "${HOME}/.bun/_bun"
# bun
export BUN_INSTALL="${HOME}/.bun"
export PATH="${BUN_INSTALL}/bin:${PATH}"

##### EMACS #####
[[ -d ~/.config/emacs/bin ]] && export PATH="${HOME}/.config/emacs/bin:${PATH}"

##### CUSTOM ENVIRONMENT VARIABLES #####
export USER_TERMINAL=alacritty
export NVIM_PATH=$(which nvim)

##### SYSTEM ENVIRONMENT VARIABLES #####
export VISUAL=$NVIM_PATH
export EDITOR=$NVIM_PATH
