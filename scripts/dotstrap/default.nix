{pkgs}: let
  src = ./.;
in
  pkgs.writeShellApplication {
    name = "dotstrap";
    text = ''
      cd ${src}
      nix-shell ./script.py "$@"
    '';
  }
