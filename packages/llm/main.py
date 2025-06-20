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
        Here are examples of clear, direct commit messages:

        ### Example 1 (bug fix):
        ```
        fix: prevent null pointer exception in user validation
        ```

        ### Example 2 (feature addition):
        ```
        feat: add pagination to search results endpoint
        ```

        ### Example 3 (refactoring):
        ```
        refactor: extract database connection logic into separate module

        * move connection pooling to db/pool.py
        * update imports in affected services
        * add connection timeout configuration
        ```

        ### Example 4 (configuration change):
        ```
        chore: increase API rate limit from 100 to 500 requests/minute
        ```

        ### Example 5 (dependency update):
        ```
        chore: upgrade pytest from 7.1.0 to 7.4.2

        * update test fixtures for new assertion format
        * fix deprecated warning in conftest.py
        ```

        ### Example 6 (breaking change):
        ```
        feat: change user ID format from integer to UUID

        * update database schema and migrations
        * modify API responses to use string IDs
        * update client SDK documentation

        BREAKING CHANGE: user IDs are now UUIDs instead of integers
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
