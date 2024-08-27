{ pkgs }:

let
  config = pkgs.callPackage ./config { };
  runtime = pkgs.callPackage ./runtime { };
  plugins = pkgs.callPackage ./plugins { };

  overrideNeovim = pkgs.neovim.override {
    configure = {
      customRC = config;
      packages.all.start = plugins;
    };
  };
in

pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = runtime;
  text = ''
    ${overrideNeovim}/bin/nvim "$@"
  '';
}
