##### PATH #####
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/scripts:$PATH"

##### JAVA #####
export JAVA_HOME=/opt/android-studio/jbr
export ANDROID_HOME="$HOME/Android/Sdk"
# export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"

##### EMACS #####
[[ -d ~/.config/emacs/bin ]] && export PATH="$HOME/.config/emacs/bin:$PATH"


##### DOTNET #####
if [[ $(ls -lAFh | grep ".dotnet") ]]; then
  export DOTNET_ROOT="/usr/local/share/dotnet"
  export PATH="$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools"
fi

##### ZSH #####
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# History setup 
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

##### SYNCTHING #####
if [[ -f /usr/bin/syncthing && "$hostOS" == "$linux" ]]; then
  autoload -U +X bashcompinit && bashcompinit;
  complete -C /usr/bin/syncthing syncthing;
fi
