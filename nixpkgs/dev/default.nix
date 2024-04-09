{ pkgs }:

pkgs.writeShellApplication {
  name = "dev";
  runtimeInputs = with pkgs; [ coreutils findutils silver-searcher fzf gnused gawk ];
  text = builtins.readFile ./script.bash;
}
