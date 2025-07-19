{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "dotstrap-eject";
  runtimeInputs = [ ];
  text = lib.readFile ./script.bash;
}
