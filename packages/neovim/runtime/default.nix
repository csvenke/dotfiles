{ pkgs }:

with pkgs;
[
  tree-sitter
  gcc
  ripgrep
  fd
  findutils
  gnutar
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
  git
  lazygit
  xclip

  ### Lua ###
  lua-language-server
  stylua

  ### Nix ###
  nil
  nixpkgs-fmt

  ### Bash ###
  nodePackages.bash-language-server
  shfmt
  shellcheck

  ### Python ###
  (python3.withPackages (ps: [ ps.pip ps.pipx ]))
  pyright
  ruff-lsp

  ### Markdown ###
  marksman

  ### Yaml ###
  yaml-language-server

  ### TOML ###
  taplo

  ### Json, eslint, markdown, css, html ###
  vscode-langservers-extracted
  vscode-extensions.dbaeumer.vscode-eslint

  ### Prettier ###
  prettierd

  ### Javascript/Typescript ###
  nodejs
  nodePackages.typescript-language-server
]

