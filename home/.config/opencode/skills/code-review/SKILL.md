---
name: code-review
description: Conduct thorough code reviews focusing on quality, security, and maintainability
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: quality-assurance
---

## What I do

I conduct comprehensive code reviews that cover:

- Code quality and readability
- Security vulnerabilities and best practices
- Performance implications
- Maintainability and documentation
- Testing coverage and quality
- Architecture and design patterns
- Adherence to project conventions

## When to use me

- Before submitting a pull request
- When reviewing teammate's code
- After completing a feature or bug fix
- When refactoring existing code
- Before merging to main/master branch

## How I work

1. **Understand the context**
   - Read the PR description or related issues
   - Identify the scope and goals of the changes
   - Check if there are existing patterns to follow

2. **Review systematically**
   - Check for obvious bugs or logic errors
   - Verify error handling and edge cases
   - Assess naming conventions and clarity
   - Look for security issues (injection, XSS, etc.)
   - Evaluate performance implications
   - Check test coverage

3. **Provide actionable feedback**
   - Categorize findings by severity (critical/warning/suggestion)
   - Explain the "why" behind recommendations
   - Suggest specific improvements with code examples
   - Acknowledge what was done well

4. **Follow up**
   - Verify fixes are properly implemented
   - Confirm no new issues were introduced

## Examples

### Example 1: Reviewing a new feature

"Please review the changes in src/auth/login.ts for the new OAuth implementation. Focus on security best practices and error handling."

### Example 2: Pre-PR review

"I've completed the user profile feature. Can you do a thorough code review before I open the PR? Check for any issues with data validation and API design."

### Example 3: Refactoring review

"I refactored the database layer to use connection pooling. Please review for thread safety and resource management issues."

## Review Checklist

### Critical (must fix)

- [ ] Security vulnerabilities
- [ ] Logic errors or bugs
- [ ] Missing error handling
- [ ] Race conditions or deadlocks

### Warnings (should fix)

- [ ] Unclear or misleading variable names
- [ ] Missing input validation
- [ ] Inefficient algorithms
- [ ] Duplicate code

### Suggestions (nice to have)

- [ ] Additional documentation
- [ ] Better test coverage
- [ ] Code style improvements
- [ ] Performance optimizations

## Gotchas

- Don't just focus on bugs - good code reviews also acknowledge what's done well
- Security issues should be flagged immediately, even if the code "works"
- Consider the context: not all projects need the same level of rigor
- Automated tools catch syntax; I catch logic and design issues
- Review tests as carefully as production code
- Check for unintended side effects in other parts of the codebase
