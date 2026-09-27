# GlinskiEngine Implementation Plan (Plan 1 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A pure-Swift, Linux-clean `GlinskiEngine` library that implements every rule of Gliński's hexagonal chess, at 100% line coverage, with CI enforcing it.

**Architecture:** A local SwiftPM package `GlinskiKit/`. For now it has one library target, `GlinskiEngine`, plus its Swift Testing target. Cells use axial hex coordinates with precomputed ray and jump tables. `Position` is an immutable value that generates moves, and `GameState` wraps it with history, results and undo. Later plans add the `GlinskiFeature` and `BoardUI` targets to the same package. Converting the app target to multiplatform, plus the `app` CI job, moves to Plan 3, where the app first has UI to build.

**Tech Stack:** Swift 6.2 (Swift 6 language mode), SwiftPM, Swift Testing, GitHub Actions (`ubuntu-latest` + `swift:6.2` container, `macos-26`), python3 for the coverage gate.

**Spec:** `docs/DESIGN.md` (and glossary `CONTEXT.md`)

## Global Constraints

- `GlinskiEngine` imports **nothing** (no Foundation, SwiftUI, UIKit, AppKit, Observation). Tests may import Foundation (for `JSONEncoder`).
- `swift-tools-version: 6.2`, platforms `.iOS(.v26)`, `.macOS(.v26)`; Swift 6 language mode, strict concurrency.
- All public engine types are value types conforming to `Sendable, Hashable` (and `Codable` where listed).
- Unit tests use **Swift Testing** only (`import Testing`, `@Test`, `#expect`, `#require`). No XCTest.
- `GlinskiEngine` line coverage **= 100%**, enforced by `scripts/coverage.sh`.
- Every rule has a positive **and** a negative test (behaviour coverage, not just lines).
- Use glossary names from `CONTEXT.md`: **cell** (never "square"), file, rank, ply, halfmove clock, promotion cell.
- Git: the owner initializes the repo and remote manually. **Never run `git init` or add remotes.** Commit steps apply once the repo exists. Before that, skip them.
- Deliberate simplifications carry a `// ponytail:` comment naming the ceiling and upgrade path.

## Review Focus

1. **Corrupt or tampered save file.** Decoding a `GameState` whose move list contains an illegal move must throw, not crash or produce an impossible game. A stored `checkmate` result must be ignored, because only resignation and agreed draws are trusted from storage. *(Task 7 tests.)*
2. **En passant that exposes the king.** A capture that removes two pawns from one line and opens a rook line to the capturer's king must be illegal. *(Task 5 test.)*
3. **Positions without a king** (test fixtures, a future editor): `isInCheck` is `false`, and move generation doesn't crash. *(Task 4 test.)*
4. **Malformed promotion moves.** A pawn reaching a promotion cell without a promotion piece, or a promotion on a non-final cell, or to a king or pawn, is rejected. *(Task 5 test.)*
5. **Undo after the game ended.** Undoing a mating move clears the result and restores the prior position. Undo on a fresh game returns `nil`. *(Task 7 test.)*

---

## File Structure

```
GlinskiKit/
  Package.swift
  Sources/GlinskiEngine/
    Cell.swift            Cell (axial q,r), notation, dense index, shade, Codable as "f6"
    Geometry.swift        Vector, direction sets, precomputed rays / knight / king tables
    Piece.swift           Side, PieceKind (+ letters), Piece
    Board.swift           91-slot board, placement string (parse/print), initial setup, Codable
    Move.swift            Move
    Position.swift        Position (board, side, en passant, halfmove clock), pawn constants
    MoveGeneration.swift  pseudo-legal + legal moves, attack detection, check
    Apply.swift           applying moves, perft
    Notation.swift        long algebraic notation for a move
    GameState.swift       GameState, GameResult, DrawReason, GameError, undo, Codable
  Tests/GlinskiEngineTests/
    TestSupport.swift     cell(), move(), position(), targets(from:) helpers
    CellTests.swift  GeometryTests.swift  BoardTests.swift  MoveGenerationTests.swift
    PawnTests.swift  ApplyTests.swift  GameStateTests.swift  NotationTests.swift
scripts/coverage.sh       swift test + per-target line-coverage floors
.github/workflows/ci.yml  engine-linux, package-macos
```

Coordinate conventions, used everywhere:
- `q` = file index − 5 (a = −5 … f = 0 … l = +5; files `abcdefghikl`, no `j`). `r` grows **downward** (towards White). On board iff `|q| ≤ 5 && |r| ≤ 5 && |q + r| ≤ 5`.
- `rank = 6 − max(q, 0) − r`. So f6 = (0,0), a1 = (−5,5), f1 = (0,5), l1 = (5,0), f11 = (0,−5), a6 = (−5,0), l6 = (5,−5).
- Orthogonal directions (through an edge), clockwise from up: up (0,−1), up-right (1,−1), down-right (1,0), down (0,1), down-left (−1,1), up-left (−1,0).
- Diagonal (through a vertex) = sum of two adjacent orthogonals. Knight = 2× an orthogonal + an adjacent orthogonal.
- White pawns move up (0,−1) and capture up-left (−1,0) / up-right (1,−1). Black pawns move down (0,1) and capture down-left (−1,1) / down-right (1,0).
- Mirroring White↔Black: (q, r) → (q, −q − r).

---

### Task 1: Package skeleton, `Cell`, coverage gate, CI

**Files:**
- Create: `GlinskiKit/Package.swift`, `GlinskiKit/Sources/GlinskiEngine/Cell.swift`, `GlinskiKit/Tests/GlinskiEngineTests/TestSupport.swift`, `GlinskiKit/Tests/GlinskiEngineTests/CellTests.swift`, `scripts/coverage.sh`, `.github/workflows/ci.yml`, `.gitignore`

**Interfaces:**
- Produces: `public struct Cell: Hashable, Sendable, Codable, CustomStringConvertible` with `q`, `r`, `init?(q:r:)`, `init?(_ notation: String)`, `file: Character`, `rank: Int`, `notation: String`, `index: Int` (0..<91), `shade: Int` (0...2), `static let all: [Cell]`, `static let files: [Character]`; test helper `cell(_:) -> Cell`.

- [ ] **Step 1: Create the package manifest and `.gitignore`**

`GlinskiKit/Package.swift`:
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GlinskiKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "GlinskiEngine", targets: ["GlinskiEngine"]),
    ],
    targets: [
        .target(name: "GlinskiEngine"),
        .testTarget(name: "GlinskiEngineTests", dependencies: ["GlinskiEngine"]),
    ]
)
```

`.gitignore` (repo root):
```
.build/
.swiftpm/
xcuserdata/
DerivedData/
.DS_Store
```

- [ ] **Step 2: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/TestSupport.swift`:
```swift
@testable import GlinskiEngine

/// Cell from notation; crashes the test on a typo so fixtures stay honest.
func cell(_ notation: String) -> Cell {
    guard let cell = Cell(notation) else { fatalError("bad cell \(notation)") }
    return cell
}
```

