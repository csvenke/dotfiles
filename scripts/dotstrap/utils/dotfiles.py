import os
import shutil
from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path

from utils.config import Config
from utils.scriptargs import ScriptArgs


class DotfileLifecycle(ABC):
    @abstractmethod
    def install(self):
        pass

    @abstractmethod
    def check(self):
        pass

    @abstractmethod
    def clean(self):
        pass


@dataclass
class DotfilesManager:
    dotfiles: list[DotfileLifecycle]

    @classmethod
    def from_script_args(cls, args: ScriptArgs):
        config = Config.load(args.dotfiles_dir, args.target_dir)
        create_dotfiles = make_create_dotfiles(config.source_dir, config.target_dir)
        dotfiles: list[DotfileLifecycle] = [
            SymlinkDotfiles(create_dotfiles(config.symlink_paths)),
            DeleteDotfiles(create_dotfiles(config.delete_paths)),
        ]

        return cls(dotfiles)

    def install_all(self):
        for dotfile in self.dotfiles:
            dotfile.install()

    def clean_all(self):
        for dotfile in self.dotfiles:
            dotfile.clean()

    def check_all(self):
        for dotfile in self.dotfiles:
            dotfile.check()


@dataclass
class Dotfile:
    source: Path
    target: Path

    def symlink(self):
        symlink_path(self.source, self.target)

    def unlink(self):
        if self.target.is_symlink():
            self.target.unlink()

    def is_symlinked(self) -> bool:
        return self.target.is_symlink() & self.target.exists()

    def exists(self) -> bool:
        return self.target.exists()

    def remove(self):
        remove_path(self.target)


@dataclass
class SymlinkDotfiles(DotfileLifecycle):
    dotfiles: list[Dotfile]

    def install(self):
        for dotfile in self.dotfiles:
            dotfile.symlink()

    def check(self):
        for dotfile in self.dotfiles:
            if dotfile.is_symlinked():
                print("OK!", dotfile.target)
            else:
                print("ERROR!", dotfile.target)

    def clean(self):
        for dotfile in self.dotfiles:
            dotfile.remove()


@dataclass
class DeleteDotfiles(DotfileLifecycle):
    dotfiles: list[Dotfile]

    def install(self):
        for dotfile in self.dotfiles:
            dotfile.unlink()

    def check(self):
        for dotfile in self.dotfiles:
            if dotfile.is_symlinked():
                print("ERROR!", dotfile.target)

    def clean(self):
        for dotfile in self.dotfiles:
            dotfile.unlink()


def make_create_dotfiles(source_dir: Path, target_dir: Path):
    return lambda paths: [
        Dotfile(Path(source_dir, path), Path(target_dir, path)) for path in paths
    ]


def remove_path(path: Path):
    if path.is_symlink():
        print(f"Unlinking {path}")
        path.unlink()
        return

    if path.is_dir():
        print(f"Deleting directory {path}")
        shutil.rmtree(path)
        return

    if path.exists():
        print(f"Deleting file {path}")
        os.remove(path)


def symlink_path(source: Path, target: Path):
    if target.is_symlink():
        print(f"Symlink already exists: {target}")
        return

    if target.exists():
        print(f"Removing existing file or directory: {target}")
        remove_path(target)

    print(f"Creating symlink: {source} -> {target}")
    create_file_if_missing(source)
    make_parents_if_missing(target)
    target.symlink_to(source, source.is_dir())


def create_file_if_missing(path: Path):
    if not path.exists():
        make_parents_if_missing(path)
        path.touch()


def make_parents_if_missing(path: Path):
    if not path.parent.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
