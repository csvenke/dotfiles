final: prev:

let
  inherit (prev)
    lib
    makeWrapper
    symlinkJoin
    callPackage
    pi-coding-agent
    ;

  inherit (callPackage ./utils.nix { })
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
in
{
  pi-coding-agent = symlinkJoin {
    name = "pi-coding-agent";
    paths = [ pi-coding-agent ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      rm $out/bin/pi
      makeWrapper ${lib.getExe pi-coding-agent} $out/bin/pi \
        ${extensionFlags piExtensions}
    '';
    meta = pi-coding-agent.meta;
  };
}