`GlinskiKit/Tests/GlinskiEngineTests/CellTests.swift`:
```swift
import Foundation
import Testing
@testable import GlinskiEngine

struct CellTests {
    @Test func boardHas91Cells() {
        #expect(Cell.all.count == 91)
        #expect(Set(Cell.all).count == 91)
    }

    @Test func indexIsDenseAndMatchesOrder() {
        for (i, c) in Cell.all.enumerated() { #expect(c.index == i) }
    }

    @Test func filesSkipJ() {
        #expect(String(Cell.files) == "abcdefghikl")
    }

    @Test(arguments: [
        ("f6", 0, 0), ("a1", -5, 5), ("f1", 0, 5), ("l1", 5, 0),
        ("f11", 0, -5), ("a6", -5, 0), ("l6", 5, -5), ("g1", 1, 4), ("e10", -1, -4),
    ])
    func notationMapsToAxial(notation: String, q: Int, r: Int) throws {
        let c = try #require(Cell(notation))
        #expect(c.q == q && c.r == r)
        #expect(c.notation == notation)
        #expect(c.description == notation)
    }

    @Test func notationRoundTripsForEveryCell() {
        for c in Cell.all { #expect(Cell(c.notation) == c) }
    }

    @Test func fileLengths() {
        let lengths = Cell.files.map { f in Cell.all.filter { $0.file == f }.count }
        #expect(lengths == [6, 7, 8, 9, 10, 11, 10, 9, 8, 7, 6])
    }

    @Test(arguments: ["j1", "a7", "l7", "f12", "f0", "", "f", "fx", "f+5", "A1", "m1"])
    func invalidNotationIsRejected(notation: String) {
        #expect(Cell(notation) == nil)
    }

    @Test func offBoardAxialIsRejected() {
        #expect(Cell(q: 6, r: 0) == nil)
        #expect(Cell(q: 0, r: -6) == nil)
        #expect(Cell(q: 3, r: 3) == nil)   // |q + r| = 6
        #expect(Cell(q: -3, r: -3) == nil)
    }

    @Test func orthogonalNeighboursHaveDifferentShades() {
        let orth = [(0, -1), (1, -1), (1, 0), (0, 1), (-1, 1), (-1, 0)]
        for c in Cell.all {
            for (dq, dr) in orth {
                if let n = Cell(q: c.q + dq, r: c.r + dr) { #expect(n.shade != c.shade) }
            }
        }
    }

    @Test func diagonalNeighboursShareShade() {
        let diag = [(1, -2), (2, -1), (1, 1), (-1, 2), (-2, 1), (-1, -1)]
        for c in Cell.all {
            for (dq, dr) in diag {
                if let n = Cell(q: c.q + dq, r: c.r + dr) { #expect(n.shade == c.shade) }
            }
        }
    }

    @Test func whiteBishopsStartOnThreeShades() {
        #expect(Set(["f1", "f2", "f3"].map { cell($0).shade }) == [0, 1, 2])
    }

    @Test func codableAsNotation() throws {
        let data = try JSONEncoder().encode(cell("f6"))
        #expect(String(decoding: data, as: UTF8.self) == "\"f6\"")
        #expect(try JSONDecoder().decode(Cell.self, from: data) == cell("f6"))
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Cell.self, from: Data("\"j1\"".utf8))
        }
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit`
Expected: compile failure, `cannot find 'Cell' in scope`.

- [ ] **Step 4: Implement `Cell`**

`GlinskiKit/Sources/GlinskiEngine/Cell.swift`:
```swift
/// One of the 91 hexagonal cells, in axial coordinates.
/// `q` is the file offset from the centre file f (-5...5); `r` grows downward, towards White.
public struct Cell: Hashable, Sendable {
    public let q: Int
    public let r: Int

    public init?(q: Int, r: Int) {
        guard abs(q) <= 5, abs(r) <= 5, abs(q + r) <= 5 else { return nil }
        self.q = q
        self.r = r
    }

    /// Parses Gliński notation such as "f6".
    public init?(_ notation: String) {
        let digits = notation.dropFirst()
        guard let letter = notation.first,
              let fileIndex = Cell.files.firstIndex(of: letter),
              !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }),
              let rank = Int(digits) else { return nil }
        let q = fileIndex - 5
        self.init(q: q, r: 6 - max(q, 0) - rank)
    }

    public static let files: [Character] = Array("abcdefghikl")

    /// Every cell, ordered by file then rank; `all[c.index] == c`.
    public static let all: [Cell] = (-5...5).flatMap { q in
        (1...(11 - abs(q))).map { rank in Cell(q: q, r: 6 - max(q, 0) - rank)! }
    }

    private static let columnStart: [Int] = (-5...5).reduce(into: [0]) { starts, q in
        starts.append(starts.last! + 11 - abs(q))
    }

    public var file: Character { Cell.files[q + 5] }
    public var rank: Int { 6 - max(q, 0) - r }
    public var notation: String { "\(file)\(rank)" }

    /// Dense index 0..<91, used for array-backed boards and lookup tables.
    public var index: Int { Cell.columnStart[q + 5] + rank - 1 }

    /// Which of the three board colours (0...2). Orthogonal neighbours differ; diagonal ones match.
    public var shade: Int { ((q - r) % 3 + 3) % 3 }
}

extension Cell: CustomStringConvertible {
    public var description: String { notation }
}

extension Cell: Codable {
    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let cell = Cell(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid cell \(text)"))
        }
        self = cell
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(notation)
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --package-path GlinskiKit`
Expected: all `CellTests` pass.

- [ ] **Step 6: Add the coverage gate**

`scripts/coverage.sh` (then `chmod +x scripts/coverage.sh`):
```bash
#!/usr/bin/env bash
# Runs GlinskiKit tests with coverage and enforces per-target line-coverage floors.
set -euo pipefail
cd "$(dirname "$0")/../GlinskiKit"
swift test --enable-code-coverage
python3 - "$(swift test --show-codecov-path)" <<'PY'
import json, sys
floors = {"GlinskiEngine": 100.0}   # later plans add GlinskiFeature: 100.0, BoardUI: 90.0
files = json.load(open(sys.argv[1]))["data"][0]["files"]
failed = False
for target, floor in floors.items():
    mine = [f for f in files if f"/Sources/{target}/" in f["filename"]]
    covered = sum(f["summary"]["lines"]["covered"] for f in mine)
    total = sum(f["summary"]["lines"]["count"] for f in mine)
    pct = 100.0 * covered / total if total else 0.0
    print(f"{target}: {pct:.2f}% ({covered}/{total} lines), floor {floor}%")
    for f in mine:
        if f["summary"]["lines"]["percent"] < 100:
            print(f'    {f["filename"].split("/Sources/")[1]}: {f["summary"]["lines"]["percent"]:.1f}%')
    failed |= pct < floor
sys.exit(1 if failed else 0)
PY
```

Run: `scripts/coverage.sh`
Expected: tests pass, prints `GlinskiEngine: 100.00% …`, exit 0. If below 100%, the script lists the files. Add tests (not `// coverage-ignore` tricks) until it passes.

- [ ] **Step 7: Add CI**

`.github/workflows/ci.yml`:
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  engine-linux:
    runs-on: ubuntu-latest
    container: swift:6.2
    steps:
      - uses: actions/checkout@v4
      - run: swift test --package-path GlinskiKit --filter GlinskiEngineTests

  package-macos:
    runs-on: macos-26
    steps:
      - uses: actions/checkout@v4
      - run: scripts/coverage.sh
```

Verify locally that the Linux job would build (optional, needs Docker):
`docker run --rm -v "$PWD":/src -w /src swift:6.2 swift test --package-path GlinskiKit --filter GlinskiEngineTests`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add .gitignore GlinskiKit scripts .github
git commit -m "feat(engine): package skeleton, Cell coordinates and notation, coverage gate, CI"
```

---

### Task 2: Geometry tables

**Files:**
- Create: `GlinskiKit/Sources/GlinskiEngine/Geometry.swift`, `GlinskiKit/Tests/GlinskiEngineTests/GeometryTests.swift`

**Interfaces:**
- Consumes: `Cell` (Task 1).
- Produces (internal): `struct Vector { dq, dr }` with `+`, `* Int`, prefix `-`; `Cell.offset(_: Vector) -> Cell?`; `enum Geometry` with `orthogonal`, `diagonal`, `knight: [Vector]`, and tables indexed by `Cell.index`: `orthogonalRays`, `diagonalRays: [[[Int]]]` (`[cell][direction]` → cell indices outward), `knightTargets`, `kingTargets: [[Int]]`.

- [ ] **Step 1: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/GeometryTests.swift`:
```swift
import Testing
@testable import GlinskiEngine

struct GeometryTests {
    private func names(_ indices: [Int]) -> [String] { indices.map { Cell.all[$0].notation } }
    private func pairs(_ vs: [Vector]) -> Set<[Int]> { Set(vs.map { [$0.dq, $0.dr] }) }

    @Test func diagonalsAreSumsOfAdjacentOrthogonals() {
        #expect(pairs(Geometry.diagonal) == [[1, -2], [2, -1], [1, 1], [-1, 2], [-2, 1], [-1, -1]])
    }

    @Test func knightHasTwelveJumps() {
        #expect(pairs(Geometry.knight) == [
            [1, -3], [2, -3], [3, -2], [3, -1], [2, 1], [1, 2],
            [-1, 3], [-2, 3], [-3, 2], [-3, 1], [-2, -1], [-1, -2],
        ])
    }

    @Test func centreRaysReachTheEdge() {
        let f6 = cell("f6").index
        #expect(Geometry.orthogonalRays[f6].map(\.count) == [5, 5, 5, 5, 5, 5])
        #expect(Geometry.diagonalRays[f6].map(\.count) == [2, 2, 2, 2, 2, 2])
        #expect(names(Geometry.orthogonalRays[f6][0]) == ["f7", "f8", "f9", "f10", "f11"])
        #expect(names(Geometry.diagonalRays[f6][0]) == ["g7", "h8"])
    }

    @Test func knightFromD1() {
        #expect(Set(names(Geometry.knightTargets[cell("d1").index])) == ["b2", "c3", "e4", "f4", "g2", "g1"])
    }

    @Test func knightFromCentreHasTwelveTargets() {
        #expect(Geometry.knightTargets[cell("f6").index].count == 12)
    }

    @Test func kingFromCornerA1() {
        #expect(Set(names(Geometry.kingTargets[cell("a1").index])) == ["a2", "b1", "b2", "b3", "c2"])
    }

    @Test func offsetOffBoardIsNil() {
        #expect(cell("a1").offset(Vector(dq: 0, dr: 1)) == nil)
        #expect(cell("a1").offset(-Vector(dq: 0, dr: -1)) == nil)
    }
}
```

(`knightFromD1` lists every on-board jump, including cells occupied at the start (e4, g1). Occupancy is filtered later, in move generation.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter GeometryTests`
Expected: compile failure, `cannot find 'Geometry' in scope`.

