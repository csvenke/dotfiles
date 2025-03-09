{ pkgs }:

let
  inherit (builtins) toFile readFile;

  userConf = toFile "tmux.conf" (readFile ./tmux.conf);
  tmuxConf = pkgs.writeTextFile {
    name = "tmux.conf";
    text = # tmux
      ''
        source-file '${userConf}'
        run-shell '${pkgs.tmuxPlugins.sensible.rtp}'
        run-shell '${pkgs.tmuxPlugins.yank.rtp}'
        run-shell '${pkgs.tmuxPlugins.catppuccin.rtp}'
      '';
  };
in

pkgs.writeShellApplication {
  name = "tmux";
  text = ''
    ${pkgs.tmux}/bin/tmux -f ${tmuxConf} "$@"
  '';
}
