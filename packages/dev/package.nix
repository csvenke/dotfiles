{
  writeShellApplication,
  lib,
  fd,
  fzf,
  gnused,
  gawk,
}:

writeShellApplication {
  name = "dev";
  runtimeInputs = [
    fd
    fzf
    gnused
    gawk
  ];
  text = lib.readFile ./script.bash;
}
