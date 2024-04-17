{ pkgs }:

let
  inherit (builtins) map filter attrNames readFile readDir toFile concatStringsSep;
  inherit (pkgs.lib) pipe;
  inherit (pkgs.lib.strings) hasSuffix;

  readLuaDir = dir:
    pipe dir [
      readDir
      attrNames
      (filter (name: hasSuffix ".lua" name))
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
