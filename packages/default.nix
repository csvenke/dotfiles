{ pkgs, neovim }:

let
  flake-packages = [
    neovim
  ];

  local-packages = with pkgs; [
    (callPackage ./cat { })
    (callPackage ./copy { })
    (callPackage ./dev { })
    (callPackage ./git { })
    (callPackage ./ls { })
    (callPackage ./tmux { })
  ];

  nix-packages = with pkgs; [
    coreutils
    findutils
    starship
    direnv
    nix-direnv
    delta
    ripgrep
    jq
    gh
    tldr
    wget
    curl
    silver-searcher
    fzf
    xclip
  ];
in

nix-packages ++ flake-packages ++ local-packages
