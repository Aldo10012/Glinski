import BoardUI
import GlinskiFeature
import SwiftUI

@main
struct GlinskiApp: App {
    @State private var store: GameStore
    private let archive: GameArchive

    init() {
        // UI tests start from a clean board and never touch the real saved game.
        let testing = CommandLine.arguments.contains("-uiTestingReset")
        archive = testing ? GameArchive(url: .temporaryDirectory.appendingPathComponent("ui-test-game.json")) : .standard
        let saved = testing ? nil : archive.load()
        _store = State(initialValue: GameStore(state: saved.map { .init(game: $0) } ?? .init()))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GameView(store: store)
                    .navigationTitle("Gliński")
            }
            // Save after every change: quitting on macOS doesn't reliably report a scene-phase change.
            .onChange(of: store.state.game) { _, game in try? archive.save(game) }
        }
        .commands {
            // New Game and Undo live on the toolbar with ⌘N / ⌘Z, so they go through confirmation.
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
        }
    }
}
