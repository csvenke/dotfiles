/**
 * PuzzleGame: state machine for solving one lichess puzzle.
 *
 * The solver plays the moves at even indexes of the solution line; odd
 * indexes are opponent replies, applied automatically after a correct move.
 * A wrong (but legal) move fails the puzzle, lichess-style; the expected
 * move and remaining solution are then available for display.
 */

import { Chess, type Square } from "chess.js";
import type { PuzzleData } from "./puzzle.ts";

export type GameStatus = "playing" | "solved" | "failed";

export type PromotionPiece = "q" | "r" | "b" | "n";

export type MoveOutcome =
  | { kind: "correct"; reply: string; replySan: string }
  | { kind: "solved"; reply: string | null; replySan: string | null }
  | { kind: "failed"; expected: string; expectedSan: string }
  | { kind: "illegal" };

export interface SquareRef {
  from: string;
  to: string;
}

export class PuzzleGame {
  readonly puzzle: PuzzleData;
  private readonly chess: Chess;
  private readonly solution: readonly string[];
  private index = 0;
  private _status: GameStatus = "playing";
  private _lastMove: SquareRef | null = null;
  private _hintUsed = false;

  constructor(puzzle: PuzzleData) {
    this.puzzle = puzzle;
    this.chess = new Chess(puzzle.fen);
    this.solution = puzzle.solution;
  }

  get status(): GameStatus {
    return this._status;
  }

  get lastMove(): SquareRef | null {
    return this._lastMove;
  }

  get hintUsed(): boolean {
    return this._hintUsed;
  }

  get turn(): "w" | "b" {
    return this.chess.turn();
  }

  get board() {
    return this.chess.board();
  }

  /** User moves completed / total user moves in the line. */
  get progress(): { done: number; total: number } {
    return {
      done: Math.ceil(this.index / 2),
      total: Math.ceil(this.solution.length / 2),
    };
  }

  pieceAt(square: string) {
    return this.chess.get(square as Square);
  }

  /** Legal target squares for the piece on `square` (for board highlights). */
  legalTargets(square: string): string[] {
    return this.chess
      .moves({ square: square as Square, verbose: true })
      .map((m) => m.to);
  }

  /** From-square of the expected move; marks the hint as used. */
  hint(): string | null {
    if (this._status !== "playing") return null;
    this._hintUsed = true;
    return this.solution[this.index].slice(0, 2);
  }

  /** True when moving from→to is a pawn promotion (choice required). */
  isPromotion(from: string, to: string): boolean {
    const piece = this.chess.get(from as Square);
    if (!piece || piece.type !== "p") return false;
    return (
      (piece.color === "w" && to[1] === "8") ||
      (piece.color === "b" && to[1] === "1")
    );
  }

  /**
   * Attempt the solver's move. Illegal moves are rejected without state
   * change; legal but off-solution moves fail the puzzle; correct moves
   * advance the line and auto-apply the opponent's reply. Like lichess,
   * any checkmating move is accepted even when the line differs.
   */
  tryMove(from: string, to: string, promotion?: PromotionPiece): MoveOutcome {
    if (this._status !== "playing") return { kind: "illegal" };

    let mv;
    try {
      mv = this.chess.move({ from, to, ...(promotion ? { promotion } : {}) });
    } catch {
      return { kind: "illegal" };
    }

    const uci = mv.from + mv.to + (mv.promotion ?? "");
    const expected = this.solution[this.index];
    const matches = uci === expected;
    if (!matches && !this.chess.isCheckmate()) {
      this.chess.undo();
      this._status = "failed";
      return { kind: "failed", expected, expectedSan: this.sanOf(expected) };
    }

    this._lastMove = { from: mv.from, to: mv.to };
    this.index++;
    if (!matches || this.index >= this.solution.length) {
      // Off-solution checkmate, or the line is complete.
      this._status = "solved";
      return { kind: "solved", reply: null, replySan: null };
    }

    const reply = this.solution[this.index];
    const replySan = this.applyUci(reply);
    this.index++;
    if (this.index >= this.solution.length) {
      this._status = "solved";
      return { kind: "solved", reply, replySan };
    }
    return { kind: "correct", reply, replySan };
  }

  /** Remaining solution (from the current position) in SAN, for display. */
  remainingSolutionSan(): string[] {
    const clone = new Chess(this.chess.fen());
    const sans: string[] = [];
    for (const uci of this.solution.slice(this.index)) {
      const mv = clone.move({
        from: uci.slice(0, 2),
        to: uci.slice(2, 4),
        ...(uci[4] ? { promotion: uci[4] } : {}),
      });
      sans.push(mv.san);
    }
    return sans;
  }

  private sanOf(uci: string): string {
    const clone = new Chess(this.chess.fen());
    const mv = clone.move({
      from: uci.slice(0, 2),
      to: uci.slice(2, 4),
      ...(uci[4] ? { promotion: uci[4] } : {}),
    });
    return mv.san;
  }

  private applyUci(uci: string): string {
    const from = uci.slice(0, 2);
    const to = uci.slice(2, 4);
    const mv = this.chess.move({
      from,
      to,
      ...(uci[4] ? { promotion: uci[4] } : {}),
    });
    this._lastMove = { from, to };
    return mv.san;
  }
}
