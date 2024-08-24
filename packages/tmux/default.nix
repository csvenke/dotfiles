{ pkgs }:

let
  inherit (builtins) toFile readFile;

  userConf = toFile "tmux.conf" (readFile ./tmux.conf);
  tmuxConf = pkgs.writeTextFile {
    name = "tmux.conf";
    text = /* tmux */ ''
      run-shell '${pkgs.tmuxPlugins.sensible.rtp}'
      run-shell '${pkgs.tmuxPlugins.catppuccin.rtp}'
      run-shell '${pkgs.tmuxPlugins.yank.rtp}'
      source-file ${userConf}
    '';
  };
in

pkgs.tmux.overrideAttrs (oldAttrs: {
  buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postInstall = oldAttrs.postInstall + /* bash */ ''
    mkdir $out/libexec
    mv $out/bin/tmux $out/libexec/tmux-unwrapped
    makeWrapper $out/libexec/tmux-unwrapped $out/bin/tmux \
      --add-flags "-f ${tmuxConf}"
  '';
})


