#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.scriptargs import ScriptArgs
from utils.dotfiles import DotfilesManager


def main():
    dotfiles = DotfilesManager.from_script_args(ScriptArgs.parse())

    print(">>> Uninstalling all dotfiles <<<")
    dotfiles.uninstall_all()


if __name__ == "__main__":
    main()
