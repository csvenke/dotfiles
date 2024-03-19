case $- in
*i*) ;;
*) return ;;
esac

source_if_exists() {
	if test -r "$1"; then
		source "$1"
	fi
}

export OSH="$HOME/.oh-my-bash"
export OSH_THEME="robbyrussell"
export OMB_USE_SUDO=true
export DOTFILES="$HOME/.dotfiles"
export DOTFLAKES="$HOME/.dotfiles/flakes"
export EDITOR="vim"

alias src='source ~/.bashrc'

source_if_exists $OSH/oh-my-bash.sh
source_if_exists $DOTFILES/.bashrc.fzf.sh
source_if_exists $DOTFILES/.bashrc.git.sh
source_if_exists $DOTFILES/.bashrc.direnv.sh
source_if_exists $HOME/.bashrc.secrets.sh
