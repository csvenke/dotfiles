{
  tmux,
  makeWrapper,
  writeText,
  lib,
}:

{
  config,
  plugins ? [ ],
  dependencies ? [ ],
}:

let
  pluginConfig = lib.concatMapStringsSep "\n" (plugin: "run-shell ${plugin.rtp}") plugins;
  configWithPlugins = writeText "tmux.conf" ''
    ${config}
    ${pluginConfig}
  '';
in

tmux.overrideAttrs (oldAttrs: {
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ makeWrapper ];
  postInstall =
    (oldAttrs.postInstall or "")
    +
    # bash
    ''
      wrapProgram $out/bin/tmux \
        --add-flags "-f ${configWithPlugins}" \
        --prefix PATH : "${lib.makeBinPath dependencies}"

      # Remove bash-completion to avoid conflicts with bash-completion package
      rm -rf $out/share/bash-completion
    '';
})
