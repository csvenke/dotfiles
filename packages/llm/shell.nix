{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    python3Packages.anthropic
    python3Packages.click
    python3Packages.halo
  ];
}
