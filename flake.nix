{
  description = "Dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim.url = "github:csvenke/neovim-flake";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, system, ... }:
        let
          neovim = inputs.neovim.packages.${system}.default;
          packages = import ./packages {
            inherit pkgs;
            inherit neovim;
          };
        in
        {
          packages.default = pkgs.buildEnv {
            name = "dotfiles-env";
            paths = packages;
          };
        };
    };
}
