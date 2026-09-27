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
