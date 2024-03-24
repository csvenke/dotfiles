import subprocess
from pathlib import Path


class Shell:
    @staticmethod
    def run(command: str):
        subprocess.run(command, shell=True, check=True)

    @staticmethod
    def source(path: Path):
        if path.exists():
            Shell.run(f"source {path}")
        else:
            print(f"{path} does not exist. Doing nothing")
