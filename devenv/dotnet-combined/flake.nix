{
  description = "Combined dotnet development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs.dotnetCorePackages) combinePackages sdk_6_0 sdk_7_0 sdk_8_0;
        dotnet = (combinePackages [
          sdk_6_0
          sdk_7_0
          sdk_8_0
        ]);
      in
      {
        devShell = pkgs.mkShell {
          packages = [
            dotnet
          ];
        };
      }
    );
}
