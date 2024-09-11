import subprocess


def run(command: str) -> str:
    process = subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    stdout, stderr = process.communicate()

    if process.returncode == 1:
        raise subprocess.CalledProcessError(
            process.returncode, command, output=stdout, stderr=stderr
        )

    return stdout.decode("utf-8")
