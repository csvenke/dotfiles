{ beads }:

beads.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./patches/no-claude-on-stealth-init.patch
  ];
})
