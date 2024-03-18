{
  description = "Fast node manager development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          packages = [
            pkgs.fnm
          ];

          shellHook = ''
            eval "$(fnm env --use-on-cd)"
            fnm use --install-if-missing --silent-if-unchanged
          '';
        };
      }
    );
}
