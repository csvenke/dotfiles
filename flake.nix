{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim = {
      url = "github:csvenke/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devkit = {
      url = "github:csvenke/devkit";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { config, system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.devkit.overlays.default
              inputs.neovim.overlays.default
            ];
          };

          dotstrap = pkgs.callPackage ./tools/dotstrap {};
        in
        {
          packages = {
            install = pkgs.writeShellApplication {
              name = "install";
              runtimeInputs = [dotstrap];
              text = ''
                dotstrap install
              '';
            };
            check = pkgs.writeShellApplication {
              name = "check";
              runtimeInputs = [dotstrap];
              text = ''
                dotstrap check
              '';
            };
            clean = pkgs.writeShellApplication {
              name = "clean";
              runtimeInputs = [dotstrap];
              text = ''
                dotstrap clean
              '';
            };

            default = pkgs.buildEnv {
              name = "dotfiles";
              paths = with pkgs; [
                nixVersions.latest
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
                htop
                neovim
                devkit.tmux
                devkit.dev
                devkit.run
              ];
            };
          };

          devShells = {
            default = pkgs.mkShell {
              name = "dotfiles";
              packages = [
                config.packages.default
              ];
            };
          };
        };
    };
}
