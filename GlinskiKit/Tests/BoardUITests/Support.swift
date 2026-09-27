import GlinskiEngine
import GlinskiFeature

func state(_ placement: String, _ side: Side = .white) -> GameFeature.State {
    GameFeature.State(game: GameState(start: Position(board: Board(placement: placement)!, sideToMove: side)))
}

extension GameFeature.State {
    func after(_ intents: GameFeature.Intent...) -> GameFeature.State {
        var s = self
        for intent in intents { GameFeature.reduce(&s, intent) }
        return s
    }
}
