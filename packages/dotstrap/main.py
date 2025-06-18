import git
from pathlib import Path
import nix
from config import Config
from dotfiles import DotfilesManager
import pyfiglet

import click

pass_dotfiles = click.make_pass_decorator(DotfilesManager)


@click.group()
@click.option(
    "--remote-url", default="https://github.com/csvenke/dotfiles.git", type=str
)
@click.option("--remote-branch", default="master", type=str)
@click.option("--dotfiles-dir", default=Path(Path.home(), ".dotfiles"), type=Path)
@click.option("--target-dir", default=Path.home(), type=Path)
@click.pass_context
def cli(
    ctx: click.Context,
    remote_url: str,
    remote_branch: str,
    dotfiles_dir: Path,
    target_dir: Path,
):
    print(pyfiglet.figlet_format("Dotstrap"))

    if dotfiles_dir.exists():
        git.pull_origin(remote_branch, str(dotfiles_dir))
    else:
        git.clone(remote_url, str(dotfiles_dir))

    config = Config.from_script_args(dotfiles_dir, target_dir)
    dotfiles = DotfilesManager.from_config(config)

    ctx.obj = dotfiles


@cli.command()
@pass_dotfiles
def install(dotfiles: DotfilesManager):
    print(">>> Cleaning dotfiles <<<")
    dotfiles.clean_all()

    print(">>> Symlinking dotfiles <<<")
    dotfiles.install_all()

    print(">>> Installing packages <<<")
    nix.profile_install(str(dotfiles.path))

    print(">>> Upgrading packages <<<")
    nix.profile_upgrade_all()

    print(">>> DONE <<<")


@cli.command()
@pass_dotfiles
def update(dotfiles: DotfilesManager):
    print(">>> Updating flake.lock <<<")
    nix.flake_update(str(dotfiles.path))

    print(">>> Installing packages <<<")
    nix.profile_install(str(dotfiles.path))

    print(">>> Upgrading packages <<<")
    nix.profile_upgrade_all()

    print(">>> DONE <<<")


@cli.command()
@pass_dotfiles
def check(dotfiles: DotfilesManager):
    print(">>> Checking dotfiles <<<")
    dotfiles.check_all()


@cli.command()
@pass_dotfiles
def clean(dotfiles: DotfilesManager):
    print(">>> Cleaning dotfiles <<<")
    dotfiles.clean_all()


if __name__ == "__main__":
    cli()
