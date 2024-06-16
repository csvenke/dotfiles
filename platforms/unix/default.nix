{ pkgs ? import <nixpkgs-unstable> { } }:

pkgs.buildEnv {
  name = "Home environment";
  paths = with pkgs; [
    # Shell
    starship
    (callPackage ../../nixpkgs/tmux { })

    # Editors
    (callPackage ../../nixpkgs/neovim { })

    # Tools
    (callPackage ../../nixpkgs/dev { })
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
