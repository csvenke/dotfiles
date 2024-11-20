import shell


def profile_install(path: str):
    shell.run(f"nix profile install {path}")


def profile_upgrade_all():
    shell.run("nix profile upgrade --all")
    shell.run("nix profile wipe-history --older-than 7d")
