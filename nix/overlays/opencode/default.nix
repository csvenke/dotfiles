final: prev:

let
  inherit (prev)
    lib
    stdenv
    fetchurl
    autoPatchelfHook
    makeWrapper
    ;

  version = "0.0.0-beta-19271";

  perSystem = {
    x86_64-linux = {
      pkg = "cli-linux-x64";
      hash = "sha512-eZxNRstEUCxYk+L6PqtZ8GdLnCi6076N490QAi2pY93qqD6+qg99OF5B1jRBF2mI/ysfCzXlrQtLNE+JfyuXRQ==";
    };
    aarch64-linux = {
      pkg = "cli-linux-arm64";
      hash = "sha512-0WIzqvdgTUwUaQK5cXibZauGbRW7NZcuXGrA8dMsRWmAyONKDCnI9LbSXigGwc1RkGeRJrLtP/Xwmc8UCeXoJA==";
    };
    aarch64-darwin = {
      pkg = "cli-darwin-arm64";
      hash = "sha512-CHfMY/7pPq4Andvrif34tC/N9mFppSujjscVISVOSMc/twAvkIGGfDUZgU65qHDsifSnt6+IJr3NZ2AbPzWOfA==";
    };
    x86_64-darwin = {
      pkg = "cli-darwin-x64";
      hash = "sha512-ZHQWqTBnDpyg78pMPYPBECEm6Qj8HpFKl3exSFPwbUDt8Gi1ixxsaggVIRpvOAOR/XdtbUj6eXwEtRHMZ2EmUw==";
    };
  };

  system =
    perSystem.${stdenv.hostPlatform.system}
      or (throw "opencode: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/${system.pkg}/-/${system.pkg}-${version}.tgz";
    hash = system.hash;
  };
in
{
  opencode = stdenv.mkDerivation {
    pname = "opencode";
    inherit version src;

    nativeBuildInputs = [
      makeWrapper
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/opencode2 $out/bin/opencode
      wrapProgram $out/bin/opencode \
        --run 'export OPENCODE_DB="''${OPENCODE_DB:-$HOME/.local/share/opencode/opencode2.db}"'
      runHook postInstall
    '';

    meta = {
      description = "OpenCode 2.0 (beta) - AI coding agent for the terminal, next-gen CLI";
      homepage = "https://github.com/anomalyco/opencode";
      license = lib.licenses.mit;
      platforms = lib.attrNames perSystem;
      mainProgram = "opencode";
    };
  };
}
