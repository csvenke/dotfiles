{ pkgs }:

pkgs.writeShellApplication {
  name = "cat";
  runtimeInputs = with pkgs; [ bat ];
  text = ''
    bat --style=plain "$@"
  '';
}
