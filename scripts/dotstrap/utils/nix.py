from pathlib import Path

from utils import shell


def install(path: Path):
    shell.run(
        "nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable"
    )
    shell.run("nix-channel --update")

    if path.exists():
        shell.run(f"nix-env -if {path}")
        shell.run("nix-env --delete-generations +5")