- [ ] **Step 3: Implement**

`GlinskiKit/Sources/GlinskiEngine/Geometry.swift`:
```swift
/// A step in axial coordinates.
struct Vector: Sendable, Equatable {
    let dq: Int
    let dr: Int

    static func + (a: Vector, b: Vector) -> Vector { Vector(dq: a.dq + b.dq, dr: a.dr + b.dr) }
    static func * (v: Vector, k: Int) -> Vector { Vector(dq: v.dq * k, dr: v.dr * k) }
    static prefix func - (v: Vector) -> Vector { v * -1 }
}

extension Cell {
    func offset(_ v: Vector) -> Cell? { Cell(q: q + v.dq, r: r + v.dr) }
}

/// Direction sets and lookup tables, computed once. Tables are indexed by `Cell.index`.
enum Geometry {
    /// Through a cell edge, clockwise from up.
    static let orthogonal: [Vector] = [
        Vector(dq: 0, dr: -1), Vector(dq: 1, dr: -1), Vector(dq: 1, dr: 0),
        Vector(dq: 0, dr: 1), Vector(dq: -1, dr: 1), Vector(dq: -1, dr: 0),
    ]
    /// Through a vertex: the sum of two adjacent orthogonals.
    static let diagonal: [Vector] = (0..<6).map { orthogonal[$0] + orthogonal[($0 + 1) % 6] }
    /// Two orthogonal steps, then one at 60° either side.
    static let knight: [Vector] = (0..<6).flatMap { i in
        [orthogonal[i] * 2 + orthogonal[(i + 1) % 6], orthogonal[i] * 2 + orthogonal[(i + 5) % 6]]
    }

    static let orthogonalRays = rays(orthogonal)
    static let diagonalRays = rays(diagonal)
    static let knightTargets = jumps(knight)
    static let kingTargets = jumps(orthogonal + diagonal)

    private static func rays(_ directions: [Vector]) -> [[[Int]]] {
        Cell.all.map { start in
            directions.map { d in
                var ray: [Int] = []
                var current = start
                while let next = current.offset(d) {
                    ray.append(next.index)
                    current = next
                }
                return ray
            }
        }
    }

    private static func jumps(_ vectors: [Vector]) -> [[Int]] {
        Cell.all.map { start in vectors.compactMap { start.offset($0)?.index } }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path GlinskiKit --filter GeometryTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): hex geometry and precomputed move tables"
```

---

### Task 3: Pieces, board, placement, initial setup

**Files:**
- Create: `GlinskiKit/Sources/GlinskiEngine/Piece.swift`, `GlinskiKit/Sources/GlinskiEngine/Board.swift`, `GlinskiKit/Tests/GlinskiEngineTests/BoardTests.swift`

**Interfaces:**
- Consumes: `Cell` (Task 1).
- Produces:
  - `public enum Side: Sendable, Hashable, Codable { case white, black; var opponent: Side }`
  - `public enum PieceKind: Sendable, Hashable, Codable, CaseIterable { case pawn, knight, bishop, rook, queen, king }` with `var letter: Character` ("P N B R Q K") and `init?(letter: Character)` (case-insensitive)
  - `public struct Piece: Sendable, Hashable, Codable { let kind: PieceKind; let side: Side; init(_ kind:, _ side:) }`
  - `public struct Board: Sendable, Hashable, Codable` with `init()` (empty), `init?(placement: String)`, `var placement: String`, `subscript(cell: Cell) -> Piece?` (get/set), `static let initial`. Internal: `subscript(index: Int) -> Piece?`, `indices: Range<Int>`, `firstIndex(of: Piece) -> Int?`.
  - Placement format: space-separated tokens `<letter><cell>`, uppercase = White, lowercase = Black, e.g. `"Kg1 qe10 Pf5"`. Cells in `placement` output are ordered by `Cell.index`.

- [ ] **Step 1: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/BoardTests.swift`:
```swift
import Foundation
import Testing
@testable import GlinskiEngine

struct BoardTests {
    @Test func initialSetup() {
        let b = Board.initial
        #expect(b[cell("g1")] == Piece(.king, .white))
        #expect(b[cell("e1")] == Piece(.queen, .white))
        #expect(b[cell("f3")] == Piece(.bishop, .white))
        #expect(b[cell("f5")] == Piece(.pawn, .white))
        #expect(b[cell("g10")] == Piece(.king, .black))
        #expect(b[cell("e10")] == Piece(.queen, .black))
        #expect(b[cell("f11")] == Piece(.bishop, .black))
        #expect(b[cell("k7")] == Piece(.pawn, .black))
        #expect(b[cell("f6")] == nil)
    }

    @Test func eachSideHasEighteenPieces() {
        for side in [Side.white, .black] {
            let pieces = Cell.all.compactMap { Board.initial[$0] }.filter { $0.side == side }
            #expect(pieces.count == 18)
            #expect(pieces.filter { $0.kind == .pawn }.count == 9)
            #expect(pieces.filter { $0.kind == .bishop }.count == 3)
        }
    }

    @Test func blackMirrorsWhite() {
        for c in Cell.all {
            guard let p = Board.initial[c], p.side == .white else { continue }
            let mirror = Cell(q: c.q, r: -c.q - c.r)!
            #expect(Board.initial[mirror] == Piece(p.kind, .black))
        }
    }

    @Test func placementRoundTrips() throws {
        let b = try #require(Board(placement: "Kg1 qe10 Pf5"))
        #expect(b[cell("g1")] == Piece(.king, .white))
        #expect(b[cell("e10")] == Piece(.queen, .black))
        #expect(b.placement == "Pf5 Kg1 qe10")
        #expect(Board(placement: Board.initial.placement) == Board.initial)
    }

    @Test func emptyPlacementIsEmptyBoard() {
        #expect(Board(placement: "") == Board())
    }

    @Test(arguments: ["Xg1", "Kj1", "K", "Kg1 Qg1", "Kg12"])
    func invalidPlacementIsRejected(text: String) {
        #expect(Board(placement: text) == nil)
    }

    @Test func pieceLetters() {
        #expect(PieceKind.allCases.map(\.letter) == ["P", "N", "B", "R", "Q", "K"])
        for kind in PieceKind.allCases {
            #expect(PieceKind(letter: kind.letter) == kind)
            #expect(PieceKind(letter: Character(kind.letter.lowercased())) == kind)
        }
        #expect(PieceKind(letter: "X") == nil)
    }

    @Test func opponent() {
        #expect(Side.white.opponent == .black)
        #expect(Side.black.opponent == .white)
    }

