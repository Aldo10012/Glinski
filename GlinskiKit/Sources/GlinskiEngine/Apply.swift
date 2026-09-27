extension Position {
    /// Plays `move` if it is legal; `nil` otherwise.
    public func applying(_ move: Move) -> Position? {
        legalMoves(from: move.from).contains(move) ? applyingUnchecked(move) : nil
    }

    /// Plays `move` without checking legality. Only pass moves produced by move generation.
    func applyingUnchecked(_ move: Move) -> Position {
        let piece = board[move.from]!
        let isPawn = piece.kind == .pawn
        let isCapture = board[move.to] != nil
        var next = self
        next.board[move.from] = nil
        // The victim sits one step past the skipped cell, in its own forward direction.
        if isPawn, move.to == enPassantTarget, let victim = move.to.offset(Position.forward(sideToMove.opponent)) {
            next.board[victim] = nil
        }
        next.board[move.to] = move.promotion.map { Piece($0, piece.side) } ?? piece
        next.enPassantTarget = nil
        if isPawn, let skipped = move.from.offset(Position.forward(sideToMove)),
           skipped.offset(Position.forward(sideToMove)) == move.to {
            // ponytail: pseudo-legal capturer check; FIDE-exact would also require the capture be legal.
            let enemy = sideToMove.opponent
            let canCapture = Position.captureVectors(enemy).contains { v in
                skipped.offset(-v).flatMap { next.board[$0] } == Piece(.pawn, enemy)
            }
            if canCapture { next.enPassantTarget = skipped }
        }
        next.halfmoveClock = isPawn || isCapture ? 0 : halfmoveClock + 1
        next.sideToMove = sideToMove.opponent
        return next
    }
}

extension Position {
    /// Number of leaf positions `depth` plies deep. Validates move generation.
    func perft(_ depth: Int) -> Int {
        guard depth > 0 else { return 1 }
        let moves = legalMoves()
        guard depth > 1 else { return moves.count }
        return moves.reduce(0) { $0 + applyingUnchecked($1).perft(depth - 1) }
    }
}
