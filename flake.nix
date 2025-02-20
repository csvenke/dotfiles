{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim = {
      url = "github:csvenke/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem =
        { config, system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.neovim.overlays.default
            ];
          };
          dotstrap = pkgs.callPackage ./packages/dotstrap { };
        in
        {
          packages = {
            install = pkgs.writeShellApplication {
              name = "install";
              runtimeInputs = [ dotstrap ];
              text = ''
                dotstrap install
              '';
            };

            default = pkgs.buildEnv {
              name = "dotfiles";
              paths = with pkgs; [
                coreutils
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
                git
                lazygit
                curl
                fzf
                xclip
                eza
                bat
                htop
                neovim
                (callPackage ./packages/tmux { })
                (callPackage ./packages/dev { })
                (callPackage ./packages/run { })
                (callPackage ./packages/llm { })
              ];
            };
          };

          devShells = {
            ci = pkgs.mkShell {
              packages = [ config.packages.default ];
            };
            default = pkgs.mkShell {
              packages = with pkgs; [
                python3Packages.setuptools
                python3Packages.anthropic
                python3Packages.halo
                python3Packages.click
                (callPackage ./packages/llm { })
                (callPackage ./packages/dotstrap { })
              ];
            };
          };
        };
    };
}
