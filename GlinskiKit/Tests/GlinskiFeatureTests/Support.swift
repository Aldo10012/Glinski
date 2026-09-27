import GlinskiEngine
@testable import GlinskiFeature

func c(_ notation: String) -> Cell {
    guard let cell = Cell(notation) else { fatalError("bad cell \(notation)") }
    return cell
}

/// A feature state starting from a custom placement, e.g. "Pf10 Ka1 kl6".
func state(_ placement: String, _ side: Side = .white) -> GameFeature.State {
    GameFeature.State(game: GameState(start: Position(board: Board(placement: placement)!, sideToMove: side)))
}

extension GameFeature.State {
    /// Applies intents in order, like a user tapping through the UI.
    func after(_ intents: GameFeature.Intent...) -> GameFeature.State {
        var s = self
        for intent in intents { GameFeature.reduce(&s, intent) }
        return s
    }
}
