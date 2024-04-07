{ pkgs }:

pkgs.symlinkJoin {
  name = "scripts";
  paths = [
    (import ./dev { inherit pkgs; })
    (import ./dotstrap { inherit pkgs; })
  ];
}
