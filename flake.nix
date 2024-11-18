{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim.url = "github:csvenke/neovim-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        homeConfigurations = {
          "csvenke@DESKTOP-OBOUJ4C" = import ./mkHomeConfig.nix {
            inherit inputs;
            username = "csvenke";
            homeDirectory = "/home/csvenke";
            system = "x86_64-linux";
            modules = [
              ./modules/core
              ./modules/dev
              ./modules/run
              ./modules/secrets
            ];
          };
        };
      };
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          system,
          pkgs,
          ...
        }:
        let
          homeManager = inputs.home-manager.packages.${system}.default;
        in
        {
          packages = {
            install = pkgs.writeShellApplication {
              name = "install";
              runtimeInputs = [
                pkgs.git
                homeManager
              ];
              text = ''
                dotfiles="$HOME/.dotfiles"

                if [ ! -d "$dotfiles" ]; then
                  git clone https://github.com/csvenke/dotfiles.git "$dotfiles"
                else
                  git -C "$dotfiles" pull origin master
                fi

                home-manager switch -b backup --flake .
              '';
            };

            switch = pkgs.writeShellApplication {
              name = "switch";
              runtimeInputs = [ homeManager ];
              text = ''
                home-manager switch -b backup --flake .
              '';
            };

            default = homeManager;
          };
        };
    };
}
