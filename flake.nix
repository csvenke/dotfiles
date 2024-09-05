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
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.neovim.overlays.default
            ];
          };

          packages = import ./packages {
            inherit pkgs;
          };

          dotstrap = import ./tools/dotstrap {
            inherit pkgs;
          };

          install = pkgs.writeShellApplication {
            name = "install";
            runtimeInputs = [ pkgs.git dotstrap ];
            text = ''
              if [ ! -d "$HOME/.dotfiles" ]; then
                git clone https://github.com/csvenke/dotfiles.git ~/.dotfiles
              fi

              dotstrap install

              nix profile install ~/.dotfiles
            '';
          };

          update = pkgs.writeShellApplication {
            name = "update";
            text = ''
              nix profile upgrade --all
              nix profile wipe-history --older-than 7d
            '';
          };

          check = pkgs.writeShellApplication {
            name = "check";
            runtimeInputs = [ dotstrap ];
            text = ''
              dotstrap check
            '';
          };

          clean = pkgs.writeShellApplication {
            name = "clean";
            runtimeInputs = [ dotstrap ];
            text = ''
              dotstrap clean
            '';
          };
        in
        {
          packages = {
            inherit install;
            inherit update;
            inherit check;
            inherit clean;

            default = pkgs.buildEnv {
              name = "dotfiles-env";
              paths = packages;
            };
          };
        };
    };
}
