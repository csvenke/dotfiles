import subprocess


def run_shell_command(command):
    subprocess.run(command, shell=True, check=True)
