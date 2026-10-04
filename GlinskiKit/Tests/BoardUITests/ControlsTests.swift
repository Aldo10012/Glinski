import GlinskiEngine
import GlinskiFeature
import SwiftUI
import Testing
import ViewInspector
@testable import BoardUI

@MainActor
struct ControlsTests {
    final class Box {
        var confirming: ConfirmAction?
        var showingSettings = false
        var flipped = false
    }

    private func controls(_ state: GameFeature.State, _ sent: Sent, _ box: Box) -> ControlsView {
        ControlsView(
            state: state,
            send: sent.send,
            confirming: Binding(get: { box.confirming }, set: { box.confirming = $0 }),
            showingSettings: Binding(get: { box.showingSettings }, set: { box.showingSettings = $0 }),
            flipped: Binding(get: { box.flipped }, set: { box.flipped = $0 })
        )
    }

    private let played = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")))

    @Test func undoIsDisabledUntilThereIsAMove() throws {
        #expect(try controls(.init(), Sent(), Box()).inspect().find(button: "Undo").isDisabled())
        let sent = Sent()
        let button = try controls(played, sent, Box()).inspect().find(button: "Undo")
        #expect(!button.isDisabled())
        try button.tap()
        #expect(sent.intents == [.undo])
    }

    @Test func newGameWithoutMovesStartsImmediately() throws {
        let sent = Sent(), box = Box()
        try controls(.init(), sent, box).inspect().find(button: "New Game").tap()
        #expect(sent.intents == [.newGame])
        #expect(box.confirming == nil)
    }

    @Test func newGameMidGameAsksFirst() throws {
        let sent = Sent(), box = Box()
        try controls(played, sent, box).inspect().find(button: "New Game").tap()
        #expect(sent.intents.isEmpty)
        #expect(box.confirming == .newGame)
    }

    @Test func newGameAfterTheGameEndedStartsImmediately() throws {
        let sent = Sent()
        try controls(played.after(.resign), sent, Box()).inspect().find(button: "New Game").tap()
        #expect(sent.intents == [.newGame])
    }

    @Test func resignAsksFirst() throws {
        let sent = Sent(), box = Box()
        try controls(.init(), sent, box).inspect().find(button: "Resign").tap()
        #expect(sent.intents.isEmpty)
        #expect(box.confirming == .resign)
    }

    @Test func confirmingSendsTheIntent() {
        let sent = Sent()
        ControlsView.confirm(.resign, send: sent.send)
        ControlsView.confirm(.newGame, send: sent.send)
        #expect(sent.intents == [.resign, .newGame])
        #expect(ConfirmAction.resign.title == "Resign this game?")
        #expect(ConfirmAction.newGame.title == "Abandon this game and start a new one?")
        #expect(ConfirmAction.resign.id == .resign)
    }

    @Test func offerDrawSendsIntent() throws {
        let sent = Sent()
        try controls(.init(), sent, Box()).inspect().find(button: "Offer Draw").tap()
        #expect(sent.intents == [.offerDraw])
    }

    @Test func gameActionsAreDisabledWhenTheGameIsOverOrWaiting() throws {
        let over = try controls(played.after(.resign), Sent(), Box()).inspect()
        #expect(try over.find(button: "Offer Draw").isDisabled())
        #expect(try over.find(button: "Resign").isDisabled())
        let offered = try controls(GameFeature.State().after(.offerDraw), Sent(), Box()).inspect()
        #expect(try offered.find(button: "Offer Draw").isDisabled())
    }

    @Test func settingsOpensTheSheet() throws {
        let box = Box()
        try controls(.init(), Sent(), box).inspect().find(button: "Settings").tap()
        #expect(box.showingSettings)
    }

    @Test func flipTogglesTheBoard() throws {
        let box = Box()
        let view = controls(.init(), Sent(), box)
        try view.inspect().find(button: "Flip").tap()
        #expect(box.flipped)
        try view.inspect().find(button: "Flip").tap()
        #expect(!box.flipped)
    }
}
