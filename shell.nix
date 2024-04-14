{ pkgs ? import <nixpkgs-unstable> { } }:

let
  install = pkgs.writeShellScriptBin "install" (builtins.readFile ./scripts/install.bash);
  check = pkgs.writeShellScriptBin "check" (builtins.readFile ./scripts/check.bash);
in

pkgs.mkShell {
  packages = [ install check ];
}