    @Test func codableAsPlacement() throws {
        let data = try JSONEncoder().encode(Board.initial)
        #expect(try JSONDecoder().decode(Board.self, from: data) == Board.initial)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Board.self, from: Data("\"Kj1\"".utf8))
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter BoardTests`
Expected: compile failure, `cannot find 'Board' in scope`.

- [ ] **Step 3: Implement**

`GlinskiKit/Sources/GlinskiEngine/Piece.swift`:
```swift
public enum Side: Sendable, Hashable, Codable {
    case white, black

    public var opponent: Side { self == .white ? .black : .white }
}

public enum PieceKind: Sendable, Hashable, Codable, CaseIterable {
    case pawn, knight, bishop, rook, queen, king

    public var letter: Character {
        switch self {
        case .pawn: "P"
        case .knight: "N"
        case .bishop: "B"
        case .rook: "R"
        case .queen: "Q"
        case .king: "K"
        }
    }

    /// Case-insensitive: "n" and "N" are both knights.
    public init?(letter: Character) {
        guard let kind = PieceKind.allCases.first(where: { String($0.letter) == letter.uppercased() }) else { return nil }
        self = kind
    }
}

public struct Piece: Sendable, Hashable, Codable {
    public let kind: PieceKind
    public let side: Side

    public init(_ kind: PieceKind, _ side: Side) {
        self.kind = kind
        self.side = side
    }
}
```

`GlinskiKit/Sources/GlinskiEngine/Board.swift`:
```swift
/// 91 slots indexed by `Cell.index`.
public struct Board: Sendable, Hashable {
    private var slots: [Piece?]

    public init() {
        slots = Array(repeating: nil, count: Cell.all.count)
    }

    /// Space-separated `<letter><cell>` tokens; uppercase is White, lowercase Black. E.g. "Kg1 qe10 Pf5".
    public init?(placement: String) {
        self.init()
        for token in placement.split(separator: " ") {
            guard let letter = token.first,
                  let kind = PieceKind(letter: letter),
                  let cell = Cell(String(token.dropFirst())),
                  self[cell] == nil else { return nil }
            self[cell] = Piece(kind, letter.isUppercase ? .white : .black)
        }
    }

    public var placement: String {
        Cell.all.compactMap { c in
            self[c].map { p in
                let letter = p.side == .white ? String(p.kind.letter) : p.kind.letter.lowercased()
                return letter + c.notation
            }
        }.joined(separator: " ")
    }

    public subscript(cell: Cell) -> Piece? {
        get { slots[cell.index] }
        set { slots[cell.index] = newValue }
    }

    subscript(index: Int) -> Piece? {
        get { slots[index] }
        set { slots[index] = newValue }
    }

    var indices: Range<Int> { slots.indices }

    func firstIndex(of piece: Piece) -> Int? { slots.firstIndex(of: piece) }

    public static let initial = Board(placement: """
        Kg1 Qe1 Rc1 Ri1 Nd1 Nh1 Bf1 Bf2 Bf3 Pb1 Pc2 Pd3 Pe4 Pf5 Pg4 Ph3 Pi2 Pk1 \
        kg10 qe10 rc8 ri8 nd9 nh9 bf9 bf10 bf11 pb7 pc7 pd7 pe7 pf7 pg7 ph7 pi7 pk7
        """)!
}

extension Board: Codable {
    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let board = Board(placement: text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid placement \(text)"))
        }
        self = board
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(placement)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path GlinskiKit --filter BoardTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): pieces, board placement format and initial setup"
```

---

### Task 4: Position, piece moves, attacks and check

**Files:**
- Create: `GlinskiKit/Sources/GlinskiEngine/Move.swift`, `GlinskiKit/Sources/GlinskiEngine/Position.swift`, `GlinskiKit/Sources/GlinskiEngine/MoveGeneration.swift`, `GlinskiKit/Sources/GlinskiEngine/Apply.swift`, `GlinskiKit/Tests/GlinskiEngineTests/MoveGenerationTests.swift`
- Modify: `GlinskiKit/Tests/GlinskiEngineTests/TestSupport.swift`

**Interfaces:**
- Consumes: `Cell`, `Geometry`, `Board`, `Piece` (Tasks 1–3).
- Produces:
  - `public struct Move: Sendable, Hashable, Codable, CustomStringConvertible { from: Cell; to: Cell; promotion: PieceKind?; init(from:to:promotion: = nil) }`, description `"e4-e6"` / `"f10-f11=Q"`.
  - `public struct Position: Sendable, Hashable, Codable` with `board`, `sideToMove`, `enPassantTarget: Cell?`, `halfmoveClock: Int` (all `public internal(set)`), `init(board:sideToMove: = .white, enPassantTarget: = nil, halfmoveClock: = 0)`, `static let initial`.
  - `public func legalMoves() -> [Move]`, `public func legalMoves(from: Cell) -> [Move]`, `public var isInCheck: Bool`.
  - Internal: `applyingUnchecked(_:) -> Position` (full version in Task 6; this task needs it for the legality filter), `isAttacked(_ index: Int, by: Side) -> Bool`, `isKingAttacked(_: Side) -> Bool`.
  - Test helpers: `move("e4-e6")`, `position(_ placement:, _ side: = .white, halfmoveClock: = 0)`, `Position.targets(from:) -> Set<String>`.
  - Pawn moves are a stub returning `[]` in this task. Task 5 fills them in.

- [ ] **Step 1: Extend test support**

Append to `GlinskiKit/Tests/GlinskiEngineTests/TestSupport.swift`:
```swift
/// "e4-e6" or "f10-f11=Q".
func move(_ text: String) -> Move {
    let parts = text.split(whereSeparator: { $0 == "-" || $0 == "=" }).map(String.init)
    return Move(from: cell(parts[0]), to: cell(parts[1]), promotion: parts.count > 2 ? PieceKind(letter: parts[2].first!) : nil)
}

func position(_ placement: String, _ side: Side = .white, halfmoveClock: Int = 0) -> Position {
    guard let board = Board(placement: placement) else { fatalError("bad placement \(placement)") }
    return Position(board: board, sideToMove: side, halfmoveClock: halfmoveClock)
}

extension Position {
    func targets(from notation: String) -> Set<String> {
        Set(legalMoves(from: cell(notation)).map(\.to.notation))
    }
}
```

- [ ] **Step 2: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/MoveGenerationTests.swift`:
```swift
import Testing
@testable import GlinskiEngine

struct MoveGenerationTests {
    // MARK: Piece patterns on an empty board

    @Test(arguments: [("Rf6", 30), ("Bf6", 12), ("Qf6", 42), ("Nf6", 12), ("Kf6", 12)])
    func centreMobility(placement: String, count: Int) {
        #expect(position(placement).legalMoves().count == count)
    }

    @Test func rookStopsAtOwnPieceAndCapturesEnemy() {
        let t = position("Rf6 Pf8 pd6").targets(from: "f6")
        #expect(t.contains("f7"))
        #expect(!t.contains("f8") && !t.contains("f9"))
        #expect(t.contains("e6") && t.contains("d6"))
        #expect(!t.contains("c6"))
    }

    @Test func rookDoesNotMoveDiagonallyAndBishopDoesNotMoveOrthogonally() {
        #expect(!position("Rf6").targets(from: "f6").contains("g7"))
        #expect(!position("Bf6").targets(from: "f6").contains("f7"))
    }

    @Test func knightLeapsAndSkipsOwnPieces() {
        #expect(Position.initial.targets(from: "d1") == ["b2", "c3", "f4", "g2"])
    }

    @Test func onlySideToMoveHasMoves() {
        #expect(Position.initial.legalMoves(from: cell("e10")).isEmpty)
        #expect(Position.initial.legalMoves(from: cell("f6")).isEmpty)
    }

    // MARK: Initial position — hand-verified count

    @Test func initialPositionHas51Moves() {
        let moves = Position.initial.legalMoves()
        #expect(moves.count == 51)
        let byKind = Dictionary(grouping: moves) { Position.initial.board[$0.from]!.kind }.mapValues(\.count)
        #expect(byKind == [.pawn: 17, .knight: 8, .bishop: 12, .rook: 6, .queen: 6, .king: 2])
    }

    // MARK: Check and legality

    @Test(arguments: [
        "Kf6 rf11", "Kf6 bh8", "Kf6 qf11", "Kf6 qh8", "Kf6 ng3", "Kf6 kg5", "Kf7 pe7",
    ])
    func whiteIsInCheck(placement: String) {
        #expect(position(placement).isInCheck)
    }

    @Test(arguments: ["Kf6 Pf8 rf11", "Kf6 bf11", "Kf6 rh8", "Ke6 pe7", "Kf6 pe7"])
    func whiteIsNotInCheck(placement: String) {
        #expect(!position(placement).isInCheck)
    }

    @Test func whitePawnGivesCheckDiagonallyForward() {
        #expect(position("kf6 Pe5", .black).isInCheck)
        #expect(!position("ke6 Pe5", .black).isInCheck)
    }

    @Test func initialPositionIsNotCheck() {
        #expect(!Position.initial.isInCheck)
    }

    @Test func positionWithoutKingIsNeverInCheck() {
        let p = position("Rf6 rf11")
        #expect(!p.isInCheck)
        #expect(!p.legalMoves().isEmpty)
    }

    @Test func kingCannotStepIntoAttack() {
        let t = position("Kf6 rg10").targets(from: "f6")
        #expect(t == ["f7", "e7", "e6", "e5", "f5", "e4", "d5", "h5"])
    }

    @Test func pinnedRookStaysOnTheFile() {
        let moves = position("Kf1 Rf3 rf10").legalMoves(from: cell("f3"))
        #expect(moves.count == 8)
        #expect(moves.allSatisfy { $0.to.file == "f" })
    }

    @Test func checkMustBeBlockedOrEscaped() {
        let p = position("Kf1 Ra3 rf10")
        #expect(p.isInCheck)
        // Both blocks: along rank 3 to f3, and up-right through b4–e7 to f8.
        #expect(Set(p.legalMoves(from: cell("a3"))) == [move("a3-f3"), move("a3-f8")])
    }

    @Test func moveDescription() {
        #expect(move("e4-e6").description == "e4-e6")
        #expect(move("f10-f11=Q").description == "f10-f11=Q")
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter MoveGenerationTests`
Expected: compile failure, `cannot find 'Position' in scope`.

- [ ] **Step 4: Implement**

`GlinskiKit/Sources/GlinskiEngine/Move.swift`:
```swift
public struct Move: Sendable, Hashable, Codable, CustomStringConvertible {
    public let from: Cell
    public let to: Cell
    /// Set exactly when a pawn reaches a promotion cell.
    public let promotion: PieceKind?

    public init(from: Cell, to: Cell, promotion: PieceKind? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }

    public var description: String {
        "\(from)-\(to)" + (promotion.map { "=\($0.letter)" } ?? "")
    }
}
```

`GlinskiKit/Sources/GlinskiEngine/Position.swift`:
```swift
/// Everything needed to generate moves: the board and the per-move state around it.
public struct Position: Sendable, Hashable, Codable {
    public internal(set) var board: Board
    public internal(set) var sideToMove: Side
    /// The cell a pawn skipped with a double step on the previous ply, if an enemy pawn could capture there.
    public internal(set) var enPassantTarget: Cell?
    /// Plies since the last capture or pawn move (50-move rule).
    public internal(set) var halfmoveClock: Int

    public init(board: Board, sideToMove: Side = .white, enPassantTarget: Cell? = nil, halfmoveClock: Int = 0) {
        self.board = board
        self.sideToMove = sideToMove
        self.enPassantTarget = enPassantTarget
        self.halfmoveClock = halfmoveClock
    }

    public static let initial = Position(board: .initial)

    static func forward(_ side: Side) -> Vector {
        side == .white ? Vector(dq: 0, dr: -1) : Vector(dq: 0, dr: 1)
    }

    /// Orthogonally forward at 60° to the vertical.
    static func captureVectors(_ side: Side) -> [Vector] {
        side == .white
            ? [Vector(dq: -1, dr: 0), Vector(dq: 1, dr: -1)]
            : [Vector(dq: -1, dr: 1), Vector(dq: 1, dr: 0)]
    }

    private static let whitePawnStarts = Set(Cell.all.filter { Board.initial[$0] == Piece(.pawn, .white) })
    private static let blackPawnStarts = Set(Cell.all.filter { Board.initial[$0] == Piece(.pawn, .black) })

    /// Any starting cell of a pawn of this side, not just the pawn's own.
    static func pawnStarts(_ side: Side) -> Set<Cell> {
        side == .white ? whitePawnStarts : blackPawnStarts
    }

    /// The last cell of a file in this side's forward direction.
    static func isPromotionCell(_ cell: Cell, for side: Side) -> Bool {
        cell.offset(forward(side)) == nil
    }
}
```

`GlinskiKit/Sources/GlinskiEngine/MoveGeneration.swift`:
```swift
extension Position {
    public func legalMoves() -> [Move] {
        board.indices.flatMap { pseudoLegalMoves(from: $0) }.filter(isLegal)
    }

    public func legalMoves(from cell: Cell) -> [Move] {
        pseudoLegalMoves(from: cell.index).filter(isLegal)
    }

    public var isInCheck: Bool { isKingAttacked(sideToMove) }

    // ponytail: make-move-then-test legality; pin-aware generation if v2 profiling needs it.
    private func isLegal(_ move: Move) -> Bool {
        !applyingUnchecked(move).isKingAttacked(sideToMove)
    }

    func pseudoLegalMoves(from i: Int) -> [Move] {
        guard let piece = board[i], piece.side == sideToMove else { return [] }
        let targets: [Int]
        switch piece.kind {
        case .pawn: return pawnMoves(from: i)
        case .knight: targets = Geometry.knightTargets[i].filter { board[$0]?.side != sideToMove }
        case .king: targets = Geometry.kingTargets[i].filter { board[$0]?.side != sideToMove }
        case .bishop: targets = slides(from: i, along: Geometry.diagonalRays)
        case .rook: targets = slides(from: i, along: Geometry.orthogonalRays)
        case .queen: targets = slides(from: i, along: Geometry.orthogonalRays) + slides(from: i, along: Geometry.diagonalRays)
        }
        return targets.map { Move(from: Cell.all[i], to: Cell.all[$0]) }
    }

    private func slides(from i: Int, along rays: [[[Int]]]) -> [Int] {
        var targets: [Int] = []
        for ray in rays[i] {
            for t in ray {
                if let p = board[t] {
                    if p.side != sideToMove { targets.append(t) }
                    break
                }
                targets.append(t)
            }
        }
        return targets
    }

    func pawnMoves(from i: Int) -> [Move] {
        []   // Task 5
    }

    func isKingAttacked(_ side: Side) -> Bool {
        guard let king = board.firstIndex(of: Piece(.king, side)) else { return false }
        return isAttacked(king, by: side.opponent)
    }

    func isAttacked(_ i: Int, by attacker: Side) -> Bool {
        if Geometry.knightTargets[i].contains(where: { board[$0] == Piece(.knight, attacker) }) { return true }
        if Geometry.kingTargets[i].contains(where: { board[$0] == Piece(.king, attacker) }) { return true }
        if slider(attacks: i, along: Geometry.orthogonalRays, kind: .rook, attacker) { return true }
        if slider(attacks: i, along: Geometry.diagonalRays, kind: .bishop, attacker) { return true }
        let cell = Cell.all[i]
        return Position.captureVectors(attacker).contains { v in
            cell.offset(-v).map { board[$0] == Piece(.pawn, attacker) } ?? false
        }
    }

    /// Is the first piece along any ray an attacker's `kind` or queen?
    private func slider(attacks i: Int, along rays: [[[Int]]], kind: PieceKind, _ attacker: Side) -> Bool {
        for ray in rays[i] {
            for t in ray {
                guard let p = board[t] else { continue }
                if p.side == attacker && (p.kind == kind || p.kind == .queen) { return true }
                break
            }
        }
        return false
    }
}
```

`GlinskiKit/Sources/GlinskiEngine/Apply.swift` (minimal for now; Task 6 extends it):
```swift
extension Position {
    /// Plays `move` without checking legality. Only pass moves produced by move generation.
    func applyingUnchecked(_ move: Move) -> Position {
        var next = self
        next.board[move.to] = board[move.from]
        next.board[move.from] = nil
        next.sideToMove = sideToMove.opponent
        return next
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --package-path GlinskiKit --filter MoveGenerationTests`
Expected: all pass **except** `initialPositionHas51Moves` (pawns missing: 34 instead of 51). That test stays red until Task 5. Everything else must be green.

- [ ] **Step 6: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): piece move generation, attack detection, check and pins"
```

---

### Task 5: Pawns (push, double step, capture, en passant, promotion)

**Files:**
- Modify: `GlinskiKit/Sources/GlinskiEngine/MoveGeneration.swift` (`pawnMoves`), `GlinskiKit/Sources/GlinskiEngine/Apply.swift`
- Create: `GlinskiKit/Tests/GlinskiEngineTests/PawnTests.swift`

**Interfaces:**
- Consumes: `Position.forward`, `captureVectors`, `pawnStarts`, `isPromotionCell` (Task 4).
- Produces: complete `pawnMoves(from:)`, and `applyingUnchecked` handling en passant capture, en passant target, promotion and the halfmove clock. Also `public func applying(_ move: Move) -> Position?`, which returns `nil` when the move is illegal. `GameState` in Task 7 builds on it.

- [ ] **Step 1: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/PawnTests.swift`:
```swift
import Testing
@testable import GlinskiEngine

struct PawnTests {
    @Test(arguments: ["b1", "c2", "d3", "e4", "f5", "g4", "h3", "i2", "k1"])
    func whitePawnDoubleStepsFromAnyWhiteStartingCell(start: String) {
        let t = position("P\(start)").targets(from: start)
        let one = cell(start).offset(Vector(dq: 0, dr: -1))!
        let two = one.offset(Vector(dq: 0, dr: -1))!
        #expect(t == [one.notation, two.notation])
    }

    @Test func pawnOnNonStartingCellSingleSteps() {
        #expect(position("Pe5").targets(from: "e5") == ["e6"])
    }

    @Test func blackPawnMovesDown() {
        #expect(position("pe7", .black).targets(from: "e7") == ["e6", "e5"])
    }

    @Test func blockedPawn() {
        #expect(position("Pe4 pe6").targets(from: "e4") == ["e5"])
        #expect(position("Pe4 pe5").targets(from: "e4").isEmpty)
    }

    @Test func capturesForwardAt60Degrees() {
        #expect(position("Pe4 pd4 pf5").targets(from: "e4") == ["e5", "e6", "d4", "f5"])
        #expect(position("Pe4 Pd4").targets(from: "e4") == ["e5", "e6"])
    }

    @Test func enPassantWhiteDoubleStepBlackCaptures() throws {
        let afterDouble = try #require(position("Pe4 pf6").applying(move("e4-e6")))
        #expect(afterDouble.enPassantTarget == cell("e5"))
        #expect(afterDouble.targets(from: "f6").contains("e5"))
        let afterCapture = try #require(afterDouble.applying(move("f6-e5")))
        #expect(afterCapture.board[cell("e5")] == Piece(.pawn, .black))
        #expect(afterCapture.board[cell("e6")] == nil)
        #expect(afterCapture.board[cell("f6")] == nil)
    }

    @Test func enPassantBlackDoubleStepWhiteCaptures() throws {
        let afterDouble = try #require(position("pe7 Pf6", .black).applying(move("e7-e5")))
        #expect(afterDouble.enPassantTarget == cell("e6"))
        let afterCapture = try #require(afterDouble.applying(move("f6-e6")))
        #expect(afterCapture.board[cell("e6")] == Piece(.pawn, .white))
        #expect(afterCapture.board[cell("e5")] == nil)
    }

    @Test func noEnPassantTargetWithoutACapturer() throws {
        let p = try #require(Position.initial.applying(move("e4-e6")))
        #expect(p.enPassantTarget == nil)
    }

    @Test func enPassantExpiresAfterOnePly() throws {
        var p = try #require(position("Pe4 pf6 Ka1 kl6").applying(move("e4-e6")))
        p = try #require(p.applying(move("l6-l5")))
        p = try #require(p.applying(move("a1-a2")))
        #expect(p.targets(from: "f6") == ["f5"])
    }

    @Test func enPassantThatExposesTheKingIsIllegal() throws {
        let p = try #require(position("Pe4 pf6 kh4 Ra6").applying(move("e4-e6")))
        #expect(p.enPassantTarget == cell("e5"))
        #expect(p.targets(from: "f6") == ["f5"])
    }

    @Test func promotionOffersFourPieces() {
        let moves = position("Pf10").legalMoves()
        #expect(Set(moves) == Set([PieceKind.queen, .rook, .bishop, .knight].map {
            Move(from: cell("f10"), to: cell("f11"), promotion: $0)
        }))
    }

    @Test func promotionOnAnyFileEndIncludingCaptures() {
        // e10 and d9 are file ends; f10 is not.
        let moves = position("Pe9 nd9 nf10").legalMoves(from: cell("e9"))
        #expect(moves.count == 9)
        #expect(moves.filter { $0.to == cell("f10") } == [move("e9-f10")])
    }

    @Test func blackPromotesOnRankOne() {
        #expect(position("pf2", .black).legalMoves().count == 4)
    }

    @Test func promotionPlacesChosenPiece() throws {
        let p = try #require(position("Pf10").applying(move("f10-f11=N")))
        #expect(p.board[cell("f11")] == Piece(.knight, .white))
        #expect(p.board[cell("f10")] == nil)
    }

    @Test(arguments: ["f10-f11", "f10-f11=K", "f10-f11=P"])
    func promotionWithoutValidPieceIsIllegal(text: String) {
        #expect(position("Pf10").applying(move(text)) == nil)
    }

    @Test func promotionPieceOnNonPromotionMoveIsIllegal() {
        #expect(Position.initial.applying(move("e4-e5=Q")) == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter PawnTests`
Expected: compile failure, `value of type 'Position' has no member 'applying'`.

- [ ] **Step 3: Implement pawn generation**

In `MoveGeneration.swift`, replace the `pawnMoves` stub:
```swift
    func pawnMoves(from i: Int) -> [Move] {
        let from = Cell.all[i]
        let forward = Position.forward(sideToMove)
        var targets: [Cell] = []
        if let one = from.offset(forward), board[one] == nil {
            targets.append(one)
            if Position.pawnStarts(sideToMove).contains(from), let two = one.offset(forward), board[two] == nil {
                targets.append(two)
            }
        }
        for v in Position.captureVectors(sideToMove) {
            guard let t = from.offset(v) else { continue }
            if let p = board[t] {
                if p.side != sideToMove { targets.append(t) }
            } else if t == enPassantTarget {
                targets.append(t)
            }
        }
        return targets.flatMap { to -> [Move] in
            guard Position.isPromotionCell(to, for: sideToMove) else { return [Move(from: from, to: to)] }
            return [PieceKind.queen, .rook, .bishop, .knight].map { Move(from: from, to: to, promotion: $0) }
        }
    }
```

- [ ] **Step 4: Implement full `applyingUnchecked` and `applying`**

Replace `Apply.swift`:
```swift
extension Position {
    /// Plays `move` if it is legal; `nil` otherwise.
    public func applying(_ move: Move) -> Position? {
        legalMoves(from: move.from).contains(move) ? applyingUnchecked(move) : nil
    }

    /// Plays `move` without checking legality. Only pass moves produced by move generation.
    func applyingUnchecked(_ move: Move) -> Position {
        let piece = board[move.from]!
        let isPawn = piece.kind == .pawn
        let isCapture = board[move.to] != nil
        var next = self
        next.board[move.from] = nil
        if isPawn, move.to == enPassantTarget {
            // The victim sits one step past the skipped cell, in its own forward direction.
            next.board[move.to.offset(Position.forward(sideToMove.opponent))!] = nil
        }
        next.board[move.to] = move.promotion.map { Piece($0, piece.side) } ?? piece
        next.enPassantTarget = nil
        if isPawn, let skipped = move.from.offset(Position.forward(sideToMove)),
           skipped.offset(Position.forward(sideToMove)) == move.to {
            // ponytail: pseudo-legal capturer check; FIDE-exact would also require the capture be legal.
            let enemy = sideToMove.opponent
            let canCapture = Position.captureVectors(enemy).contains { v in
                skipped.offset(-v).map { next.board[$0] == Piece(.pawn, enemy) } ?? false
            }
            if canCapture { next.enPassantTarget = skipped }
        }
        next.halfmoveClock = isPawn || isCapture ? 0 : halfmoveClock + 1
        next.sideToMove = sideToMove.opponent
        return next
    }
}
```

- [ ] **Step 5: Run the whole suite**

Run: `swift test --package-path GlinskiKit`
Expected: all pass, **including** `initialPositionHas51Moves` from Task 4.

- [ ] **Step 6: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): pawn pushes, double steps, captures, en passant and promotion"
```

---

### Task 6: Applying moves, halfmove clock, perft

**Files:**
- Modify: `GlinskiKit/Sources/GlinskiEngine/Apply.swift`
- Create: `GlinskiKit/Tests/GlinskiEngineTests/ApplyTests.swift`

**Interfaces:**
- Consumes: `applying`, `applyingUnchecked`, `legalMoves` (Tasks 4–5).
- Produces: internal `func perft(_ depth: Int) -> Int`.

- [ ] **Step 1: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/ApplyTests.swift`:
```swift
import Testing
@testable import GlinskiEngine

struct ApplyTests {
    @Test func applyingMovesThePieceAndFlipsSide() throws {
        let p = try #require(Position.initial.applying(move("d1-f4")))
        #expect(p.board[cell("f4")] == Piece(.knight, .white))
        #expect(p.board[cell("d1")] == nil)
        #expect(p.sideToMove == .black)
    }

    @Test(arguments: ["f6-f7", "e10-e9", "e4-e7", "g1-g3"])
    func illegalMovesAreRejected(text: String) {
        #expect(Position.initial.applying(move(text)) == nil)
    }

    @Test func captureRemovesPieceAndResetsClock() throws {
        let p = try #require(position("Rf6 pf9", halfmoveClock: 7).applying(move("f6-f9")))
        #expect(p.board[cell("f9")] == Piece(.rook, .white))
        #expect(p.halfmoveClock == 0)
    }

    @Test func pawnMoveResetsClockAndQuietMoveIncrements() throws {
        #expect(try #require(position("Pe5", halfmoveClock: 7).applying(move("e5-e6"))).halfmoveClock == 0)
        #expect(try #require(position("Rf6", halfmoveClock: 7).applying(move("f6-f7"))).halfmoveClock == 8)
    }

    @Test func perftDepthZeroAndOne() {
        #expect(Position.initial.perft(0) == 1)
        #expect(Position.initial.perft(1) == 51)
    }

    @Test func perftDeeper() {
        #expect(Position.initial.perft(2) == PERFT_2)
        #expect(Position.initial.perft(3) == PERFT_3)
    }
}
```

