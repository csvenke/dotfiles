final: prev:

let
  inherit (prev)
    lib
    stdenv
    fetchurl
    autoPatchelfHook
    makeWrapper
    ;

  version = "0.0.0-beta-17927";

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
