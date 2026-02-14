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
@click.option(
    "--amend",
    "-a",
    is_flag=True,
    default=False,
    help="Amend the previous commit",
)
@pass_claude
def commit(claude: Claude, full: bool, amend: bool) -> None:
    """Draft a commit message"""
    diff_command = ["git", "diff", "--staged"]
    if amend:
        diff_command.append("HEAD~1")

    diff_stat = execute(diff_command + ["--stat"])

    if not diff_stat:
        print("No changes to commit.")
        return

    if full:
        staged_diff = execute(diff_command + ["-W"])
    else:
        staged_diff = execute(diff_command)

    recent_commits = execute(["git", "log", "--format=%s%n%b", "-5"])
    current_branch = execute(["git", "branch", "--show-current"])

    prompt = f""" 
        Generate a commit message for the following git diff. Follow the conventional commit format for semantic versioning.

        ## CRITICAL: Semantic Commit Type Selection
        The commit type determines version bumping in semantic versioning:
        - feat: MINOR version bump (new functionality, new features, new capabilities)
        - fix: PATCH version bump (bug fixes, corrections to existing functionality)
        - BREAKING CHANGE: MAJOR version bump (incompatible API changes)

        OTHER types (docs, style, refactor, test, chore, ci, build, perf) DO NOT trigger version bumps.

        IMPORTANT: Choose the type carefully based on the actual impact:
        - Use 'feat' ONLY for user-facing features or new capabilities
        - Use 'fix' ONLY for actual bug fixes
        - Use 'chore' for maintenance tasks, dependency updates, config changes, tooling
        - Use 'refactor' for code restructuring without behavior change
        - Use 'docs' for documentation-only changes
        - Use 'ci' for CI/CD pipeline changes
        - Use 'build' for build system/dependency changes
        - Use 'test' for test-only changes

        When in doubt, prefer non-versioning types (chore, refactor, etc.) over feat/fix unless the change genuinely adds new functionality or fixes a bug.

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
        Here are examples of clear, direct commit messages with correct type usage:

        ### Example 1 (bug fix - PATCH bump):
        ```gitcommit
        fix: prevent null pointer exception in user validation

        Closes: #1234
        ```

        ### Example 2 (new feature - MINOR bump):
        ```gitcommit
        feat: add pagination to search results endpoint

        Closes: #4321
        ```

        ### Example 3 (refactoring - NO bump):
        ```gitcommit
        refactor: extract database connection logic into separate module

        * move connection pooling to db/pool.py
        * update imports in affected services
        * add connection timeout configuration

        Fixes: #2134
        ```

        ### Example 4 (configuration change - NO bump):
        ```gitcommit
        chore: increase API rate limit from 100 to 500 requests/minute

        Fixes: #3124
        ```

        ### Example 5 (dependency update - NO bump):
        ```gitcommit
        chore: upgrade pytest from 7.1.0 to 7.4.2

        * update test fixtures for new assertion format
        * fix deprecated warning in conftest.py

        Related work items: #8345
        ```

        ### Example 6 (breaking change - MAJOR bump):
        ```gitcommit
        feat: change user ID format from integer to UUID

        * update database schema and migrations
        * modify API responses to use string IDs
        * update client SDK documentation

        BREAKING CHANGE: user IDs are now UUIDs instead of integers

        Related work items: #9663
        ```

        Based on the examples above, and previous commits, create a commit message that accurately describes the changes in the diff.
        Reference issue(s) in commit footer if possible. Issue numbers are often in branch name

        IMPORTANT: Return ONLY the commit message text without any markdown formatting, code blocks, or additional explanation.
    """

    commit_message = claude.message(prompt)

    commit_command = ["git", "commit", "-m", commit_message, "-e"]
    if amend:
        commit_command.insert(2, "--amend")

    subprocess.run(commit_command)


def execute(args: list[str]) -> str:
    return subprocess.check_output(args).decode().strip()


if __name__ == "__main__":
    cli()
