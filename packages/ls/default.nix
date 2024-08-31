{ pkgs }:

let
  list-files = pkgs.writeShellApplication {
    name = "ls";
    runtimeInputs = with pkgs; [ eza ];
    text = ''
      command eza --icons --colour=auto --sort=type --group-directories-first "$@"
    '';
  };
  list-all-files = pkgs.writeShellApplication {
    name = "la";
    runtimeInputs = [ list-files ];
    text = ''
      ls -a "$@"
    '';
  };
  list-all-files-long = pkgs.writeShellApplication {
    name = "ll";
    runtimeInputs = [ list-files ];
    text = ''
      ls -al "$@"
    '';
  };
in


pkgs.symlinkJoin {
  name = "ls-packages";
  paths = [
    list-files
    list-all-files
    list-all-files-long
  ];
}
