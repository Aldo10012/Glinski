import Foundation
import Testing
@testable import GlinskiEngine

/// Saved positions are untrusted: impossible ones must be rejected, never crash the engine.
struct PositionCodingTests {
    private func decode(_ board: String, side: String = "white", ep: String? = nil, clock: String = "0") throws -> Position {
        let epField = ep.map { #","enPassantTarget":"\#($0)""# } ?? ""
        let json = #"{"board":"\#(board)","sideToMove":"\#(side)"\#(epField),"halfmoveClock":\#(clock)}"#
        return try JSONDecoder().decode(Position.self, from: Data(json.utf8))
    }

    @Test func validPositionRoundTrips() throws {
        let p = try #require(position("Pe4 pf6 Ka1 kl6").applying(move("e4-e6")))
        #expect(p.enPassantTarget != nil)
        #expect(try JSONDecoder().decode(Position.self, from: JSONEncoder().encode(p)) == p)
    }

    @Test(arguments: [
        ("Ka1 kl6 Pf1", "e1"),     // no cell beyond the target: used to crash
        ("Pe4 Rd3 Ka1 kl6", "d4"), // no double-stepped pawn: would delete White's own rook
        ("Ka1 kl6 Pe6 pe5", "e5"), // target occupied
        ("Ka1 kl6 Pe7", "e6"),     // pawn beyond, but it could not have double-stepped from e5
    ])
    func impossibleEnPassantTargetIsRejected(board: String, ep: String) {
        #expect(throws: DecodingError.self) { try decode(board, side: "black", ep: ep) }
    }

    @Test(arguments: ["9223372036854775807", "-1", "101"])
    func outOfRangeHalfmoveClockIsRejected(clock: String) {
        #expect(throws: DecodingError.self) { try decode("Ka1 kl6", clock: clock) }
    }

    @Test(arguments: ["Ka1 Kf6 kl6", "kl6", "Ka1", "Ka1 kl6 kf9"])
    func eachSideNeedsExactlyOneKing(board: String) {
        #expect(throws: DecodingError.self) { try decode(board) }
    }

    @Test func sideNotToMoveMustNotBeInCheck() {
        #expect(throws: DecodingError.self) { try decode("Ka1 kf9 Rf2") }
    }

    @Test func bogusEnPassantTargetFromPublicInitDoesNotCrash() {
        let p = Position(board: Board(placement: "Ka1 kl6 Pf1")!, enPassantTarget: cell("e1"))
        #expect(p.legalMoves().count > 0)
    }
}
