from pathlib import Path
from utils.config import Config
from utils.shell import run_shell_command


class NixEnvironment:
    @staticmethod
    def install(config: Config):
        path = Path(config.dotfilesFolder(), "env.nix")
        if path.exists():
            run_shell_command(f"nix-env -if {path}")

    @staticmethod
    def uninstall():
        run_shell_command("nix-env --uninstall '.*'")
