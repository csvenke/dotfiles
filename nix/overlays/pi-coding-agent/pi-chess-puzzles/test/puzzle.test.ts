import assert from "node:assert/strict";
import test from "node:test";
import { Chess } from "chess.js";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import { parsePuzzle, validatePuzzleResponse } from "../src/puzzle.ts";

test("parsePuzzle parses every bundled fallback puzzle", () => {
  assert.ok(fallbackPuzzles.length >= 5, "expected a meaningful fallback pool");
  for (const raw of fallbackPuzzles) {
    const puzzle = parsePuzzle(raw);
    assert.ok(puzzle.id.length > 0);
    assert.ok(puzzle.rating > 0);
    assert.match(puzzle.color, /^(white|black)$/);
    assert.ok(puzzle.solution.length > 0);
    // FEN is a real position whose side to move is the solver
    const chess = new Chess(puzzle.fen);
    assert.equal(chess.turn(), puzzle.color === "white" ? "w" : "b");
    assert.equal(puzzle.url, `https://lichess.org/training/${puzzle.id}`);
    assert.ok(puzzle.source.length > 0);
  }
});

test("parsePuzzle replays PGN to the exact solving position", () => {
  // afPQd: pinned literal FEN (PGN replay must land exactly here)
  const raw = fallbackPuzzles.find((p) => p.puzzle.id === "afPQd");
  assert.ok(raw);
  const puzzle = parsePuzzle(raw);
  assert.equal(
    puzzle.fen,
    "r3nr1k/pb2q2P/1p4Q1/2ppPp2/3P4/2P1P1R1/PP5P/R1B3K1 w - - 2 25",
  );
  // PGN contains the game up to and including the opponent's initial move
  const replay = new Chess();
  replay.loadPgn(raw.game.pgn);
  assert.equal(replay.history().length, (raw.puzzle.initialPly ?? -1) + 1);
});

test("parsePuzzle accepts matching API fen with different counters", () => {
  const raw = structuredClone(fallbackPuzzles[0]);
  const puzzle = parsePuzzle(raw);
  // lichess normalizes counters (e.g. "0 1"); only board/turn/castling/ep matter
  const core = puzzle.fen.split(" ").slice(0, 4).join(" ");
  raw.puzzle.fen = `${core} 0 1`;
  const reparsed = parsePuzzle(raw);
  assert.equal(reparsed.fen, puzzle.fen);
});

test("parsePuzzle rejects an API fen that disagrees with the PGN", () => {
  const raw = structuredClone(fallbackPuzzles[0]);
  raw.puzzle.fen = "8/8/8/8/8/8/8/K6k w - - 0 1";
  assert.throws(() => parsePuzzle(raw), /disagrees with API fen/);
});

test("parsePuzzle rejects an illegal solution line", () => {
  const raw = {
    game: { pgn: "e4 e5" },
    puzzle: { id: "badline1", rating: 1500, solution: ["e1e3"] },
  };
  assert.throws(() => parsePuzzle(raw), /illegal solution move e1e3/);
});

test("validatePuzzleResponse rejects malformed payloads", () => {
  assert.throws(() => validatePuzzleResponse(null), /not an object/);
  assert.throws(() => validatePuzzleResponse({}), /game\.pgn/);
  assert.throws(
    () =>
      validatePuzzleResponse({
        game: { pgn: "e4" },
        puzzle: { rating: 1, solution: ["e1e2"] },
      }),
    /puzzle\.id/,
  );
  assert.throws(
    () =>
      validatePuzzleResponse({
        game: { pgn: "e4" },
        puzzle: { id: "x", rating: 1, solution: [] },
      }),
    /solution/,
  );
  assert.throws(
    () =>
      validatePuzzleResponse({
        game: { pgn: "e4" },
        puzzle: { id: "x", rating: 1, solution: ["e9e4"] },
      }),
    /malformed move/,
  );
});

test("parsePuzzle builds a human-readable source line", () => {
  const raw = {
    game: {
      pgn: "e4 e5",
      clock: "3+2",
      perf: { key: "blitz", name: "Blitz" },
      players: [
        { name: "alice", color: "white", rating: 1500 },
        { name: "bob", color: "black", rating: 1600 },
      ],
    },
    // white to move after 1...e5, so the opponent is black
    puzzle: { id: "srcline1", rating: 1200, solution: ["f1c4", "f8c5"] },
  };
  const puzzle = parsePuzzle(raw);
  assert.equal(puzzle.color, "white");
  assert.equal(puzzle.source, "Blitz · 3+2 · vs bob (1600)");
});