`PERFT_2` and `PERFT_3` are filled in during Step 4. They are the only values in this plan that aren't known up front.

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter ApplyTests`
Expected: compile failure, `value of type 'Position' has no member 'perft'`.

- [ ] **Step 3: Implement perft**

Append to `Apply.swift`:
```swift
extension Position {
    /// Number of leaf positions `depth` plies deep. Validates move generation.
    func perft(_ depth: Int) -> Int {
        guard depth > 0 else { return 1 }
        let moves = legalMoves()
        guard depth > 1 else { return moves.count }
        return moves.reduce(0) { $0 + applyingUnchecked($1).perft(depth - 1) }
    }
}
```

- [ ] **Step 4: Pin perft(2) and perft(3)**

1. Temporarily print the values: `swift test --package-path GlinskiKit --filter perftDeeper` after changing the test to `print(Position.initial.perft(2), Position.initial.perft(3))`.
2. Search the web for published Gliński perft values (for example "Gliński hexagonal chess perft" on talkchess.com, the Chess Programming Wiki, or open-source hex-chess engines).
3. If a published value matches, replace `PERFT_2` / `PERFT_3` with the numbers and add a `// source: <url>` comment above the test.
4. If a published value **differs**, stop. There's a move-generation bug. Use `superpowers:systematic-debugging`: split perft by first move (`legalMoves().map { ($0, applyingUnchecked($0).perft(depth-1)) }`) against the reference's divide output.
5. If no reference can be found, replace the placeholders with the computed values and add `// regression lock: no published reference found (searched <date>); 51 at depth 1 is hand-verified`.

