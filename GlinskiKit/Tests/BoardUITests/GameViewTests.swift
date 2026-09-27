import GlinskiEngine
import GlinskiFeature
import SwiftUI
import Testing
import ViewInspector
@testable import BoardUI

@MainActor
struct GameViewTests {
    @Test func layoutIsWideOnlyWhenThereIsRoomBesideTheBoard() {
        #expect(GameView.isWide(CGSize(width: 1000, height: 700)))
        #expect(!GameView.isWide(CGSize(width: 390, height: 844)))
        #expect(!GameView.isWide(CGSize(width: 700, height: 690)))   // narrow Mac window / split view
    }

    @Test func boardFlipsOnlyWithAutoRotateOnBlacksTurn() {
        let black = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")))
        #expect(GameView.isFlipped(black, autoRotate: true))
        #expect(!GameView.isFlipped(black, autoRotate: false))
        #expect(!GameView.isFlipped(.init(), autoRotate: true))
    }

    @Test func overlayPicksTheOneThatMatters() {
        #expect(GameView.overlay(.init()) == nil)
        #expect(GameView.overlay(GameFeature.State().after(.offerDraw)) == .drawOffer(.white))
        let pending = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")))
        #expect(GameView.overlay(pending) == .promotion(.white))
        #expect(GameView.overlay(GameFeature.State().after(.resign)) == .gameOver("White resigns — Black wins"))
    }

    @Test(arguments: [CGSize(width: 1000, height: 700), CGSize(width: 390, height: 844)])
    func contentShowsBoardStatusAndMoves(size: CGSize) throws {
        let store = GameStore()
        let view = GameContent(store: store, size: size, autoRotate: false)
        #expect(try view.inspect().findAll(CellView.self).count == 91)
        #expect(try view.inspect().find(text: "White to move").string() == "White to move")
        #expect(try view.inspect().find(text: "No moves yet").string() == "No moves yet")
    }

    @Test func tappingTheBoardDrivesTheStore() throws {
        let store = GameStore()
        let view = GameContent(store: store, size: CGSize(width: 390, height: 844), autoRotate: false)
        try view.inspect().find(viewWithAccessibilityIdentifier: "cell.e4").callOnTapGesture()
        #expect(store.state.selection == c("e4"))
    }

    @Test(arguments: [
        GameFeature.State().after(.offerDraw),
        state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11"))),
        GameFeature.State().after(.resign),
    ])
    func overlaysAreRendered(s: GameFeature.State) throws {
        let view = GameContent(store: GameStore(state: s), size: CGSize(width: 390, height: 844), autoRotate: false)
        switch GameView.overlay(s) {
        case .drawOffer: _ = try view.inspect().find(DrawOfferView.self)
        case .promotion: _ = try view.inspect().find(PromotionPicker.self)
        case .gameOver: _ = try view.inspect().find(GameOverView.self)
        case nil: Issue.record("expected an overlay")
        }
    }

    @Test func gameViewBuilds() throws {
        _ = try GameView(store: GameStore()).inspect()
    }
}
