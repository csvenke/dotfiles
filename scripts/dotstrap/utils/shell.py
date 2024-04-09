import subprocess


class Shell:
    @staticmethod
    def run(command: str):
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        process.wait()
        return process.returncode
