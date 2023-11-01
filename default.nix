{ pkgs ? import <nixpkgs> {} }:

let
  cwd = builtins.toString ./.;
  dotfilesScripts = pkgs.callPackage "${cwd}/scripts.nix" { };
in

pkgs.mkShell {
  buildInputs = [
    dotfilesScripts
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

  shellHook = ''
    echo "Welcome to the machine"
  '';
}
