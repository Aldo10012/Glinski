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
