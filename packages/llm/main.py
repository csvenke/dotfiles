import subprocess
from typing import Optional

import click
from claude import Claude

pass_claude = click.make_pass_decorator(Claude)


@click.group()
@click.option("--model", default="claude-sonnet-4-20250514")
@click.option("--api-key", envvar="ANTHROPIC_API_KEY", default=None)
@click.pass_context
def cli(ctx: click.Context, model: str, api_key: Optional[str]) -> None:
    ctx.obj = Claude(model=model, api_key=api_key)


@cli.command()
@click.argument("question")
@pass_claude
def ask(claude: Claude, question: str) -> None:
    """Ask me anything"""
    answer = claude.message(question)
    print(answer)


@cli.command()
@click.option(
    "--full",
    "-f",
    is_flag=True,
    default=False,
    help="Include full file diff context",
)
@pass_claude
def commit(claude: Claude, full: bool) -> None:
    """Draft a commit message"""
    diff_stat = execute(["git", "diff", "--staged", "--stat"])

    if not diff_stat:
        print("No staged changes to commit.")
        return

    if full:
        staged_diff = execute(["git", "diff", "--staged", "-W"])
    else:
        staged_diff = execute(["git", "diff", "--staged"])

    recent_commits = execute(["git", "log", "--oneline", "-n", "5"])
    current_branch = execute(["git", "branch", "--show-current"])

    prompt = f""" 
        Generate a commit message for the following git diff. Follow the conventional commit format.

        ## Repository context
        Current branch: {current_branch}

        Recent commits:
        ```
        {recent_commits}
        ```

        Diff stat:
        ```
        {diff_stat}
        ```

        Staged diff:
        ```
        {staged_diff}
        ```

        ## Examples
        Here are some examples of great commit messages:

        ### Example 1 (small change):
        ```
        feat(auth): implement JWT token refresh mechanism
        ```

        ### Example 2 (small change):
        ```
        fix(api): handle null response from user service
        ```

        ### Example 3 (larger change):
        ```
        refactor(database): improve query performance

        * replace ORM with raw SQL for critical paths
        * add indexes to frequently queried columns
        * implement connection pooling
        ```

        ### Example 4 (larger change):
        ```
        feat(ui): redesign dashboard layout

        * reorganize widgets for better information hierarchy
        * implement responsive grid system
        * add dark mode support
        ```

        ### Example 5 (breaking change):
        ```
        feat(api): revise authentication endpoints

        * consolidate login and signup flows
        * require 2FA for admin accounts
        * remove deprecated password reset endpoint

        BREAKING CHANGE: clients using the old password reset flow need to migrate
        ```

        Based on the examples above, create a commit message that accurately describes the changes in the diff.

        IMPORTANT: Return ONLY the commit message text without any markdown formatting, code blocks, or additional explanation.
    """

    commit = claude.message(prompt)

    subprocess.run(["git", "commit", "-m", commit, "-e"])


def execute(args: list[str]) -> str:
    return subprocess.check_output(args).decode().strip()


if __name__ == "__main__":
    cli()
