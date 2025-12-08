{
  writeShellApplication,
  nerd-fonts,
  asciinema,
  asciinema-agg,
  gifsicle,
}:

writeShellApplication {
  name = "record";
  runtimeInputs = [
    asciinema
    asciinema-agg
    gifsicle
  ];
  text = ''
    # Nordic theme colors
    # Format: bg,fg,black,red,green,yellow,blue,magenta,cyan,white,br_black,br_red,br_green,br_yellow,br_blue,br_magenta,br_cyan,br_white
    THEME="242933,D8DEE9,191D24,BF616A,A3BE8C,EBCB8B,5E81AC,B48EAD,8FBCBB,BBC3D4,4C566A,C5727A,B1C89D,EFD49F,81A1C1,BE9DB8,9FC6C5,ECEFF4"
    FONT_DIR="${nerd-fonts.jetbrains-mono}/share/fonts"
    FONT_FAMILY="JetBrainsMono Nerd Font"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    FILE_NAME="recording_$TIMESTAMP"

    asciinema rec --overwrite "$FILE_NAME".cast \
      && agg --font-dir "$FONT_DIR" --font-family "$FONT_FAMILY" --theme "$THEME" "$FILE_NAME".cast "$FILE_NAME".gif
    gifsicle --lossy=80 -k 128 -O2 -Okeep-empty "$FILE_NAME".gif -o "$FILE_NAME".gif 
    rm "$FILE_NAME".cast
  '';
}
