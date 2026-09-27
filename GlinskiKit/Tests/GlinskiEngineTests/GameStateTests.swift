import Foundation
import Testing
@testable import GlinskiEngine

struct GameStateTests {
    private func game(_ placement: String, _ side: Side = .white, halfmoveClock: Int = 0) -> GameState {
        GameState(start: position(placement, side, halfmoveClock: halfmoveClock))
    }

    @Test func newGame() {
        let g = GameState()
        #expect(g.position == .initial)
        #expect(g.moves.isEmpty)
        #expect(g.result == nil)
        #expect(g.legalMoves.count == 51)
        #expect(g.legalMoves(from: cell("e4")).count == 2)
    }

    @Test func playRecordsMove() throws {
        var g = GameState()
        try g.play(move("e4-e6"))
        #expect(g.moves == [move("e4-e6")])
        #expect(g.position.sideToMove == .black)
    }

    @Test func illegalMoveThrows() {
        var g = GameState()
        #expect(throws: GameError.illegalMove(move("e4-e7"))) { try g.play(move("e4-e7")) }
        #expect(g.moves.isEmpty)
    }

    @Test func checkmate() throws {
        var g = game("Ki5 Qk4 kl6")
        try g.play(move("k4-k6"))
        #expect(g.result == .checkmate(winner: .white))
        #expect(g.legalMoves.isEmpty)
        #expect(g.legalMoves(from: cell("l6")).isEmpty)
    }

    @Test func stalemateScoresForTheStalematingSide() throws {
        var g = game("Ki5 kl6")
        try g.play(move("i5-i6"))
        #expect(g.result == .stalemate(winner: .white))
    }

    @Test func startingInCheckmateIsAlreadyOver() {
        #expect(game("Ki5 Qk6 kl6", .black).result == .checkmate(winner: .white))
    }

    @Test func fiftyMoveRule() throws {
        var g = game("Ka1 kl6", halfmoveClock: 98)
        try g.play(move("a1-a2"))
        #expect(g.result == nil)
        try g.play(move("l6-l5"))
        #expect(g.result == .draw(.fiftyMove))
    }

    @Test func checkmateBeatsFiftyMoveRule() throws {
        var g = game("Ki5 Qk4 kl6", halfmoveClock: 99)
        try g.play(move("k4-k6"))
        #expect(g.result == .checkmate(winner: .white))
    }

    @Test func threefoldRepetition() throws {
        var g = game("Ka1 kl6")
        let cycle = ["a1-a2", "l6-l5", "a2-a1", "l5-l6"]
        for text in cycle + cycle.dropLast() { try g.play(move(text)) }
        #expect(g.result == nil)
        try g.play(move(cycle.last!))
        #expect(g.result == .draw(.repetition))
    }

    @Test func resignation() throws {
        var g = GameState()
        try g.resign(.white)
        #expect(g.result == .resignation(winner: .black))
        #expect(g.legalMoves.isEmpty)
    }

    @Test func drawByAgreement() throws {
        var g = GameState()
        try g.agreeDraw()
        #expect(g.result == .draw(.agreement))
    }

    @Test func actionsAfterGameOverThrow() throws {
        var g = GameState()
        try g.resign(.black)
        #expect(throws: GameError.gameOver) { try g.play(move("e4-e6")) }
        #expect(throws: GameError.gameOver) { try g.resign(.white) }
        #expect(throws: GameError.gameOver) { try g.agreeDraw() }
    }

    @Test func undo() throws {
        var g = GameState()
        #expect(g.undoingLastMove() == nil)
        try g.play(move("e4-e6"))
        let afterOne = g
        try g.play(move("f7-f6"))
        #expect(g.undoingLastMove() == afterOne)
    }

    @Test func undoClearsCheckmate() throws {
        var g = game("Ki5 Qk4 kl6")
        try g.play(move("k4-k6"))
        let undone = try #require(g.undoingLastMove())
        #expect(undone.result == nil)
        #expect(undone.position == position("Ki5 Qk4 kl6"))
    }

    @Test func codableRoundTrip() throws {
        var g = GameState()
        try g.play(move("e4-e6"))
        try g.play(move("f7-f6"))
        try g.resign(.white)
        let data = try JSONEncoder().encode(g)
        #expect(try JSONDecoder().decode(GameState.self, from: data) == g)
    }

    @Test func codableRoundTripAgreedDraw() throws {
        var g = GameState()
        try g.agreeDraw()
        #expect(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g)) == g)
    }

    @Test func decodingIllegalMovesThrows() throws {
        var json = try jsonObject(GameState())
        json["moves"] = [["from": "e4", "to": "e7"]]
        #expect(throws: GameError.illegalMove(move("e4-e7"))) {
            try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        }
    }

    @Test func decodingIgnoresUntrustedStoredResult() throws {
        var json = try jsonObject(GameState())
        json["result"] = ["checkmate": ["winner": "white"]]
        let g = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(g.result == nil)
    }

    private func jsonObject(_ g: GameState) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(g)) as? [String: Any])
    }
}
