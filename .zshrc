eval "$(direnv hook zsh)"

export DIRENV_LOG_FORMAT=
export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="$HOME/.config"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

if [ -z "$TMUX" ]; then
  tmux attach-session -t main || tmux new-session -s main -n main -d
  tmux attach-session -t main
  exit
fi

