{ pkgs }:

let
  src = ./.;
in

pkgs.writeShellApplication {
  name = "dotstrap";
  runtimeInputs = with pkgs; [
    python3
    git
  ];
  text = ''
    python3 ${src}/main.py "$@"
  '';
}
