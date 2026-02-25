{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    dev-cli = {
      url = "github:csvenke/dev-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-cli = {
      url = "github:csvenke/llm-cli";
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
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                neovim = inputs.neovim.packages.${system}.default;
                dev-cli = inputs.dev-cli.packages.${system}.default;
                llm-cli = inputs.llm-cli.packages.${system}.default;
              })
            ];
          };
          inherit (pkgs)
            lib
            callPackage
            buildEnv
            writeShellScriptBin
            ;

          packages = lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./nix/packages;
          };

          mkShellScriptApp = content: {
            type = "app";
            program = writeShellScriptBin "program" content;
          };
        in
        {
          apps = {
            install = mkShellScriptApp /* bash */ ''
              migrate_dotfiles_path_to_xdg_config() {
                local new="$1"
                local old="$HOME/.dotfiles"

                if [[ ! -d "$old" && -d "$new" ]]; then
                  return
                fi

                nix profile remove --all
                stow -v --dir="$old/home" --target="$HOME" --delete .
                mv "$old" "$new"
              }

              DOTFILES_URL="https://github.com/csvenke/dotfiles.git"
              DOTFILES_BRANCH="master"
              DOTFILES_PATH="$HOME/.config/dotfiles"

              migrate_dotfiles_path_to_xdg_config "$DOTFILES_PATH"

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

            fix-broken-profile = mkShellScriptApp /* bash */ ''
              DOTFILES_PATH="$HOME/.config/dotfiles"

              nix-collect-garbage -d
              rm ~/.local/state/nix/profiles/profile*
              rm ~/.nix-profile
              nix profile add "$DOTFILES_PATH"
              nix profile list
            '';
          };

          packages = {
            default = buildEnv {
              name = "dotfiles";
              pathsToLink = [
                "/bin"
                "/share"
              ];
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
                  xclip
                  eza
                  bat
                  htop-vim
                  gh
                  fastfetch
                  nodejs
                  neovim
                  opencode
                  beads
                  dev-cli
                  llm-cli
                ]
                ++ (lib.attrValues packages);
            };
          };
        };
    };
}
