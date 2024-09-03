import functools
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from scriptargs import ScriptArgs


@dataclass
class Config:
    dotfiles_dir: Path
    source_dir: Path
    target_dir: Path
    symlink_paths: list[str]
    unlink_paths: list[str]

    @classmethod
    def from_script_args(cls, args: ScriptArgs):
        dotfiles_dir = args.dotfiles_dir
        target_dir = args.target_dir
        config_path = Path(dotfiles_dir, "config.json")

        if not (config_path.exists()):
            raise FileNotFoundError("config.json does not exist")

        config = load_json_file(config_path)
        root_path: str = get_nested_value(config, "dotfiles", "root")
        symlink_paths: list[str] = get_nested_value(config, "dotfiles", "symlink")
        unlink_paths: list[str] = get_nested_value(config, "dotfiles", "unlink")
        source_dir = Path(dotfiles_dir, root_path)

        return cls(dotfiles_dir, source_dir, target_dir, symlink_paths, unlink_paths)

    def get_dotfiles_path(self, *path: str) -> Path:
        return Path(self.dotfiles_dir, *path)

    def get_source_path(self, *path: str) -> Path:
        return Path(self.source_dir, *path)

    def get_target_path(self, *path: str) -> Path:
        return Path(self.target_dir, *path)


def get_nested_value(obj: Any, *keys: str) -> Any:
    return functools.reduce(lambda acc, cv: acc[cv], keys, obj)


def load_json_file(path: Path) -> Any:
    with open(path) as f:
        return json.load(f)