Expected after replacement: `swift test --package-path GlinskiKit --filter ApplyTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): move application, halfmove clock and perft"
```

---

### Task 7: `GameState` — history, results, resign, draw, undo, persistence

**Files:**
- Create: `GlinskiKit/Sources/GlinskiEngine/GameState.swift`, `GlinskiKit/Tests/GlinskiEngineTests/GameStateTests.swift`

**Interfaces:**
- Consumes: `Position.applying`, `legalMoves`, `isInCheck`, `halfmoveClock` (Tasks 4–6).
- Produces (the API `GlinskiFeature` will use):
  ```swift
  public enum DrawReason: Sendable, Hashable, Codable { case agreement, repetition, fiftyMove }
  public enum GameResult: Sendable, Hashable, Codable {
      case checkmate(winner: Side), stalemate(winner: Side), resignation(winner: Side), draw(DrawReason)
  }
  public enum GameError: Error, Equatable { case illegalMove(Move), gameOver }
  public struct GameState: Sendable, Hashable, Codable {
      public let start: Position
      public private(set) var moves: [Move]
      public private(set) var position: Position
      public private(set) var result: GameResult?
      public init(start: Position = .initial)
      public var legalMoves: [Move]                       // empty once the game is over
      public func legalMoves(from: Cell) -> [Move]        // empty once the game is over
      public mutating func play(_ move: Move) throws(GameError)
      public mutating func resign(_ side: Side) throws(GameError)
      public mutating func agreeDraw() throws(GameError)
      public func undoingLastMove() -> GameState?         // nil when no moves; clears any result
  }
  ```
