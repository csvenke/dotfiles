{
  pkgs,
  lib,
  ...
}: let
  run = pkgs.writeShellApplication {
    name = "run";
    runtimeInputs = [
      pkgs.fzf
      pkgs.jq
      pkgs.findutils
    ];
    text = lib.readFile ./script.bash;
  };
in {
  home.packages = [run];
}
