{ pkgs ? import <nixpkgs> {} }:

let
  cwd = builtins.toString ./.;
  dotfilesScripts = pkgs.callPackage "${cwd}/scripts.nix" { };
  tmuxPluginManagerSrc = pkgs.stdenv.mkDerivation {
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
  buildInputs = [
    dotfilesScripts
    pkgs.coreutils
    pkgs.tree-sitter
    pkgs.nodejs
    pkgs.dotnet-sdk_7
    pkgs.gcc
    pkgs.rustup
    pkgs.python3
    pkgs.htop
    pkgs.unzip
    pkgs.fd
    pkgs.ripgrep
    pkgs.curl
    pkgs.git
    pkgs.gh
    pkgs.lazygit
    pkgs.tmux
    pkgs.delta
    pkgs.neovim
  ];

  DOTNET_ROOT = "${pkgs.dotnet-sdk_7}";
  TPM_BIN = "${tmuxPluginManagerSrc}/tpm";

  shellHook = ''
  '';
}
