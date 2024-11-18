{ lib, ... }:

{
  programs = {
    wezterm = {
      enable = true;
      extraConfig = lib.readFile ./config/wezterm.lua;
    };
  };
}
