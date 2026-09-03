final: prev:

let
  inherit (prev)
    lib
    stdenv
    fetchurl
    autoPatchelfHook
    makeWrapper
    ;

  version = "0.0.0-beta-18985";

  perSystem = {
    x86_64-linux = {
      pkg = "cli-linux-x64";
      hash = "sha512-A+grA7DCFhIknrOpZYSLf6370PDNO+AkDFrQ91mwZotqMUzMdymR2Fb8+68qP09z+GikeTbHzeUBABJIYR/Zng==";
    };
    aarch64-linux = {
      pkg = "cli-linux-arm64";
      hash = "sha512-ZKq8AUcXW9xrof/upcCgCkJ4xJtoHKm2DVaYRZROQMHAdMIS1aLxS5Hb94qCYKuHOaMs1BQvfIvNSSzj7WeOqg==";
    };
    aarch64-darwin = {
      pkg = "cli-darwin-arm64";
      hash = "sha512-CMiWg4zAoToq6bqK79kZgbhw45WdLt71TJ4pxezv5txLS3aFMBJrtHq8kf7h8qNuL+DF0RNvdIk6RkCy0z7prQ==";
    };
    x86_64-darwin = {
      pkg = "cli-darwin-x64";
      hash = "sha512-SQi3BQZbBA5fdB/NTuwvK5UCKoJWmgBTZM6Gp1OGqdnGeetb1ZxUUHAH4yon0YttsSn5WomPRxmk+pm5dA5ZBg==";
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
