from utils.dotfiles import DotfilesManager
from utils.shell import Shell


class NixEnvironment:
    def __init__(self, dotfiles: DotfilesManager):
        self.path = dotfiles.get_path("env.nix")

    def install(self):
        if self.path.exists():
            Shell.run(f"nix-env -if {self.path}")
        else:
            print("env.nix does not exist. Doing nothing")
