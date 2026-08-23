---
description: Review stored team retrospectives and propose workflow improvements
agent: process-analyst
---

Review the current team workflow in the `home/.config/opencode/skills/team-workflow*/` skills and stored workflow retrospectives from MemPalace in `wing=opencode`, `room=team-retros`.

Focus area: $ARGUMENTS

Instructions:

- Treat this as a manual retrospective, not an autonomous self-edit.
- Use the workflow retrospectives as primary evidence. If the focus area is empty, review the most relevant recent retrospectives and prioritize repeated patterns.
- Recommend the smallest set of workflow changes that would materially improve future runs.
- Do not apply changes automatically.
- End with an exact patch suggestion for the relevant `home/.config/opencode/skills/team-workflow*/SKILL.md` file, or explicitly say no patch is warranted yet.
- Retrospectives are stored per machine, so this corpus is partial. Note when a recommendation rests on thin evidence.
- Retrospectives cannot show the value of anything whose benefit is a prevented failure or preserved context. Do not read absence of praise as absence of value.
