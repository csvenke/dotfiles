{ pkgs }:

let
  configure-tmux = pkgs.writeShellScript "configure-tmux.bash" ''
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
    tmux run-shell '${pkgs.tmuxPlugins.catppuccin.rtp}'
    tmux run-shell '${pkgs.tmuxPlugins.yank.rtp}'

    # set vi-mode
    tmux set-window-option -g mode-keys vi

    tmux bind-key -T copy-mode-vi v send-keys -X begin-selection
    tmux bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    tmux bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

    tmux set -g @catppuccin_window_right_separator "█ "

    tmux bind '-' split-window -v -c "#{pane_current_path}"
    tmux bind 's' split-window -v -c "#{pane_current_path}"

    tmux bind '|' split-window -h -c "#{pane_current_path}"
    tmux bind 'v' split-window -h -c "#{pane_current_path}"

    tmux bind 'p' run-shell "tmux popup -d '#{pane_current_path}' -E 'tmux attach -t popup || tmux new -s popup'"
    tmux bind 'q' run-shell "tmux detach-client"

    # '@pane-is-vim' is a pane-local option that is set by the plugin on load,
    # and unset when Neovim exits or suspends; note that this means you'll probably
    # not want to lazy-load smart-splits.nvim, as the variable won't be set until
    # the plugin is loaded
    # Smart pane switching with awareness of Neovim splits.
    tmux bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
    tmux bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
    tmux bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
    tmux bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'

    # Smart pane resizing with awareness of Neovim splits.
    tmux bind-key -n M-h if -F "#{@pane-is-vim}" 'send-keys M-h' 'resize-pane -L 3'
    tmux bind-key -n M-j if -F "#{@pane-is-vim}" 'send-keys M-j' 'resize-pane -D 3'
    tmux bind-key -n M-k if -F "#{@pane-is-vim}" 'send-keys M-k' 'resize-pane -U 3'
    tmux bind-key -n M-l if -F "#{@pane-is-vim}" 'send-keys M-l' 'resize-pane -R 3'

    tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
    tmux if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    		"bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\'  'select-pane -l'"
    tmux if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    		"bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\\\'  'select-pane -l'"

    tmux bind-key -T copy-mode-vi 'C-h' select-pane -L
    tmux bind-key -T copy-mode-vi 'C-j' select-pane -D
    tmux bind-key -T copy-mode-vi 'C-k' select-pane -U
    tmux bind-key -T copy-mode-vi 'C-l' select-pane -R
  '';

  tmuxConf = pkgs.writeTextFile {
    name = "tmux.conf";
    text = /* tmux */ ''
      run-shell ${configure-tmux}
    '';
  };
in


pkgs.tmux.overrideAttrs (oldAttrs: {
  buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postInstall = oldAttrs.postInstall + /* bash */ ''
    mkdir $out/libexec
    mv $out/bin/tmux $out/libexec/tmux-unwrapped
    makeWrapper $out/libexec/tmux-unwrapped $out/bin/tmux \
      --add-flags "-f ${tmuxConf}"
  '';
})


