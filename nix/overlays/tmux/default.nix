final: prev:

let
  inherit (prev)
    lib
    makeWrapper
    tmuxPlugins
    fetchFromGitHub
    writeText
    ;

  bundledPlugins = [
    tmuxPlugins.sensible
    tmuxPlugins.yank
    (tmuxPlugins.mkTmuxPlugin rec {
      pluginName = "smart-splits";
      rtpFilePath = "smart-splits.tmux";
      version = "v2.0.5";
      src = fetchFromGitHub {
        owner = "mrjones2014";
        repo = "smart-splits.nvim";
        rev = version;
        sha256 = "sha256-EqnSGTyADvIpHxN3jZxwetENdqv/XUossUzrEvLHHMk=";
      };
    })
  ];

  pluginInitScript = lib.concatMapStringsSep "\n" (plugin: "run-shell ${plugin.rtp}") bundledPlugins;

  config = writeText "tmux.conf" /* tmux */ ''
    source-file ~/.config/tmux/tmux.conf
    ${pluginInitScript}
  '';
in
{
  tmux = prev.symlinkJoin {
    name = "tmux-wrapped";
    paths = [ prev.tmux ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tmux \
        --add-flags "-f ${config}"

      # Remove bash-completion to avoid conflicts with bash-completion package
      rm -rf $out/share/bash-completion
    '';
  };
}
