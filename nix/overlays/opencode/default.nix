final: prev:

let
  inherit (prev)
    lib
    stdenv
    fetchurl
    autoPatchelfHook
    makeWrapper
    unzip
    wayland
    ;

  version = "2.0.27";

  perSystem = {
    x86_64-linux = {
      pkg = "opencode-linux-x64.tar.gz";
      hash = "sha256-lDdyz/MDGbgUxJ/oQFjxEht0tsu10ns4JL7GLyrey5o=";
    };
    aarch64-linux = {
      pkg = "opencode-linux-arm64.tar.gz";
      hash = "sha256-KNtFn6mcNYK5aOOc7MxEJUwVJJIFbUDNK8VIZp1oqrc=";
    };
    aarch64-darwin = {
      pkg = "opencode-darwin-arm64.zip";
      hash = "sha256-ORsQYdw/H0OUt/0ZUTsub/EvMXOe4S8ziAUG7W7gCLw=";
    };
    x86_64-darwin = {
      pkg = "opencode-darwin-x64.zip";
      hash = "sha256-uTOVslfdKpfCs2hxEbPVAYbbOH5PWY6BouszC+ac4uI=";
    };
  };

  system =
    perSystem.${stdenv.hostPlatform.system}
      or (throw "opencode: unsupported system ${stdenv.hostPlatform.system}");

  # The TUI's native clipboard host dlopens libwayland-client.so.0 at runtime
  # (Wayland data-control protocol for image paste). The patched nix glibc does
  # not search system lib paths, so expose the nix wayland lib explicitly.
  waylandFlags = lib.optionalString stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${
    lib.makeLibraryPath [ wayland ]
  } ";

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
        ${waylandFlags}--run 'export OPENCODE_DB="''${OPENCODE_DB:-$HOME/.local/share/opencode/opencode2.db}"'
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
