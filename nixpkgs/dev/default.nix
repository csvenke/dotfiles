{ pkgs }:

pkgs.writeShellApplication {
  name = "dev";
  runtimeInputs = with pkgs; [ findutils silver-searcher fzf gnused gawk ];
  text = builtins.readFile ./script.bash;
}
