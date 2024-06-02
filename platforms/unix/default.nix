with import <nixpkgs-unstable> { };

buildEnv {
  name = "Home environment";
  paths = [
    # Config
    (callPackage ../../nixpkgs/bashrc { })

    # Shell
    starship
    (callPackage ../../nixpkgs/tmux { })

    # Editors
    (callPackage ../../nixpkgs/neovim { })

    # Tools
    (callPackage ../../nixpkgs/dev { })
    findutils
    direnv
    nix-direnv
    eza
    bat
    silver-searcher
    delta
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
