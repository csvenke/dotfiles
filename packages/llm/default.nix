{ pkgs }:

pkgs.python3Packages.buildPythonApplication {
  pname = "llm";
  version = "1.0.0";
  src = ./.;
  propagatedBuildInputs = with pkgs; [
    git
    python3Packages.anthropic
    python3Packages.halo
  ];
}
