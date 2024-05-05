import functools
import json
import os
import shutil
from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Any

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
        dotfiles_dir = args.dotfiles_dir
        target_dir = args.target_dir
        config_loader = DotfileConfigLoader(dotfiles_dir, target_dir)

        symlink_dotfiles = config_loader.get_dotfiles("dotfiles", "symlink")
        deprecated_dotfiles = config_loader.get_dotfiles("dotfiles", "deprecated")
        manual_dotfiles = config_loader.get_dotfiles("dotfiles", "manual")

        dotfiles: list[DotfileLifecycle] = [
            SymlinkDotfiles(symlink_dotfiles),
            ManualDotfiles(manual_dotfiles),
            DeprecatedDotfiles(deprecated_dotfiles),
        ]

        return cls(dotfiles_dir, target_dir, dotfiles)

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
    def __init__(self, path: str, source_dir: Path, target_dir: Path):
        self.source = Path(source_dir, path)
        self.target = Path(target_dir, path)

    def symlink(self):
        symlink_path(self.source, self.target)

    def is_symlinked(self) -> bool:
        return self.target.is_symlink() & self.target.exists()

    def exists(self) -> bool:
        return self.target.exists()

    def remove(self):
        remove_path(self.target)


class DotfileConfigLoader:
    def __init__(self, dotfiles_dir: Path, target_dir: Path):
        config_path = Path(dotfiles_dir, "config.json")

        if not (config_path.exists()):
            raise FileNotFoundError("config.json does not exist")

        self.config = load_json_file(config_path)
        self.source_dir = Path(dotfiles_dir, self.get("dotfiles", "root"))
        self.target_dir = target_dir

    def get(self, *keys: str):
        return functools.reduce(lambda acc, cv: acc[cv], keys, self.config)

    def get_dotfiles(self, *keys: str):
        paths = self.get(*keys)
        return [Dotfile(path, self.source_dir, self.target_dir) for path in paths]


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
            if not dotfile.source.exists():
                print(f"Creating {dotfile.source}")
                dotfile.source.touch()

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
