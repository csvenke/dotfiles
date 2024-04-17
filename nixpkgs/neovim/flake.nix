{
  description = "Neovim flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-extra-plugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";
  };

  outputs = { self, nixpkgs, flake-utils, neovim-extra-plugins }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neovim-extra-plugins.overlays.default
          ];
        };
        config = import ./lua { inherit pkgs; };
        runtimeInputs = import ./runtimeInputs.nix { inherit pkgs; };
        plugins = import ./plugins.nix { inherit pkgs; };
        overrideNeovim = pkgs.neovim.override {
          configure = {
            customRC = config;
            packages.all.start = plugins;
          };
        };
      in
      {
        defaultPackage = pkgs.writeShellApplication {
          name = "nvim";
          runtimeInputs = runtimeInputs;
          text = ''
            ${overrideNeovim}/bin/nvim "$@"
          '';
        };
      });
}

