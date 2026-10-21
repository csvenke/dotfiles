{
  lib,
  fetchFromGitHub,
  importNpmLock,
  stdenvNoCC,
  nodejs,
}:

let
  mkGitHubPiExtension =
    {
      pname,
      version ? lib.substring 0 8 rev,
      owner,
      repo,
      rev ? "v${version}",
      hash,
      rootDir ? "",
    }:
    let
      src = fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          rootDir
          ;
      };
      hasNpmLock = lib.pathExists (src + "/package-lock.json");
      nodeModules = importNpmLock.buildNodeModules {
        npmRoot = src;
        inherit nodejs;
        derivationArgs.npmInstallFlags = [ "--omit=dev" ];
      };
    in
    stdenvNoCC.mkDerivation {
      inherit pname version src;
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r ${src}/. $out/
        ${lib.optionalString hasNpmLock ''
          if [ -d ${nodeModules}/node_modules ]; then
            cp -rL ${nodeModules}/node_modules $out/node_modules
          fi
        ''}
        runHook postInstall
      '';
    };

  mkLocalPiExtension =
    { npmRoot }:
    let
      manifest = lib.importJSON "${npmRoot}/package.json";
      nodeModules = importNpmLock.buildNodeModules {
        inherit npmRoot nodejs;
        derivationArgs.npmInstallFlags = [ "--omit=dev" ];
      };
    in
    stdenvNoCC.mkDerivation {
      pname = manifest.name;
      inherit (manifest) version;
      src = lib.cleanSourceWith {
        src = npmRoot;
        filter = name: _type: !(baseNameOf name == "node_modules");
      };
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r . $out/
        if [ -d ${nodeModules}/node_modules ]; then
          cp -rL ${nodeModules}/node_modules $out/node_modules
        fi
        runHook postInstall
      '';
    };

  # Line-continued for embedding in a makeWrapper invocation.
  extensionFlags =
    extensions:
    lib.concatMapStringsSep " \\\n    " (ext: ''--add-flags "--extension ${ext}"'') extensions;
in
{
  inherit
    mkGitHubPiExtension
    mkLocalPiExtension
    extensionFlags
    ;
}
