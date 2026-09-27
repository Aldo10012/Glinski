import GlinskiEngine
import GlinskiFeature
import SwiftUI

/// The single game screen: board, status, move list, overlays and controls.
public struct GameView: View {
    let store: GameStore
    @AppStorage("autoRotate") private var autoRotate = false
    @State private var confirming: ConfirmAction?
    @State private var showingSettings = false

    public init(store: GameStore) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geometry in
            GameContent(store: store, size: geometry.size, autoRotate: autoRotate)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ControlsView(state: store.state, send: store.send, confirming: $confirming, showingSettings: $showingSettings)
            }
        }
        .confirmationDialog(confirming?.title ?? "", isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }), presenting: confirming) { confirmation in
            Button(role: .destructive) { ControlsView.confirm(confirmation, send: store.send) } label: { Text(confirmation.title) }
        }
        .sheet(isPresented: $showingSettings) { SettingsView(autoRotate: $autoRotate) }
    }

    enum Overlay: Equatable {
        case promotion(Side), drawOffer(Side), gameOver(String)
    }

    /// At most one overlay: the game-over result outranks everything else.
    static func overlay(_ state: GameFeature.State) -> Overlay? {
        if state.game.result != nil { return .gameOver(BoardText.status(state)) }
        if state.pendingPromotion != nil { return .promotion(state.sideToMove) }
        if let side = state.drawOfferedBy { return .drawOffer(side) }
        return nil
    }

    /// Side panel only when the board, fitted to the height, leaves 240pt beside it.
    static func isWide(_ size: CGSize) -> Bool {
        size.width >= size.height * 17 / (11 * 3.0.squareRoot()) + 240
    }

    static func isFlipped(_ state: GameFeature.State, autoRotate: Bool) -> Bool {
        autoRotate && state.sideToMove == .black
    }
}

struct GameContent: View {
    let store: GameStore
    let size: CGSize
    let autoRotate: Bool

    var body: some View {
        let state = store.state
        let board = BoardView(state: state, flipped: GameView.isFlipped(state, autoRotate: autoRotate), send: store.send)
            .overlay { overlay(GameView.overlay(state)) }
        let status = Text(BoardText.status(state)).font(.headline).accessibilityIdentifier("status")
        let rows = BoardText.moveRows(state.moveList)
        if GameView.isWide(size) {
            HStack(alignment: .top, spacing: 16) {
                board
                VStack(alignment: .leading, spacing: 12) {
                    status
                    MoveListView(rows: rows, horizontal: false)
                }
                .frame(width: 224, alignment: .leading)
            }
        } else {
            VStack(spacing: 12) {
                status
                board
                MoveListView(rows: rows, horizontal: true)
            }
        }
    }

    @ViewBuilder private func overlay(_ overlay: GameView.Overlay?) -> some View {
        switch overlay {
        case .promotion(let side): PromotionPicker(side: side, send: store.send)
        case .drawOffer(let side): DrawOfferView(offeredBy: side, send: store.send)
        case .gameOver(let text): GameOverView(text: text, send: store.send)
        case nil: EmptyView()
        }
    }
}
