{pkgs}: let
  tpmRepo = pkgs.stdenv.mkDerivation {
    name = "tmux plugin manager";
    src = builtins.fetchGit {
      url = "https://github.com/tmux-plugins/tpm";
      ref = "master";
      rev = "99469c4a9b1ccf77fade25842dc7bafbc8ce9946";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };
  tpmWrapper = pkgs.writeShellScriptBin "tpm" ''
    bash ${tpmRepo}/tpm
  '';
  tpmInstallWrapper = pkgs.writeShellScriptBin "tpm-install-plugins" ''
    bash ${tpmRepo}/scripts/install_plugins.sh
  '';

  ohMyBashRepo = pkgs.stdenv.mkDerivation {
    name = "oh my bash";
    src = builtins.fetchGit {
      url = "https://github.com/ohmybash/oh-my-bash";
      ref = "master";
      rev = "4c2afd012ae56a735f18a5f313a49da29b616998";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };

  nix-bashrc = pkgs.writeShellScriptBin "nix-bashrc" ''
    case $- in
      *i*) ;;
        *) return;;
    esac

    source_if_exists() {
    	if test -r "$1"; then
    		source "$1"
    	fi
    }

    export OSH="${ohMyBashRepo}"
    export OSH_THEME="robbyrussell"
    export OMB_USE_SUDO=true

    export DIRENV_LOG_FORMAT=
    export DIRENV_WARN_TIMEOUT=1m

    export FZF_DEFAULT_COMMAND='ag --hidden -l -g ""'
    export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

    export TPM="${tpmRepo}"
    export TPM_SCRIPTS="$TPM/scripts"

    export DOTFILES="$HOME/.dotfiles"
    export DOTFLAKES="$HOME/.dotfiles/flakes"
    export EDITOR="nvim --clean"

    alias src="source ~/.bashrc"
    alias dot="cd ~/.dotfiles/"
    alias vim="nvim --clean"
    alias ggpush='command git push origin "$(git_current_branch)"'
    alias ggpull='command git pull origin "$(git_current_branch)"'

    source_if_exists "$OSH/oh-my-bash.sh"
    source_if_exists "$(fzf-share)/key-bindings.bash"
    source_if_exists "$(fzf-share)/completion.bash"
    source_if_exists "$HOME/.bashrc.secrets.sh"

    eval "$(direnv hook bash)"
  '';
in
  pkgs.symlinkJoin {
    name = "configuration";
    paths = [
      tpmWrapper
      tpmInstallWrapper
      nix-bashrc
    ];
  }
