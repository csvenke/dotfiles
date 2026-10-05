{
  lib,
  symlinkJoin,
  writeShellApplication,
  python3,
  python3Packages,
  fetchFromGitHub,
  stdenvNoCC,
}:

let
  mempalace = python3Packages.buildPythonPackage rec {
    pname = "mempalace";
    version = "3.7.1";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "MemPalace";
      repo = "mempalace";
      rev = "v${version}";
      hash = "sha256-XlEjuVKARzh94xB4oZLAkgffDcaScgGqL5SUIxh968Q=";
    };

    nativeBuildInputs = with python3Packages; [
      pythonRelaxDepsHook
      hatchling
    ];

    pythonRelaxDeps = [ "chromadb" ];

    propagatedBuildInputs = with python3Packages; [
      chromadb
      huggingface-hub
      tokenizers
      numpy
      python-dateutil
      pyyaml
    ];

    pythonImportsCheck = [ "mempalace" ];

    meta = {
      description = "AI memory system";
      homepage = "https://github.com/milla-jovovich/mempalace";
      license = lib.licenses.mit;
      maintainers = [ ];
    };
  };

  pythonWithMemPalace = python3.withPackages (_: [ mempalace ]);

  mempalaceCli = writeShellApplication {
    name = "mempalace";
    runtimeInputs = [ pythonWithMemPalace ];
    text = ''
      exec python -m mempalace "$@"
    '';
  };

  mempalaceMcp = writeShellApplication {
    name = "mempalace-mcp";
    runtimeInputs = [ pythonWithMemPalace ];
    text = ''
      exec python -m mempalace.mcp_server "$@"
    '';
  };

  mempalaceSkills = stdenvNoCC.mkDerivation {
    pname = "mempalace-skills";
    version = mempalace.version;

    src = mempalace.src;

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/mempalace/skills
      cp -r skills/. $out/share/mempalace/skills/

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      test -f $out/share/mempalace/skills/mempalace/SKILL.md
      test -f $out/share/mempalace/skills/mempalace-recall/SKILL.md

      runHook postInstallCheck
    '';

    meta = mempalace.meta // {
      description = "MemPalace agent skills";
    };
  };
in

symlinkJoin {
  name = "mempalace-tools";
  paths = [
    mempalaceCli
    mempalaceMcp
    mempalaceSkills
  ];
  meta = mempalace.meta // {
    mainProgram = "mempalace";
  };
}
