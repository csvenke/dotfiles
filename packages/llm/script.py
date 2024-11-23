import argparse
import subprocess
from anthropic import Anthropic


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--anthropicApiKey",
        required=True,
    )
    sub_parser = parser.add_subparsers(dest="command")
    sub_parser.add_parser("commit")

    args: dict[str, str] = vars(parser.parse_args())

    command = args.get("command")
    anthropic_api_key = args.get("anthropicApiKey")

    client = Anthropic(api_key=anthropic_api_key)

    match command:
        case "commit":
            commit_command(client)


def commit_command(client):
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
    message = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[{"role": "user", "content": f"{prompt}"}],
    )
    commit = message.content[0].text

    subprocess.run(["git", "commit", "-m", commit, "-e"])


main()
