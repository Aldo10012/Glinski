import GlinskiEngine
import GlinskiFeature
import SwiftUI
import Testing
import ViewInspector
@testable import BoardUI

/// Collects intents a view sends, standing in for the store.
@MainActor final class Sent {
    var intents: [GameFeature.Intent] = []
    func send(_ intent: GameFeature.Intent) { intents.append(intent) }
}

@MainActor
struct BoardViewTests {
    private func board(_ state: GameFeature.State = .init(), flipped: Bool = false, sent: Sent = Sent()) -> BoardView {
        BoardView(state: state, flipped: flipped, send: sent.send)
    }

    private func cellView(_ notation: String, in view: BoardView) throws -> InspectableView<ViewType.ClassifiedView> {
        try view.inspect().find(viewWithAccessibilityIdentifier: "cell.\(notation)")
    }

    @Test func drawsAll91Cells() throws {
        #expect(try board().inspect().findAll(CellView.self).count == 91)
    }

    @Test func cellsAreLabelledForVoiceOver() throws {
        let view = board()
        #expect(try cellView("e4", in: view).accessibilityLabel().string() == "e4, white pawn")
        #expect(try cellView("f6", in: view).accessibilityLabel().string() == "f6, empty")
    }

    @Test func tappingACellSendsIntent() throws {
        let sent = Sent()
        try cellView("e4", in: board(sent: sent)).callOnTapGesture()
        #expect(sent.intents == [.cellTapped(c("e4"))])
    }

    @Test func tappingWorksWhenFlipped() throws {
        let sent = Sent()
        try cellView("e10", in: board(flipped: true, sent: sent)).callOnTapGesture()
        #expect(sent.intents == [.cellTapped(c("e10"))])
    }

    @Test func highlightsAreExposedAsAccessibilityValue() throws {
        let selected = GameFeature.State().after(.cellTapped(c("e4")))
        let view = board(selected)
        #expect(try cellView("e4", in: view).accessibilityValue().string() == "selected")
        #expect(try cellView("e6", in: view).accessibilityValue().string() == "legal move")
        #expect(try cellView("f6", in: view).accessibilityValue().string() == "")
    }

    @Test func lastMoveAndCheckAreHighlighted() throws {
        let checked = state("kf6 Rf11 Ka1", .black)
        #expect(try cellView("f6", in: board(checked)).accessibilityValue().string() == "in check")
        let moved = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")))
        #expect(try cellView("e4", in: board(moved)).accessibilityValue().string() == "last move")
        #expect(try cellView("e6", in: board(moved)).accessibilityValue().string() == "last move")
    }

    @Test func captureTargetsAreHighlighted() throws {
        let s = state("Ra1 ra6 Kc1 kl6").after(.cellTapped(c("a1")))
        #expect(try cellView("a6", in: board(s)).accessibilityValue().string() == "legal move")
    }

    @Test func reviewShowsTheEarlierPositionAndItsLastMove() throws {
        let s = GameFeature.State().after(.cellTapped(c("e4")), .cellTapped(c("e6")), .cellTapped(c("f7")), .cellTapped(c("f6")), .review(1))
        let view = board(s)
        #expect(try cellView("f7", in: view).accessibilityLabel().string() == "f7, black pawn")
        #expect(try cellView("e6", in: view).accessibilityValue().string() == "last move")
        #expect(try cellView("f6", in: view).accessibilityValue().string() == "")
    }

    @Test func coordinatesSitOnTheBoardEdge() {
        #expect(["a1", "a6", "b7", "c8", "d9", "e10", "f11"].allSatisfy { CellView.showsRank(c($0)) })
        #expect(!CellView.showsRank(c("b1")) && !CellView.showsRank(c("g10")) && !CellView.showsRank(c("f6")))
        #expect(Cell.all.filter(CellView.showsFile).count == 11)
        #expect(!CellView.showsFile(c("a6")))
    }

    @Test func piecesUseTheirAssetImages() throws {
        let view = board()
        #expect(try cellView("g1", in: view).find(ViewType.Image.self).actualImage().name() == "wK")
        #expect(try cellView("e10", in: view).find(ViewType.Image.self).actualImage().name() == "bQ")
        #expect(throws: (any Error).self) { try cellView("f6", in: view).find(ViewType.Image.self) }
    }

    @Test func highlightSetForACell() {
        let s = GameFeature.State().after(.cellTapped(c("e4")))
        let map = CellHighlight.all(in: s)
        #expect(map[c("e4")] == [.selected])
        #expect(map[c("e5")] == [.target])
        #expect(map[c("a1")] == nil)
    }

    @Test func paletteHasThreeDistinctShadesPerScheme() {
        for scheme in [ColorScheme.light, .dark] {
            #expect(Set((0...2).map { Palette.cell($0, scheme) }).count == 3)
        }
        #expect(Palette.cell(0, .light) != Palette.cell(0, .dark))
    }
}
