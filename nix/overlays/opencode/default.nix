final: prev:

let
  inherit (prev)
    lib
    stdenv
    fetchurl
    autoPatchelfHook
    makeWrapper
    unzip
    ;

  version = "2.0.6";

  perSystem = {
    x86_64-linux = {
      pkg = "opencode-linux-x64.tar.gz";
      hash = "sha256-gzADIT4VUmbAc64/GeKmPQJ7nWaovJpGEOycnUs2nI0=";
    };
    aarch64-linux = {
      pkg = "opencode-linux-arm64.tar.gz";
      hash = "sha256-wHS+xv0FJWqqRFJamYZBhibgBFmUQ38w6Cs+zgkpGdg=";
    };
    aarch64-darwin = {
      pkg = "opencode-darwin-arm64.zip";
      hash = "sha256-VlIVGKp/XKJQ0aNtx/hnTVUGZFqQJtSLAHaXuQIWITw=";
    };
    x86_64-darwin = {
      pkg = "opencode-darwin-x64.zip";
      hash = "sha256-tZ6hFNUYgGwF8TxQbt8kRsUw9ihaBU/Jr0hYFsSmPfc=";
    };
  };

  system =
    perSystem.${stdenv.hostPlatform.system}
      or (throw "opencode: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://opencode.ai/files/bin/${version}/${system.pkg}";
    hash = system.hash;
  };
in
{
  opencode = stdenv.mkDerivation {
    pname = "opencode";
    inherit version src;

    sourceRoot = ".";

    nativeBuildInputs = [
      makeWrapper
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ unzip ];

    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 opencode $out/bin/opencode
      wrapProgram $out/bin/opencode \
        --run 'export OPENCODE_DB="''${OPENCODE_DB:-$HOME/.local/share/opencode/opencode2.db}"'
      runHook postInstall
    '';

    meta = {
      description = "OpenCode - AI coding agent for the terminal";
      homepage = "https://github.com/anomalyco/opencode";
      license = lib.licenses.mit;
      platforms = lib.attrNames perSystem;
      mainProgram = "opencode";
    };
  };
}
