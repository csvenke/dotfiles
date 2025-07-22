{ pkgs, lib }:

let
  mkTmux = pkgs.callPackage ./mkTmux.nix { };
in

mkTmux {
  extraConfig = lib.readFile ./tmux.conf;
  extraPlugins = with pkgs.tmuxPlugins; [
    sensible
    yank
    catppuccin
  ];
}
