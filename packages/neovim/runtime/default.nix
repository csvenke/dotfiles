{ pkgs, language-servers }:

with pkgs;
[
  # Deps
  tree-sitter
  gcc
  ripgrep
  fd
  findutils
  gnutar
  git
  lazygit
  fzf
  wget
  curl
  unzip
  gzip
  gnumake
  gnutar
  gnused
  gnugrep
  xdg-utils

  # Nix
  nil
  nixpkgs-fmt

  # Bash
  nodePackages.bash-language-server
  shellcheck
  shfmt

  # Haskell
  haskell-language-server
  haskellPackages.hoogle
  haskellPackages.fast-tags

  # Dotnet
  dotnet-sdk
  omnisharp-roslyn

  # Java
  jdk
  jdt-language-server

  # Typescript
  nodejs
  nodePackages.typescript-language-server

  ## Rust
  cargo
  rustc
  rust-analyzer

  # Lua
  lua-language-server
  stylua

  # Markdown
  markdownlint-cli
  marksman

  # Eslint
  vscode-extensions.dbaeumer.vscode-eslint

  # Prettier
  prettierd

  # Python
  (python3.withPackages (ps: [ ps.pip ps.pipx ]))
  pyright
  ruff-lsp

  # Yaml
  yaml-language-server

  # TOML
  taplo

  # Json, eslint, markdown, css, html
  vscode-langservers-extracted

  # Angular
  language-servers.packages.angular-language-server
]

