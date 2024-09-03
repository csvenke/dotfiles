{ pkgs }:

let
  src = ./.;
in

pkgs.writeShellApplication {
  name = "dotstrap";
  runtimeInputs = [ pkgs.python3 ];
  text = ''
    python3 ${src}/main.py "$@"
  '';
}

