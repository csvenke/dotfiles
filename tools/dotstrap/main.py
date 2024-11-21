import git
import nix
from config import Config
from dotfiles import DotfilesManager
from scriptargs import ScriptArgs


def main():
    args = ScriptArgs.parse()
    clone_or_update_dotfiles(args)

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
    print(">>> Checking dotfiles <<<")
    dotfiles.check_all()


def clean_command(dotfiles: DotfilesManager):
    print(">>> Cleaning dotfiles <<<")
    dotfiles.clean_all()


def clone_or_update_dotfiles(args: ScriptArgs):
    if args.dotfiles_dir.exists():
        git.pull_origin(args.remote_branch, str(args.dotfiles_dir))
    else:
        git.clone(args.remote_url, str(args.dotfiles_dir))


if __name__ == "__main__":
    main()
