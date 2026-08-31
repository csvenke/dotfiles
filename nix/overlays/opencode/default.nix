final: prev:

let
  inherit (prev)
    lib
    stdenv
    fetchurl
    autoPatchelfHook
    makeWrapper
    ;

  version = "0.0.0-beta-18721";

  perSystem = {
    x86_64-linux = {
      pkg = "cli-linux-x64";
      hash = "sha512-RWuw504xQubiWxxv5TTKR8CrlhKzdvTLo27Ke81B56rjmSNOUdWSlAoCrWKR966bUVGxC091cf3oZwzv7GvNJQ==";
    };
    aarch64-linux = {
      pkg = "cli-linux-arm64";
      hash = "sha512-TsntJ1ZuXPBSXOicxZNwcs4cBfYvCfY3c9ZXEO1hXvBjj8eLT13B8vBdGkSZMB86fwNgYtSxhyh5ToU0ZpVwIg==";
    };
    aarch64-darwin = {
      pkg = "cli-darwin-arm64";
      hash = "sha512-CVu7OHGLTyeCk8tT3JKcQts6386YMjLfeqCCUXm+m4PQGs4ZrWxPcdlIxblmrY90maIwi06VV9ozstQ182VIrg==";
    };
    x86_64-darwin = {
      pkg = "cli-darwin-x64";
      hash = "sha512-wR87aGg62oGWDyXhd34NvbAG/6B51kQa1fjM9ZblSD8IC0faQLDtKb1gXe2/RABrXhcPAMfkrgC1ZMVHAaFz9w==";
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
