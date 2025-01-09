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
        Create a semantic git commit message that accurately describes the changes shown in the diff, following conventional commit format.

        Input Format:
        Below you'll find the git diff stat (showing changed files) and detailed diff.

        Output Format:
        1. For small changes (1-2 files, single purpose):
           <type>(<scope>): <description>

        2. For larger changes (multiple files or purposes):
           <type>(<scope>): <general description>

           * <specific change 1>
           * <specific change 2>
           * <specific change 3>

        Rules:
        - Types: feat, fix, docs, style, refactor, test, chore
        - Use present tense imperative ("add" not "added")
        - Be concise and direct
        - No self-references ("this commit", "this change")
        - Start with lowercase
        - No period at end
        - Use scope when clearly applicable
        - For multiple changes, make title broad and use bullets for details

        Examples:

        Small change:
        feat(auth): add password reset endpoint

        Large change:
        refactor(api): restructure authentication flow

        * extract auth middleware to separate module
        * implement JWT token validation
        * add rate limiting for auth endpoints
        * update error handling

        Review the following changes and respond with only the commit message:

        Git Stat:
        {diff_stat}

        Detailed Diff:
        {staged_diff}
	"""
    commit = claude.message(prompt)

    subprocess.run(["git", "commit", "-m", commit, "-e"])


if __name__ == "__main__":
    main()
