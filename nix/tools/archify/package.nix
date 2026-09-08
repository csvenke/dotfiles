{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "archify";
  version = "2.16.0";

  src = fetchurl {
    url = "https://github.com/tt-a1i/archify/releases/download/v${version}/archify.zip";
    hash = "sha256-TFn6ZVeiOFvqrvjHIZzEFFc6zJ8MMKky1QU7CyBomkY=";
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/opencode/skills
    unzip -q $src -d $out/share/opencode/skills
    makeWrapper ${nodejs}/bin/node $out/bin/archify \
      --add-flags $out/share/opencode/skills/archify/bin/archify.mjs

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/archify doctor
    runHook postInstallCheck
  '';

  meta = {
    description = "Agent skill for creating validated interactive system diagrams";
    homepage = "https://github.com/tt-a1i/archify";
    license = lib.licenses.mit;
    mainProgram = "archify";
  };
}
