{ pkgs }:

pkgs.python3Packages.buildPythonApplication {
  pname = "dotstrap";
  version = "1.0.0";
  src = ./.;
  propagatedBuildInputs = with pkgs; [
    git
  ];
}

