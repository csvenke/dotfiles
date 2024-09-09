{ pkgs }:

let
  local-packages = with pkgs; [
    (callPackage ./cat { })
    (callPackage ./copy { })
    (callPackage ./git { })
    (callPackage ./ls { })
    (callPackage ./tmux { })
  ];

  nix-packages = with pkgs; [
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
    neovim
  ];
in

nix-packages ++ local-packages
