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

  python3 = pkgs.python3.withPackages (ps: [
    ps.pip
    ps.pipx
  ]);
in
  pkgs.buildEnv {
    name = "My default environment";
    paths = [
      pkgs.direnv
      pkgs.nix-direnv

      # Python
      python3

      # Node
      pkgs.nodejs
      pkgs.bun
      pkgs.yarn
      pkgs.nodePackages.pnpm

      # Rust
      pkgs.cargo
      pkgs.rustc

      # Neovim
      pkgs.coreutils
      pkgs.tree-sitter
      pkgs.alejandra
      pkgs.gcc
      pkgs.gnumake
      pkgs.gnutar
      pkgs.gnused
      pkgs.gnugrep
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
      pkgs.fzf
    ];
  }
