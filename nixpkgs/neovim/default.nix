{ pkgs }:

with builtins;

let
  inherit (pkgs.lib) pipe;

  getFlakeForSystem = path:
    pipe path [
      toPath
      (path: "path:${path}")
      getFlake
      (flake: flake.defaultPackage."${currentSystem}")
    ];
in

getFlakeForSystem ./.
