{
  description = "Neovim flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    vim-extra-plugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";
  };

  outputs = inputs@{ flake-parts, nixpkgs, vim-extra-plugins, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              vim-extra-plugins.overlays.default
            ];
          };
          neovim = pkgs.callPackage ./default.nix { };
        in
        {
          packages.default = neovim;
        };
    };
}
