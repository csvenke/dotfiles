import assert from "node:assert/strict";
import test from "node:test";
import { Chess } from "chess.js";
import fallbackPuzzles from "../src/fallback-puzzles.ts";
import { PuzzleGame } from "../src/game.ts";
import { parsePuzzle, type PuzzleData } from "../src/puzzle.ts";

const pool = fallbackPuzzles.map((raw) => ({ raw, puzzle: parsePuzzle(raw) }));

function byId(id: string): PuzzleData {
  const entry = pool.find((p) => p.puzzle.id === id);
  assert.ok(entry, `fixture puzzle ${id} missing`);
  return entry.puzzle;
}

/** A legal move in the current position that is NOT the expected one. */
function someWrongMove(puzzle: PuzzleData): { from: string; to: string } {
  const chess = new Chess(puzzle.fen);
  const expected = puzzle.solution[0];
  for (const move of chess.moves({ verbose: true })) {
    const uci = move.from + move.to + (move.promotion ?? "");
    if (uci !== expected) return { from: move.from, to: move.to };
  }
  throw new Error("no alternative legal move in fixture");
}

function playUserMove(game: PuzzleGame, index: number) {
  const uci = game.puzzle.solution[index];
  return game.tryMove(
    uci.slice(0, 2),
    uci.slice(2, 4),
    uci[4] as "q" | "r" | "b" | "n" | undefined,
  );
}

test("full solution solves every bundled puzzle, with opponent replies applied", () => {
  for (const { puzzle } of pool) {
    const game = new PuzzleGame(puzzle);
    let solved = false;
    for (let i = 0; i < puzzle.solution.length; i += 2) {
      const before = game.progress;
      assert.equal(before.done, i / 2);
      const outcome = playUserMove(game, i);
      if (i + 2 >= puzzle.solution.length) {
        assert.equal(outcome.kind, "solved", `${puzzle.id} move ${i}`);
      } else {
        assert.equal(outcome.kind, "correct", `${puzzle.id} move ${i}`);
        if (outcome.kind === "correct") {
          // opponent reply is the next UCI in the line and was applied
          assert.equal(outcome.reply, puzzle.solution[i + 1]);
          assert.equal(game.lastMove?.from, puzzle.solution[i + 1].slice(0, 2));
          assert.equal(game.lastMove?.to, puzzle.solution[i + 1].slice(2, 4));
        }
      }
      solved = outcome.kind === "solved";
    }
    assert.ok(solved, `${puzzle.id} solved`);
    assert.equal(game.status, "solved");
    assert.equal(game.progress.done, game.progress.total);
  }
});

test("single-move puzzle solves immediately without a reply", () => {
  const game = new PuzzleGame(byId("fxiw1")); // mateIn1, one-move solution
  const outcome = playUserMove(game, 0);
  assert.deepEqual(outcome, { kind: "solved", reply: null, replySan: null });
  assert.equal(game.status, "solved");
});

test("illegal move is rejected without changing state", () => {
  const game = new PuzzleGame(pool[0].puzzle);
  const outcome = game.tryMove("a1", "a8");
  assert.equal(outcome.kind, "illegal");
  assert.equal(game.status, "playing");
  assert.equal(game.progress.done, 0);
});

test("wrong legal move fails the puzzle and reveals the expected move", () => {
  const puzzle = pool[0].puzzle;
  const game = new PuzzleGame(puzzle);
  const wrong = someWrongMove(puzzle);
  const outcome = game.tryMove(wrong.from, wrong.to);
  assert.equal(outcome.kind, "failed");
  if (outcome.kind === "failed") {
    assert.equal(outcome.expected, puzzle.solution[0]);
    assert.ok(outcome.expectedSan.length > 0);
    // the position was restored (move undone): solution SAN starts with it
    assert.equal(game.remainingSolutionSan()[0], outcome.expectedSan);
  }
  assert.equal(game.status, "failed");
  // board unchanged after the failed attempt
  assert.equal(game.lastMove, null);
  assert.equal(game.turn, puzzle.color === "white" ? "w" : "b");
  assert.ok(game.pieceAt(wrong.from), "moved piece is back on its square");
  // remaining solution is displayed in SAN from the original position
  assert.equal(game.remainingSolutionSan().length, puzzle.solution.length);
  // game is over: further moves rejected
  assert.equal(playUserMove(game, 0).kind, "illegal");
});

test("an alternative checkmating move is accepted, lichess-style", () => {
  // Position with two distinct mates in one: Kb3# and Qb2#.
  const puzzle: PuzzleData = {
    id: "synthetic-mate",
    rating: 1200,
    themes: ["mateIn1"],
    fen: "8/8/8/8/8/K7/Q7/k7 w - - 0 1",
    color: "white",
    solution: ["a3b3"],
    source: "synthetic",
    url: "",
  };
  const game = new PuzzleGame(puzzle);
  const outcome = game.tryMove("a2", "b2"); // Qb2#, not the listed solution
  assert.equal(outcome.kind, "solved");
  assert.equal(game.status, "solved");
});

test("promotion requires the choice and must match the solution", () => {
  const puzzle = byId("afPQd"); // promotion puzzle
  const promoIndex = puzzle.solution.findIndex((m) => m.length === 5);
  assert.ok(
    promoIndex >= 0 && promoIndex % 2 === 0,
    "promotion is a user move",
  );

  // Play up to the promotion move
  const game = new PuzzleGame(puzzle);
  for (let i = 0; i < promoIndex; i += 2) {
    assert.notEqual(playUserMove(game, i).kind, "illegal");
  }
  const uci = puzzle.solution[promoIndex];
  const from = uci.slice(0, 2);
  const to = uci.slice(2, 4);
  assert.ok(game.isPromotion(from, to));

  // Missing promotion choice is illegal (caller must prompt first)
  assert.equal(game.tryMove(from, to).kind, "illegal");
  assert.equal(game.status, "playing");

  // Wrong promotion piece is legal chess but off-solution: fails
  const other = uci[4] === "q" ? "r" : "q";
  const failed = game.tryMove(from, to, other);
  assert.equal(failed.kind, "failed");

  // Fresh game, correct promotion solves the line (last user move)
  const game2 = new PuzzleGame(puzzle);
  for (let i = 0; i < promoIndex; i += 2) playUserMove(game2, i);
  const outcome = game2.tryMove(from, to, uci[4] as "q");
  assert.equal(outcome.kind, "solved");
});

test("hint reveals the expected from-square and is tracked", () => {
  const game = new PuzzleGame(pool[0].puzzle);
  assert.equal(game.hintUsed, false);
  const square = game.hint();
  assert.equal(square, pool[0].puzzle.solution[0].slice(0, 2));
  assert.equal(game.hintUsed, true);
});

test("hint is unavailable once the game is over", () => {
  const game = new PuzzleGame(byId("fxiw1"));
  playUserMove(game, 0);
  assert.equal(game.hint(), null);
});

test("isPromotion is false for non-pawn moves", () => {
  const game = new PuzzleGame(byId("fxiw1"));
  const uci = game.puzzle.solution[0];
  // mateIn1 fixture's solution is not a pawn promotion
  assert.equal(game.isPromotion(uci.slice(0, 2), uci.slice(2, 4)), false);
});
