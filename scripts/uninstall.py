#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.dotfiles import Dotfiles
from utils.nix import NixEnvironment


def main():
    print(">>> Removing all dotfiles <<<")
    all_dotfiles = [*Dotfiles.get(), *Dotfiles.get_old(), *Dotfiles.get_manual()]
    for dotfile in all_dotfiles:
        dotfile.remove()

    print(">>> Uninstalling nix environment <<<")
    NixEnvironment.uninstall()


if __name__ == "__main__":
    main()
