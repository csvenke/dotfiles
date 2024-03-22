case $- in
*i*) ;;
*) return ;;
esac

source_if_exists() {
	if test -r "$1"; then
		source "$1"
	fi
}

export OSH="$(oh-my-bash)"
export OSH_THEME="robbyrussell"
export OMB_USE_SUDO=true
export DOTFILES="$HOME/.dotfiles"
export DOTFLAKES="$HOME/.dotfiles/flakes"
export EDITOR="nvim --clean"

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles/"
alias vim="nvim --clean"

source_if_exists $OSH/oh-my-bash.sh
source_if_exists $DOTFILES/.bashrc.fzf.sh
source_if_exists $DOTFILES/.bashrc.git.sh
source_if_exists $DOTFILES/.bashrc.direnv.sh
source_if_exists $HOME/.bashrc.secrets.sh
