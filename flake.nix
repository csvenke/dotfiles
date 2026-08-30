{
  description = "dotfiles flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    inputs@{
      flake-parts,
      treefmt-nix,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        treefmt-nix.flakeModule
      ];

      perSystem =
        { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (import ./nix/overlays/tmux)
              (import ./nix/overlays/fzf)
              (import ./nix/overlays/opencode)
            ];
          };
          inherit (pkgs)
            lib
            callPackage
            buildEnv
            stdenv
            ;

          localTools = lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./nix/tools;
          };

          flakePackages = [
            inputs.neovim.packages.${system}.default
            inputs.llm-cli.packages.${system}.default
            inputs.dev-cli.packages.${system}.default
          ];
        in
        {
          packages = {
            default = buildEnv {
              name = "dotfiles-${inputs.self.lastModifiedDate or "dirty"}";
              paths =
                with pkgs;
                [
                  bash-completion
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
                  httpie
                  tldr
                  wget
                  git
                  lazygit
                  curl
                  eza
                  bat
                  htop-vim
                  gh
                  fastfetch
                  nodejs
                  tmux
                  fzf
                  opencode
                ]
                ++ lib.optionals stdenv.hostPlatform.isLinux [
                  xclip
                  wl-clipboard
                ]
                ++ flakePackages
                ++ lib.attrValues localTools;
            };

            bootstrap = pkgs.writeShellApplication {
              name = "dotfiles-bootstrap";
              runtimeInputs = with pkgs; [
                git
                jq
                stow
              ];
              text = lib.readFile ./scripts/bootstrap.sh;
            };

            eject = pkgs.writeShellApplication {
              name = "dotfiles-eject";
              runtimeInputs = with pkgs; [ stow ];
              text = lib.readFile ./scripts/eject.sh;
            };
          };

          treefmt.config = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.prettier.enable = true;
            programs.shfmt.enable = true;
            programs.stylua.enable = true;
            programs.taplo.enable = true;
          };
        };
    };
}
