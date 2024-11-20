import shell

def clone(url: str, path: str):
    shell.run(f"git clone {url} {path}")

def pull_origin(branch: str, cwd: str = "."):
    shell.run(f"git -C {cwd} pull origin {branch}")
