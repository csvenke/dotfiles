{
  writeShellApplication,
  lib,
  fzf,
  jq,
  findutils,
}:

writeShellApplication {
  name = "run";
  runtimeInputs = [
    fzf
    jq
    findutils
  ];
  text = lib.readFile ./script.bash;
}
