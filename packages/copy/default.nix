{ pkgs }:

pkgs.writeShellApplication {
  name = "copy";
  runtimeInputs = with pkgs; [ xclip ];
  text = ''
    xclip -selection clipboard
  '';
}
