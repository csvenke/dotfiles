import argparse
import subprocess
from anthropic import Anthropic


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--anthropic-api-key",
        required=True,
    )
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
    status = subprocess.check_output(["git", "status"]).decode()
    diff = subprocess.check_output(["git", "diff", "--staged"]).decode()
    prompt = f"""
	You are an experienced software developer tasked with generating commit messages based on git diff output.
        Your goal is to create concise, meaningful commit messages that follow the conventional commits specification.
        Respond only with the commit, if the output of git diff --staged is empty, respond with empty string

        git status
        {status}

        git diff --staged
        {diff}
	"""
    commit = claude.message(prompt)

    subprocess.run(["git", "commit", "-m", commit, "-e"])


if __name__ == "__main__":
    main()
