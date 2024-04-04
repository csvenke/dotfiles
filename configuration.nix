{pkgs}: let
  tmux = pkgs.writeShellScriptBin "configure-tmux" ''
    # What the fuck Apple
    tmux set -g default-terminal screen-256color
    
    # Let there be color
    tmux set-option -sa terminal-overrides ",xterm*:Tc"

    # Evil mode
    tmux set -g mouse on

    # Why isnt this default
    tmux set -s escape-time 0
    tmux set -g status-interval 0

    # Rebind prefix
    tmux unbind C-b
    tmux set -g prefix C-Space
    tmux bind C-Space send-prefix

    # Vim style pane selection
    tmux bind h select-pane -L
    tmux bind j select-pane -D
    tmux bind k select-pane -U
    tmux bind l select-pane -R

    # Start windows and panes at 1, not 0
    tmux set -g base-index 1
    tmux set -g pane-base-index 1
    tmux set-window-option -g pane-base-index 1
    tmux set-option -g renumber-windows on

    tmux run-shell '${pkgs.tmuxPlugins.sensible.rtp}'
    tmux run-shell '${pkgs.tmuxPlugins.vim-tmux-navigator.rtp}'
    tmux run-shell '${pkgs.tmuxPlugins.catppuccin.rtp}'
    tmux run-shell '${pkgs.tmuxPlugins.yank.rtp}'

    # set vi-mode
    tmux set-window-option -g mode-keys vi

    tmux bind-key -T copy-mode-vi v send-keys -X begin-selection
    tmux bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    tmux bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

    tmux set -g @catppuccin_window_right_separator "█ "

    tmux bind '-' split-window -v -c "#{pane_current_path}"
    tmux bind '|' split-window -h -c "#{pane_current_path}"
  '';


  bash = pkgs.writeShellScriptBin "configure-bash" ''
    source_if_exists() {
    	if test -r "$1"; then
    		source "$1"
    	fi
    }
    git_current_branch() {
      git branch --show-current
    }
    git_main_branch() {
      git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
    }

    # What the fuck Apple
    export BASH_SILENCE_DEPRECATION_WARNING=1

    export DIRENV_LOG_FORMAT=
    export DIRENV_WARN_TIMEOUT=1m
    export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
    export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'
    export DOTFILES="$HOME/.dotfiles"
    export DOTFLAKES="$HOME/.dotfiles/flakes"
    export EDITOR="nvim --clean"

    alias src="source ~/.bashrc"
    alias dot="cd ~/.dotfiles/"
    alias vim="nvim --clean"
    alias ggpush='git push origin "$(git_current_branch)"'
    alias ggpull='git pull origin "$(git_current_branch)"'
    alias ggsync='git pull origin "$(git_main_branch)"'
    alias ls='eza --icons --colour=auto --sort=type --group-directories-first'
    alias la='ls -a'
    alias ll='ls -al'
    alias cat='bat --style=plain'

    source_if_exists "$HOME/.nix-profile/share/fzf/key-bindings.bash"
    source_if_exists "$HOME/.nix-profile/share/fzf/completion.bash"
    source_if_exists "$HOME/.bashrc.secrets.sh"

    eval "$(direnv hook bash)"
    eval "$(starship init bash)"
  '';
in
  pkgs.symlinkJoin {
    name = "configuration";
    paths = [
      tmux
      bash
    ];
  }
