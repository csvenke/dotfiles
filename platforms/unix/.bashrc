source_if_exists() {
  if test -r "$1"; then
    source "$1"
  fi
}
commands_exist() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || return 1
  done
  return 0
}
git_current_branch() {
  git branch --show-current
}
git_main_branch() {
  git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}
git_all_branches() {
  git branch -a |
    sed "s@*@@g" |
    sed "s@ @@g" |
    sed "s@remotes/origin/@@g" |
    sed "s@HEAD->origin/$(git_main_branch)@@g" |
    sed "/^$/d" |
    sort |
    uniq
}

export DOTFILES="$HOME/.dotfiles"
export BASH_SILENCE_DEPRECATION_WARNING=1

alias src="source ~/.bashrc"
alias dot="cd ~/.dotfiles"

if commands_exist "nvim"; then
  export EDITOR="nvim --clean"
  export VISUAL="nvim"

  alias chatgpt='nvim -c GpChatNew'
fi

if commands_exist "eza"; then
  alias ls='command eza --icons --colour=auto --sort=type --group-directories-first'
  alias la='ls -a'
  alias ll='ls -al'
fi

if commands_exist "bat"; then
  alias cat='command bat --style=plain'
fi

if commands_exist "nix"; then
  alias flake-init="nix flake init -t github:csvenke/devenv"
fi

if commands_exist "git"; then
  alias gpc='command git push origin "$(git_current_branch)"'
  alias gsc='command git pull origin "$(git_current_branch)"'
  alias gsm='command git pull origin "$(git_main_branch)"'
  alias gcm='command git checkout "$(git_main_branch)"'
  alias ggpush="gpc"
  alias ggpull="gsc"

  if commands_exist "fzf"; then
    alias gcb='git_all_branches | fzf | xargs git checkout'
  fi

  if commands_exist "fzf" "xclip"; then
    alias gfb='git_all_branches | fzf | xclip -selection clipboard'
  fi
fi

if commands_exist "lazygit"; then
  alias gui='lazygit'
fi

if commands_exist "starship"; then
  eval "$(starship init bash)"
fi

if commands_exist "direnv"; then
  export DIRENV_LOG_FORMAT=
  export DIRENV_WARN_TIMEOUT=1m

  eval "$(direnv hook bash)"
fi

if commands_exist "fzf" "ag"; then
  export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
  export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

  eval "$(fzf --bash)"
fi

source_if_exists "$HOME/.bashrc.work.sh"
source_if_exists "$HOME/.bashrc.machine.sh"

if commands_exist "tmux" && [ -n "$PS1" ] && [ -z "$TMUX" ]; then
  tmux new-session -A -s main
fi
