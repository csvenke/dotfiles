/**
 * lichess puzzle client with prefetching and offline fallback.
 *
 * Anonymous access to /api/puzzle/next is rate-limited (~60/hour per IP),
 * so PuzzleSource keeps a small prefetch queue and falls back to the bundled
 * puzzle set when the network fails.
 */

import fallbackPuzzles from "./fallback-puzzles.ts";
import { parsePuzzle, validatePuzzleResponse } from "./puzzle.ts";
import type { LichessPuzzleResponse, PuzzleData } from "./puzzle.ts";

const DEFAULT_BASE_URL = "https://lichess.org";
const FETCH_TIMEOUT_MS = 10_000;

export interface FetchPuzzleOptions {
  /** lichess puzzle theme angle, e.g. "mateIn2". Defaults to lichess's mix. */
  angle?: string;
  signal?: AbortSignal;
  fetchFn?: typeof fetch;
  baseUrl?: string;
}

export type PuzzleFetcher = (
  options?: FetchPuzzleOptions,
) => Promise<LichessPuzzleResponse>;

/** Fetch the next puzzle for the anonymous (or default) puzzle selection. */
export async function fetchNextPuzzle(
  options: FetchPuzzleOptions = {},
): Promise<LichessPuzzleResponse> {
  const fetchFn = options.fetchFn ?? fetch;
  const url = new URL("/api/puzzle/next", options.baseUrl ?? DEFAULT_BASE_URL);
  if (options.angle) url.searchParams.set("angle", options.angle);
  const signal = options.signal
    ? AbortSignal.any([options.signal, AbortSignal.timeout(FETCH_TIMEOUT_MS)])
    : AbortSignal.timeout(FETCH_TIMEOUT_MS);

  let res: Response;
  try {
    res = await fetchFn(url, {
      headers: { accept: "application/json" },
      signal,
    });
  } catch (err) {
    throw new Error(
      `lichess puzzle fetch failed: ${err instanceof Error ? err.message : err}`,
    );
  }
  if (!res.ok) {
    throw new Error(`lichess puzzle fetch failed: HTTP ${res.status}`);
  }
  return validatePuzzleResponse(await res.json());
}

export interface PuzzleSourceOptions {
  angle?: string;
  /** Injectable for tests; defaults to fetchNextPuzzle. */
  fetcher?: PuzzleFetcher;
  /** Offline pool; defaults to the bundled set. */
  fallbacks?: LichessPuzzleResponse[];
  /** Target number of buffered puzzles. Default 2. */
  prefetchCount?: number;
  /** Cooldown after a failed fill before the network is retried. Default 60s. */
  cooldownMs?: number;
}

export class PuzzleSource {
  private queue: PuzzleData[] = [];
  private readonly seen = new Set<string>();
  private fallbackPool: LichessPuzzleResponse[];
  private filling: Promise<void> | null = null;
  private _lastError: string | null = null;
  private retryAfter = 0;
  private chain: Promise<void> = Promise.resolve();
  private readonly options: PuzzleSourceOptions;

  constructor(options: PuzzleSourceOptions = {}) {
    this.options = options;
    this.fallbackPool = [...(options.fallbacks ?? fallbackPuzzles)];
  }

  /** Last fetch error message, when the source had to use fallbacks. */
  get lastError(): string | null {
    return this._lastError;
  }

  /** Next puzzle to play. Rejects only if no bundled puzzle is usable either. */
  async next(): Promise<PuzzleData> {
    // Serialize calls so concurrent next() cannot both drain an empty queue.
    const result = this.chain.then(() => this.take());
    this.chain = result.then(
      () => undefined,
      () => undefined,
    );
    return result;
  }

  private async take(): Promise<PuzzleData> {
    const queued = this.queue.shift();
    if (queued) {
      void this.fill();
      return queued;
    }
    await this.fill();
    const fresh = this.queue.shift();
    if (fresh) {
      void this.fill();
      return fresh;
    }
    return this.nextFallback();
  }

  private async fill(): Promise<void> {
    this.filling ??= this.fillQueue().finally(() => {
      this.filling = null;
    });
    return this.filling;
  }

  private async fillQueue(): Promise<void> {
    if (Date.now() < this.retryAfter) return; // cooling down after a failure
    const target = this.options.prefetchCount ?? 2;
    const fetcher = this.options.fetcher ?? fetchNextPuzzle;
    // Bound attempts so a stubborn API (e.g. repeating ids) cannot loop forever.
    for (
      let attempts = 0;
      this.queue.length < target && attempts < target + 3;
      attempts++
    ) {
      try {
        const puzzle = parsePuzzle(
          await fetcher({ angle: this.options.angle }),
        );
        if (this.seen.has(puzzle.id)) continue;
        this.seen.add(puzzle.id);
        this.queue.push(puzzle);
        this._lastError = null;
        this.retryAfter = 0;
      } catch (err) {
        this._lastError = err instanceof Error ? err.message : String(err);
        this.retryAfter = Date.now() + (this.options.cooldownMs ?? 60_000);
        return;
      }
    }
  }

  private nextFallback(): PuzzleData {
    for (let attempt = 0; attempt < 2; attempt++) {
      const candidates = this.fallbackPool.filter(
        (p) => !this.seen.has(p.puzzle.id),
      );
      if (candidates.length === 0) {
        // Pool exhausted: recycle (allow repeats) rather than failing.
        this.fallbackPool = [...(this.options.fallbacks ?? fallbackPuzzles)];
        for (const p of this.fallbackPool) this.seen.delete(p.puzzle.id);
        continue;
      }
      const shuffled = [...candidates].sort(() => Math.random() - 0.5);
      for (const raw of shuffled) {
        this.fallbackPool = this.fallbackPool.filter((p) => p !== raw);
        try {
          const puzzle = parsePuzzle(raw);
          this.seen.add(puzzle.id);
          return puzzle;
        } catch {
          // Corrupt bundled entry: drop it and try the next one.
        }
      }
    }
    throw new Error(
      "no usable puzzles: every bundled fallback failed to parse",
    );
  }
}
