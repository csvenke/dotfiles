{
  lib,
  tmux,
  writeText,
  makeWrapper,
  tmuxPlugins,
  fetchFromGitHub,
}:

let
  bundledPlugins = [
    (tmuxPlugins.mkTmuxPlugin rec {
      pluginName = "sensible";
      rtpFilePath = "sensible.tmux";
      version = "25cb91f42d020f675bb0a2ce3fbd3a5d96119efa";
      src = fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tmux-sensible";
        rev = version;
        sha256 = "sha256-sw9g1Yzmv2fdZFLJSGhx1tatQ+TtjDYNZI5uny0+5Hg=";
      };
    })
    (tmuxPlugins.mkTmuxPlugin rec {
      pluginName = "yank";
      rtpFilePath = "yank.tmux";
      version = "acfd36e4fcba99f8310a7dfb432111c242fe7392";
      src = fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tmux-yank";
        rev = version;
        sha256 = "sha256-/5HPaoOx2U2d8lZZJo5dKmemu6hKgHJYq23hxkddXpA=";
      };
    })
    (tmuxPlugins.mkTmuxPlugin rec {
      pluginName = "smart-splits";
      rtpFilePath = "smart-splits.tmux";
      version = "v2.0.3";
      src = fetchFromGitHub {
        owner = "mrjones2014";
        repo = "smart-splits.nvim";
        rev = version;
        sha256 = "sha256-zfuBaSnudCWw0N1XAms9CeVrAuPEAPDXxLLg1rTX7FE=";
      };
    })
  ];

  pluginInitScript = lib.concatMapStringsSep "\n" (plugin: "run-shell ${plugin.rtp}") bundledPlugins;

  config = writeText "tmux.conf" /* tmux */ ''
    source-file ~/.config/tmux/tmux.conf
    ${pluginInitScript}
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
        --add-flags "-f ${config}"

      # Remove bash-completion to avoid conflicts with bash-completion package
      rm -rf $out/share/bash-completion
    '';
})
