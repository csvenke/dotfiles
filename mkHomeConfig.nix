{
  inputs,
  username,
  homeDirectory,
  modules,
  system,
}:

let
  configureUser = username: homeDirectory: {
    home.username = username;
    home.homeDirectory = homeDirectory;
  };

  configureNix =
    stateVersion:
    { pkgs, ... }:
    let
      nixPackage = pkgs.nixVersions.nix_2_24;
    in
    {
      home.stateVersion = stateVersion;
      home.packages = [ nixPackage ];
      nix.package = nixPackage;
      nix.extraOptions = ''
        experimental-features = nix-command flakes
        allow-dirty = true
        warn-dirty = false
        nix-path = nixpkgs=${inputs.nixpkgs}
      '';
    };

  defaultModules = [
    (configureNix "24.05")
    (configureUser username homeDirectory)
  ];
in

inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs { inherit system; };
  modules = defaultModules ++ modules;
  extraSpecialArgs = {
    inherit inputs;
  };
}
