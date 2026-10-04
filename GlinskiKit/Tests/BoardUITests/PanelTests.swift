import GlinskiEngine
import GlinskiFeature
import SwiftUI
import Testing
import ViewInspector
@testable import BoardUI

@MainActor
struct PanelTests {
    private let played = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("f7")), .cellTapped(c("f6")))

    @Test func moveTableHasARowPerPlyAndTappingReviews() throws {
        let sent = Sent()
        let view = MoveTableView(state: played, send: sent.send)
        #expect(try view.inspect().find(text: "2 of 2").string() == "2 of 2")
        let row = try view.inspect().find(viewWithAccessibilityIdentifier: "move.1")
        #expect(try row.accessibilityLabel().string() == "1, white pawn, e4 to e6")
        #expect(try row.find(ViewType.Image.self).actualImage().name() == "wP")
        try row.button().tap()
        #expect(sent.intents == [.review(1)])
        _ = try view.inspect().find(viewWithAccessibilityIdentifier: "move.2")
    }

    @Test func moveTableShowsPromotions() throws {
        let s = state("Pf10 Ka1 kl6").after(.cellTapped(c("f10")), .cellTapped(c("f11")), .promotionChosen(.knight))
        let images = try MoveTableView(state: s, send: { _ in }).inspect().find(viewWithAccessibilityIdentifier: "move.1").findAll(ViewType.Image.self)
        #expect(try images.compactMap { try? $0.actualImage().name() }.contains("wN"))
    }

    @Test func moveChipsTapToReview() throws {
        let sent = Sent()
        let view = MoveChipsView(state: played, send: sent.send)
        try view.inspect().find(viewWithAccessibilityIdentifier: "move.2").button().tap()
        #expect(sent.intents == [.review(2)])
        #expect(try view.inspect().find(text: "e4-e6").string() == "e4-e6")
    }

    @Test func emptyMoveListsSaySo() throws {
        #expect(try MoveTableView(state: .init(), send: { _ in }).inspect().find(text: "No moves yet").string() == "No moves yet")
        #expect(try MoveChipsView(state: .init(), send: { _ in }).inspect().find(text: "No moves yet").string() == "No moves yet")
    }

    @Test func historyNavStepsThroughPositions() throws {
        let sent = Sent()
        let live = try HistoryNavView(state: played, send: sent.send).inspect()
        #expect(try live.find(button: "Next Move").isDisabled())
        #expect(try live.find(button: "Latest Move").isDisabled())
        try live.find(button: "First Move").tap()
        try live.find(button: "Previous Move").tap()
        let reviewing = try HistoryNavView(state: played.after(.review(1)), send: sent.send).inspect()
        try reviewing.find(button: "Next Move").tap()
        try reviewing.find(button: "Latest Move").tap()
        #expect(sent.intents == [.review(0), .review(1), .review(2), .review(nil)])
        let start = try HistoryNavView(state: .init(), send: sent.send).inspect()
        #expect(try start.find(button: "First Move").isDisabled())
        #expect(try start.find(button: "Previous Move").isDisabled())
    }

    @Test func playerCardShowsCapturesAndTurn() throws {
        let s = state("Ra1 ra6 Kc1 kl6").after(.cellTapped(c("a1")), .cellTapped(c("a6")))
        let white = try PlayerCard(side: .white, state: s).inspect()
        #expect(try white.find(viewWithAccessibilityIdentifier: "player.white").accessibilityLabel().string() == "White, captured rook")
        #expect(try white.findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }.contains("bR"))
        #expect(try PlayerCard(side: .black, state: s).inspect().find(text: "Black").string() == "Black")
    }

    @Test(arguments: [false, true])
    func statusShowsTurnAndDetail(centered: Bool) throws {
        let view = StatusView(state: played, centered: centered)
        #expect(try view.inspect().find(text: "White to move").string() == "White to move")
        #expect(try view.inspect().find(text: "Move 2").string() == "Move 2")
        #expect(try StatusView(state: GameFeature.State().after(.resign)).inspect().find(text: "White resigns — Black wins").string() == "White resigns — Black wins")
    }

    @Test(arguments: [PieceKind.queen, .rook, .bishop, .knight])
    func promotionPickerSendsTheChosenPiece(kind: PieceKind) throws {
        let sent = Sent()
        let picker = PromotionPicker(side: .white, send: sent.send)
        try picker.inspect().find(viewWithAccessibilityIdentifier: "promote.\(kind)").button().tap()
        #expect(sent.intents == [.promotionChosen(kind)])
    }

    @Test func promotionPickerShowsTheMoversPieces() throws {
        let picker = PromotionPicker(side: .black, send: { _ in })
        #expect(try picker.inspect().find(viewWithAccessibilityIdentifier: "promote.queen").find(ViewType.Image.self).actualImage().name() == "bQ")
    }

    @Test func drawOfferCanBeAcceptedOrDeclined() throws {
        let sent = Sent()
        let view = DrawOfferView(offeredBy: .white, send: sent.send)
        #expect(try view.inspect().find(text: "White offers a draw").string() == "White offers a draw")
        try view.inspect().find(button: "Accept").tap()
        try view.inspect().find(button: "Decline").tap()
        #expect(sent.intents == [.respondToDraw(accept: true), .respondToDraw(accept: false)])
    }

    @Test func gameOverShowsResultAndOffersANewGame() throws {
        let sent = Sent()
        let view = GameOverView(text: "Stalemate — White ¾, Black ¼", send: sent.send)
        #expect(try view.inspect().find(text: "Stalemate — White ¾, Black ¼").string() == "Stalemate — White ¾, Black ¼")
        try view.inspect().find(button: "New Game").tap()
        #expect(sent.intents == [.newGame])
    }

    @Test func settingsToggleAutoRotateAndCreditPieces() throws {
        var rotate = false
        let view = SettingsView(autoRotate: Binding(get: { rotate }, set: { rotate = $0 }))
        try view.inspect().find(ViewType.Toggle.self).tap()
        #expect(rotate)
        #expect(try view.inspect().find(textWhere: { t, _ in t.contains("Cburnett") }).string().contains("BSD"))
    }

    @Test func settingsShipThePieceLicenceInFull() throws {
        let view = SettingsView(autoRotate: .constant(false))
        let licence = try view.inspect().find(textWhere: { t, _ in t.contains("Redistribution and use") }).string()
        #expect(licence.contains("Copyright (c) Cburnett"))
        #expect(licence.contains("Neither the name of the copyright holder"))
        #expect(licence.contains("THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\""))
    }
}
