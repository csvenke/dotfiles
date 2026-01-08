final: prev: {
  context7-mcp = prev.callPackage ./context7-mcp/package.nix { };
  fzf = prev.callPackage ./fzf/package.nix { fzf = prev.fzf; };
  tmux = prev.callPackage ./tmux/package.nix { tmux = prev.tmux; };
}
