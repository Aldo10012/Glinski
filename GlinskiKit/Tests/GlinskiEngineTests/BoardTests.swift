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
        #expect(b.placement == "qe10 Pf5 Kg1")   // ordered by file, then rank
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
