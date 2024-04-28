from utils.dotfiles import DotfilesManager
from utils.shell import Shell


class Nix:
    def __init__(self, dotfiles: DotfilesManager):
        self.path = dotfiles.get_path("home.nix")

    def install(self):
        if self.path.exists():
            Shell.run(f"nix-env -if {self.path}")
            Shell.run("nix-env --delete-generations +5")
        else:
            print("home.nix does not exist. Doing nothing")

    def add_unstable_channel(self):
        Shell.run(
            "nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable"
        )
        Shell.run("nix-channel --update")
