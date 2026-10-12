import type { LichessPuzzleResponse } from "./puzzle.ts";

/**
 * Bundled offline puzzles from the lichess puzzle API
 * (https://lichess.org/api/puzzle/next - lichess puzzle database).
 * Used when the network is unavailable. Keep small (~8 puzzles).
 * Regenerate by fetching fresh puzzles and pasting the JSON array below.
 */
const puzzles: LichessPuzzleResponse[] = [
  {
    game: {
      id: "VJ0nbvQP",
      perf: {
        key: "blitz",
        name: "Blitz",
      },
      rated: true,
      players: [
        {
          name: "limentur1",
          id: "limentur1",
          color: "white",
          rating: 2023,
        },
        {
          name: "Kjar",
          flair: "objects.gem-stone",
          patron: true,
          patronColor: 10,
          id: "kjar",
          color: "black",
          rating: 1982,
        },
      ],
      pgn: "d4 e6 e3 d5 Bd3 c5 c3 Nf6 Nd2 Nc6 f4 Bd6 Ngf3 b6 O-O O-O Ne5 Bb7 Rf3 Ne7 Rh3 Nf5 g4 Ne7 Qf3 g6 g5 Ne8 Qg4 h5 gxh6 Kh7 Ndf3 Nf5 Ng5+ Kg8 h7+ Kg7 Bxf5 Bxe5 Nxe6+ fxe6 Qxg6+ Kh8 fxe5 exf5 Rg3 Qe7",
      clock: "3+2",
    },
    puzzle: {
      id: "afPQd",
      rating: 1472,
      plays: 1310,
      solution: ["g6g8", "f8g8", "h7g8q"],
      themes: [
        "mateIn2",
        "advancedPawn",
        "middlegame",
        "short",
        "promotion",
        "kingsideAttack",
      ],
      initialPly: 47,
    },
  },
  {
    game: {
      id: "2oshuFJb",
      perf: {
        key: "rapid",
        name: "Rapid",
      },
      rated: true,
      players: [
        {
          name: "basemelahwal",
          id: "basemelahwal",
          color: "white",
          rating: 1998,
        },
        {
          name: "Chiara15",
          flair: "activity.lichess-horsey",
          id: "chiara15",
          color: "black",
          rating: 1924,
        },
      ],
      pgn: "d4 d5 e3 a6 Nf3 Nc6 a3 Bg4 Be2 Nf6 Nbd2 e6 c4 Bd6 c5 Be7 b4 h6 Bb2 b6 b5 axb5 Bxb5 Qd7 h3 Bxf3 Nxf3 Bd6 cxd6 cxd6 Rc1 Rc8 Qa4 O-O Bxc6 Qe7 O-O Ne4 Qd1 Rc7 Bb5 Rb7 Bd3 f5 Nd2 Qg5 Nxe4 fxe4 Be2 Rbf7 Bg4 Rf6 Rc6 Rg6 Rxd6 h5 Bxe6+ Kh8 g3 Rf3 Rd8+ Kh7 Bg8+ Kh6 Bf7 Rxg3+ Kh1",
      clock: "10+0",
    },
    puzzle: {
      id: "fxiw1",
      rating: 1310,
      plays: 1311,
      solution: ["g3h3"],
      themes: ["middlegame", "oneMove", "mateIn1", "kingsideAttack"],
      initialPly: 66,
    },
  },
  {
    game: {
      id: "eQfn2gwg",
      perf: {
        key: "rapid",
        name: "Rapid",
      },
      rated: true,
      players: [
        {
          name: "KK_91",
          id: "kk_91",
          color: "white",
          rating: 1756,
        },
        {
          name: "limon78",
          id: "limon78",
          color: "black",
          rating: 1679,
        },
      ],
      pgn: "e4 e5 Nf3 Nf6 Nxe5 Nc6 Nxc6 dxc6 f3 Bc5 Nc3 Qd4 Qe2 O-O d3 Nh5 Bd2 b5 O-O-O b4 Na4 Be6 Nxc5 Qxc5 b3 a5 Be3 Qc3 Kb1 a4 Bd2 Qd4 Qe3 Qd6 e5 Qe7 Qe4 c5 d4 axb3 cxb3 Rfd8 Be3 f6 exf6 Nxf6 Bg5 Nxe4 Bxe7 Nc3+ Kc2 Rxa2+ Kc1 Ra1+ Kc2 Rxd4 Rxa1 Bf5+ Kb2 Rd2+ Kc1 Rd1+ Kb2",
      clock: "10+5",
    },
    puzzle: {
      id: "i3JgW",
      rating: 1593,
      plays: 5907,
      solution: ["d1d2", "b2c1", "d2c2"],
      themes: ["mateIn2", "middlegame", "short", "operaMate", "vukovicMate"],
      initialPly: 62,
    },
  },
  {
    game: {
      id: "21WVlZia",
      perf: {
        key: "blitz",
        name: "Blitz",
      },
      rated: true,
      players: [
        {
          name: "Graf_Sheremetiev",
          id: "graf_sheremetiev",
          color: "white",
          rating: 2103,
        },
        {
          name: "visimpishakiv",
          id: "visimpishakiv",
          color: "black",
          rating: 2061,
        },
      ],
      pgn: "d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 f3 O-O Be3 Nbd7 Qd2 c5 Nge2 a6 Nc1 Nh5 Nb3 cxd4 Nxd4 e5 Nb3 f5 Qxd6 Qh4+ Bf2 Qg5 Qd2 Bh6 Qxg5 Bxg5 Nd5 Ndf6 Nc7 fxe4 Nxa8 e3 Bg3 e4 Nc7 exf3 gxf3 Nxg3 hxg3 Ng4 fxg4 Bxg4 Bh3 Bf3 Rf1 Bf6 Ne6 Bxb2 Nxf8",
      clock: "5+3",
    },
    puzzle: {
      id: "KY0hx",
      rating: 1467,
      plays: 29162,
      solution: ["b2c3", "b3d2", "c3d2"],
      themes: ["mateIn2", "middlegame", "short", "fork"],
      initialPly: 54,
    },
  },
  {
    game: {
      id: "u6TM432b",
      perf: {
        key: "blitz",
        name: "Blitz",
      },
      rated: true,
      players: [
        {
          name: "Takuya62",
          id: "takuya62",
          color: "white",
          rating: 1759,
        },
        {
          name: "Livingdead77",
          id: "livingdead77",
          color: "black",
          rating: 1642,
        },
      ],
      pgn: "e4 e5 Nf3 Nc6 Bc4 h6 d4 Nxd4 Nxd4 exd4 Qxd4 d6 Nc3 Be6 O-O Bxc4 Qxc4 Nf6 Re1 Be7 Bf4 O-O Nd5 Nxd5 Qxd5 c6 Qd3 Re8 Qg3 Bf6 Bxh6 g5 h4 Kh7 Bxg5 Bxg5 hxg5 Kg6 f4 Rh8 Kf2 Qb6+ Re3 Qxb2 f5+ Kg7 f6+ Kg6 Rae1 Qxc2+ R1e2 Qc5 Qf4 Rae8",
      clock: "3+0",
    },
    puzzle: {
      id: "8mMcP",
      rating: 1451,
      plays: 17147,
      solution: ["f4f5", "c5f5", "e4f5", "g6g5", "e3e8", "h8e8", "e2e8"],
      themes: ["exposedKing", "veryLong", "endgame", "crushing"],
      initialPly: 53,
    },
  },
  {
    game: {
      id: "fiONgSra",
      perf: {
        key: "blitz",
        name: "Blitz",
      },
      rated: true,
      players: [
        {
          name: "Lemuel_Bermas",
          flair: "activity.chess-pawn",
          id: "lemuel_bermas",
          color: "white",
          rating: 2421,
        },
        {
          name: "ChambalerongBatil",
          id: "chambalerongbatil",
          color: "black",
          rating: 2163,
        },
      ],
      pgn: "e4 c6 d4 d5 exd5 cxd5 c4 Nc6 Nc3 Nf6 Bg5 e6 Nf3 Bb4 Qa4 Bxc3+ bxc3 O-O cxd5 exd5 Bd3 Re8+ Be3 Ng4 O-O Nxe3 fxe3 Rxe3 Rad1 Bg4 Rde1 Rxd3 Qc2 Bf5 Ne5 Rf3 Qc1 Rxf1+ Rxf1 Bg6 Nf3 Qa5 Rf2 Re8 h4 h5 Ng5 Nxd4 Kh2 Nf5 Qf4 Qxc3 Nf3 Re4 Qb8+ Kh7",
      clock: "3+0",
    },
    puzzle: {
      id: "MLU82",
      rating: 1400,
      plays: 11924,
      solution: ["f3g5", "h7h6", "b8h8", "g6h7", "h8h7"],
      themes: ["middlegame", "fork", "long", "mateIn3"],
      initialPly: 55,
    },
  },
  {
    game: {
      id: "bn6GbdLm",
      perf: {
        key: "blitz",
        name: "Blitz",
      },
      rated: true,
      players: [
        {
          name: "strateji",
          id: "strateji",
          color: "white",
          rating: 1693,
        },
        {
          name: "Timofey-2010",
          flair: "smileys.clown-face",
          id: "timofey-2010",
          color: "black",
          rating: 1654,
        },
      ],
      pgn: "e4 b6 Nf3 Bb7 Nc3 e6 d4 c5 d5 exd5 exd5 Nf6 Bc4 d6 O-O Be7 Bg5 O-O a4 Nxd5 Bxe7 Nxe7 Nd5 Nxd5 Bxd5 Bxd5 Qxd5 Nd7 Qxd6 Nf6 Rad1 Qxd6 Rxd6 Rad8 Rfd1 Rxd6 Rxd6 Ne4 Rd7 a5 Rb7 Rd8 g3 g6 Rxb6 Nd2 Nxd2 Rxd2 c3 Rd5 Rb5 Rd2 b3 Rb2 Rxc5 Rxb3 c4 Rc3 Rxa5 Rxc4 Ra7 Rc1+ Kg2 Ra1 a5 Ra3 a6 Kg7 Ra8 Kh6 a7 Kg5 Kh3 h5 f4+ Kf5 Kh4 f6 Kh3 Ra2 Rb8 Rxa7 Rb5+ Ke6 Kh4 Ra2 h3 Ra4 Rb6+ Kf5",
      clock: "3+2",
    },
    puzzle: {
      id: "2eB1o",
      rating: 1529,
      plays: 14467,
      solution: ["g3g4", "h5g4", "h3g4", "f5f4", "b6f6"],
      themes: ["endgame", "crushing", "rookEndgame", "long"],
      initialPly: 89,
    },
  },
  {
    game: {
      id: "h9u8EPhj",
      perf: {
        key: "rapid",
        name: "Rapid",
      },
      rated: true,
      players: [
        {
          name: "Golzadeh",
          id: "golzadeh",
          color: "white",
          rating: 1715,
        },
        {
          name: "javadtaheri1364",
          id: "javadtaheri1364",
          color: "black",
          rating: 1647,
        },
      ],
      pgn: "e4 e6 d4 d5 e5 c5 c3 Qb6 Nf3 Nc6 Bd3 Nge7 O-O cxd4 Re1 dxc3 Nxc3 Nf5 Bxf5 exf5 Nxd5 Qd8 Bf4 Bc5 e6 fxe6 Nc7+ Kf7 Nxa8 e5 Nxe5+ Nxe5 Bxe5 Re8 Qxd8 Rxd8 Nc7 Rd2 Rf1 Re2 Rae1",
      clock: "10+5",
    },
    puzzle: {
      id: "TrMDl",
      rating: 1440,
      plays: 8178,
      solution: ["c5f2", "f1f2", "e2e1", "f2f1", "e1e5"],
      themes: ["deflection", "middlegame", "advantage", "fork", "long"],
      initialPly: 40,
    },
  },
];

export default puzzles;
