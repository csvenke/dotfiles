{
  lib,
  symlinkJoin,
  writeShellApplication,
  python3,
  fetchFromGitHub,
  stdenvNoCC,
}:

let
  python = python3.override {
    packageOverrides = final: prev: {
      posthog = prev.posthog.override {
        # PostHog 7.71.0 is marked broken with MCP 2.x.
        # MCP is only a PostHog test dependency here.
        mcp = prev.mcp_1;
      };
    };
  };

  pythonPackages = python.pkgs;

  mempalace = pythonPackages.buildPythonPackage rec {
    pname = "mempalace";
    version = "3.11.0";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "MemPalace";
      repo = "mempalace";
      rev = "v${version}";
      hash = "sha256-flBz0bAL3X6dSTNedyKXnKSSonrb1kJQpy0XtjNyq6I=";
    };

    nativeBuildInputs = with pythonPackages; [
      pythonRelaxDepsHook
      hatchling
    ];

    pythonRelaxDeps = [ "chromadb" ];

    propagatedBuildInputs = with pythonPackages; [
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

  pythonWithMemPalace = python.withPackages (_: [ mempalace ]);

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
      exec ${pythonWithMemPalace}/bin/mempalace-mcp "$@"
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
      test -f $out/share/mempalace/skills/mempalace-task/SKILL.md

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
