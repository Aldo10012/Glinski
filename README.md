# Gliński

Hexagonal chess (Gliński's rules) for iPhone, iPad and Mac, written in SwiftUI.

v1 is local pass-and-play: legal-move highlighting, undo, a move list in Gliński notation, resign, draw by
agreement, and resume after quitting. A computer opponent (v2) and online play (v3) are planned.

## Rules in brief

- 91 hexagonal cells in three colours; 11 files `a–l` (no `j`), ranks `1–11`.
- Rooks move orthogonally (through cell edges), bishops diagonally (through vertices), in 6 directions each.
- No castling. Pawns may double-step from any starting cell of their colour, capture at 60°, take en passant,
  and promote at the end of any file.
- Stalemate is not a draw: the stalemating side scores ¾, the stalemated side ¼.

The full rules are in [docs/DESIGN.md](docs/DESIGN.md#4-engine). [CONTEXT.md](CONTEXT.md) defines the terms
used in the code.

## Layout

```
Gliński/            App target (composition root: window, store wiring, save/restore)
GlinskiKit/         Swift package
  GlinskiEngine     Rules, move generation, game state (pure Swift, builds on Linux)
  GlinskiFeature    MVI state, intents, reducer, GameStore
  BoardUI           SwiftUI views and hex layout
GlinskiUITests/     XCUITest smoke tests
scripts/            coverage.sh (enforces coverage floors)
docs/               Design doc and implementation plans
```

Dependencies point one way: `BoardUI → GlinskiFeature → GlinskiEngine`.

## Requirements

- Xcode 26, Swift 6.2
- iOS / iPadOS 18+, macOS 15+

## Build and test

Open `Gliński.xcodeproj` and run the `Gliński` scheme.

From the command line:

```sh
swift test --package-path GlinskiKit   # package tests
scripts/coverage.sh                    # package tests + coverage floors (Engine/Feature 100%, BoardUI ≥ 90%)
```

CI (`.github/workflows/ci.yml`) runs the engine tests on Linux, the coverage script on macOS, and the app and
UI tests on macOS and the iOS simulator.

## Credits

The piece images are Cburnett's set from Wikimedia Commons, used under the BSD licence. See
[Pieces-LICENSE.txt](GlinskiKit/Sources/BoardUI/Resources/Pieces-LICENSE.txt).
