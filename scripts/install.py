#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.nix import NixEnvironment
from utils.shell import Shell
from utils.dotfiles import DotfilesManager
from utils.scriptargs import ScriptArgs


def main():
    dotfiles = DotfilesManager.from_script_args(ScriptArgs.parse())

    print(">>> Install nix environment <<<")
    nix_environment = NixEnvironment(dotfiles)
    nix_environment.install()

    print(">>> Creating .config directory if missing <<<")
    config_dir = dotfiles.get_target_path(".config")
    if not config_dir.exists():
        print("Creating .config directory")
        config_dir.mkdir()

    print(">>> Installing all dotfiles")
    dotfiles.install_all()

    print(">>> Update neovim plugins <<<")
    Shell.run('nvim --headless "+Lazy! update" +qa')

    print(">>> DONE <<<")
    print("Restart shell for changes to take effect")


if __name__ == "__main__":
    main()
