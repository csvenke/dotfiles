{ pkgs ? import <nixpkgs-unstable> { } }:

with builtins;

let
  inherit (pkgs.lib) pipe;

  getDefaultPackageFromFlake = path:
    pipe path [
      toPath
      (path: "path:${path}")
      getFlake
      (flake: flake.packages."${currentSystem}".default)
    ];
in

pkgs.buildEnv {
  name = "Home environment";
  paths = with pkgs; [
    (getDefaultPackageFromFlake ../../packages/neovim)
    (callPackage ../../packages/tmux { })
    (callPackage ../../packages/dev { })
    starship
    findutils
    direnv
    nix-direnv
    eza
    bat
    silver-searcher
    delta
    ripgrep
    jq
    gh
    tldr
    git
    wget
    curl
    fzf
    xclip
    lazygit
  ];
}
