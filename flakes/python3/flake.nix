{
  description = "Python3 development environment";

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
        python3 = pkgs.python3.withPackages (ps: [
          ps.pip
          ps.pipx
        ]);
      in {
        devShell = pkgs.mkShell {
          packages = [
            python3
          ];
        };
      }
    );
}
