import subprocess
import sys
import threading
from typing import Tuple


def run(command: str, check: bool = True) -> Tuple[int, str, str]:
    process = subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        bufsize=1,
    )

    stdout_output = []
    stderr_output = []

    def read_output(pipe, output_list, output_stream):
        for line in iter(pipe.readline, ""):
            output_list.append(line)
            output_stream.write(line)
            output_stream.flush()

    stdout_thread = threading.Thread(
        target=read_output, args=(process.stdout, stdout_output, sys.stdout)
    )
    stderr_thread = threading.Thread(
        target=read_output, args=(process.stderr, stderr_output, sys.stderr)
    )

    stdout_thread.start()
    stderr_thread.start()
    stdout_thread.join()
    stderr_thread.join()

    return_code = process.wait()

    stdout = "".join(stdout_output)
    stderr = "".join(stderr_output)

    if check and return_code != 0:
        raise subprocess.CalledProcessError(
            return_code, command, output=stdout, stderr=stderr
        )

    return return_code, stdout, stderr
