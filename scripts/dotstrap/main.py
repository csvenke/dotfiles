#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.config import Config
from utils import nix, shell
from utils.dotfiles import DotfilesManager
from utils.scriptargs import ScriptArgs

def main():
    args = ScriptArgs.parse()
    config = Config.from_script_args(args)
    dotfiles = DotfilesManager.from_config(config)

    if args.command == "install":
        return install_command(config, dotfiles)

    if args.command == "check":
        return check_command(dotfiles)

    if args.command == "clean":
        return clean_command(dotfiles)


def install_command(config: Config, dotfiles: DotfilesManager):
    print(">>> Symlink dotfiles")
    dotfiles.install_all()

    print(">>> Install nix packages <<<")
    home = config.get_source_path()
    nix.install(home)

    print(">>> Source .bashrc <<<")
    bashrc = config.get_target_path(".bashrc")
    shell.run(f"source {bashrc}")

    print(">>> DONE <<<")
    print("Restart shell for changes to take effect")


def check_command(dotfiles: DotfilesManager):
    print(">>> Check dotfiles status <<<")
    dotfiles.check_all()


def clean_command(dotfiles: DotfilesManager):
    print(">>> Cleaning all dotfiles <<<")
    dotfiles.clean_all()


if __name__ == "__main__":
    main()
