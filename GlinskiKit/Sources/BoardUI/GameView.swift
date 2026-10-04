import GlinskiEngine
import GlinskiFeature
import SwiftUI

/// The single game screen: board, players, status, moves, overlays and controls.
public struct GameView: View {
    let store: GameStore
    @AppStorage("autoRotate") private var autoRotate = false
    @Environment(\.colorScheme) private var scheme

    public init(store: GameStore) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geometry in
            GameContent(store: store, size: geometry.size, autoRotate: $autoRotate)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Palette.background(scheme).ignoresSafeArea())
        #if os(macOS)
        .navigationSubtitle(Text("Two players on this Mac", bundle: .module))
        #endif
    }

    enum Overlay: Equatable {
        case promotion(Side), drawOffer(Side), gameOver(String)
    }

    /// At most one overlay: the game-over result outranks everything else. None while reviewing.
    static func overlay(_ state: GameFeature.State) -> Overlay? {
        if state.reviewPly != nil { return nil }
        if state.game.result != nil { return .gameOver(BoardText.status(state)) }
        if state.pendingPromotion != nil { return .promotion(state.sideToMove) }
        if let side = state.drawOfferedBy { return .drawOffer(side) }
        return nil
    }

    static let panelWidth: CGFloat = 320

    /// Side panel only when the board, fitted to the height, leaves room for it beside.
    static func isWide(_ size: CGSize) -> Bool {
        size.width >= size.height * 17 / (11 * 3.0.squareRoot()) + panelWidth + 16
    }

    /// Auto-rotate turns the board to the player to move; the Flip button turns it on top of that.
    static func isFlipped(_ state: GameFeature.State, autoRotate: Bool, manual: Bool = false) -> Bool {
        (autoRotate && state.sideToMove == .black) != manual
    }
}

struct GameContent: View {
    let store: GameStore
    let size: CGSize
    @Binding var autoRotate: Bool
    @State private var confirming: ConfirmAction?
    @State private var showingSettings = false
    @State private var flipped = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let state = store.state
        let isFlipped = GameView.isFlipped(state, autoRotate: autoRotate, manual: flipped)
        let board = BoardView(state: state, flipped: isFlipped, send: store.send)
            .overlay { overlay(GameView.overlay(state)) }
        // The player at the bottom of the board sits at the bottom of the screen.
        let (top, bottom): (Side, Side) = isFlipped ? (.white, .black) : (.black, .white)
        Group {
            if GameView.isWide(size) {
                HStack(spacing: 16) {
                    board.padding(8).frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(spacing: 12) {
                        PlayerCard(side: top, state: state)
                        StatusView(state: state).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                        MoveTableView(state: state, send: store.send)
                        HistoryNavView(state: state, send: store.send)
                        PlayerCard(side: bottom, state: state)
                    }
                    .frame(width: GameView.panelWidth)
                }
                .padding(16)
                .toolbar { wideToolbar }
            } else {
                VStack(spacing: 12) {
                    header
                    PlayerCard(side: top, state: state)
                    board.frame(maxHeight: .infinity)
                    PlayerCard(side: bottom, state: state)
                    MoveChipsView(state: state, send: store.send)
                    actionBar
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
            }
        }
        .confirmationDialog(confirming?.title ?? "", isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }), presenting: confirming) { confirmation in
            Button(role: .destructive) { ControlsView.confirm(confirmation, send: store.send) } label: { Text(confirmation.title) }
        }
        .sheet(isPresented: $showingSettings) { SettingsView(autoRotate: $autoRotate) }
    }

    private var controls: ControlsView {
        ControlsView(state: store.state, send: store.send, confirming: $confirming, showingSettings: $showingSettings, flipped: $flipped)
    }

    @ToolbarContentBuilder private var wideToolbar: some ToolbarContent {
        #if os(macOS)
        ToolbarItemGroup(placement: .primaryAction) {
            controls.newGame
            controls.undo
            controls.flip
        }
        ToolbarItemGroup(placement: .primaryAction) {
            controls.offerDraw.labelStyle(.titleAndIcon)
            controls.resign.labelStyle(.titleAndIcon)
        }
        ToolbarItem(placement: .primaryAction) { controls.settings }
        #else
        ToolbarItem(placement: .topBarLeading) { controls.newGame }
        ToolbarItem(placement: .principal) {
            VStack(spacing: 0) {
                Text(verbatim: "Gliński").font(.headline)
                Text("Two players · pass and play", bundle: .module).font(.caption).foregroundStyle(.secondary)
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            controls.undo
            controls.flip
            controls.offerDraw
            controls.resign
            controls.settings
        }
        #endif
    }

    /// Narrow layout: round New Game and Settings buttons around the centred status.
    private var header: some View {
        HStack {
            controls.newGame.labelStyle(.iconOnly).buttonStyle(RoundButtonStyle(tint: Palette.accent))
            Spacer()
            StatusView(state: store.state, centered: true)
            Spacer()
            controls.settings.labelStyle(.iconOnly).buttonStyle(RoundButtonStyle(tint: Palette.ink(scheme)))
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            controls.undo
            controls.flip
            controls.offerDraw
            controls.resign
        }
        .labelStyle(TileLabelStyle())
        .buttonStyle(TileButtonStyle())
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

/// A 48pt card-coloured circle, for the narrow header.
struct RoundButtonStyle: ButtonStyle {
    let tint: Color
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundStyle(tint)
            .frame(width: 48, height: 48)
            .background(Palette.card(scheme), in: Circle())
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.06), radius: 6, y: 2)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// A card-coloured tile, for the narrow action bar.
struct TileButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.ink(scheme))
            .card()
            .opacity(configuration.isPressed || !isEnabled ? 0.45 : 1)
    }
}
