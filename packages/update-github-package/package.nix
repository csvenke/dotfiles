{
  lib,
  writeShellApplication,
  curl,
  jq,
  nix,
  gnused,
}:

writeShellApplication {
  name = "update-github-package";
  runtimeInputs = [
    curl
    jq
    nix
    gnused
  ];
  text = lib.readFile ./script.bash;
}
