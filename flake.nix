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
            config = {
              allowUnfree = true;
            };
          };
          inherit (pkgs) lib callPackage;

          packages = lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./nix/packages;
          };
          scripts = lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./nix/scripts;
          };
        in
        {
          packages = scripts // {
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
