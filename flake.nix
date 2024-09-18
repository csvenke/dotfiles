{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim.url = "github:csvenke/neovim-flake";
    devkit.url = "github:csvenke/devkit";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.devkit.overlays.default
              inputs.neovim.overlays.default
            ];
          };

          dotstrap = import ./tools/dotstrap {
            inherit pkgs;
          };

          packages = with pkgs; [
            findutils
            fd
            starship
            direnv
            nix-direnv
            delta
            ripgrep
            jq
            gh
            tldr
            wget
            curl
            fzf
            xclip
            eza
            bat
            neovim
            devkit.tmux
            devkit.dev
            devkit.npm-run
            devkit.dotnet-run
          ];

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
              name = "dotfiles";
              paths = packages;
            };

          };

          devShells = {
            default = pkgs.mkShell {
              name = "dotfiles";
              packages = packages;
            };
          };
        };
    };
}
