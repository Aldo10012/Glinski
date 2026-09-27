extension Position {
    /// Long algebraic notation, e.g. "Nd1-f4", "e4xd4", "f10-f11=Q", "Re3-f3+", "Qk4-k6#".
    /// Long form needs no disambiguation. Pass a legal move, before it is played.
    public func notation(for move: Move) -> String {
        let piece = board[move.from]!
        let isCapture = board[move.to] != nil || (piece.kind == .pawn && move.to == enPassantTarget)
        var text = piece.kind == .pawn ? "" : String(piece.kind.letter)
        text += move.from.notation + (isCapture ? "x" : "-") + move.to.notation
        if let promotion = move.promotion { text += "=\(promotion.letter)" }
        let next = applyingUnchecked(move)
        if next.isInCheck { text += next.legalMoves().isEmpty ? "#" : "+" }
        return text
    }
}

extension GameState {
    /// One notation string per played move, for the move list.
    public var notation: [String] {
        var current = start
        return moves.map { move in
            defer { current = current.applyingUnchecked(move) }
            return current.notation(for: move)
        }
    }
}
