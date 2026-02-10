##### SYSTEM #####
alias l='command ls --color=auto'
alias grep='grep --color=auto'
alias cls="clear"
alias modhelp="cat ${DOTS}/shell/manpages/help_chmod.md"
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
# alias sls="eza -lhAF --color=auto --icons=always -RTL"
if command -v eza >/dev/null 2>&1; then
  alias ls="eza -lhAF --color=auto --icons=always"
else
  alis ls="ls -lAFh --color=auto"
fi
if command -v zoxide >/dev/null 2>&1; then
  alias cd="z"
fi

if [ "$(uname -s)" = "Darwin" ]; then
  alias modstat='stat -f "File name: %N
File type: %HT%SY
Exec modes: %Sp
Hex values: %Lp"'
elif [[ "$(uname -s)" == "Linux" ]]; then
  alias modstat='stat -c "File name: %n
File type: %F -> %N
Exec modes: %A
Hex values: %a"'
fi

##### EXIFTOOL #####
if command -v exiftool >/dev/null 2>&1; then
  alias exifall="exiftool -all="
  alias exifkeepicc="exiftool -all= --icc_profile:all"
fi

##### EDITOR #####
alias nv="nvim"

##### CLAUDE #####
if command -v claude >/dev/null 2>&1; then
  alias safe-claude="claude"
  alias claude="claude --allow-dangerously-skip-permissions"
fi

##### GIT #####

##### CARGO #####
if [[ -d $HOME/.cargo ]]; then
  alias cr="cargo run"
  alias ct="cargo test"
  alias cb="cargo build"
fi

##### TMUX #####
alias tms="tmux new-session -d -s GoodSesh; tmux new-window -t GoodSesh::1 -n 'Terminal'; tmux new-window -t GoodSesh:2 -n 'Neovim'; tmux attach-session -t GoodSesh;"

##### EMACS #####
alias emacs="emacsclient -c -a 'emacs'"

if [[ "$(uname -s)" = "Darwin" ]]; then
  ##### PYTHON #####
  alias python="python3"
  alias pip="pip3"
  # alias pypy="pypy3.10"

  ##### RUBY #####
  alias ruby="/opt/homebrew/bin/ruby"
fi
