from pathlib import Path
from typing import Any
import json


class Config:
    @staticmethod
    def dotfilesFolder():
        return Path(Path.home(), ".dotfiles")

    @staticmethod
    def configFilePath():
        return Path(Config.dotfilesFolder(), "config.json")

    def __init__(self):
        self.config = load_json_file(Config.configFilePath())

    def dotfiles(self):
        return self.config.get("dotfiles", [])

    def manual_dotfiles(self):
        return self.config.get("manualDotfiles", [])

    def old_dotfiles(self):
        return self.config.get("oldDotfiles", [])


def load_json_file(path: Path) -> Any:
    with open(path) as f:
        return json.load(f)
