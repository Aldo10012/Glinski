import GlinskiEngine
import Testing
@testable import GlinskiFeature

struct ReviewTests {
    /// 1. e4-e6  f7-f6  2. d3-d5
    private let threePlies = GameFeature.State().after(
        .cellTapped(c("e4")), .cellTapped(c("e6")),
        .cellTapped(c("f7")), .cellTapped(c("f6")),
        .cellTapped(c("d3")), .cellTapped(c("d5"))
    )

    // MARK: Reviewing

    @Test func liveByDefault() {
        #expect(threePlies.reviewPly == nil)
        #expect(threePlies.displayedPly == 3)
        #expect(threePlies.displayedPosition == threePlies.game.position)
        #expect(threePlies.displayedLastMove == threePlies.lastMove)
    }

    @Test func reviewShowsAnEarlierPosition() {
        let s = threePlies.after(.review(1))
        #expect(s.reviewPly == 1)
        #expect(s.displayedPly == 1)
        #expect(s.displayedPosition == s.positions[1])
        #expect(s.displayedPosition.board[c("e6")] == Piece(.pawn, .white))
        #expect(s.displayedPosition.board[c("f6")] == nil)
        #expect(s.displayedLastMove == s.game.moves[0])
    }

    @Test func reviewOfTheStartHasNoLastMove() {
        let s = threePlies.after(.review(0))
        #expect(s.displayedPosition == .initial)
        #expect(s.displayedLastMove == nil)
    }

    @Test func reviewClampsAndReturnsToLiveAtTheEnd() {
        #expect(threePlies.after(.review(-4)).reviewPly == 0)
        #expect(threePlies.after(.review(1), .review(3)).reviewPly == nil)
        #expect(threePlies.after(.review(1), .review(99)).reviewPly == nil)
        #expect(threePlies.after(.review(1), .review(nil)).reviewPly == nil)
    }

    @Test func reviewClearsTheSelection() {
        let s = threePlies.after(.cellTapped(c("f6")), .review(1))
        #expect(s.selection == nil)
        #expect(s.targets.isEmpty)
    }

    @Test func boardTapWhileReviewingOnlyReturnsToLive() {
        let reviewing = threePlies.after(.review(1))
        let s = reviewing.after(.cellTapped(c("f6")))
        #expect(s.reviewPly == nil)
        #expect(s.selection == nil)
        #expect(s.game == threePlies.game)
    }

    @Test func otherIntentsReturnToLiveAndApply() {
        let reviewing = threePlies.after(.review(1))
        #expect(reviewing.after(.undo).reviewPly == nil)
        #expect(reviewing.after(.undo).game.moves.count == 2)
        #expect(reviewing.after(.resign).game.result == .resignation(winner: .white))
        #expect(reviewing.after(.offerDraw).drawOfferedBy == .black)
        #expect(reviewing.after(.newGame) == GameFeature.State())
    }

    // MARK: History

    @Test func historyRecordsEveryPly() {
        let h = threePlies.history
        #expect(h.count == 3)
        #expect(h[0] == GameFeature.PlyRecord(number: 1, piece: Piece(.pawn, .white), from: c("e4"), to: c("e6"), promotion: nil))
        #expect(h[1].piece == Piece(.pawn, .black))
        #expect(h[2].number == 3)
    }

    @Test func historyKeepsThePromotion() {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .promotionChosen(.queen))
        #expect(s.history == [GameFeature.PlyRecord(number: 1, piece: Piece(.pawn, .white), from: c("f10"), to: c("f11"), promotion: .queen)])
    }

    // MARK: Captures

    @Test func noCapturesAtTheStart() {
        #expect(GameFeature.State().captured(by: .white).isEmpty)
        #expect(GameFeature.State().captured(by: .black).isEmpty)
    }

    @Test func captureIsCreditedToTheCapturer() {
        let s = state("Ra1 ra6 Kc1 kl6").after(.cellTapped(c("a1")), .cellTapped(c("a6")))
        #expect(s.captured(by: .white) == [.rook])
        #expect(s.captured(by: .black).isEmpty)
        #expect(s.after(.review(0)).captured(by: .white).isEmpty)
    }

    @Test func enPassantCountsAsACapture() {
        let s = state("Pe4 pf6 Ka1 kl6").after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("f6")), .cellTapped(c("e5")))
        #expect(s.captured(by: .black) == [.pawn])
    }

    @Test func promotionIsNotACapture() {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .promotionChosen(.queen))
        #expect(s.captured(by: .white).isEmpty)
        #expect(s.captured(by: .black).isEmpty)
    }

    @Test func checkFollowsTheDisplayedPosition() {
        let s = state("Ki5 Qk4 kl6").after(.cellTapped(c("k4")), .cellTapped(c("k6")))
        #expect(s.checkedKing == c("l6"))
        #expect(s.after(.review(0)).checkedKing == nil)
    }
}
