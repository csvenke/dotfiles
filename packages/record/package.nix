{ pkgs }:

(pkgs.writeShellApplication {
  name = "record";
  runtimeInputs = with pkgs; [
    asciinema
    asciinema-agg
  ];
  text = ''
    FONT_DIR="${pkgs.nerd-fonts.jetbrains-mono}/share/fonts"
    FONT_FAMILY="JetBrainsMono Nerd Font Mono"
    FILE_NAME="recording"

    asciinema rec --overwrite "$FILE_NAME".cast \
      && agg --font-dir "$FONT_DIR" --font-family "$FONT_FAMILY" "$FILE_NAME".cast "$FILE_NAME".gif
  '';
})
