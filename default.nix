{pkgs ? import <nixpkgs> {}}: let
  tmuxPluginManagerDrv = pkgs.stdenv.mkDerivation {
    name = "tmux plugin manager";
    src = builtins.fetchGit {
      url = "https://github.com/tmux-plugins/tpm";
      ref = "master";
      rev = "99469c4a9b1ccf77fade25842dc7bafbc8ce9946";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };
  jvmEnv = pkgs.buildEnv {
    name = "jvm env";
    paths = with pkgs; [
      jdk
      maven
      gradle
    ];
  };
  dotnetEnv = pkgs.buildEnv {
    name = "dotnet env";
    paths = with pkgs; [
      dotnet-sdk_7
    ];
  };
  rustEnv = pkgs.buildEnv {
    name = "rust env";
    paths = with pkgs; [
      rustup
    ];
  };
  nodejsEnv = pkgs.buildEnv {
    name = "nodejs env";
    paths = with pkgs; [
      nodejs
      bun
      yarn
      nodePackages.pnpm
      nodePackages.prettier
    ];
  };
  pythonEnv = pkgs.buildEnv {
    name = "python env";
    paths = with pkgs; [
      python3
      python311Packages.pip
    ];
  };
  neovimEnv = pkgs.buildEnv {
    name = "neovim env";
    paths = with pkgs; [
      coreutils
      tree-sitter
      alejandra
      gcc
      unzip
      gzip
      fd
      ripgrep
      curl
      wget
      git
      gh
      lazygit
      tmux
      delta
      neovim
      shell_gpt
    ];
  };
in
  pkgs.mkShell {
    packages = [
      neovimEnv
      dotnetEnv
      jvmEnv
      nodejsEnv
      rustEnv
      pythonEnv
    ];
    DOTNET_ROOT = "${pkgs.dotnet-sdk_7}";
    TMUX_PLUGIN_MANAGER_SCRIPT = "${tmuxPluginManagerDrv}/tpm";
  }
