{ pkgs }:

with builtins;

let
  inherit (pkgs.lib) pipe strings;

  readLuaDir = dir:
    pipe dir [
      readDir
      attrNames
      (filter (name: strings.hasSuffix ".lua" name))
      (map (name: readFile "${dir}/${name}"))
      (concatStringsSep "\n")
    ];


  mkVimRc = files:
    pipe files [
      (map (file: "luafile ${file}"))
      (concatStringsSep "\n")
    ];
in

mkVimRc [
  (toFile "options.lua" (readFile ./core/options.lua))
  (toFile "keymaps.lua" (readFile ./core/keymaps.lua))
  (toFile "autocmds.lua" (readFile ./core/autocmds.lua))
  (toFile "plugins.lua" (readLuaDir ./plugins))
]
