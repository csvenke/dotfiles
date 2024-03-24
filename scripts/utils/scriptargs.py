from pathlib import Path
import argparse


class ScriptArgs:
    @staticmethod
    def parse():
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "-d",
            "--dotfilesDirectory",
            default=str(Path(Path.home(), ".dotfiles")),
            help="Default is $HOME/.dotfiles",
        )
        parser.add_argument(
            "-t", "--targetDirectory", default=str(Path.home()), help="Default is $HOME"
        )
        args = parser.parse_args()

        return ScriptArgs(args)

    def __init__(self, args: argparse.Namespace):
        self.dotfiles_directory = Path(args.dotfilesDirectory)
        self.target_directory = Path(args.targetDirectory)
