{
  pkgs,
  lib,
  ...
}: let
  dev = pkgs.writeShellApplication {
    name = "dev";
    runtimeInputs = [
      pkgs.fd
      pkgs.fzf
      pkgs.gnused
      pkgs.gawk
    ];
    text = lib.readFile ./script.bash;
  };
in {
  home.packages = [dev];
}
