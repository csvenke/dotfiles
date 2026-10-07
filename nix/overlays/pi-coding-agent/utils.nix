{
  lib,
  fetchurl,
  importNpmLock,
  stdenvNoCC,
  nodejs,
}:

let
  # Registry tarball URL for an npm package. Scoped packages (@scope/name)
  # publish their tarball under the unscoped name.
  npmTarballUrl =
    pname: version:
    "https://registry.npmjs.org/${pname}/-/${lib.last (lib.splitString "/" pname)}-${version}.tgz";

  # Fetch the registry tarball of an npm package.
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

  # Build a pi extension from its npm tarball, vendoring its dependencies
  # from the package-lock.json in npmRoot.
  mkPiExtension =
    { npmRoot, hash }:
    let
      manifest = lib.importJSON "${npmRoot}/package.json";
      nodeModules = importNpmLock.buildNodeModules { inherit npmRoot nodejs; };
    in
    stdenvNoCC.mkDerivation {
      pname = manifest.name;
      inherit (manifest) version;
      src = fetchNpmPackage {
        pname = manifest.name;
        inherit (manifest) version;
        inherit hash;
      };
      sourceRoot = "package";
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

  # One `--extension` flag per extension, line-continued for embedding in a
  # makeWrapper invocation.
  extensionFlags =
    extensions:
    lib.concatMapStringsSep " \\\n    " (ext: ''--add-flags "--extension ${ext}"'') extensions;
in
{
  inherit
    fetchNpmPackage
    mkPiExtension
    extensionFlags
    ;
}
