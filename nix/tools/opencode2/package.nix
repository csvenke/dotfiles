{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "0.0.0-beta-17823"; # tracks @opencode-ai/cli "beta" dist-tag; bump manually

  perSystem = {
    x86_64-linux = {
      pkg = "cli-linux-x64";
      hash = "sha512-D5KP6uIWLjbdY6TmPEYZqbBmOgqg7i76O+KwM566JRPVNUxYRfvA/OhR9g7Iz6HOQZqU/fWMJa+1E0irteImwg==";
    };
    aarch64-linux = {
      pkg = "cli-linux-arm64";
      hash = "sha512-nZ6HkT0qL0mSB7nW57hIxaf3KdxAGyWeeoLHDCbxlpQMYcpFiqDYNc5nl/xKDdsJ8lPHSMQTUy1fdeOqMphYyA==";
    };
    aarch64-darwin = {
      pkg = "cli-darwin-arm64";
      hash = "sha512-10vuMRIVxzOw/wy/ikyOQbjotPSAGsV95S1YMqy+BFRPSlvAcppBjXGRbguPsqctsIniRh/rQkJMbjLLK83hQA==";
    };
    x86_64-darwin = {
      pkg = "cli-darwin-x64";
      hash = "sha512-oNkUyQ3Y+5HK1O1bdP9Khqn2Bn3v4ayoPiGmCMrg//UVMUIcc3NW9VqhCdxFX84WITxV2Mx0NQUQ83Qg/qSN4g==";
    };
  };

  system =
    perSystem.${stdenv.hostPlatform.system}
      or (throw "opencode2: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/${system.pkg}/-/${system.pkg}-${version}.tgz";
    hash = system.hash;
  };
in
stdenv.mkDerivation {
  pname = "opencode2";
  inherit version src;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  # Bun's `--compile` executables embed the JS bundle in a non-standard ELF
  # section; stripping corrupts it (matches nixpkgs' own opencode v1 recipe,
  # which sets the same flag for the same reason).
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/opencode2 $out/bin/opencode2
    # Default OPENCODE_DB to a v2-only file so it never opens v1's
    # opencode-stable.db (or the stale legacy opencode.db) which has an
    # incompatible schema (SQLiteError: no such column: name). Respects an
    # existing OPENCODE_DB if the user has already set one.
    wrapProgram $out/bin/opencode2 \
      --run 'export OPENCODE_DB="''${OPENCODE_DB:-$HOME/.local/share/opencode/opencode2.db}"'
    runHook postInstall
  '';

  meta = {
    description = "OpenCode 2.0 (beta) - AI coding agent for the terminal, next-gen CLI";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    platforms = builtins.attrNames perSystem;
    mainProgram = "opencode2";
  };
}
