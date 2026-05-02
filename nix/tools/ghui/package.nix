{
  stdenv,
  lib,
  fetchFromGitHub,
  bun,
  makeWrapper,
  gh,
}:

let
  ghui-deps = stdenv.mkDerivation rec {
    pname = "ghui-deps";
    version = "0.1.20";

    src = fetchFromGitHub {
      owner = "kitlangton";
      repo = "ghui";
      rev = "v${version}";
      hash = "sha256-v40Atfm48qt7yzL37fC8x6kZScDSoXtrMYxtykbnQ6M=";
    };

    nativeBuildInputs = [ bun ];

    buildPhase = ''
      export HOME=$(mktemp -d)
      bun install --frozen-lockfile --no-progress
    '';

    installPhase = ''
      mkdir -p $out/lib/ghui
      cp -r . $out/lib/ghui/
    '';

    dontFixup = true;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-fo3L88vbvY1Aa7pyRd9doTAlvOI9kJr9WZ4vUyxhNhA=";
  };
in

stdenv.mkDerivation {
  pname = "ghui";
  inherit (ghui-deps) version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${bun}/bin/bun $out/bin/ghui \
      --add-flags "${ghui-deps}/lib/ghui/bin/ghui.js" \
      --prefix PATH : ${lib.makeBinPath [ gh ]}
  '';

  meta = {
    description = "A GitHub PR TUI built with Bun and TypeScript";
    homepage = "https://github.com/kitlangton/ghui";
    license = lib.licenses.mit;
  };
}
