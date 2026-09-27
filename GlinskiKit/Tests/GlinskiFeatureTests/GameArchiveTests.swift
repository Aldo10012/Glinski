import Foundation
import GlinskiEngine
import Testing
@testable import GlinskiFeature

struct GameArchiveTests {
    private let archive = GameArchive(url: FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString).appendingPathComponent("game.json"))

    @Test func missingFileLoadsNothing() {
        #expect(archive.load() == nil)
    }

    @Test func savedGameLoadsBack() throws {
        var game = GameState()
        try game.play(Move(from: c("e4"), to: c("e6")))
        try archive.save(game)
        #expect(archive.load() == game)
    }

    @Test func corruptFileLoadsNothing() throws {
        try archive.save(GameState())
        try Data("{\"start\":{\"board\":\"Kj1\"}}".utf8).write(to: archive.url)
        #expect(archive.load() == nil)
    }

    @Test func defaultLocationIsApplicationSupport() {
        #expect(GameArchive.standard.url.lastPathComponent == "game.json")
        #expect(GameArchive.standard.url.path.contains("Application Support"))
    }
}
