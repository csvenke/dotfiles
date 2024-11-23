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
          dotstrap = pkgs.callPackage ./lib/dotstrap { };
        in
        {
          packages = {
            install = dotstrap "install";
            check = dotstrap "check";
            clean = dotstrap "clean";

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
                (callPackage ./packages/tmux { })
                (callPackage ./packages/dev { })
                (callPackage ./packages/run { })
                (callPackage ./packages/llm { })
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
