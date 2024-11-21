{ pkgs }:

pkgs.writeShellApplication {
  name = "run";
  runtimeInputs = with pkgs; [ fzf jq findutils ];
  text = builtins.readFile ./script.bash;
}
