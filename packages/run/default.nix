{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "run";
  runtimeInputs = with pkgs; [
    fzf
    jq
    findutils
  ];
  text = lib.readFile ./script.bash;
}
