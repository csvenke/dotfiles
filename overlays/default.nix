final: prev: {
  fzf = prev.callPackage ./fzf/package.nix { fzf = prev.fzf; };
  tmux = prev.callPackage ./tmux/package.nix { tmux = prev.tmux; };
}
