import assert from "node:assert/strict";
import test from "node:test";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import { fetchNextPuzzle, PuzzleSource } from "../src/lichess.ts";
import type { LichessPuzzleResponse } from "../src/puzzle.ts";

function jsonResponse(body: unknown, init?: { status?: number }): Response {
  return new Response(JSON.stringify(body), {
    status: init?.status ?? 200,
    headers: { "content-type": "application/json" },
  });
}

const flush = () => new Promise((resolve) => setImmediate(resolve));

test("fetchNextPuzzle returns a validated response", async () => {
  const raw = fallbackPuzzles[0];
  const res = await fetchNextPuzzle({ fetchFn: async () => jsonResponse(raw) });
  assert.equal(res.puzzle.id, raw.puzzle.id);
});

test("fetchNextPuzzle sets the angle query param", async () => {
  let seenUrl = "";
  const raw = fallbackPuzzles[0];
  await fetchNextPuzzle({
    angle: "mateIn2",
    fetchFn: async (url) => {
      seenUrl = String(url);
      return jsonResponse(raw);
    },
  });
  assert.match(
    seenUrl,
    /^https:\/\/lichess\.org\/api\/puzzle\/next\?angle=mateIn2/,
  );
});

test("fetchNextPuzzle rejects on HTTP errors", async () => {
  await assert.rejects(
    () =>
      fetchNextPuzzle({
        fetchFn: async () => jsonResponse({}, { status: 429 }),
      }),
    /HTTP 429/,
  );
});

test("fetchNextPuzzle rejects on malformed payloads", async () => {
  await assert.rejects(
    () => fetchNextPuzzle({ fetchFn: async () => jsonResponse({ nope: 1 }) }),
    /game\.pgn/,
  );
});

test("fetchNextPuzzle rejects when the network fails", async () => {
  await assert.rejects(
    () =>
      fetchNextPuzzle({
        fetchFn: async () => {
          throw new TypeError("fetch failed");
        },
      }),
    /fetch failed/,
  );
});

test("fetchNextPuzzle passes a signal to fetch", async () => {
  let seenSignal: AbortSignal | undefined;
  const raw = fallbackPuzzles[0];
  await fetchNextPuzzle({
    fetchFn: async (_url, init) => {
      seenSignal = init?.signal ?? undefined;
      return jsonResponse(raw);
    },
  });
  assert.ok(seenSignal instanceof AbortSignal);
});

test("PuzzleSource serves fetched puzzles and keeps prefetching", async () => {
  let calls = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> =>
    fallbackPuzzles[calls++ % fallbackPuzzles.length];
  const source = new PuzzleSource({ fetcher, prefetchCount: 2 });
  const first = await source.next();
  assert.equal(first.id, fallbackPuzzles[0].puzzle.id);
  await flush();
  assert.equal(calls, 3, "next() triggered a refill beyond the initial fill");
  const second = await source.next();
  assert.equal(second.id, fallbackPuzzles[1].puzzle.id);
  assert.equal(source.lastError, null);
});

test("PuzzleSource backs off after a failure instead of hammering", async () => {
  let calls = 0;
  const source = new PuzzleSource({
    fetcher: async (): Promise<LichessPuzzleResponse> => {
      calls++;
      throw new Error("offline");
    },
    cooldownMs: 60_000,
  });
  await source.next();
  await source.next();
  await source.next();
  assert.equal(calls, 1, "no new fetch while the cooldown is in effect");
});

test("PuzzleSource clears lastError once the network recovers", async () => {
  // A network puzzle outside the fallback pool (no id collision possible).
  const netRaw = structuredClone(fallbackPuzzles[2]);
  netRaw.puzzle.id = "net-unique-1";
  let calls = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> => {
    calls++;
    if (calls === 1) throw new Error("offline");
    return netRaw;
  };
  const source = new PuzzleSource({ fetcher, cooldownMs: 0 });
  await source.next();
  assert.match(source.lastError ?? "", /offline/);
  const puzzle = await source.next();
  assert.equal(puzzle.id, "net-unique-1");
  assert.equal(source.lastError, null);
});

test("PuzzleSource skips corrupt fallback entries", async () => {
  const corrupt = {
    game: { pgn: "" },
    puzzle: { id: "corrupt", rating: 1, solution: [] },
  };
  const good = fallbackPuzzles[3];
  const source = new PuzzleSource({
    fetcher: async () => {
      throw new Error("offline");
    },
    fallbacks: [corrupt as LichessPuzzleResponse, good],
  });
  const puzzle = await source.next();
  assert.equal(puzzle.id, good.puzzle.id);
});

test("PuzzleSource rejects clearly when every fallback is corrupt", async () => {
  const corrupt = {
    game: { pgn: "" },
    puzzle: { id: "corrupt", rating: 1, solution: [] },
  };
  const source = new PuzzleSource({
    fetcher: async () => {
      throw new Error("offline");
    },
    fallbacks: [corrupt as LichessPuzzleResponse],
  });
  await assert.rejects(() => source.next(), /no usable puzzles/);
});

test("PuzzleSource serializes concurrent next() calls", async () => {
  let calls = 0;
  const fetcher = async (): Promise<LichessPuzzleResponse> =>
    fallbackPuzzles[calls++ % fallbackPuzzles.length];
  const source = new PuzzleSource({ fetcher, prefetchCount: 1 });
  const [a, b] = await Promise.all([source.next(), source.next()]);
  assert.notEqual(a.id, b.id);
  assert.ok(
    [a.id, b.id].every((id) =>
      [fallbackPuzzles[0].puzzle.id, fallbackPuzzles[1].puzzle.id].includes(id),
    ),
    "both came from the network, not the fallback pool",
  );
});

test("fetchNextPuzzle rejects on invalid JSON bodies", async () => {
  await assert.rejects(() =>
    fetchNextPuzzle({
      fetchFn: async () => new Response("not json at all", { status: 200 }),
    }),
  );
});

test("PuzzleSource falls back to bundled puzzles when the network is down", async () => {
  const source = new PuzzleSource({
    fetcher: async () => {
      throw new Error("offline");
    },
  });
  const puzzle = await source.next();
  assert.ok(fallbackPuzzles.some((raw) => raw.puzzle.id === puzzle.id));
  assert.match(source.lastError ?? "", /offline/);
  // and it keeps working
  const another = await source.next();
  assert.ok(another.id.length > 0);
});

test("PuzzleSource never repeats a puzzle within a session", async () => {
  // Network always returns the same puzzle: second next() must fall back.
  const fetcher = async (): Promise<LichessPuzzleResponse> =>
    fallbackPuzzles[0];
  const source = new PuzzleSource({ fetcher, prefetchCount: 1 });
  const first = await source.next();
  const second = await source.next();
  assert.notEqual(second.id, first.id);
});

test("PuzzleSource recycles fallbacks when the pool is exhausted", async () => {
  const only = [fallbackPuzzles[1]];
  const source = new PuzzleSource({
    fetcher: async () => {
      throw new Error("offline");
    },
    fallbacks: only,
  });
  const first = await source.next();
  const second = await source.next();
  assert.equal(first.id, only[0].puzzle.id);
  assert.equal(second.id, only[0].puzzle.id); // recycled, not an error
});
