{ pkgs, language-servers }:

let

  config = import ./config { inherit pkgs; };
  runtime = import ./runtime { inherit pkgs; inherit language-servers; };
  plugins = import ./plugins { inherit pkgs; };

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
