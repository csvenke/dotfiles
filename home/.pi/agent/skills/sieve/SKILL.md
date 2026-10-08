---
name: sieve
description: Filter or triage many items (memory search results, grep hits, log lines, test failures, knowledge-graph facts) with the jev classifier inside a codemode script, so only what matters enters context. Use when a tool would return ~15+ items or >10KB that need a yes/no judgment per item.
compatibility: Requires pi codemode and a jev classifier credential (typesafe, openrouter, or opencode). Lead sessions only — subagents have no codemode.
---

# Sieve

A codemode script fetches bulk output, trims it with code, asks jev one yes/no
question per item, and returns only the survivors plus a note on what was
dropped. Rejected items never enter your context.

**Fit test** — use only when all hold: many items (~15+) or large output; each
item can be judged alone from a small view (≤2k chars); the judgment is a crisp
yes/no; most items are likely noise; you don't need to see the rejects.
Otherwise read the items yourself.

## Rules

1. **Code first.** Strip metadata, dedupe, and pre-narrow (`rg` patterns,
   `head`) before jev. This alone roughly halves output.
2. **Ask a concrete category test, and name the junk in `no`.** Vague
   questions ("relevant to the goal?") produce mushy scores (0.35–0.87);
   concrete ones separate cleanly (≥0.82 vs ≤0.08 on the same items).
3. **Keep P ≥ 0.5** by default. The output always reports how many items were
   dropped and the top borderline drops — widen if they look relevant.
   Classifier errors keep the item (fail open).
4. **Jev labels, you decide.** Check flagged items yourself before acting on
   anything with stakes (failures, memory edits).
5. **Watch `stats`.** If `out_bytes` comes close to `raw_bytes`, most items
   passed and the sieve only added overhead — read directly next time.

Throughput: ~100 items ≈ 6 s (4 concurrent calls). `jev-latest` on typesafe is
free.

## Helper — paste at the top of the script

```js
const avail = await models.getAvailableOfType("classifier");
const JEV =
  ["jev-latest", "~typesafe/jev-latest", "jev-1.13-free", "typesafe/jev-1.13"]
    .map((id) => avail.find((m) => m.id === id))
    .find(Boolean) || avail.find((m) => m.id.includes("jev"));
if (!JEV)
  return "sieve: no jev classifier available; process the items directly";
const brief = (x) =>
  (typeof x === "string" ? x : JSON.stringify(x))
    .replace(/\s+/g, " ")
    .slice(0, 100);
// ask: { q, yes, no } · view: item → small state for jev · show: item → what you get back
// drops: how many dropped items to list (borderline first) · rawBytes: size before sieving
const sieve = async (
  items,
  {
    goal,
    ask,
    view = (x) => x,
    show = (x) => x,
    keep = 0.5,
    drops = 3,
    rawBytes = 0,
  },
) => {
  const res = await Promise.all(
    items.map((it) =>
      models.classify(JEV, {
        state: { goal, item: view(it) },
        questions: {
          q: {
            type: "bool",
            instructions: ask.q,
            criteria: { true: ask.yes, false: ask.no },
          },
        },
      }),
    ),
  );
  const rows = items.map((it, i) => ({
    it,
    p:
      res[i].stopReason === "stop"
        ? +res[i].answers.q.probability.toFixed(2)
        : null,
  }));
  const kept = rows
    .filter((r) => r.p === null || r.p >= keep)
    .sort((a, b) => (b.p ?? 1) - (a.p ?? 1));
  const dropped = rows
    .filter((r) => r.p !== null && r.p < keep)
    .sort((a, b) => b.p - a.p);
  const fmt = (r) => {
    const v = show(r.it);
    return typeof v === "string" ? `${r.p} ${v}` : { p: r.p, ...v };
  };
  const out = {
    kept: kept.map(fmt),
    dropped: dropped.length,
    listed: dropped.slice(0, drops).map((r) => `${r.p} ${brief(show(r.it))}`),
  };
  return {
    ...out,
    stats: {
      items: items.length,
      raw_bytes: rawBytes,
      out_bytes: JSON.stringify(out).length,
    },
  };
};
```

## Recipes

**Memory recall**

```js
const raw = (
  await tools.mcp__mempalace__mempalace_search({
    query: "<keywords>",
    limit: 15,
  })
).content[0].text;
const seen = new Set();
const items = JSON.parse(raw)
  .results.filter((r) => !seen.has(r.text) && seen.add(r.text))
  .map((r) => ({ src: `${r.wing}/${r.room}/${r.source_file}`, text: r.text }));
return await sieve(items, {
  goal: "<goal>",
  rawBytes: raw.length,
  view: (x) => ({ src: x.src, text: x.text.slice(0, 2000) }),
  ask: {
    q: "Is this memory about <concrete topic>?",
    yes: "<what counts>",
    no: "Test scripts, manuals, setup docs, or anything else",
  },
});
```

**Search hits**

```js
const r = await tools.bash({
  command:
    "cd <dir> && rg -n --no-heading --max-columns 200 --max-columns-preview '<pattern>' | head -300",
});
return await sieve(r.output.split("\n").filter(Boolean), {
  goal: "<goal>",
  rawBytes: r.output.length,
  ask: {
    q: "Does this line <concrete property>?",
    yes: "<what counts>",
    no: "Unrelated, or only mentions the word",
  },
});
```

**New test failures** — diff failing test names against the baseline with code
first; sieve only the new ones. Parse `failures: [{ name, log }]` from the
test command's `tools.bash` output (format is project-specific).

```js
return await sieve(failures, {
  goal: "Which new failures did the change cause?",
  drops: Infinity,
  view: (f) => ({
    changed_files: ["<paths>"],
    test: f.name,
    log: f.log.slice(0, 1500),
  }),
  ask: {
    q: "Is this failure plausibly caused by the code change, not flakiness or the environment?",
    yes: "Assertion or error traceable to changed code",
    no: "Network, timeout, disk, or other environmental cause",
  },
});
```

**Contradiction check before a KG write** — `kept` are candidates for
`mempalace_kg_supersede` / `mempalace_kg_invalidate`; confirm each yourself.

```js
const fact = { subject: "<s>", predicate: "<p>", object: "<o>" };
const kg = JSON.parse(
  (await tools.mcp__mempalace__mempalace_kg_query({ entity: fact.subject }))
    .content[0].text,
);
return await sieve(
  kg.facts.filter((f) => f.current),
  {
    goal: "Keep the knowledge graph free of contradictions",
    drops: 0,
    view: (f) => ({
      existing: `${f.subject} ${f.predicate} ${f.object}`,
      incoming: `${fact.subject} ${fact.predicate} ${fact.object}`,
    }),
    show: (f) => ({
      subject: f.subject,
      predicate: f.predicate,
      object: f.object,
    }),
    ask: {
      q: "Does the incoming fact contradict or replace the existing fact?",
      yes: "Both cannot be true now; incoming updates existing",
      no: "Compatible, unrelated, or complementary",
    },
  },
);
```
