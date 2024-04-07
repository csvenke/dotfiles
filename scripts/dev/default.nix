{ pkgs }:

pkgs.writeShellApplication {
  name = "dev";
  text = builtins.readFile ./script.bash;
}
