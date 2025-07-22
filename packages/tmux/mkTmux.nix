{ pkgs, lib }:

{
  extraConfig ? "",
  extraPlugins ? [ ],
  extraPackages ? [ ],
}:

let
  pluginConfig = lib.concatMapStringsSep "\n" (plugin: "run-shell ${plugin.rtp}") extraPlugins;
  configWithPlugins = pkgs.writeText "tmux.conf" ''
    ${extraConfig}
    ${pluginConfig}
  '';
in

pkgs.tmux.overrideAttrs (oldAttrs: {
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postInstall =
    (oldAttrs.postInstall or "")
    +
    # bash
    ''
      wrapProgram $out/bin/tmux \
        --add-flags "-f ${configWithPlugins}" \
        --prefix PATH : "${lib.makeBinPath extraPackages}"
    '';
})
