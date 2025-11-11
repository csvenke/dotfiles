{
  opencode,
  fetchFromGitHub,
  fetchpatch,
  stdenvNoCC,
}:

opencode.overrideAttrs (prev: rec {
  version = "1.0.55";

  src = fetchFromGitHub {
    owner = "sst";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-iKD58BA1ueIVsQXvsAZwXCMkSAM1ZzYPL8WGtKANfIE=";
  };

  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/op/opencode/local-models-dev.patch";
      hash = "sha256-fbSRO1D2RCFMAMzwnDULy+/Os1ZXpSyJ983tIfSPAVI=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/op/opencode/skip-npm-pack.patch";
      hash = "sha256-ooLOMgwfjEkp0rpU1SviNsG5GQTSK+emjYZONQu7aEE=";
    })
  ];

  node_modules = stdenvNoCC.mkDerivation {
    pname = "opencode-node_modules";
    inherit version src;
    inherit (prev.node_modules)
      impureEnvVars
      nativeBuildInputs
      dontConfigure
      buildPhase
      installPhase
      dontFixup
      outputHashAlgo
      outputHashMode
      ;

    outputHash = "sha256-RIHrhZ2dr3zlyMq4WUSaUdFiVTqNuM87iNZvNizSjKk=";
  };

  env = prev.env // {
    OPENCODE_VERSION = version;
  };
})
