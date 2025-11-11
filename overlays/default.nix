final: prev: {
  fzf = prev.callPackage ./fzf/package.nix { fzf = prev.fzf; };
  opencode = prev.callPackage ./opencode/package.nix { opencode = prev.opencode; };
  tmux = prev.callPackage ./tmux/package.nix { tmux = prev.tmux; };
}
