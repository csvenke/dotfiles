from pathlib import Path
import argparse


class ScriptArgs:
    @classmethod
    def parse(cls):
        parser = argparse.ArgumentParser()
        sub_parser = parser.add_subparsers(dest="command")

        parser.add_argument(
            "--remoteUrl",
            default="https://github.com/csvenke/dotfiles.git",
            help="Default is https://github.com/csvenke/dotfiles.git",
        )
        parser.add_argument(
            "--remoteBranch",
            default="master",
            help="Default is master",
        )
        parser.add_argument(
            "-d",
            "--dotfilesDirectory",
            default=str(Path(Path.home(), ".dotfiles")),
            help="Default is $HOME/.dotfiles",
        )
        parser.add_argument(
            "-t",
            "--targetDirectory",
            default=str(Path.home()),
            help="Default is $HOME",
        )

        sub_parser.add_parser("install")
        sub_parser.add_parser("clean")
        sub_parser.add_parser("check")

        args: dict[str, str] = vars(parser.parse_args())

        return cls(args)

    def __init__(self, args: dict[str, str]):
        self.command = str(args.get("command"))
        self.remote_url = str(args.get("remoteUrl"))
        self.remote_branch = str(args.get("remoteBranch"))
        self.dotfiles_dir = Path(str(args.get("dotfilesDirectory")))
        self.target_dir = Path(str(args.get("targetDirectory")))
