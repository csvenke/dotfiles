{ pkgs }:

let
  config = pkgs.writeTextFile {
    name = "tmux.conf";
    text = /* tmux */ ''
      # What the fuck Apple
      set -g default-terminal screen-256color

      # Let there be color
      set-option -sa terminal-overrides ",xterm*:Tc"

      # Evil mode
      set -g mouse on

      # Why isnt this default
      set -s escape-time 0
      set -g status-interval 0

      # Rebind prefix
      unbind C-b
      set -g prefix C-Space
      bind C-Space send-prefix

      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Start windows and panes at 1, not 0
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      run-shell '${pkgs.tmuxPlugins.sensible.rtp}'
      run-shell '${pkgs.tmuxPlugins.vim-tmux-navigator.rtp}'
      run-shell '${pkgs.tmuxPlugins.catppuccin.rtp}'
      run-shell '${pkgs.tmuxPlugins.yank.rtp}'

      # set vi-mode
      set-window-option -g mode-keys vi

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

      set -g @catppuccin_window_right_separator "█ "

      bind '-' split-window -v -c "#{pane_current_path}"
      bind '|' split-window -h -c "#{pane_current_path}"
    '';
  };
in


pkgs.tmux.overrideAttrs (oldAttrs: {
  buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postInstall = oldAttrs.postInstall + /* bash */ ''
    mkdir $out/libexec
    mv $out/bin/tmux $out/libexec/tmux-unwrapped
    makeWrapper $out/libexec/tmux-unwrapped $out/bin/tmux \
      --add-flags "-f ${config}"
  '';
})


