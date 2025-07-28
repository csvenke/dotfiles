{ pkgs }:

pkgs.writeShellApplication {
  name = "dev";
  runtimeInputs = with pkgs; [ fd fzf gnused gawk ];
  text = builtins.readFile ./script.bash;
}

