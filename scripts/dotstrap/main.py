#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

import shell
from config import Config
from dotfiles import DotfilesManager
from scriptargs import ScriptArgs

def main():
    args = ScriptArgs.parse()
    config = Config.from_script_args(args)
    dotfiles = DotfilesManager.from_config(config)

    match args.command:
        case "install":
            install_command(config, dotfiles)
        case "check":
            check_command(dotfiles)
        case "clean":
            clean_command(dotfiles)


def install_command(config: Config, dotfiles: DotfilesManager):
    print(">>> Unlinking all dotfiles <<<")
    dotfiles.clean_all()

    print(">>> Symlink dotfiles")
    dotfiles.install_all()

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
