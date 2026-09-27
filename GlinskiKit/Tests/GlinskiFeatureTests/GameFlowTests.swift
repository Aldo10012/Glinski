import GlinskiEngine
import Testing
@testable import GlinskiFeature

struct GameFlowTests {
    // MARK: Undo

    @Test func undoTakesBackTheLastMoveAndClearsSelection() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("f7")), .undo)
        #expect(s.game == GameState())
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
        #expect(!s.canUndo)
    }

    @Test func undoWithNoMovesDoesNothing() {
        #expect(GameFeature.State().after(.undo) == GameFeature.State())
    }

    @Test func undoAfterCheckmateReopensTheGame() {
        let mated = state("Ki5 Qk4 kl6").after(.cellTapped(c("k4")), .cellTapped(c("k6")))
        #expect(mated.game.result == .checkmate(winner: .white))
        #expect(mated.canUndo)
        #expect(mated.after(.undo).game.result == nil)
    }

    @Test func resignationCannotBeUndone() {
        let over = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .resign)
        #expect(!over.canUndo)
        #expect(over.after(.undo) == over)
    }

    @Test func agreedDrawCannotBeUndone() {
        let over = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .offerDraw, .respondToDraw(accept: true))
        #expect(!over.canUndo)
        #expect(over.after(.undo) == over)
    }

    @Test func undoClearsADrawOffer() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .offerDraw, .undo)
        #expect(s.drawOfferedBy == nil)
        #expect(s.game.moves.isEmpty)
    }

    // MARK: New game, resign

    @Test func newGameResetsEverything() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .offerDraw, .newGame)
        #expect(s == GameFeature.State())
    }

    @Test func sideToMoveResigns() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .resign)
        #expect(s.game.result == .resignation(winner: .white))
        #expect(s.after(.resign) == s)
    }

    // MARK: Draw offers

    @Test func acceptedDrawEndsTheGame() {
        let offered = GameFeature.State().after(.offerDraw)
        #expect(offered.drawOfferedBy == .white)
        let s = offered.after(.respondToDraw(accept: true))
        #expect(s.game.result == .draw(.agreement))
        #expect(s.drawOfferedBy == nil)
    }

    @Test func declinedDrawContinuesPlay() {
        let s = GameFeature.State().after(.offerDraw, .respondToDraw(accept: false))
        #expect(s.drawOfferedBy == nil)
        #expect(s.game.result == nil)
        #expect(s.after(.cellTapped(c("e4"))).selection == c("e4"))
    }

    @Test func tapsAreIgnoredWhileADrawIsOffered() {
        #expect(GameFeature.State().after(.offerDraw, .cellTapped(c("e4"))).selection == nil)
    }

    @Test func offerDrawClearsSelection() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .offerDraw)
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func responseWithoutOfferIsIgnored() {
        #expect(GameFeature.State().after(.respondToDraw(accept: true)) == GameFeature.State())
    }

    @Test func noOfferAfterGameOverOrWhilePending() {
        let over = GameFeature.State().after(.resign, .offerDraw)
        #expect(over.drawOfferedBy == nil)
        let twice = GameFeature.State().after(.offerDraw, .cellTapped(c("e4")), .offerDraw)
        #expect(twice.drawOfferedBy == .white)
    }

    // MARK: Check highlight

    @Test func checkedKingIsHighlighted() {
        #expect(state("Kf6 rf11 ka1").checkedKing == c("f6"))
        #expect(GameFeature.State().checkedKing == nil)
    }
}

/// Ending the game must not leave pickers, prompts or highlights behind on the finished board.
struct GameEndCleanupTests {
    private let pendingPromotion = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")))

    @Test func resigningDuringPromotionClearsIt() {
        let s = pendingPromotion.after(.resign)
        #expect(s.game.result == .resignation(winner: .black))
        #expect(s.pendingPromotion == nil)
        #expect(!s.canUndo)
    }

    @Test func noDrawOfferWhilePromotionIsPending() {
        #expect(pendingPromotion.after(.offerDraw).drawOfferedBy == nil)
    }

    @Test func resigningClearsSelection() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .resign)
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func resigningClearsADrawOffer() {
        #expect(GameFeature.State().after(.offerDraw, .resign).drawOfferedBy == nil)
    }
}
