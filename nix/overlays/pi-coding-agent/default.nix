final: prev:

let
  inherit (prev)
    lib
    fetchFromGitHub
    fetchNpmDeps
    makeWrapper
    symlinkJoin
    callPackage
    pi-coding-agent
    ;

  inherit (callPackage ./utils.nix { })
    fetchNpmPackage
    mkPiExtension
    extensionFlags
    ;

  # After bumping a plugin version, update the hash and regenerate the lock:
  #   (cd nix/overlays/pi-coding-agent/<pname> && npm install --package-lock-only)
  piExtensions = map mkPiExtension [
    {
      npmRoot = ./pi-direnv;
      hash = "sha512-N+njfllbcKvd5qbtSMS1nP5QTSaqVZSmo8gQk8TCgWefPQidcg+FG6cY79HIJggS9RiI4FjhGyhVX8DY9kcuIA==";
    }
    {
      npmRoot = ./pi-subagents;
      hash = "sha512-r1uoi43ysqbi2MJOGAnJWMbF3o2xBwaWI7/pwJHgGaenv/JqGEmtt5YHYWoq8JRvlhVCquTnrtFeB7e0apLlOQ==";
    }
    {
      npmRoot = ./pi-web-access;
      hash = "sha512-Je7D5ghQi9dpN0KhpFMuHYwKy0oBvpNrNR7zuTzSyCRsIJDC5in8yGz/3yItxvWYHF1W+q2Sq190nyaLkoWhgg==";
    }
  ];

  pi-pinned = pi-coding-agent.overrideAttrs (old: rec {
    version = "1.1.0";
    src = fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${version}";
      hash = "sha256-lwjspkMGrW+8Fl/yBEDEFsHZJA57OKOhmVQmi6zfej4=";
    };
    npmDeps = fetchNpmDeps {
      inherit src;
      name = "pi-coding-agent-${version}-npm-deps";
      hash = "sha256-GOh5WG+rRgzoy/yVHY5PoEKJZGQcEGhISrDDJxkP8W4=";
    };
    modelData = fetchNpmPackage {
      pname = "@earendil-works/pi-ai";
      inherit version;
      hash = "sha256-bKqzPOxXSA7QLFf+N0KKAwp3zCoGYoFLQ1pc+JMq2Ck=";
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
