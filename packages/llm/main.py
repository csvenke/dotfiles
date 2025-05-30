import re
import subprocess
from typing import Optional

import click
from claude import Claude

pass_claude = click.make_pass_decorator(Claude)


@click.group()
@click.option("--api-key", envvar="ANTHROPIC_API_KEY", default=None)
@click.pass_context
def cli(ctx: click.Context, api_key: Optional[str]):
    ctx.obj = Claude(api_key=api_key)


@cli.command()
@click.argument("question")
@pass_claude
def ask(claude: Claude, question: str):
    answer = claude.message(question)
    print(answer)


@cli.command()
@click.option("--full", "-f", is_flag=True, default=False)
@pass_claude
def commit(claude: Claude, full: bool):
    diff_stat = subprocess.check_output(["git", "diff", "--staged", "--stat"]).decode()

    if full:
        staged_diff = subprocess.check_output(
            ["git", "diff", "--staged", "-W"]
        ).decode()
    else:
        staged_diff = subprocess.check_output(["git", "diff", "--staged"]).decode()

    prompt = f"""
        You are an experienced software developer tasked with creating semantic git commit messages that accurately describe code changes. Your goal is to produce clear, concise, and informative commit messages following the conventional commit format.

        Here are the git diff details you need to analyze:

        <diff_stat>
        {diff_stat}
        </diff_stat>

        <staged_diff>
        {staged_diff}
        </staged_diff>

        Instructions:

        1. Analyze the provided git diff information.
        2. Determine whether the changes are small (1-2 files, single purpose) or large (multiple files or purposes).
        3. Create an appropriate commit message based on the following format:

           For small changes:
           <type>(<scope>): <description>

           For larger changes:
           <type>(<scope>): <general description>

           * <specific change 1>
           * <specific change 2>
           * <specific change 3>

        Conventional Commit Types:

        - feat: A new feature or significant enhancement
        - fix: A bug fix
        - docs: Documentation changes only
        - style: Changes that don't affect code meaning (formatting, whitespace)
        - refactor: Code changes that neither fix bugs nor add features
        - test: Adding or correcting tests
        - chore: Maintenance tasks, dependency updates, build changes
        - perf: Performance improvements
        - ci: Changes to CI/CD configuration
        - build: Changes to build system or external dependencies

        Rules for creating commit messages:

        - Write in present tense imperative (e.g., "add" not "added")
        - Be concise and direct (50-72 characters for title)
        - Avoid self-references like "this commit" or "this change"
        - Start with lowercase
        - Omit the period at the end
        - Include a scope when clearly applicable (e.g., component name, module)
        - For larger changes, make the title broad and use bullet points for specific details
        - Focus on WHY the change was made, not just WHAT changed
        - Mention breaking changes explicitly with "BREAKING CHANGE:" prefix
        - Reference issue numbers when applicable with "#123" format

        Before formulating your final commit message, break down the changes, categorize them, and plan your commit message structure inside <diff_analysis> tags:

        1. List out the files changed and the number of lines added/removed for each file.
        2. Categorize each change with the most appropriate commit type.
        3. Determine if this is a small or large change based on the number of files and purposes.
        4. Identify the most suitable scope(s) for the commit message.
        5. For larger changes, brainstorm clear and specific bullet points.
        6. Consider if any changes are breaking changes that need special notation.

        Pay special attention to making the commit title general for larger changes while using bullet points to specify each change.

        After your analysis, provide your final commit message without any additional commentary.

        Example output structure:

        <diff_analysis>
        [Your detailed analysis of the diff, categorization of changes, and commit message planning]
        </diff_analysis>

        [Your final commit message, formatted according to the rules above]

        Please proceed with your analysis and commit message creation based on the provided git diff information.
    """

    commit = claude.message(prompt)
    commit = re.sub(r"<diff_analysis>.*?</diff_analysis>", "", commit, flags=re.DOTALL)

    subprocess.run(["git", "commit", "-m", commit, "-e"])


if __name__ == "__main__":
    cli()
