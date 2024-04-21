{ pkgs ? import <nixpkgs-unstable> { } }:

let
  tmux = import ./nixpkgs/tmux { inherit pkgs; };
  neovim = import ./nixpkgs/neovim { inherit pkgs; };
  dev = import ./nixpkgs/dev { inherit pkgs; };
in

pkgs.buildEnv {
  name = "Home environment";
  paths = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.eza
    pkgs.bat
    pkgs.silver-searcher
    pkgs.delta

    # Shell
    pkgs.starship
    tmux

    # Editors
    neovim

    # Tools
    dev
    pkgs.devenv
    pkgs.ripgrep
    pkgs.jq
    pkgs.gh
    pkgs.tldr
    pkgs.git
    pkgs.wget
    pkgs.curl
    pkgs.fzf
  ];
}
