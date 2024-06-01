with import <nixpkgs-unstable> { };

buildEnv {
  name = "Home environment";
  paths = [
    # Config
    (callPackage ../../nixpkgs/bashrc { })

    coreutils
    findutils
    direnv
    nix-direnv
    eza
    bat
    silver-searcher
    delta

    # Shell
    starship
    (callPackage ../../nixpkgs/tmux { })

    # Editors
    (callPackage ../../nixpkgs/neovim { })

    # Tools
    (callPackage ../../nixpkgs/dev { })
    devenv
    ripgrep
    jq
    gh
    tldr
    git
    wget
    curl
    fzf
  ];
}
