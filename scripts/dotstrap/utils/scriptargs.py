from pathlib import Path
import argparse


class ScriptArgs:
    @classmethod
    def parse(cls):
        parser = argparse.ArgumentParser()

        sub_parser = parser.add_subparsers(dest="command")

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
        sub_parser.add_parser("update")
        sub_parser.add_parser("clean")
        sub_parser.add_parser("check")

        args: dict[str, str] = vars(parser.parse_args())

        return cls(args)

    def __init__(self, args: dict[str, str]):
        self.command = str(args.get("command"))
        self.dotfiles_dir = Path(str(args.get("dotfilesDirectory")))
        self.target_dir = Path(str(args.get("targetDirectory")))
