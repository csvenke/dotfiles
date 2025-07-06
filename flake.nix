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
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem =
        { config, system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.neovim.overlays.default
            ];
            config = {
              allowUnfree = true;
            };
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
            update = pkgs.writeShellApplication {
              name = "update";
              runtimeInputs = [ dotstrap ];
              text = ''
                dotstrap update
              '';
            };

            default = pkgs.buildEnv {
              name = "dotfiles";
              paths = with pkgs; [
                nix
                findutils
                fd
                starship
                direnv
                nix-direnv
                delta
                ripgrep
                jq
                tldr
                wget
                git
                lazygit
                curl
                fzf
                xclip
                eza
                bat
                htop-vim
                gh
                neovim
                claude-code
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
                python3Packages.pyfiglet
              ];
            };
          };
        };
    };
}
