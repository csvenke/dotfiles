from config import Config
from dotfiles import DotfilesManager
from scriptargs import ScriptArgs
import nix
import git


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
    if config.dotfiles_dir.exists():
        git.clone(config.dotfiles_url, str(config.dotfiles_dir))
    else:
        git.pull_origin("master", str(config.dotfiles_dir))

    print(">>> Cleaning dotfiles <<<")
    dotfiles.clean_all()

    print(">>> Symlinking dotfiles <<<")
    dotfiles.install_all()

    print(">>> Installing packages <<<")
    nix.profile_install(str(config.dotfiles_dir))

    print(">>> Upgrading packages <<<")
    nix.profile_upgrade_all()

    print(">>> DONE <<<")


def check_command(dotfiles: DotfilesManager):
    dotfiles.check_all()


def clean_command(dotfiles: DotfilesManager):
    dotfiles.clean_all()


if __name__ == "__main__":
    main()
