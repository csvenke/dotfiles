/**
 * Puzzle model: parse lichess puzzle API responses into a ready-to-play
 * PuzzleData. The solving position is derived by replaying the (already
 * truncated) game PGN, which uniformly includes the opponent's final move
 * before the solver's turn.
 */

import { Chess } from "chess.js";

export interface LichessPlayer {
  name?: string;
  id?: string;
  color?: string;
  rating?: number;
  flair?: string;
  // lichess adds more optional profile badges; tolerate them.
  [key: string]: unknown;
}

export interface LichessPuzzleResponse {
  game: {
    id?: string;
    clock?: string;
    rated?: boolean;
    perf?: { key?: string; name?: string };
    players?: LichessPlayer[];
    pgn: string;
  };
  puzzle: {
    id: string;
    rating: number;
    plays?: number;
    initialPly?: number;
    solution: string[];
    themes?: string[];
    fen?: string;
    lastMove?: string;
  };
}

export interface PuzzleData {
  id: string;
  rating: number;
  themes: string[];
  /** FEN of the solving position; the side to move is the solver. */
  fen: string;
  /** Color the solver plays ("white" | "black"); board is oriented for it. */
  color: "white" | "black";
  /** UCI moves alternating solver/opponent, starting with the solver. */
  solution: string[];
  /** e.g. "Blitz 3+2 · vs RPMondal (1544)". */
  source: string;
  /** Puzzle page on lichess. */
  url: string;
}

/** Validate the raw API shape enough to parse safely. */
export function validatePuzzleResponse(data: unknown): LichessPuzzleResponse {
  if (typeof data !== "object" || data === null) {
    throw new Error("puzzle: response is not an object");
  }
  const res = data as Partial<LichessPuzzleResponse>;
  if (typeof res.game?.pgn !== "string" || res.game.pgn.trim() === "") {
    throw new Error("puzzle: missing game.pgn");
  }
  if (typeof res.puzzle?.id !== "string" || res.puzzle.id === "") {
    throw new Error("puzzle: missing puzzle.id");
  }
  if (!Array.isArray(res.puzzle.solution) || res.puzzle.solution.length === 0) {
    throw new Error("puzzle: missing puzzle.solution");
  }
  if (
    !res.puzzle.solution.every(
      (m) => typeof m === "string" && /^[a-h][1-8][a-h][1-8][qrbn]?$/.test(m),
    )
  ) {
    throw new Error("puzzle: solution contains a malformed move");
  }
  return res as LichessPuzzleResponse;
}

/**
 * Parse a validated API response into PuzzleData. Replays the PGN (truncated
 * by lichess to just past the opponent's initial move) to obtain the solving
 * position, then sanity-checks the whole solution line is legal from it.
 */
export function parsePuzzle(data: unknown): PuzzleData {
  const res = validatePuzzleResponse(data);
  const chess = new Chess();
  try {
    chess.loadPgn(res.game.pgn);
  } catch (err) {
    throw new Error(
      `puzzle ${res.puzzle.id}: cannot replay PGN: ${err instanceof Error ? err.message : err}`,
    );
  }
  const fen = chess.fen();

  // When lichess provides the solving FEN directly, cross-check the parts
  // that must match (counters are normalized differently by each side).
  if (res.puzzle.fen) {
    const core = (f: string) => f.split(" ").slice(0, 4).join(" ");
    if (core(res.puzzle.fen) !== core(fen)) {
      throw new Error(
        `puzzle ${res.puzzle.id}: PGN replay disagrees with API fen`,
      );
    }
  }

  // Verify the entire solution is legal from the solving position.
  const probe = new Chess(fen);
  for (const uci of res.puzzle.solution) {
    const move = {
      from: uci.slice(0, 2),
      to: uci.slice(2, 4),
      promotion: uci[4],
    };
    try {
      probe.move(uci.length === 5 ? move : { from: move.from, to: move.to });
    } catch {
      throw new Error(`puzzle ${res.puzzle.id}: illegal solution move ${uci}`);
    }
  }

  const opponent = res.game.players?.find(
    (p) => p.color !== (chess.turn() === "w" ? "white" : "black"),
  );
  const sourceParts = [res.game.perf?.name, res.game.clock].filter(Boolean);
  if (opponent?.name) {
    sourceParts.push(
      `vs ${opponent.name}${opponent.rating ? ` (${opponent.rating})` : ""}`,
    );
  }

  return {
    id: res.puzzle.id,
    rating: res.puzzle.rating,
    themes: res.puzzle.themes ?? [],
    fen,
    color: chess.turn() === "w" ? "white" : "black",
    solution: [...res.puzzle.solution],
    source: sourceParts.join(" · ") || "lichess",
    url: `https://lichess.org/training/${res.puzzle.id}`,
  };
}
