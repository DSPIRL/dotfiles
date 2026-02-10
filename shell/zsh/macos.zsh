##### JAVA #####
# For most things use this one below
# export JAVA_HOME="$HOME/Library/Java/JavaVirtualMachines/openjdk-22.0.2/Contents/Home"

# For Rust Tauri Dev use the below
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export NDK_HOME="${ANDROID_HOME}/ndk/$(command ls -1 ${ANDROID_HOME}/ndk)"

##### PATH #####
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.local/scripts:${PATH}"
export PATH="${HOME}/development/flutter/bin:${PATH}"
export PATH="${HOME}/fvm/default/bin:${PATH}"
export PATH="/opt/homebrew/opt/ruby/bin:${PATH}"
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:${PATH}"
export PATH="${JAVA_HOME}/bin:${PATH}"
export GEM_HOME=$HOME/.gem

##### DOTNET #####
if [[ $(command ls -A | grep ".dotnet") ]]; then
  export DOTNET_ROOT="/opt/homebrew/bin"
  export PATH="${PATH}:${DOTNET_ROOT}:${HOME}/.dotnet/tools"
fi

##### NVM #####
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh" # This loads nvm

[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion

##### DART #####
## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f $HOME/.config/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.config/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

##### ZSH #####
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source /opt/homebrew/share/zsh-completions/zsh-completions.zsh
# History setup 
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

