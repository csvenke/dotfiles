{
  tmux,
  callPackage,
  tmuxPlugins,
  fetchFromGitHub,
  lib,
}:

let
  mkTmux = callPackage ./mkTmux.nix { inherit tmux; };
in

mkTmux {
  config = lib.readFile ./tmux.conf;
  plugins = [
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
}
