import argparse
import subprocess
from anthropic import Anthropic


def main():
    parser = argparse.ArgumentParser(prog="llm")
    parser.add_argument("--anthropic-api-key", required=True)
    sub_parser = parser.add_subparsers(dest="command")
    sub_parser.add_parser("commit")
    sub_parser.add_parser("ask").add_argument("prompt")
    sub_parser.add_parser("help")

    args = vars(parser.parse_args())

    anthropic_api_key: str = args["anthropic_api_key"]
    claude = Claude(api_key=anthropic_api_key)

    command = args.get("command") or "help"

    match command:
        case "commit":
            commit_command(claude)
        case "ask":
            ask_command(args, claude)
        case "help":
            parser.print_help()


class Claude:
    def __init__(self, api_key: str):
        self.client = Anthropic(api_key=api_key)

    def message(self, prompt: str):
        message = self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": f"{prompt}"}],
        )
        commit = message.content[0].text
        return commit


def ask_command(args: dict[str, str], claude: Claude):
    prompt = args.get("prompt")
    if prompt:
        answer = claude.message(prompt)
        print(answer)


def commit_command(claude: Claude):
    diff_stat = subprocess.check_output(["git", "diff", "--staged", "--stat"]).decode()
    staged_diff = subprocess.check_output(["git", "diff", "--staged", "-W"]).decode()

    prompt = f"""
	Act as an expert software developer tasked with creating commit messages based on git diff output.
        Your prime directive is to create concise, meaningful commit messages that follow conventional commit specification.
        Respond only with commit message, if empty git diff command then respond with empty string

        git diff --stat
        {diff_stat}

        git diff --staged -W
        {staged_diff}
	"""
    commit = claude.message(prompt)

    subprocess.run(["git", "commit", "-m", commit, "-e"])


if __name__ == "__main__":
    main()
