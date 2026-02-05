---
name: create-skill
description: Guide for creating reusable OpenCode agent skills
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: onboarding
---

## What I do

I guide you through creating reusable agent skills for OpenCode. Skills are reusable behavior definitions that agents can discover and load on-demand.

## When to use me

Use this when you need to:

- Create a new skill from scratch
- Port a Claude or Agent skill to OpenCode
- Document a recurring workflow for your team
- Standardize how agents handle specific tasks

## Step-by-step

### 1. Choose a location

**Global skill** (available everywhere):

```
~/.config/opencode/skills/<name>/SKILL.md
```

**Project skill** (available in repo):

```
.opencode/skills/<name>/SKILL.md
```

### 2. Create the directory structure

```
.opencode/
  skills/
    my-skill/
      SKILL.md
```

The directory name must match the skill `name` in frontmatter.

### 3. Write SKILL.md

Every skill must have YAML frontmatter with `name` and `description`:

```yaml
---
name: my-skill
description: Brief description (1-1024 chars)
license: MIT
compatibility: opencode
metadata:
  key: value
---
## What I do
- Point 1
- Point 2

## When to use me
Context about when to invoke this skill
```

### 4. Validate the skill

- `name`: 1-64 chars, lowercase alphanumeric with single hyphens
- `description`: 1-1024 chars
- File must be named `SKILL.md` (all caps)

### 5. Test it

1. Run OpenCode in the target directory
2. Ask: "What skills do you have?"
3. Verify your skill appears with the correct description
4. Test loading it with `skill({ name: "my-skill" })`

## Template

```yaml
---
name: my-workflow
description: One-line description of the workflow
license: MIT
compatibility: opencode
metadata:
  audience: team|developers|maintainers
  workflow: category
---

## What I do
- Describe the main actions
- List key behaviors

## When to use me
- Situation 1
- Situation 2

## How I work
1. Step one
2. Step two
3. Step three

## Examples
### Example 1
Your example prompt here

### Example 2
Another example

## Gotchas
- Common mistake 1
- Common mistake 2
```

## Naming conventions

- Use kebab-case: `git-release`, `code-review`, `write-tests`
- Be specific: `python-unittest` not just `test`
- Include context: `aws-s3-upload` not just `upload`

## Best practices

- Keep descriptions concise but specific
- Include "When to use me" section
- Add examples for common use cases
- Document any gotchas or edge cases
- Use metadata to categorize for discovery
- License your skill if sharing
