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

struct ControlsView: View {
    let state: GameFeature.State
    let send: @MainActor (GameFeature.Intent) -> Void
    @Binding var confirming: ConfirmAction?
    @Binding var showingSettings: Bool

    private var inProgress: Bool { state.game.result == nil }
    private var waiting: Bool { state.drawOfferedBy != nil || state.pendingPromotion != nil }

    var body: some View {
        Button {
            if inProgress && !state.game.moves.isEmpty { confirming = .newGame } else { send(.newGame) }
        } label: { Label { Text("New Game", bundle: .module) } icon: { Image(systemName: "plus") } }
            .keyboardShortcut("n")
        Button { send(.undo) } label: { Label { Text("Undo", bundle: .module) } icon: { Image(systemName: "arrow.uturn.backward") } }
            .keyboardShortcut("z")
            .disabled(!state.canUndo)
        Button { send(.offerDraw) } label: { Label { Text("Offer Draw", bundle: .module) } icon: { Image(systemName: "equal.circle") } }
            .disabled(!inProgress || waiting)
        Button { confirming = .resign } label: { Label { Text("Resign", bundle: .module) } icon: { Image(systemName: "flag") } }
            .disabled(!inProgress)
        Button { showingSettings = true } label: { Label { Text("Settings", bundle: .module) } icon: { Image(systemName: "gearshape") } }
    }

    static func confirm(_ confirmation: ConfirmAction, send: @MainActor (GameFeature.Intent) -> Void) {
        send(confirmation == .newGame ? .newGame : .resign)
    }
}
