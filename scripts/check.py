#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.dotfiles import DotfilesManager
from utils.scriptargs import ScriptArgs


def main():
    dotfiles = DotfilesManager.from_script_args(ScriptArgs.parse())

    print(">>> Check dotfiles status <<<")
    dotfiles.check_all()


if __name__ == "__main__":
    main()
