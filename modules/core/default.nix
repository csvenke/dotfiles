{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    inputs.neovim.overlays.default
  ];

  home.packages = [
    pkgs.findutils
    pkgs.fd
    pkgs.ripgrep
    pkgs.jq
    pkgs.tldr
    pkgs.wget
    pkgs.curl
    pkgs.fzf
    pkgs.xclip
    pkgs.eza
    pkgs.bat
    pkgs.htop
    pkgs.neovim
  ];

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    bash = {
      enable = true;
      bashrcExtra = lib.readFile ./config/.bashrc;
      initExtra =
        # bash
        ''
          if [ -n "$PS1" ] && [ -z "$TMUX" ]; then
            tmux new -A -s main
          fi
        '';
    };

    tmux = {
      enable = true;
      plugins = [
        pkgs.tmuxPlugins.sensible
        pkgs.tmuxPlugins.yank
        {
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig =
            # tmux
            ''
              set -g @catppuccin_window_right_separator "█ "
            '';
        }
      ];
      extraConfig = lib.readFile ./config/tmux.conf;
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        command_timeout = 3000;
        package = {
          disabled = true;
        };
      };
    };

    git = {
      enable = true;
      userName = "csvenke";
      userEmail = "csvenke@users.noreply.github.com";
      extraConfig = {
        pull.rebase = true;
        rebase.autoStash = true;
      };
      ignores = [
        ".direnv"
        ".envrc"
        ".neoconf.json"
        "neoconf.json"
        ".gp.md"
      ];
      delta.enable = true;
    };

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };

    lazygit = {
      enable = true;
      settings = {
        gui.showRandomTip = false;
        gui.showCommandLog = false;
        git.paging.pager = "delta --dark --paging=never";
      };
    };
  };
}