- Repetition uses a `Hashable` key (board, side to move, en passant target) counted in a dictionary. This intentionally departs from the Zobrist hashing in DESIGN.md: it's exact, has no collision risk, and needs less code. Zobrist hashing moves to v2 with the transposition table.

- [ ] **Step 1: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/GameStateTests.swift`:
```swift
import Foundation
import Testing
@testable import GlinskiEngine

struct GameStateTests {
    private func game(_ placement: String, _ side: Side = .white, halfmoveClock: Int = 0) -> GameState {
        GameState(start: position(placement, side, halfmoveClock: halfmoveClock))
    }

    @Test func newGame() {
        let g = GameState()
        #expect(g.position == .initial)
        #expect(g.moves.isEmpty)
        #expect(g.result == nil)
        #expect(g.legalMoves.count == 51)
        #expect(g.legalMoves(from: cell("e4")).count == 2)
    }

    @Test func playRecordsMove() throws {
        var g = GameState()
        try g.play(move("e4-e6"))
        #expect(g.moves == [move("e4-e6")])
        #expect(g.position.sideToMove == .black)
    }

    @Test func illegalMoveThrows() {
        var g = GameState()
        #expect(throws: GameError.illegalMove(move("e4-e7"))) { try g.play(move("e4-e7")) }
        #expect(g.moves.isEmpty)
    }

    @Test func checkmate() throws {
        var g = game("Ki5 Qk4 kl6")
        try g.play(move("k4-k6"))
        #expect(g.result == .checkmate(winner: .white))
        #expect(g.legalMoves.isEmpty)
        #expect(g.legalMoves(from: cell("l6")).isEmpty)
    }

    @Test func stalemateScoresForTheStalematingSide() throws {
        var g = game("Ki5 kl6")
        try g.play(move("i5-i6"))
        #expect(g.result == .stalemate(winner: .white))
    }

    @Test func startingInCheckmateIsAlreadyOver() {
        #expect(game("Ki5 Qk6 kl6", .black).result == .checkmate(winner: .white))
    }

    @Test func fiftyMoveRule() throws {
        var g = game("Ka1 kl6", halfmoveClock: 98)
        try g.play(move("a1-a2"))
        #expect(g.result == nil)
        try g.play(move("l6-l5"))
        #expect(g.result == .draw(.fiftyMove))
    }

    @Test func checkmateBeatsFiftyMoveRule() throws {
        var g = game("Ki5 Qk4 kl6", halfmoveClock: 99)
        try g.play(move("k4-k6"))
        #expect(g.result == .checkmate(winner: .white))
    }

    @Test func threefoldRepetition() throws {
        var g = game("Ka1 kl6")
        let cycle = ["a1-a2", "l6-l5", "a2-a1", "l5-l6"]
        for text in cycle + cycle.dropLast() { try g.play(move(text)) }
        #expect(g.result == nil)
        try g.play(move(cycle.last!))
        #expect(g.result == .draw(.repetition))
    }

    @Test func resignation() throws {
        var g = GameState()
        try g.resign(.white)
        #expect(g.result == .resignation(winner: .black))
        #expect(g.legalMoves.isEmpty)
    }

    @Test func drawByAgreement() throws {
        var g = GameState()
        try g.agreeDraw()
        #expect(g.result == .draw(.agreement))
    }

    @Test func actionsAfterGameOverThrow() throws {
        var g = GameState()
        try g.resign(.black)
        #expect(throws: GameError.gameOver) { try g.play(move("e4-e6")) }
        #expect(throws: GameError.gameOver) { try g.resign(.white) }
        #expect(throws: GameError.gameOver) { try g.agreeDraw() }
    }

    @Test func undo() throws {
        var g = GameState()
        #expect(g.undoingLastMove() == nil)
        try g.play(move("e4-e6"))
        let afterOne = g
        try g.play(move("f7-f6"))
        #expect(g.undoingLastMove() == afterOne)
    }

    @Test func undoClearsCheckmate() throws {
        var g = game("Ki5 Qk4 kl6")
        try g.play(move("k4-k6"))
        let undone = try #require(g.undoingLastMove())
        #expect(undone.result == nil)
        #expect(undone.position == position("Ki5 Qk4 kl6"))
    }

    @Test func codableRoundTrip() throws {
        var g = GameState()
        try g.play(move("e4-e6"))
        try g.play(move("f7-f6"))
        try g.resign(.white)
        let data = try JSONEncoder().encode(g)
        #expect(try JSONDecoder().decode(GameState.self, from: data) == g)
    }

    @Test func codableRoundTripAgreedDraw() throws {
        var g = GameState()
        try g.agreeDraw()
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g)) == g)
    }

    @Test func decodingIllegalMovesThrows() throws {
        var json = try jsonObject(GameState())
        json["moves"] = [["from": "e4", "to": "e7"]]
        #expect(throws: GameError.illegalMove(move("e4-e7"))) {
            try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        }
    }

    @Test func decodingIgnoresUntrustedStoredResult() throws {
        var json = try jsonObject(GameState())
        json["result"] = ["checkmate": ["winner": "white"]]
        let g = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(g.result == nil)
    }

    private func jsonObject(_ g: GameState) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(g)) as? [String: Any])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter GameStateTests`
Expected: compile failure, `cannot find 'GameState' in scope`.

- [ ] **Step 3: Implement**

`GlinskiKit/Sources/GlinskiEngine/GameState.swift`:
```swift
public enum DrawReason: Sendable, Hashable, Codable {
    case agreement, repetition, fiftyMove
}

