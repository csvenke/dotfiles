import functools
import json
from pathlib import Path
import os
import shutil
from abc import ABC, abstractmethod
from typing import Any
from dataclasses import dataclass

from utils.scriptargs import ScriptArgs


class DotfileLifecycle(ABC):
    @abstractmethod
    def install(self):
        pass

    @abstractmethod
    def check(self):
        pass

    @abstractmethod
    def uninstall(self):
        pass


@dataclass
class DotfilesManager:
    dotfiles_dir: Path
    target_dir: Path
    dotfiles: list[DotfileLifecycle]

    @classmethod
    def from_script_args(cls, args: ScriptArgs):
        dotfiles_directory = args.dotfiles_dir
        target_directory = args.target_dir
        config_loader = DotfileConfigLoader(dotfiles_directory, target_directory)
        dotfiles: list[DotfileLifecycle] = [
            SymlinkDotfiles(config_loader.get("dotfiles", "symlink")),
            DeprecatedDotfiles(config_loader.get("dotfiles", "deprecated")),
            ManualDotfiles(config_loader.get("dotfiles", "manual")),
        ]
        return cls(dotfiles_directory, target_directory, dotfiles)

    def install_all(self):
        for dotfile in self.dotfiles:
            dotfile.install()

    def uninstall_all(self):
        for dotfile in self.dotfiles:
            dotfile.uninstall()

    def check_all(self):
        for dotfile in self.dotfiles:
            dotfile.check()

    def get_path(self, path: str):
        return Path(self.dotfiles_dir, path)

    def get_target_path(self, path: str):
        return Path(self.target_dir, path)


class Dotfile:
    def __init__(self, path: str, dotfiles_directory: Path, target_directory: Path):
        self.source = Path(dotfiles_directory, path)
        self.target = Path(target_directory, path)

    def symlink(self):
        symlink_path(self.source, self.target)

    def is_symlinked(self) -> bool:
        return self.target.is_symlink() & self.target.exists()

    def exists(self) -> bool:
        return self.target.exists()

    def remove(self):
        remove_path(self.target)

    def create_empty(self):
        self.target.touch()


class DotfileConfigLoader:
    def __init__(self, dotfiles_directory: Path, target_directory: Path):
        config_path = Path(dotfiles_directory, "config.json")

        if not (config_path.exists()):
            raise FileNotFoundError("config.json does not exist")

        self.dotfiles_directory = dotfiles_directory
        self.target_directory = target_directory
        self.config = load_json_file(config_path)

    def get(self, *keys: str) -> list[Dotfile]:
        paths = functools.reduce(lambda acc, cv: acc[cv], keys, self.config)
        return [self.create_dotfile(path) for path in paths]

    def create_dotfile(self, path: str):
        return Dotfile(path, self.dotfiles_directory, self.target_directory)


class SymlinkDotfiles(DotfileLifecycle):
    def __init__(self, dotfiles: list[Dotfile]):
        self.dotfiles = dotfiles

    def install(self):
        for dotfile in self.dotfiles:
            dotfile.symlink()

    def check(self):
        for dotfile in self.dotfiles:
            if dotfile.is_symlinked():
                print("OK!", dotfile.target)
            else:
                print("ERROR!", dotfile.target)

    def uninstall(self):
        for dotfile in self.dotfiles:
            dotfile.remove()


class DeprecatedDotfiles(DotfileLifecycle):
    def __init__(self, dotfiles: list[Dotfile]):
        self.dotfiles = dotfiles

    def install(self):
        for dotfile in self.dotfiles:
            dotfile.remove()

    def check(self):
        for dotfile in self.dotfiles:
            if dotfile.exists():
                print("ERROR!", dotfile.target)

    def uninstall(self):
        for dotfile in self.dotfiles:
            dotfile.remove()


class ManualDotfiles(DotfileLifecycle):
    def __init__(self, dotfiles: list[Dotfile]):
        self.dotfiles = dotfiles

    def install(self):
        for dotfile in self.dotfiles:
            if not dotfile.exists():
                print(f"Creating {dotfile.target}")
                dotfile.create_empty()

    def check(self):
        for dotfile in self.dotfiles:
            if not dotfile.exists():
                print("MISSING!", dotfile.target)

    def uninstall(self):
        for dotfile in self.dotfiles:
            dotfile.remove()


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
        return


def symlink_path(source: Path, target: Path):
    if target.is_symlink():
        print(f"Symlink already exists: {target}")
        return

    if target.exists():
        print(f"Removing existing file or directory: {target}")
        remove_path(target)

    print(f"Creating symlink: {source} -> {target}")
    target.symlink_to(source, source.is_dir())


def load_json_file(path: Path) -> Any:
    with open(path) as f:
        return json.load(f)
