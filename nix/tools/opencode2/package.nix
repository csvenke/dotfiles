{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "0.0.0-beta-17927"; # tracks @opencode-ai/cli "beta" dist-tag; bump manually

  perSystem = {
    x86_64-linux = {
      pkg = "cli-linux-x64";
      hash = "sha512-sCuCbo+s0xU6vlWqTGO72URboviGaitTwi+t82q+qDZag4wotgXMppCnBNl9x/Eqwdb+AwJsoD6XYJX+fn5jVg==";
    };
    aarch64-linux = {
      pkg = "cli-linux-arm64";
      hash = "sha512-Q/MDYbAahNU7dgkvZmyNvJURBbUH6KzKFYLscbnuge3tlHfztxgjrWCbopN2eoOK0/oBsohT+q5JvY0A7kxtmw==";
    };
    aarch64-darwin = {
      pkg = "cli-darwin-arm64";
      hash = "sha512-9QXFLYAtG1V/yJHZE/umQ3xabUQXo+Vkay5HPbREFvTMMbEXcbtUXIpO63cHjyuWejY+bFJ9NSmYdCSN+6IT0g==";
    };
    x86_64-darwin = {
      pkg = "cli-darwin-x64";
      hash = "sha512-JJfO4E5XiR98p4/+5eYS4UyZt6q2Qy7mnMwxAke+xPWiXzajRTMc3wcq7vWH65+ylWmB01iJ6tKvXxdEEnLaSw==";
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