public enum GameResult: Sendable, Hashable, Codable {
    case checkmate(winner: Side)
    /// Not a draw in Gliński's chess: the stalemating side scores ¾, the stalemated side ¼.
    case stalemate(winner: Side)
    case resignation(winner: Side)
    case draw(DrawReason)
}

public enum GameError: Error, Equatable {
    case illegalMove(Move)
    case gameOver
}

/// Positions that count as "the same" for threefold repetition.
struct RepetitionKey: Hashable, Sendable {
    let board: Board
    let sideToMove: Side
    let enPassantTarget: Cell?

    init(_ p: Position) {
        board = p.board
        sideToMove = p.sideToMove
        enPassantTarget = p.enPassantTarget
    }
}

/// A game from a starting position: its moves, the current position and the result.
public struct GameState: Sendable, Hashable {
    public let start: Position
    public private(set) var moves: [Move] = []
    public private(set) var position: Position
    public private(set) var result: GameResult?
    private var seen: [RepetitionKey: Int]

    public init(start: Position = .initial) {
        self.start = start
        position = start
        seen = [RepetitionKey(start): 1]
        result = outcome()
    }

    public var legalMoves: [Move] { result == nil ? position.legalMoves() : [] }

    public func legalMoves(from cell: Cell) -> [Move] {
        result == nil ? position.legalMoves(from: cell) : []
    }

    public mutating func play(_ move: Move) throws(GameError) {
        guard result == nil else { throw .gameOver }
        guard let next = position.applying(move) else { throw .illegalMove(move) }
        position = next
        moves.append(move)
        seen[RepetitionKey(next), default: 0] += 1
        result = outcome()
    }

    public mutating func resign(_ side: Side) throws(GameError) {
        guard result == nil else { throw .gameOver }
        result = .resignation(winner: side.opponent)
    }

    public mutating func agreeDraw() throws(GameError) {
        guard result == nil else { throw .gameOver }
        result = .draw(.agreement)
    }

    /// The game with its last move taken back, replayed from the start; any result is cleared.
    public func undoingLastMove() -> GameState? {
        guard !moves.isEmpty else { return nil }
        var game = GameState(start: start)
        for move in moves.dropLast() { try! game.play(move) }   // already played once, so legal
        return game
    }

    /// Checkmate and stalemate take precedence over the 50-move and repetition draws.
    private func outcome() -> GameResult? {
        let mover = position.sideToMove.opponent
        if position.legalMoves().isEmpty {
            return position.isInCheck ? .checkmate(winner: mover) : .stalemate(winner: mover)
        }
        if position.halfmoveClock >= 100 { return .draw(.fiftyMove) }
        if seen[RepetitionKey(position)]! >= 3 { return .draw(.repetition) }
        // ponytail: no insufficient-material rule; hex dead-material table unresearched, 50-move rule ends dead games.
        return nil
    }
}

extension GameState: Codable {
    private enum CodingKeys: String, CodingKey { case start, moves, result }

    /// Replays the stored moves, so a tampered move list throws instead of producing an impossible game.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(start: try container.decode(Position.self, forKey: .start))
        for move in try container.decode([Move].self, forKey: .moves) { try play(move) }
        // Only results that can't be derived from the moves are trusted from storage.
        switch try container.decodeIfPresent(GameResult.self, forKey: .result) {
        case let stored? where result == nil && (stored == .draw(.agreement) || stored.isResignation):
            result = stored
        default:
            break
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encode(moves, forKey: .moves)
        try container.encodeIfPresent(result, forKey: .result)
    }
}

private extension GameResult {
    var isResignation: Bool {
        if case .resignation = self { true } else { false }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path GlinskiKit --filter GameStateTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): GameState with results, undo, resign, draws and validated persistence"
```

---

### Task 8: Move notation, then full verification

**Files:**
- Create: `GlinskiKit/Sources/GlinskiEngine/Notation.swift`, `GlinskiKit/Tests/GlinskiEngineTests/NotationTests.swift`

**Interfaces:**
- Consumes: `Position.applyingUnchecked`, `isInCheck`, `legalMoves`, `GameState.start/moves` (Tasks 4–7).
- Produces: `public func Position.notation(for move: Move) -> String` (long algebraic: piece letter except pawns, from, `-` or `x`, to, `=Q` promotion, `+` check, `#` mate) and `public var GameState.notation: [String]` (one entry per played move, for the move list).

- [ ] **Step 1: Write the failing tests**

`GlinskiKit/Tests/GlinskiEngineTests/NotationTests.swift`:
```swift
import Testing
@testable import GlinskiEngine

struct NotationTests {
    @Test(arguments: [
        ("Kg1 kg10", "g1-g2", "Kg1-g2"),                 // piece letter, quiet
        ("Pe4", "e4-e6", "e4-e6"),                        // pawn has no letter
        ("Pe4 pd4", "e4-d4", "e4xd4"),                    // capture
        ("Pf10", "f10-f11=Q", "f10-f11=Q"),               // promotion
        ("Ka1 Re3 kf10", "e3-f3", "Re3-f3+"),             // check
        ("Ki5 Qk4 kl6", "k4-k6", "Qk4-k6#"),              // mate
    ])
    func longAlgebraic(placement: String, text: String, expected: String) {
        #expect(position(placement).notation(for: move(text)) == expected)
    }

    @Test func enPassantIsACapture() throws {
        let p = try #require(position("Pe4 pf6").applying(move("e4-e6")))
        #expect(p.notation(for: move("f6-e5")) == "f6xe5")
    }

    @Test func gameNotationListsPlayedMoves() throws {
        var g = GameState()
        #expect(g.notation.isEmpty)
        try g.play(move("d1-f4"))
        try g.play(move("e7-e6"))
        #expect(g.notation == ["Nd1-f4", "e7-e6"])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path GlinskiKit --filter NotationTests`
Expected: compile failure, `value of type 'Position' has no member 'notation'`.

- [ ] **Step 3: Implement**

`GlinskiKit/Sources/GlinskiEngine/Notation.swift`:
```swift
extension Position {
    /// Long algebraic notation, e.g. "Nd1-f4", "e4xd4", "f10-f11=Q", "Re3-f3+", "Qk4-k6#".
    /// Long form needs no disambiguation. Pass a legal move, before it is played.
    public func notation(for move: Move) -> String {
        let piece = board[move.from]!
        let isCapture = board[move.to] != nil || (piece.kind == .pawn && move.to == enPassantTarget)
        var text = piece.kind == .pawn ? "" : String(piece.kind.letter)
        text += move.from.notation + (isCapture ? "x" : "-") + move.to.notation
        if let promotion = move.promotion { text += "=\(promotion.letter)" }
        let next = applyingUnchecked(move)
        if next.isInCheck { text += next.legalMoves().isEmpty ? "#" : "+" }
        return text
    }
}

extension GameState {
    /// One notation string per played move, for the move list.
    public var notation: [String] {
        var current = start
        return moves.map { move in
            defer { current = current.applyingUnchecked(move) }
            return current.notation(for: move)
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path GlinskiKit --filter NotationTests`
Expected: PASS.

- [ ] **Step 5: Full verification**

Run: `scripts/coverage.sh`
Expected: every test passes, and it prints `GlinskiEngine: 100.00%`, exit 0. For any uncovered line it lists, add a **behavioural** test that exercises it (a real rule or input), not a test that only touches the line. Then rerun.

Run: `grep -rn "^import" GlinskiKit/Sources/GlinskiEngine`
Expected: no output (the engine imports nothing).

Optional Linux check: `docker run --rm -v "$PWD":/src -w /src swift:6.2 swift test --package-path GlinskiKit --filter GlinskiEngineTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add GlinskiKit
git commit -m "feat(engine): long algebraic notation for moves and game move list"
```

---

## Later plans (not in scope here)

- **Plan 2 — `GlinskiFeature`:** `GameStore`, `State`/`Intent`, pure reducer: selection, highlighting, promotion flow, undo, resign, draw offers, game over. Coverage floor 100%.
- **Plan 3 — `BoardUI` + app:** ViewInspector, hex layout math, 91 cell views, SVG pieces, adaptive layout, toolbar/menus, settings sheet, overlay, converting the app target to multiplatform (iOS 26 + macOS 26, Swift 6) and linking GlinskiKit, save/restore, XCUITest smoke tests, `app` CI job, BoardUI floor 90%.
