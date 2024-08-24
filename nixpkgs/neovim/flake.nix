{
  description = "Neovim flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim-extra-plugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";
    language-servers.url = "git+https://git.sr.ht/~bwolf/language-servers.nix";
  };

  outputs = inputs@{ flake-parts, nixpkgs, neovim-extra-plugins, language-servers, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              neovim-extra-plugins.overlays.default
            ];
          };
          neovim = import ./neovim.nix {
            inherit pkgs;
            inherit language-servers;
          };
        in
        {
          packages.default = neovim;
        };
    };
}
