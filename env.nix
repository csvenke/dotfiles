let
  pkgs = import <nixpkgs> {};

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
in
  pkgs.buildEnv {
    name = "My default environment";
    paths = [
      pkgs.direnv
      pkgs.nix-direnv

      # Python
      pkgs.python3
      pkgs.python311Packages.pip

      # Node
      pkgs.fnm
      pkgs.bun
      pkgs.yarn
      pkgs.nodePackages.pnpm
      pkgs.nodePackages.prettier

      # Neovim
      pkgs.coreutils
      pkgs.tree-sitter
      pkgs.alejandra
      pkgs.cargo
      pkgs.gcc
      pkgs.unzip
      pkgs.gzip
      pkgs.fd
      pkgs.ripgrep
      pkgs.curl
      pkgs.wget
      pkgs.git
      pkgs.gh
      pkgs.lazygit
      pkgs.delta
      pkgs.neovim

      # tmux
      pkgs.tmux
      tpmWrapper
      tpmInstallWrapper

      # Tools
      pkgs.jq
      pkgs.yq
    ];
  }
