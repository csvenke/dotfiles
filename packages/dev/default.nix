{ pkgs }:

pkgs.writeShellApplication {
  name = "dev";
  runtimeInputs = with pkgs; [ fd findutils gnused gawk ];
  text = builtins.readFile ./script.bash;
}
