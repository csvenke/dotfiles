final: prev: {
  fzf = prev.callPackage ./fzf/package.nix { fzf = prev.fzf; };
}
