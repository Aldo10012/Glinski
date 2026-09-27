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
