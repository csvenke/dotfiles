{ pkgs }:

let
  src = ./script.py;
in

pkgs.writeShellApplication {
  name = "llm";
  runtimeInputs = [
    (pkgs.python3.withPackages (ps: [ ps.anthropic ]))
    pkgs.git
  ];
  text = ''
    apiKey=$(cat "$HOME"/.vault/anthropic-api-key.txt)
    python3 ${src} --anthropicApiKey "$apiKey" "$@"
  '';
}
