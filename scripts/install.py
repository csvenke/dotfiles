#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from pathlib import Path

from utils.dotfiles import Dotfiles
from utils.nix import NixEnvironment
from utils.shell import run_shell_command
from utils.config import Config


def main():
    config = Config()

    print(">>> Install nix environment <<<")
    NixEnvironment.install(config)

    print(">>> Creating .config directory if missing <<<")
    config_dir = Path(Path.home(), ".config")
    if not config_dir.exists():
        print("Creating .config directory")
        config_dir.mkdir()

    print(">>> Remove old dotfiles if exists <<<")
    for dotfile in Dotfiles.get_old():
        dotfile.remove()

    print(">>> Symlink dotfiles <<<")
    for dotfile in Dotfiles.get():
        dotfile.symlink()

    print(">>> Install tmux plugins <<<")
    run_shell_command("tmux-plugin-manager-install")

    print(">>> Sync neovim plugins <<<")
    run_shell_command('nvim --headless "+Lazy! sync" +qa')

    print(">>> Source .bashrc <<<")
    bashrc = Path(Path.home(), ".bashrc")
    run_shell_command(f"source {bashrc}")


if __name__ == "__main__":
    main()
