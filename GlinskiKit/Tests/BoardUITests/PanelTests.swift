import GlinskiEngine
import GlinskiFeature
import SwiftUI
import Testing
import ViewInspector
@testable import BoardUI

@MainActor
struct PanelTests {
    @Test func moveListShowsNumberedRows() throws {
        let view = MoveListView(rows: ["1. e4-e6  f7-f6", "2. Nd1-f4"], horizontal: false)
        #expect(try view.inspect().find(text: "1. e4-e6  f7-f6").string() == "1. e4-e6  f7-f6")
        #expect(try view.inspect().find(text: "2. Nd1-f4").string() == "2. Nd1-f4")
        let strip = MoveListView(rows: ["1. e4-e6"], horizontal: true)
        #expect(try strip.inspect().find(text: "1. e4-e6").string() == "1. e4-e6")
    }

    @Test func emptyMoveListSaysSo() throws {
        #expect(try MoveListView(rows: [], horizontal: false).inspect().find(text: "No moves yet").string() == "No moves yet")
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
