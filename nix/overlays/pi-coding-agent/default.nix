final: prev:

let
  inherit (prev)
    lib
    fetchFromGitHub
    fetchurl
    makeWrapper
    symlinkJoin
    callPackage
    pi-coding-agent
    ;

  inherit (callPackage ./utils.nix { })
    mkGitHubPiExtension
    mkLocalPiExtension
    extensionFlags
    ;

  piExtensions = [
    (mkGitHubPiExtension {
      pname = "pi-direnv";
      owner = "edmundmiller";
      repo = "dotfiles";
      rev = "ac2fc2165e60ac30d6f1b55c0496b0710f681ddf";
      rootDir = "packages/pi-packages/pi-direnv";
      hash = "sha256-sWAT2FTM4khch4xv/O94U2VVLqdXPPF/0/SKkUc63ew=";
    })
    (mkGitHubPiExtension {
      pname = "pi-subagents";
      version = "0.80.0";
      owner = "nicobailon";
      repo = "pi-subagents";
      hash = "sha256-/XjtoCIQu1c0DwOM+aeWWBmyk7JFuQWB10o9RLJk/kU=";
    })
    (mkGitHubPiExtension {
      pname = "pi-web-access";
      version = "0.37.0";
      owner = "nicobailon";
      repo = "pi-web-access";
      hash = "sha256-iD8q2t6OdbVmV7BKaKn8EhNqCeMnv25WyZNuVOEI9bw=";
    })
    (mkLocalPiExtension {
      npmRoot = ./pi-tidy;
    })
  ];

  pi-pinned = pi-coding-agent.overrideAttrs (old: {
    version = "1.3.0";
    src = fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v1.3.0";
      hash = "sha256-AsutbwnjiwwLkB5tqLW+1GdGZyLmXsU0W+SNdNhJu7U=";
    };
    npmDepsHash = "sha256-+gFyvrhkCsF99oNvs0gBmLXnDW0hWnZI/wFId7UbI6Q=";
    modelData = fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-1.3.0.tgz";
      hash = "sha256-U0PhY5vzQ73DNE3zrWwxwFpQtoutB6xrzhCJDUtrimE=";
    };
  });

in
{
  pi-coding-agent = symlinkJoin {
    name = "pi-coding-agent";
    paths = [ pi-pinned ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      rm $out/bin/pi
      makeWrapper ${lib.getExe pi-pinned} $out/bin/pi \
        ${extensionFlags piExtensions}
    '';
    meta = pi-pinned.meta;
  };
}
