# BoardUI + App Implementation Plan (Plan 3 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** A playable pass-and-play app on iPhone, iPad and Mac. `BoardUI` renders `GameFeature.State` and sends intents. The app target only wires things together, saves and restores the game, and adds Mac menu commands.

**Architecture:** `BoardUI` target (depends on `GlinskiFeature`, with ViewInspector for tests only). `GameArchive` (save and restore, file-based) goes in `GlinskiFeature`, where it is unit-tested. The app target becomes multiplatform (iOS 26 + macOS 26, Swift 6) and links `BoardUI` + `GlinskiFeature`. There's a UI-test target with smoke tests, and a CI `app` job.

**Spec:** `docs/DESIGN.md` §2, §6, §7, §8, §9.

## Global Constraints
- The coverage floor becomes `BoardUI: 90.0`, alongside Engine and Feature at 100.
- The board is 91 individual cell views, not a `Canvas`. Each has the identifier `cell.<notation>` and the label `"<notation>, <colour> <piece>"` or `"<notation>, empty"`. Its highlights go in the accessibility value.
- The layout adapts to **available size**, not platform.
- All user-facing strings are plain English string literals. SwiftUI extracts them into the String Catalog, so no manual keys.
- ViewInspector is pinned `exact: "0.10.3"`. 0.10.4's manifest fails under Xcode 26.
- Pieces are Cburnett SVGs (Wikimedia Commons), used under their **BSD** option, with attribution in Settings. `swift build` doesn't compile `.xcassets`, so images render only in Xcode builds. Tests inspect image names.

## Pure pieces (tested without views)
- `HexLayout(fitting: CGSize)`: `cellRadius = min(w/17, h/(11√3))`. `center(of:flipped:)` gives x = 1.5·R·q, y = √3·R·(r + q/2), about the view centre. Flipped = rotated 180°.
- `BoardText`: `status(state)` gives "White to move", "Black to move — check", "Checkmate — White wins", "Stalemate — White ¾, Black ¼", "Draw by agreement", "Draw by threefold repetition", "Draw by the 50-move rule" or "White resigns — Black wins". `moveRows(moveList)` pairs moves into numbered rows. `pieceName`, `cellLabel`.

## Views
`CellView`, `BoardView`, `MoveListView`, `PromotionPicker`, `DrawOfferView`, `GameOverView`, `ControlsView` (New Game, confirmed if moves were played; Undo, disabled unless `canUndo`; Offer Draw; Resign, confirmed; Settings), `SettingsView` (auto-rotate toggle, attribution), and the public `GameView`, which composes them and flips the board when auto-rotate is on and Black is to move.

## Tasks
1. BoardUI target + `HexLayout` + `HexShape` (TDD).
2. `BoardText` (status/result/move rows/labels) (TDD).
3. `CellView` + `BoardView` (ViewInspector: 91 cells, identifiers, labels, highlight values, tap → intent).
4. Panels: `MoveListView`, `PromotionPicker`, `DrawOfferView`, `GameOverView`, `ControlsView`, `SettingsView`, `GameView` (ViewInspector).
5. `GameArchive` in GlinskiFeature (save/load JSON; a missing or corrupt file gives nil) (TDD).
6. App target: multiplatform build settings, Swift 6, link the package, `GliñskiApp` (store, restore, save on scene phase, commands), delete `ContentView`. Build for the iOS simulator + macOS.
7. UI-test target + shared scheme + smoke tests (launch → tap e4 → tap e6 → move list shows "e4-e6"). CI `app` job.
8. Coverage gate, final review.

## Review Focus
1. Saved-game restore with a corrupt or old file must start a fresh game, not crash.
2. Promotion picker and draw prompt must never appear together with the game-over overlay.
3. Flipped board: taps must hit the cell drawn under the finger (the positions and the hit shape both come from the same layout).
4. VoiceOver: every cell has a meaningful label and the highlight state.
5. A narrow Mac window or iPad split view gets the stacked layout.
