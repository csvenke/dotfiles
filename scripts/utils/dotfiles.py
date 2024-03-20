from pathlib import Path
from utils.config import Config
from utils.shell import run_shell_command


class Dotfile:
    def __init__(self, source: Path, target: Path):
        self.source = source
        self.target = target

    def symlink(self):
        if self.target.is_symlink():
            print(f"Symlink already exists: {self.target}")
            return

        if self.target.exists():
            print(f"Removing existing file or directory: {self.target}")
            run_shell_command(f"rm -rf {self.target}")

        print(f"Creating symlink: {self.target} -> {self.source}")
        self.target.symlink_to(self.source, self.source.is_dir())

    def is_symlinked(self):
        return self.target.is_symlink()

    def exists(self):
        return self.target.exists()

    def remove(self):
        if self.target.exists():
            print(f"Deleting {self.target}")
            run_shell_command(f"rm -rf {self.target}")


class Dotfiles:
    @staticmethod
    def get() -> list[Dotfile]:
        paths = Config().dotfiles()
        return Dotfiles.create(paths)

    @staticmethod
    def get_old() -> list[Dotfile]:
        paths = Config().old_dotfiles()
        return Dotfiles.create(paths)

    @staticmethod
    def get_manual() -> list[Dotfile]:
        paths = Config().manual_dotfiles()
        return Dotfiles.create(paths)

    @staticmethod
    def create(paths: list[str]) -> list[Dotfile]:
        def create_dotfile(path: str) -> Dotfile:
            src = Path(Config.dotfilesFolder(), path)
            target = Path(Path.home(), path)
            return Dotfile(src, target)

        return list(map(create_dotfile, paths))
