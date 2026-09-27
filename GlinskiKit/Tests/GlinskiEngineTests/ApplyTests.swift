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

    // regression lock: no published reference found (searched 2026-09-25); 51 at depth 1 is hand-verified.
    @Test func perftDeeper() {
        #expect(Position.initial.perft(2) == 2_586)
        #expect(Position.initial.perft(3) == 137_858)
    }
}
