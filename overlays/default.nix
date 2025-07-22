final: prev: {
  opencode = prev.opencode.overrideAttrs (oldAttrs: {
    node_modules = oldAttrs.node_modules.overrideAttrs (nodeAttrs: {
      outputHash = "sha256-XIRV1QrgRHnpJyrgK9ITxH61dve7nWfVoCPs3Tc8nuU=";
      buildPhase = ''
        runHook preBuild

        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

        bun install \
          --filter=opencode \
          --force \
          --no-progress

        runHook postBuild
      '';
    });
  });
}
