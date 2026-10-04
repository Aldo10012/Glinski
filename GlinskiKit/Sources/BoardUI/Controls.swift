import GlinskiFeature
import SwiftUI

/// Irreversible actions that ask before they happen.
enum ConfirmAction: Identifiable {
    case newGame, resign

    var id: Self { self }

    var title: String {
        switch self {
        case .newGame: String(localized: "Abandon this game and start a new one?", bundle: .module)
        case .resign: String(localized: "Resign this game?", bundle: .module)
        }
    }
}

/// Every game action as a button; the layouts in `GameContent` pick and arrange them.
struct ControlsView: View {
    let state: GameFeature.State
    let send: @MainActor (GameFeature.Intent) -> Void
    @Binding var confirming: ConfirmAction?
    @Binding var showingSettings: Bool
    @Binding var flipped: Bool

    private var inProgress: Bool { state.game.result == nil }
    private var waiting: Bool { state.drawOfferedBy != nil || state.pendingPromotion != nil }

    var body: some View {
        newGame
        undo
        flip
        offerDraw
        resign
        settings
    }

    var newGame: some View {
        Button {
            if inProgress && !state.game.moves.isEmpty { confirming = .newGame } else { send(.newGame) }
        } label: { Label { Text("New Game", bundle: .module) } icon: { Image(systemName: "plus") } }
            .keyboardShortcut("n")
    }

    var undo: some View {
        Button { send(.undo) } label: { Label { Text("Undo", bundle: .module) } icon: { Image(systemName: "arrow.uturn.backward") } }
            .keyboardShortcut("z")
            .disabled(!state.canUndo)
    }

    var flip: some View {
        Button { flipped.toggle() } label: { Label { Text("Flip", bundle: .module) } icon: { Image(systemName: "arrow.up.arrow.down") } }
    }

    var offerDraw: some View {
        Button { send(.offerDraw) } label: {
            Label { Text("Offer Draw", bundle: .module) } icon: { Text(verbatim: "½").font(.body.weight(.semibold)) }
        }
            .disabled(!inProgress || waiting)
    }

    var resign: some View {
        Button { confirming = .resign } label: { Label { Text("Resign", bundle: .module) } icon: { Image(systemName: "flag") } }
            .disabled(!inProgress)
    }

    var settings: some View {
        Button { showingSettings = true } label: { Label { Text("Settings", bundle: .module) } icon: { Image(systemName: "slider.horizontal.3") } }
    }

    static func confirm(_ confirmation: ConfirmAction, send: @MainActor (GameFeature.Intent) -> Void) {
        send(confirmation == .newGame ? .newGame : .resign)
    }
}

/// The narrow layout's bottom tiles: icon over title.
struct TileLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 6) {
            configuration.icon.font(.title3)
            configuration.title.font(.footnote.weight(.medium))
        }
        .frame(maxWidth: .infinity, minHeight: 64)
    }
}
