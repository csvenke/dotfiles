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
              (import ./overlays/default.nix)
              inputs.neovim.overlays.default
            ];
            config = {
              allowUnfree = true;
            };
          };
          dotstrap-eject = pkgs.callPackage ./packages/dotstrap-eject { };
        in
        {
          packages = {
            install = pkgs.writeShellApplication {
              name = "install";
              runtimeInputs = with pkgs; [
                dotstrap-eject
                stow
                git
                nix
              ];
              text = ''
                DOTFILES_URL="https://github.com/csvenke/dotfiles.git"
                DOTFILES_BRANCH="master"
                DOTFILES_PATH="$HOME"/.dotfiles

                if [ ! -d "$DOTFILES_PATH" ]; then
                  git clone "$DOTFILES_URL" "$DOTFILES_PATH"
                else
                  git -C "$DOTFILES_PATH" pull origin "$DOTFILES_BRANCH"
                fi

                dotstrap-eject
                stow -v --dir="$DOTFILES_PATH/home" --target="$HOME" --restow .
                nix profile install "$DOTFILES_PATH"
                nix profile upgrade --all
                nix profile wipe-history --older-than 7d
              '';
            };

            default = pkgs.buildEnv {
              name = "dotfiles";
              paths = with pkgs; [
                bash-completion
                nix
                stow
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
                (azure-cli.withExtensions [
                  azure-cli-extensions.azure-devops
                ])
                neofetch
                neovim
                claude-code
                opencode
                (callPackage ./packages/record { })
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
              inputsFrom = [
                (pkgs.callPackage ./packages/llm/shell.nix { })
              ];
            };
          };
        };
    };
}
