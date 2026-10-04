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

    @Test func detailShowsMoveNumberSelectionAndReview() {
        #expect(BoardText.detail(GameFeature.State()) == "Move 1")
        #expect(BoardText.detail(GameFeature.State().after(.cellTapped(c("e10")))) == "Move 1")   // not White's piece
        let played = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("f7")), .cellTapped(c("f6")))
        #expect(BoardText.detail(played) == "Move 2")
        #expect(BoardText.detail(played.after(.cellTapped(c("e1")))) == "Move 2 · Queen on e1 selected")
        #expect(BoardText.detail(played.after(.review(1))) == "Reviewing move 1 of 2")
    }

    @Test func counterShowsDisplayedPlyOfAll() {
        let played = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("f7")), .cellTapped(c("f6")))
        #expect(BoardText.counter(played) == "2 of 2")
        #expect(BoardText.counter(played.after(.review(0))) == "0 of 2")
    }

    @Test func plyAndPlayerLabels() {
        let record = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6"))).history[0]
        #expect(BoardText.plyLabel(record) == "1, white pawn, e4 to e6")
        let promotion = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .promotionChosen(.queen)).history[0]
        #expect(BoardText.plyLabel(promotion) == "1, white pawn, f10 to f11, promotes to queen")
        #expect(BoardText.playerLabel(.white, captured: []) == "White")
        #expect(BoardText.playerLabel(.black, captured: [.pawn, .knight]) == "Black, captured pawn, knight")
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
