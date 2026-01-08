{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    dev-cli = {
      url = "github:csvenke/dev-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (import ./overlays/default.nix)
              (final: prev: {
                neovim = inputs.neovim.packages.${system}.default;
                dev-cli = inputs.dev-cli.packages.${system}.default;
              })
            ];
            config = {
              allowUnfree = true;
            };
          };
          inherit (pkgs) lib callPackage;

          packages = lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./packages;
          };
        in
        {
          packages = packages // {
            install = pkgs.writeShellApplication {
              name = "install";
              runtimeInputs = with pkgs; [
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

                stow -v --dir="$DOTFILES_PATH/home" --target="$HOME" --adopt --restow .
                nix profile add "$DOTFILES_PATH"
                nix profile upgrade --all
                nix profile wipe-history --older-than 7d
              '';
            };

            fix-broken-profile = pkgs.writeShellApplication {
              name = "fix-broken-profile";
              text = ''
                DOTFILES_PATH="$HOME"/.dotfiles

                nix-collect-garbage -d
                rm ~/.local/state/nix/profiles/profile*
                rm ~/.nix-profile
                nix profile add "$DOTFILES_PATH"
                nix profile list
              '';
            };

            default = pkgs.buildEnv {
              name = "dotfiles";
              paths =
                with pkgs;
                [
                  bash-completion
                  nix
                  stow
                  findutils
                  fd
                  starship
                  direnv
                  nix-direnv
                  mise
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
                  fastfetch
                  tmux
                  nodejs
                  neovim
                  gemini-cli
                  opencode
                  context7-mcp
                  dev-cli
                ]
                ++ (lib.attrValues packages);
            };
          };

          devShells = {
            default = pkgs.mkShell {
              inputsFrom = [
                (pkgs.callPackage ./packages/llm/shell.nix { })
              ];
            };
          };
        };
    };
}
