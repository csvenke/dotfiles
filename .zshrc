export DIRENV_LOG_FORMAT=
export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="$HOME/.config"
export DOTFILES="$HOME/.dotfiles"
export FLAKES="$DOTFILES/flakes"

ZSH_THEME="robbyrussell"

plugins=(direnv git)

source $ZSH/oh-my-zsh.sh

eval "$(fnm env --use-on-cd)"
