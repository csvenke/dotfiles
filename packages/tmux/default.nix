{ pkgs }:

let
  inherit (builtins) toFile readFile;

  userConf = toFile "tmux.conf" (readFile ./tmux.conf);
  tmuxConf = pkgs.writeTextFile {
    name = "tmux.conf";
    text = # tmux
      ''
        run-shell '${pkgs.tmuxPlugins.sensible.rtp}'
        run-shell '${pkgs.tmuxPlugins.yank.rtp}'
        run-shell '${pkgs.tmuxPlugins.catppuccin.rtp}'
        source-file ${userConf}
      '';
  };
in

pkgs.writeShellApplication {
  name = "tmux";
  text = ''
    ${pkgs.tmux}/bin/tmux -f ${tmuxConf} "$@"
  '';
}
