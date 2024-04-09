#! /usr/bin/env nix-shell
#! nix-shell -i python -p python3


from utils.nix import Nix
from utils.shell import Shell
from utils.dotfiles import DotfilesManager
from utils.scriptargs import ScriptArgs


def main():
    args = ScriptArgs.parse()
    dotfiles = DotfilesManager.from_script_args(args)
    nix = Nix(dotfiles)

    if args.command == "install":
        return install(dotfiles, nix)

    if args.command == "check":
        return check(dotfiles)

    if args.command == "uninstall":
        return uninstall(dotfiles)


def install(dotfiles: DotfilesManager, nix: Nix):
    print(">>> Add nixpkgs-unstable <<<")
    nix.add_unstable_channel()

    print(">>> Install nix packages <<<")
    nix.install()

    print(">>> Creating .config directory if missing <<<")
    config_dir = dotfiles.get_target_path(".config")
    if not config_dir.exists():
        print("Creating .config directory")
        config_dir.mkdir()

    print(">>> Installing all dotfiles")
    dotfiles.install_all()

    print(">>> Update neovim plugins <<<")
    Shell.run('nvim --headless "+Lazy! update" +qa')

    print(">>> Source .bashrc <<<")
    bashrc = dotfiles.get_target_path(".bashrc")
    Shell.run(f"source {bashrc}")

    print(">>> DONE <<<")
    print("Restart shell for changes to take effect")


def check(dotfiles: DotfilesManager):
    print(">>> Check dotfiles status <<<")
    dotfiles.check_all()


def uninstall(dotfiles: DotfilesManager):
    print(">>> Uninstalling all dotfiles <<<")
    dotfiles.uninstall_all()


if __name__ == "__main__":
    main()
