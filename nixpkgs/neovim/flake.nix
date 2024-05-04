{
  description = "Neovim flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-extra-plugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";
    language-servers.url = "git+https://git.sr.ht/~bwolf/language-servers.nix";
  };

  outputs = { self, nixpkgs, flake-utils, neovim-extra-plugins, language-servers }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neovim-extra-plugins.overlays.default
          ];
        };
        config = import ./config { inherit pkgs; };
        runtimeInputs = import ./runtimeInputs.nix { inherit pkgs; inherit language-servers; };
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

