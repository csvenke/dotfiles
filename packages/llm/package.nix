{
  writeShellApplication,
  python3,
  git,
}:

let
  src = ./.;
in

writeShellApplication {
  name = "llm";
  runtimeInputs = [
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
