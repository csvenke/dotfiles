{ pkgs }:

let
  src = ./.;
in

pkgs.writeShellApplication {
  name = "dotstrap";
  runtimeInputs = with pkgs; [
    (python3.withPackages (ps: [
      ps.click
      ps.pyfiglet
    ]))
    git
  ];
  text = ''
    python3 ${src}/main.py "$@"
  '';
}
