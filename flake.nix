{
  description = "Dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim.url = "path:./packages/neovim";
  };

  outputs = inputs@{ flake-parts, nixpkgs, neovim, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, system, ... }: {
        packages = {
          tmux = pkgs.callPackage ./packages/tmux { };
          dev = pkgs.callPackage ./packages/dev { };
          neovim = neovim.packages.${system}.default;
        };
      };
    };
}
