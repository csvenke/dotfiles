{ beads }:

beads.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./patches/beads/no-claude-on-stealth-init.patch
  ];
})
