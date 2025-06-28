{ buildNpmPackage }:

buildNpmPackage {
  pname = "@google/gemini-cli";
  version = "0.1.5";
  src = ./.;
  npmDepsHash = "sha256-dSFxvZRStokgWQbumG4ZTZZJ6t/kUc4xQO++lRgS6qM=";
}
