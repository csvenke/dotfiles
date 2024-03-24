#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.nix import NixEnvironment
from utils.shell import Shell
from utils.dotfiles import DotfilesManager
from utils.scriptargs import ScriptArgs


def main():
    dotfiles = DotfilesManager.from_script_args(ScriptArgs.parse())

    print(">>> Updating nix environment <<<")
    nix_environment = NixEnvironment(dotfiles)
    nix_environment.install()

    print(">>> Updating all dotfiles")
    dotfiles.install_all()

    print(">>> Update neovim plugins <<<")
    Shell.run('nvim --headless "+Lazy! update" +qa')


if __name__ == "__main__":
    main()
