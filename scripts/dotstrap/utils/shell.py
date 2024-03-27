import subprocess


class Shell:
    @staticmethod
    def run(command: str):
        subprocess.run(command, shell=True, check=True)
