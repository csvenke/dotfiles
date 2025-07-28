{ pkgs }:

let
  src = ./.;
in

pkgs.writeShellApplication {
  name = "llm";
  runtimeInputs = with pkgs; [
    (python3.withPackages (ps: [
      ps.anthropic
      ps.click
      ps.halo
    ]))
    git
  ];
  text = ''
    python3 ${src}/main.py "$@"
  '';
}
