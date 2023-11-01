{ pkgs ? import <nixpkgs> {} }:

let
  cwd = builtins.toString ./.;
  dotfilesLink = pkgs.callPackage "${cwd}/link.nix" { };
in

pkgs.mkShell {
  buildInputs = [
    dotfilesLink
  ];
  packages = with pkgs; [
    nodejs
    dotnet-sdk_7
    libstdcxx5
    gcc
    rustup
    python3
    htop
    unzip
    fd
    ripgrep
    curl
    git
    gh
    lazygit
    tmux
    delta
    neovim
  ];

  shellHook = ''
  '';
}
