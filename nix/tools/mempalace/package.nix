{
  lib,
  symlinkJoin,
  writeShellApplication,
  python3,
  python3Packages,
  fetchPypi,
}:

let
  mempalace = python3Packages.buildPythonPackage rec {
    pname = "mempalace";
    version = "3.1.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-E90NR/tNWz3BeZPh4uBYFEl5Rp3V69Xu80gIaB1t09I=";
    };

    nativeBuildInputs = with python3Packages; [
      pythonRelaxDepsHook
      hatchling
    ];

    pythonRelaxDeps = [ "chromadb" ];

    propagatedBuildInputs = with python3Packages; [
      chromadb
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
in

symlinkJoin {
  name = "mempalace-tools";
  paths = [
    mempalaceCli
    mempalaceMcp
  ];
}
