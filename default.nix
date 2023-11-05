{ pkgs ? import <nixpkgs> {} }:

let
  tmuxPluginManagerDrv = pkgs.stdenv.mkDerivation {
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
in

pkgs.mkShell {
  packages = with pkgs; [
    coreutils
    tree-sitter
    nodejs
    dotnet-sdk_7
    gcc
    rustup
    python3
    htop
    unzip
    gzip
    fd
    ripgrep
    curl
    wget
    git
    gh
    lazygit
    tmux
    delta
    neovim
  ];

  DOTNET_ROOT = "${pkgs.dotnet-sdk_7}";
  TMUX_PLUGIN_MANAGER_SCRIPT = "${tmuxPluginManagerDrv}/tpm";

  shellHook = ''
  '';
}
