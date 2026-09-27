import GlinskiEngine
import Testing
@testable import GlinskiFeature

struct SelectionTests {
    @Test func initialState() {
        let s = GameFeature.State()
        #expect(s.game == GameState())
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
        #expect(s.pendingPromotion == nil)
        #expect(s.drawOfferedBy == nil)
        #expect(s.sideToMove == .white)
        #expect(s.moveList.isEmpty)
        #expect(s.lastMove == nil)
        #expect(!s.canUndo)
    }

    @Test func tappingOwnPieceSelectsItAndHighlightsTargets() {
        let s = GameFeature.State().after(.cellTapped(c("e4")))
        #expect(s.selection == c("e4"))
        #expect(s.targets == [c("e5"), c("e6")])
    }

    @Test func tappingOpponentPieceSelectsNothing() {
        let s = GameFeature.State().after(.cellTapped(c("e7")))
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func tappingNonTargetCellDeselects() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("f6")))
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func tappingSelectedCellAgainDeselects() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e4")))
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func tappingAnotherOwnPieceReselects() {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("d1")))
        #expect(s.selection == c("d1"))
        #expect(s.targets == [c("b2"), c("c3"), c("f4"), c("g2")])
    }

    @Test func pieceWithNoMovesSelectsWithNoTargets() {
        // b1 pawn: b2 blocked, a1 is its own king, c2 is empty (no capture).
        let s = state("Ka1 Pb1 pb2 kl6").after(.cellTapped(c("b1")))
        #expect(s.selection == c("b1"))
        #expect(s.targets.isEmpty)
    }

    @Test func tapsAfterGameOverAreIgnored() {
        let s = GameFeature.State().after(.resign, .cellTapped(c("e4")))
        #expect(s.selection == nil)
    }
}
