import Foundation
import GlinskiEngine

/// The one saved game, as JSON. Loading never crashes: a missing or corrupt file just means a fresh game.
public struct GameArchive: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static let standard = GameArchive(url: URL.applicationSupportDirectory.appendingPathComponent("game.json"))

    public func load() -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }

    public func save(_ game: GameState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(game).write(to: url, options: .atomic)
    }
}
