import GlinskiEngine
import Testing
@testable import GlinskiFeature

struct MoveAndPromotionTests {
    @Test func tappingATargetPlaysTheMove() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")))
        #expect(s.game.moves == [Move(from: c("e4"), to: c("e6"))])
        #expect(s.lastMove == Move(from: c("e4"), to: c("e6")))
        #expect(s.moveList == ["e4-e6"])
        #expect(s.sideToMove == .black)
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
        #expect(s.canUndo)
    }

    @Test func doubleTapOnTargetPlaysOnlyOnce() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("e6")))
        #expect(s.game.moves.count == 1)
    }

    @Test func promotingMoveWaitsForAPiece() {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")))
        #expect(s.pendingPromotion == GameFeature.PendingPromotion(from: c("f10"), to: c("f11")))
        #expect(s.game.moves.isEmpty)
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func choosingAPieceCompletesThePromotion() {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .promotionChosen(.knight))
        #expect(s.pendingPromotion == nil)
        #expect(s.game.position.board[c("f11")] == Piece(.knight, .white))
        #expect(s.sideToMove == .black)
    }

    @Test func tapsAreIgnoredWhilePromotionIsPending() {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .cellTapped(c("a1")))
        #expect(s.selection == nil)
        #expect(s.pendingPromotion != nil)
    }

    @Test func illegalPromotionChoiceKeepsItPending() {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .promotionChosen(.king))
        #expect(s.pendingPromotion != nil)
        #expect(s.game.moves.isEmpty)
    }

    @Test func promotionChoiceWithoutPendingIsIgnored() {
        #expect(GameFeature.State().after(.promotionChosen(.queen)) == GameFeature.State())
    }

    @Test func undoCancelsPendingPromotion() {
        let pending = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")))
        #expect(pending.canUndo)
        let s = pending.after(.undo)
        #expect(s.pendingPromotion == nil)
        #expect(s.game.moves.isEmpty)
        #expect(s.game.position.board[c("f10")] == Piece(.pawn, .white))
    }
}
