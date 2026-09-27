import GlinskiEngine
import GlinskiFeature
import Testing
@testable import BoardUI

struct BoardTextTests {
    @Test func turnAndCheck() {
        #expect(BoardText.status(GameFeature.State()) == "White to move")
        #expect(BoardText.status(GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")))) == "Black to move")
        #expect(BoardText.status(state("kf6 Rf11 Ka1", .black)) == "Black to move — check")
    }

    @Test func checkmateAndStalemate() {
        #expect(BoardText.status(state("Ki5 Qk6 kl6", .black)) == "Checkmate — White wins")
        #expect(BoardText.status(state("Ki6 kl6", .black)) == "Stalemate — White ¾, Black ¼")
        #expect(BoardText.status(state("ki6 Kl6")) == "Stalemate — Black ¾, White ¼")
    }

    @Test func resignationAndDraws() {
        #expect(BoardText.status(GameFeature.State().after(.resign)) == "White resigns — Black wins")
        #expect(BoardText.status(GameFeature.State().after(.offerDraw, .respondToDraw(accept: true))) == "Draw by agreement")
        #expect(BoardText.result(.draw(.repetition)) == "Draw by threefold repetition")
        #expect(BoardText.result(.draw(.fiftyMove)) == "Draw by the 50-move rule")
    }

    @Test func moveRowsPairWhiteAndBlack() {
        #expect(BoardText.moveRows([]) == [])
        #expect(BoardText.moveRows(["e4-e6"]) == ["1. e4-e6"])
        #expect(BoardText.moveRows(["e4-e6", "f7-f6", "Nd1-f4"]) == ["1. e4-e6  f7-f6", "2. Nd1-f4"])
    }

    @Test func cellLabels() {
        #expect(BoardText.cellLabel(c("f6"), piece: nil) == "f6, empty")
        #expect(BoardText.cellLabel(c("d1"), piece: Piece(.knight, .white)) == "d1, white knight")
        #expect(BoardText.cellLabel(c("e10"), piece: Piece(.queen, .black)) == "e10, black queen")
    }

    @Test func pieceNames() {
        #expect(PieceKind.allCases.map(BoardText.name) == ["pawn", "knight", "bishop", "rook", "queen", "king"])
    }
}
