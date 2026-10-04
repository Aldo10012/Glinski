# Gliński — Design

Hexagonal chess (Gliński's rules) for iPhone, iPad and Mac. SwiftUI, MVI, Clean Architecture,
modular Swift packages, full test coverage. Game logic never lives in the UI; the UI renders state.

Decided 2026-09-25 (grilling session). Change this doc when a decision changes.

## 1. Scope by version

| Version | Scope |
|---|---|
| **v1** | Local pass-and-play on one device |
| v2 | Computer opponent (`GlinskiAI` target, depends only on `GlinskiEngine`) |
| v3 | Online multiplayer via a Vapor server that reuses `GlinskiEngine` for authoritative move validation |

Consequence of v3: `GlinskiEngine` must build and test on Linux — pure Swift, no SwiftUI/UIKit/AppKit/Observation,
avoid Foundation.

### v1 features
- In: legal-move highlighting, undo, move list (long algebraic Gliński notation, e.g. `Nd1-f4`, `e4xd4`, `f10-f11=Q`, `Qk4-k6#`), resume after quitting, auto-rotate board
  setting (default **off**), resign, draw by agreement.
- Out: clocks/time controls (v2+), sounds/haptics (later), multiple saved games (YAGNI), drag-and-drop (later).

## 2. Platforms & toolchain
- One **native multiplatform** SwiftUI app target: **iOS 18, iPadOS 18, macOS 15** (lowered from 26 on 2026-09-25:
  the dev Mac is an Intel MacBook Pro on macOS 15.7). No Catalyst.
- Xcode 26, Swift 6.2, **Swift 6 language mode + strict concurrency** in the package.
- App target keeps default MainActor isolation; package targets do **not** (engine runs off-main / on server).

## 3. Modules

One local package `GlinskiKit/` with library targets, each with its own test target; a thin app target.

```
BoardUI ──► GlinskiFeature ──► GlinskiEngine
   ▲
App target (composition root: @main, window, store wiring, save/restore, menu commands)
```

| Target | Responsibility | Depends on |
|---|---|---|
| `GlinskiEngine` | Domain: coordinates, notation, pieces, board, move generation, legality, game end, `GameState` | — |
| `GlinskiFeature` | MVI: `State`, `Intent`, pure reducer, `GameStore` | Engine |
| `BoardUI` | SwiftUI views, hex layout math, hit-testing, piece assets | Feature |
| App (`Gliński`) | Composition root only | BoardUI, Feature |

Deliberately omitted: separate package per module (one package with N targets gives the same boundaries), a
UseCases layer (the reducer is the application layer; add when v2/v3 bring real side effects), a
persistence/repository module (one JSON file, one writer — the app target does it).

## 4. Engine

### Rules (Gliński, per Wikipedia)
- Board: 91 hex cells in 3 colours, flat-topped cells, 11 files `a–l` (no `j`), ranks `1–11` bending at file `f`.
  File lengths: a6 b7 c8 d9 e10 f11 g10 h9 i8 k7 l6.
- Setup — White: K g1, Q e1, R c1 i1, N d1 h1, B f1 f2 f3, P b1 c2 d3 e4 f5 g4 h3 i2 k1.
  Black mirrors: K g10, Q e10, R c8 i8, N d9 h9, B f9 f10 f11, P b7 c7 d7 e7 f7 g7 h7 i7 k7.
- Rook: any distance orthogonally (6 directions). Bishop: any distance diagonally (6 directions).
  Queen: both. King: one step orthogonally or diagonally; **no castling**.
  Knight: two cells orthogonally then one at 60° (leaps).
- Pawn: one vacant cell straight forward. Two vacant cells forward if standing on **its own or any other
  starting cell of a pawn of its colour**. Captures one cell orthogonally forward at 60° to the vertical.
  En passant allowed. Promotes on reaching the end of **any** file (White: top cell of each file; Black: rank 1)
  to Q, R, B or N.
- Check, checkmate as in chess.

### Game end
`GameResult = .checkmate(winner) | .stalemate(winner) | .resignation(winner) | .draw(.agreement | .repetition | .fiftyMove)`
- Stalemate is **not a draw**: stalemating side scores ¾, stalemated side ¼.
- Threefold repetition and 50-move rule are **automatic** (no claiming on a shared device).
- Insufficient material: **not in v1** (hex dead-material table differs from orthodox chess; 50-move rule ends
  dead games). Marked with a `ponytail:` note.

### Representation
- Axial hex coordinates `(q, r)` internally; Gliński notation (`f6`) only at edges (display, move list, tests).
- `Board` = fixed 91-slot `[Piece?]` indexed by precomputed cell index; static lookup tables for neighbours,
  12 sliding rays (6 orthogonal + 6 diagonal), knight jumps. No dictionaries in hot paths.
- `Board`, `GameState`, `Move`, `Piece` are value types: `Sendable, Hashable, Codable`.
  `apply(_:) -> GameState` returns a new state; `GameState` keeps move history (enables undo, repetition).
- Legal moves: pseudo-legal generation filtered by own-king-safety. Pin-aware generation deferred to v2 profiling.
- Repetition: count a `Hashable` key (board, side to move, en passant target) per position. Exact, no collisions.
  Zobrist hashing deferred to v2's transposition table.

## 5. MVI (`GlinskiFeature`)
Hand-rolled, no TCA.

```swift
@Observable @MainActor final class GameStore {
    private(set) var state: GameFeature.State
    func send(_ intent: GameFeature.Intent)          // calls the pure reducer
}
static func reduce(_ state: inout State, _ intent: Intent)   // pure, synchronous
```

```swift
enum Intent { case cellTapped(Cell), promotionChosen(PieceKind), undo,
              newGame, resign, offerDraw, respondToDraw(accept: Bool) }
```

`State` holds: the engine `GameState`, selection, highlighted legal targets, `pendingPromotion: Move?`,
`pendingDrawOffer`, result. No effect system in v1; v2 adds `reduce` returning an optional async `Effect`.

Interaction: **tap-tap only.** Tap own piece → select + highlight targets; tap target → move; tap another own
piece → reselect; tap elsewhere → deselect. Promotion: reducer sets `pendingPromotion`, UI shows Q/R/B/N picker,
`.promotionChosen` completes; `.undo` while pending cancels it.

## 6. UI (`BoardUI` + app)
Restyled 2026-10-04 from the Claude Design mocks (macOS / iPadOS / iOS, light + dark).
- One game screen, no home menu. Warm cream (light) / near-black (dark) page; wood board with thin gaps between
  cells, a soft shadow, rank/file labels on the edge cells, gold selected and last-move cells, dot (empty) or ring
  (capture) for legal targets, red glow for check.
- Adaptive by **available size**, not platform:
  - **Wide** (Mac, iPad landscape): board + 320pt side panel — opponent card, serif-italic status with detail line
    ("Move 4 · Queen on e10 selected"), move table, |< < > >| history nav, own card. System toolbar: Mac
    `+ ↶ ⇅ | ½ Offer draw ⚑ Resign | settings` with the subtitle "Two players on this Mac"; iPad `+` leading,
    title + "Two players · pass and play" centred, `↶ ⇅ ½ ⚑ ⚙︎` trailing.
  - **Narrow** (iPhone): no nav bar; header with round New Game / Settings buttons around the status, player cards
    above and below the board, a horizontal strip of move chips, and a bottom bar of Undo / Flip / Offer Draw / Resign.
- **Player cards**: avatar, name, captured pieces; the side to move gets a gold border. **No clocks** (v2+).
- **Move table**: one row per ply — number, from cell, to cell, image of the piece moved (plus the promoted piece).
  Tapping a row or chip reviews that position.
- **Review**: `Intent.review(ply)` shows an earlier position read-only; any other intent returns to the live
  position first, and a board tap while reviewing only returns to live. Overlays are hidden while reviewing.
- **Flip**: a manual toggle on top of the auto-rotate setting (default off). Mac menu shortcuts ⌘N, ⌘Z.
- Game over: overlay card on the board with the result ("Stalemate — White ¾, Black ¼") + New Game.
- Board = **91 individual cell views** positioned by pure hex-layout math (not a `Canvas`, which ViewInspector
  can't inspect). Each cell: accessibility identifier `cell.f6`, label "f6, white knight"; move rows `move.<n>`.
- Pieces: Cburnett SVG set (BSD), attribution in Settings.
- Colours: `Palette` tokens with light/dark variants (functions of `ColorScheme`; no asset catalog, so `swift test`
  sees them). No theme setting.
- Strings: English only, all via a String Catalog.

## 7. Persistence
`GameState: Codable`. The app target writes one JSON file on scene-phase change and restores it on launch.

## 8. Testing
- **Swift Testing** everywhere for unit tests. XCTest only for 2–3 XCUITest smoke tests in the app.
- Behaviour coverage, not just line coverage: every rule has positive **and** negative tests.
- `GlinskiEngine`, `GlinskiFeature`: **100% line coverage**.
- `BoardUI`: **≥ 90%**, tested with [ViewInspector](https://github.com/nalexn/ViewInspector) (test-only dependency).
- Engine: one test per rule + **perft** from the start position against verified reference values
  (shallow depth on PRs, deeper tagged tests available). If no reference can be verified, rely on per-rule
  tests + cross-checked hand counts.
- Mutation testing: **skipped**.

## 9. CI (GitHub Actions)

| Job | Runner | Gate |
|---|---|---|
| `engine-linux` | ubuntu + Swift 6.2 container | `swift test --filter GlinskiEngineTests` passes |
| `package-macos` | macos-26 | `swift test --enable-code-coverage`; Engine + Feature = 100%, BoardUI ≥ 90% (`llvm-cov report` + script) |
| `app` | macos-26 | `xcodebuild test` on iOS simulator + macOS, incl. smoke UI tests |

Repo/remote setup (git init, GitHub) is done manually by the owner.

## 10. Build order (TDD, vertical slices)
1. Package skeleton + CI (engine jobs). App-target conversion to multiplatform / Swift 6 happens with the UI (Plan 3).
2. Engine: coordinates & notation → setup → piece moves → check/legality → pawn specials → game end → perft.
3. Feature: selection, moves, promotion, undo, resign/draw, game over.
4. BoardUI: layout math → cell views → pieces → move list → toolbar/menus → overlay.
5. App: save/restore, settings sheet, smoke UI tests.
