#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3

from utils.dotfiles import Dotfiles


def main():
    print(">>> Check if dotfiles are symlinked <<<")
    for dotfile in Dotfiles.get():
        if dotfile.is_symlinked():
            print("OK!", dotfile.source)
        else:
            print("ERROR!", dotfile.source)

    print(">>> Check if manual dotfiles exists <<<")
    for dotfile in Dotfiles.get_manual():
        if dotfile.exists():
            print("OK!", dotfile.source)
        else:
            print("MISSING!", dotfile.source)

    print(">>> Check if old dotfiles exists <<<")
    for dotfile in Dotfiles.get_old():
        if dotfile.exists():
            print("OK!", dotfile.source)
        else:
            print("ERROR!", dotfile.source)


if __name__ == "__main__":
    main()