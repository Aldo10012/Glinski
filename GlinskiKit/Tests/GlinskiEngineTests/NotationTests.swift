import Testing
@testable import GlinskiEngine

struct NotationTests {
    @Test(arguments: [
        ("Kg1 kg10", "g1-g2", "Kg1-g2"),                 // piece letter, quiet
        ("Pe4", "e4-e6", "e4-e6"),                        // pawn has no letter
        ("Pe4 pd4", "e4-d4", "e4xd4"),                    // capture
        ("Pf10", "f10-f11=Q", "f10-f11=Q"),               // promotion
        ("Ka1 Re3 kf10", "e3-f3", "Re3-f3+"),             // check
        ("Ki5 Qk4 kl6", "k4-k6", "Qk4-k6#"),              // mate
    ])
    func longAlgebraic(placement: String, text: String, expected: String) {
        #expect(position(placement).notation(for: move(text)) == expected)
    }

    @Test func enPassantIsACapture() throws {
        let p = try #require(position("Pe4 pf6").applying(move("e4-e6")))
        #expect(p.notation(for: move("f6-e5")) == "f6xe5")
    }

    @Test func gameNotationListsPlayedMoves() throws {
        var g = GameState()
        #expect(g.notation.isEmpty)
        try g.play(move("d1-f4"))
        try g.play(move("e7-e6"))
        #expect(g.notation == ["Nd1-f4", "e7-e6"])
    }
}
