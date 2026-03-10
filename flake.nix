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
              (import ./nix/overlays/tmux)
              (import ./nix/overlays/fzf)
              (import ./nix/overlays/beads)
            ];
          };
          inherit (pkgs) lib callPackage buildEnv;

          tools = lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./nix/tools;
          };

          homePackages =
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
              tmux
              fzf
              beads
              neovim
              opencode
              llm-cli
              dev-cli
            ]
            ++ (lib.attrValues tools);
        in
        {
          apps = {
            bootstrap = {
              type = "app";
              program = "${./scripts/bootstrap.sh}";
              meta.description = "Bootstrap dotfiles on the system";
            };
            eject = {
              type = "app";
              program = "${./scripts/eject.sh}";
              meta.description = "Remove dotfiles completly from the system";
            };
            fix-broken-profile = {
              type = "app";
              program = "${./scripts/fix-broken-profile.sh}";
              meta.description = "Fix broken nix profile";
            };
          };
          packages = {
            default = buildEnv {
              name = "dotfiles";
              paths = homePackages;
            };
          };
        };
    };
}
