{ pkgs }:

let
  inherit (builtins) readDir attrNames;
  inherit (pkgs.lib) pipe;

  callPackages = dir:
    pipe dir [
      readDir
      attrNames
      (map (name: pkgs.callPackage "${dir}/${name}" { }))
    ];

  local-packages = callPackages ./packages;

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

nix-packages ++ local-packages
