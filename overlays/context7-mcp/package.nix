{
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage rec {
  pname = "context7-mcp";
  version = "1.0.31";
  src = fetchurl {
    url = "https://registry.npmjs.org/@upstash/context7-mcp/-/context7-mcp-${version}.tgz";
    hash = "sha256-GW2uWkiIfEjzVuaDYZh4Son8BqXyHLtQgIzqBIek0Bc=";
  };
  sourceRoot = "package";
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';
  npmDepsHash = "sha256-/YfBqfBkKRKYa6mHWl+HrtKN0Ce6hsRmr7Fyl/QD5fQ=";
  dontNpmBuild = true;
}
