{ pkgs }:

let
  src = ./.;
in

pkgs.writeShellApplication {
  name = "dotstrap";
  runtimeInputs = [ pkgs.python3 pkgs.git ];
  text = ''
    python3 ${src}/main.py "$@"
  '';
}

