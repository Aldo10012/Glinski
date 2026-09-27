# GlinskiFeature Implementation Plan (Plan 2 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** The MVI layer for pass-and-play: `GameFeature.State`, `GameFeature.Intent`, a pure `reduce`, and an `@Observable` `GameStore`. It must be 100% line-covered.

**Architecture:** New library target `GlinskiFeature` in `GlinskiKit`, depending only on `GlinskiEngine`. It holds all interaction logic (selection, highlights, promotion flow, undo, resign, draw offers), so views in Plan 3 only render `state` and `send` intents.

**Tech Stack:** Swift 6.2, Observation, Swift Testing.

**Spec:** `docs/DESIGN.md` §5 (MVI), §4 (game end). Engine API: Plan 1 (`GameState`, `Position`, `Move`, `Cell`).

## Global Constraints
- Same as Plan 1, plus: `GlinskiFeature` imports only `GlinskiEngine` and `Observation`. `reduce` is pure and synchronous. There's no effect system in v1.
- Coverage floor `GlinskiFeature: 100.0` is added to `scripts/coverage.sh`.
- The namespace enum is `GameFeature`, so it doesn't clash with the module name `GlinskiFeature`.

## Behaviour (the reducer's contract)

| Intent | Behaviour |
|---|---|
| `cellTapped(c)` | Ignored when the game is over, a promotion is pending, or a draw offer is pending. If `c` is a highlighted target: play the move, or set `pendingPromotion` when the move promotes. If `c` holds a piece of the side to move: select it and highlight its legal targets; tapping the selected cell again deselects it. Otherwise: deselect. |
| `promotionChosen(k)` | Completes the pending promotion with `k`. Ignored if nothing is pending or `k` is illegal (king/pawn), and the promotion stays pending. |
| `undo` | Cancels a pending promotion if there is one. Otherwise takes back the last move, clearing selection and any draw offer. Not allowed (`canUndo == false`) with no moves, or after a resignation or agreed draw: those were deliberate decisions, and undo would also take back an unrelated move. |
| `newGame` | Fresh `State()`. Confirmation is the UI's job (Plan 3). |
| `resign` | The side to move resigns. Ignored when the game is over. |
| `offerDraw` | Records `drawOfferedBy = sideToMove`. Ignored when the game is over or an offer is pending. |
| `respondToDraw(accept:)` | Accept: the game ends `.draw(.agreement)`. Decline: the offer clears and play continues. Ignored with no offer pending. |

Derived: `sideToMove`, `checkedKing: Cell?` (for the check highlight), `moveList: [String]`, `canUndo`, `lastMove: Move?`.

## Tasks
### Task 1: Target, State, selection
- [ ] Add `GlinskiFeature` (+ `GlinskiFeatureTests`) to `Package.swift`, and add the floor to `coverage.sh`.
- [ ] RED: `SelectionTests` (initial state, select/deselect/reselect, opponent's piece, taps after game over).
- [ ] GREEN: `GameFeature.State`, `Intent`, `reduce` handling `cellTapped` selection.
### Task 2: Moving and promotion
- [ ] RED: `MoveAndPromotionTests` (tap target plays, promotion becomes pending, taps ignored while pending, choose piece, illegal choice ignored, undo cancels pending).
- [ ] GREEN.
### Task 3: Undo, new game, resign, draw offers, check highlight
- [ ] RED: `GameFlowTests`. GREEN.
### Task 4: Store and verification
- [ ] RED: `GameStoreTests` (`@MainActor`: `send` runs the reducer). GREEN: `GameStore`.
- [ ] `scripts/coverage.sh`: GlinskiEngine 100%, GlinskiFeature 100%.
- [ ] Final whole-branch review.

## Review Focus
1. Double taps and taps during pending states must never play two moves or lose a pending promotion.
2. Undo must never desync `selection`/`targets` from the new position (no stale highlights).
3. A draw offer must not survive undo, or a new game.
4. After the game ends, no intent other than `newGame`/`undo` may change the game.
5. When the side to move has a piece with no legal moves, tapping it selects it with empty targets and doesn't crash.
