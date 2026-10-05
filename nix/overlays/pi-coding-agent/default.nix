final: prev:

let
  inherit (prev)
    lib
    fetchurl
    stdenvNoCC
    symlinkJoin
    makeWrapper
    ;

  # Registry tarball URL for an npm package. Scoped packages (@scope/name)
  # publish their tarball under the unscoped name.
  npmTarballUrl =
    pname: version:
    "https://registry.npmjs.org/${pname}/-/${lib.last (lib.splitString "/" pname)}-${version}.tgz";

  fetchNpmPackage =
    {
      pname,
      version,
      hash,
    }:
    fetchurl {
      url = npmTarballUrl pname version;
      inherit hash;
    };

  # Build a pi extension from its npm tarball, vendoring any pinned deps
  # into node_modules.
  mkPiExtension =
    {
      pname,
      version,
      hash,
      files,
      description,
      homepage,
      license ? lib.licenses.mit,
      deps ? [ ],
    }:
    let
      installDep = dep: ''
        dep_tmp=$(mktemp -d)
        tar -xzf ${fetchNpmPackage dep} -C "$dep_tmp"
        mkdir -p "$out/node_modules/$(dirname "${dep.pname}")"
        cp -r "$dep_tmp/package" "$out/node_modules/${dep.pname}"
        rm -rf "$dep_tmp"
      '';
    in
    stdenvNoCC.mkDerivation {
      inherit pname version;

      src = fetchNpmPackage { inherit pname version hash; };

      sourceRoot = "package";

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r ${lib.concatStringsSep " " files} $out/
        ${lib.concatMapStringsSep "\n" installDep deps}
        runHook postInstall
      '';

      meta = {
        inherit description homepage license;
      };
    };

  # pi-web-access ships an npm lockfile, so it builds its node_modules with
  # importNpmLock instead of mkPiExtension's vendored-tarball deps.
  pi-web-access =
    let
      version = "0.37.0";
      nodeModules = prev.importNpmLock.buildNodeModules {
        npmRoot = ./pi-web-access;
        nodejs = prev.nodejs;
      };
    in
    stdenvNoCC.mkDerivation {
      inherit version;
      pname = "pi-web-access";

      src = fetchurl {
        url = "https://registry.npmjs.org/pi-web-access/-/pi-web-access-${version}.tgz";
        hash = "sha512-Je7D5ghQi9dpN0KhpFMuHYwKy0oBvpNrNR7zuTzSyCRsIJDC5in8yGz/3yItxvWYHF1W+q2Sq190nyaLkoWhgg==";
      };

      sourceRoot = "package";

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r package.json dist README.md LICENSE $out/
        cp -rL ${nodeModules}/node_modules $out/node_modules
        runHook postInstall
      '';

      meta = {
        description = "Web search, URL fetching, GitHub repo cloning, PDF extraction, and YouTube/video understanding for pi";
        homepage = "https://github.com/nicobailon/pi-web-access";
        license = lib.licenses.mit;
      };
    };

  piExtensions = map mkPiExtension (import ./extensions.nix) ++ [ pi-web-access ];

  pi-latest = prev.pi-coding-agent.overrideAttrs (old: rec {
    version = "1.0.3";

    src = prev.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${version}";
      hash = "sha256-2SfC8zEf6emG1sDG1J7hjjSBt+3hFIz1/TcwBLa/hRU=";
    };

    npmDeps = prev.fetchNpmDeps {
      inherit src;
      name = "pi-coding-agent-${version}-npm-deps";
      hash = "sha256-SpbadDFtPdwn+H2TXDl1TGAI+ejb6dbRvALZoUIvx3c=";
    };

    # Model catalog shipped in the pi-ai npm package
    modelData = fetchNpmPackage {
      pname = "@earendil-works/pi-ai";
      inherit version;
      hash = "sha256-3YmV+x3zyj4r0DMFO9LCi0DES7f1PCU1eMpoCCYR4O4=";
    };
  });

  # One --extension flag per bundled extension
  extensionFlags = lib.concatMapStringsSep " \\\n          " (
    ext: ''--add-flags "--extension ${ext}"''
  ) piExtensions;
in
{
  pi-coding-agent = symlinkJoin {
    name = "pi-coding-agent-with-extensions-${pi-latest.version}";
    paths = [ pi-latest ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      rm $out/bin/pi
      makeWrapper ${lib.getExe pi-latest} $out/bin/pi \
        ${extensionFlags}
    '';
    meta = pi-latest.meta // {
      description = "pi-coding-agent with bundled extensions";
    };
  };
}
