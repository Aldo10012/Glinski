extension Position {
    public func legalMoves() -> [Move] {
        board.indices.flatMap { pseudoLegalMoves(from: $0) }.filter(isLegal)
    }

    public func legalMoves(from cell: Cell) -> [Move] {
        pseudoLegalMoves(from: cell.index).filter(isLegal)
    }

    public var isInCheck: Bool { isKingAttacked(sideToMove) }

    // ponytail: make-move-then-test legality; pin-aware generation if v2 profiling needs it.
    private func isLegal(_ move: Move) -> Bool {
        !applyingUnchecked(move).isKingAttacked(sideToMove)
    }

    func pseudoLegalMoves(from i: Int) -> [Move] {
        guard let piece = board[i], piece.side == sideToMove else { return [] }
        let targets: [Int]
        switch piece.kind {
        case .pawn: return pawnMoves(from: i)
        case .knight: targets = Geometry.knightTargets[i].filter { board[$0]?.side != sideToMove }
        case .king: targets = Geometry.kingTargets[i].filter { board[$0]?.side != sideToMove }
        case .bishop: targets = slides(from: i, along: Geometry.diagonalRays)
        case .rook: targets = slides(from: i, along: Geometry.orthogonalRays)
        case .queen: targets = slides(from: i, along: Geometry.orthogonalRays) + slides(from: i, along: Geometry.diagonalRays)
        }
        return targets.map { Move(from: Cell.all[i], to: Cell.all[$0]) }
    }

    private func slides(from i: Int, along rays: [[[Int]]]) -> [Int] {
        var targets: [Int] = []
        for ray in rays[i] {
            for t in ray {
                if let p = board[t] {
                    if p.side != sideToMove { targets.append(t) }
                    break
                }
                targets.append(t)
            }
        }
        return targets
    }

    func pawnMoves(from i: Int) -> [Move] {
        let from = Cell.all[i]
        let forward = Position.forward(sideToMove)
        var targets: [Cell] = []
        if let one = from.offset(forward), board[one] == nil {
            targets.append(one)
            if Position.pawnStarts(sideToMove).contains(from), let two = one.offset(forward), board[two] == nil {
                targets.append(two)
            }
        }
        for v in Position.captureVectors(sideToMove) {
            guard let t = from.offset(v) else { continue }
            if let p = board[t] {
                if p.side != sideToMove { targets.append(t) }
            } else if t == enPassantTarget {
                targets.append(t)
            }
        }
        return targets.flatMap { to -> [Move] in
            guard Position.isPromotionCell(to, for: sideToMove) else { return [Move(from: from, to: to)] }
            return [PieceKind.queen, .rook, .bishop, .knight].map { Move(from: from, to: to, promotion: $0) }
        }
    }

    func isKingAttacked(_ side: Side) -> Bool {
        guard let king = board.firstIndex(of: Piece(.king, side)) else { return false }
        return isAttacked(king, by: side.opponent)
    }

    func isAttacked(_ i: Int, by attacker: Side) -> Bool {
        if Geometry.knightTargets[i].contains(where: { board[$0] == Piece(.knight, attacker) }) { return true }
        if Geometry.kingTargets[i].contains(where: { board[$0] == Piece(.king, attacker) }) { return true }
        if slider(attacks: i, along: Geometry.orthogonalRays, kind: .rook, attacker) { return true }
        if slider(attacks: i, along: Geometry.diagonalRays, kind: .bishop, attacker) { return true }
        let cell = Cell.all[i]
        return Position.captureVectors(attacker).contains { v in
            cell.offset(-v).map { board[$0] == Piece(.pawn, attacker) } ?? false
        }
    }

    /// Is the first piece along any ray an attacker's `kind` or queen?
    private func slider(attacks i: Int, along rays: [[[Int]]], kind: PieceKind, _ attacker: Side) -> Bool {
        for ray in rays[i] {
            for t in ray {
                guard let p = board[t] else { continue }
                if p.side == attacker && (p.kind == kind || p.kind == .queen) { return true }
                break
            }
        }
        return false
    }
}
