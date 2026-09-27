@testable import GlinskiEngine

/// Cell from notation; crashes the test on a typo so fixtures stay honest.
func cell(_ notation: String) -> Cell {
    guard let cell = Cell(notation) else { fatalError("bad cell \(notation)") }
    return cell
}

/// "e4-e6" or "f10-f11=Q".
func move(_ text: String) -> Move {
    let parts = text.split(whereSeparator: { $0 == "-" || $0 == "=" }).map(String.init)
    return Move(from: cell(parts[0]), to: cell(parts[1]), promotion: parts.count > 2 ? PieceKind(letter: parts[2].first!) : nil)
}

func position(_ placement: String, _ side: Side = .white, halfmoveClock: Int = 0) -> Position {
    guard let board = Board(placement: placement) else { fatalError("bad placement \(placement)") }
    return Position(board: board, sideToMove: side, halfmoveClock: halfmoveClock)
}

extension Position {
    func targets(from notation: String) -> Set<String> {
        Set(legalMoves(from: cell(notation)).map(\.to.notation))
    }
}
