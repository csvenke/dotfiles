---
name: code-review
description: "Staff/Principal engineer quality code reviews. Triggers on requests to review code, diffs, changes, patches, branches, commits, or pull requests. Accepts code from any source: GitHub PRs, git diffs, patch files, or code shared directly. Applies senior engineering judgment across architecture, security, operations, performance, quality, and testing - independent of language or technology stack."
---

# Code Review Skill

Perform code reviews at the level of a Staff or Principal engineer - evaluating not just correctness, but system-wide implications, operational risk, and long-term maintainability.

## Review Philosophy

- Junior: "Does this code work?"
- Senior: "Should this code exist? What are the second-order effects?"

Every review should consider: **If this ships and I'm paged at 3am, what will I wish we had caught?**

## Workflow

### 1. Triage: Size Up the Change

Assess scope and risk to calibrate effort. See [review-strategy.md](references/review-strategy.md) for detailed guidance.

| Change Size | Characteristics                                         | Review Strategy                                                                      |
| ----------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Trivial** | Config tweaks, typo fixes, dependency bumps, formatting | Verify intent matches change, check for hidden complexity, approve quickly           |
| **Small**   | Single-purpose changes, <100 lines of logic             | Full review, but time-box to ~10 minutes                                             |
| **Medium**  | Feature additions, refactors, 100-500 lines             | Structured review across all dimensions                                              |
| **Large**   | 500+ lines, multiple concerns, architectural changes    | Break into logical chunks, focus on high-risk areas first, consider requesting split |

A 5-line config change doesn't need 30 minutes of security analysis. A 1000-line refactor doesn't need line-by-line style feedback.

### 2. Gather Context

Understand: what problem is being solved, why this approach, and what's the scope of impact.

- For PRs: `gh pr view <N> --json title,body,files,additions,deletions` and `gh pr diff <N>`
- For branches: `git diff main...<branch>`, `git log --oneline main..<branch>`
- For commits: `git show <sha>`
- For staged/unstaged: `git diff --cached`, `git diff`

When context is limited, read commit messages carefully and ask clarifying questions before critiquing.

### 3. Review Across Six Dimensions

Evaluate changes against these dimensions, weighted by relevance:

| Dimension    | Key Question                                 | Reference                                     |
| ------------ | -------------------------------------------- | --------------------------------------------- |
| Architecture | Does this change fit the system's design?    | [architecture.md](references/architecture.md) |
| Security     | What could go wrong if inputs are malicious? | [security.md](references/security.md)         |
| Operations   | How does this behave in production?          | [operations.md](references/operations.md)     |
| Performance  | How does this scale?                         | [performance.md](references/performance.md)   |
| Code Quality | Will future engineers thank us?              | [code-quality.md](references/code-quality.md) |
| Testing      | Are we testing the right things?             | [testing.md](references/testing.md)           |

**Dimension priority by risk level:**

- **High risk** (security boundaries, data migrations, public APIs): All dimensions, thorough
- **Medium risk** (features, refactors, dependency updates): Focus on relevant dimensions
- **Low risk** (docs, tests, cosmetic): Quick sanity check, approve and move on

### 4. Clarify Before Critiquing

If intent, motivation, or impact is unclear, ask specific questions before providing the review. Don't critique based on wrong assumptions.

Good: "What's the expected behavior when X happens?" / "Is this intended to replace Y, or work alongside it?"
Bad: "Why didn't you use X instead?" (critique disguised as question) / "Are you sure this works?" (lacks specificity)

If no clarification is needed, proceed directly to the review.

### 5. Calibrate and Deliver Feedback

Only comment when it justifies the author's time: real risk, conflicts with established patterns, future confusion, or a significantly better approach. Skip stylistic preferences without team conventions, marginal improvements, and anything linters should catch.

For large changes: focus on the 20% of code carrying 80% of risk. Batch related comments. Approve with follow-up items rather than blocking on minor issues.

Structure feedback by severity:

- **🚨 Blocker**: Must fix before merge (security holes, data loss risk, breaking changes)
- **⚠️ Concern**: Should fix, or explicitly justify not fixing
- **💡 Suggestion**: Consider for this change or future work
- **❓ Question**: Need clarification to complete review
- **👍 Praise**: Highlight good patterns others should learn from

## Output Format

**When clarification is needed:**

```markdown
## Before I Complete This Review

I have a few questions to make sure I understand the change correctly:

1. [Specific question]
2. [Specific question]

Once clarified, I'll provide a complete review.
```

**For trivial/small changes:**

```markdown
LGTM - [one line summary of what was verified]
```

**For medium/large changes:**

```markdown
## Summary

[1-2 sentence assessment: what this change does and overall readiness]

## Risk Assessment

- **Blast Radius**: [Low/Medium/High] - what's affected if this breaks
- **Rollback Complexity**: [Easy/Medium/Hard] - can we undo this quickly
- **Confidence**: [High/Medium/Low] - confidence in review completeness

## Findings

### 🚨 Blockers

[or "None"]

### ⚠️ Concerns

[issues that should be addressed]

### 💡 Suggestions

[improvements to consider]

### 👍 What's Good

[patterns worth highlighting]

## Checklist

- [ ] Changes are backwards compatible (or migration plan exists)
- [ ] Error handling covers failure modes
- [ ] Observability exists for new code paths
- [ ] Tests cover critical paths and edge cases
- [ ] Documentation updated if needed
```

## Principles

- **Think in Systems**: Every change exists in a larger context. Consider upstream dependencies, downstream consumers, and adjacent components.
- **Optimize for the Long Term**: Favor clarity over cleverness, explicit over implicit, boring over novel.
- **Assume Good Intent**: Seek to understand before critiquing. Ask "what led to this approach?" not "why didn't you do X?"
- **Be Specific and Actionable**: "This is confusing" is not helpful. "This function does three things; consider splitting into X, Y, Z" is actionable.
