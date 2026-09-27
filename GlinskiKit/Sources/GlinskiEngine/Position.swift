/// Everything needed to generate moves: the board and the per-move state around it.
public struct Position: Sendable, Hashable, Codable {
    public internal(set) var board: Board
    public internal(set) var sideToMove: Side
    /// The cell a pawn skipped with a double step on the previous ply, if an enemy pawn could capture there.
    public internal(set) var enPassantTarget: Cell?
    /// Plies since the last capture or pawn move (50-move rule).
    public internal(set) var halfmoveClock: Int

    public init(board: Board, sideToMove: Side = .white, enPassantTarget: Cell? = nil, halfmoveClock: Int = 0) {
        self.board = board
        self.sideToMove = sideToMove
        self.enPassantTarget = enPassantTarget
        self.halfmoveClock = halfmoveClock
    }

    public static let initial = Position(board: .initial)

    static func forward(_ side: Side) -> Vector {
        side == .white ? Vector(dq: 0, dr: -1) : Vector(dq: 0, dr: 1)
    }

    /// Orthogonally forward at 60° to the vertical.
    static func captureVectors(_ side: Side) -> [Vector] {
        side == .white
            ? [Vector(dq: -1, dr: 0), Vector(dq: 1, dr: -1)]
            : [Vector(dq: -1, dr: 1), Vector(dq: 1, dr: 0)]
    }

    private static let whitePawnStarts = Set(Cell.all.filter { Board.initial[$0] == Piece(.pawn, .white) })
    private static let blackPawnStarts = Set(Cell.all.filter { Board.initial[$0] == Piece(.pawn, .black) })

    /// Any starting cell of a pawn of this side, not just the pawn's own.
    static func pawnStarts(_ side: Side) -> Set<Cell> {
        side == .white ? whitePawnStarts : blackPawnStarts
    }

    /// The last cell of a file in this side's forward direction.
    static func isPromotionCell(_ cell: Cell, for side: Side) -> Bool {
        cell.offset(forward(side)) == nil
    }
}

extension Position {
    private enum CodingKeys: String, CodingKey { case board, sideToMove, enPassantTarget, halfmoveClock }

    /// Saved positions are untrusted: reject anything that couldn't arise in a real game.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            board: try container.decode(Board.self, forKey: .board),
            sideToMove: try container.decode(Side.self, forKey: .sideToMove),
            enPassantTarget: try container.decodeIfPresent(Cell.self, forKey: .enPassantTarget),
            halfmoveClock: try container.decode(Int.self, forKey: .halfmoveClock)
        )
        guard isPlausible else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Impossible position"))
        }
    }

    private var isPlausible: Bool {
        let kings = [Side.white, .black].map { side in board.indices.count { board[$0] == Piece(.king, side) } }
        guard kings == [1, 1], (0...100).contains(halfmoveClock), !isKingAttacked(sideToMove.opponent) else { return false }
        guard let target = enPassantTarget else { return true }
        // The side that just moved double-stepped over `target` from one of its pawn starting cells.
        let mover = sideToMove.opponent
        let forward = Position.forward(mover)
        return board[target] == nil
            && target.offset(forward).flatMap { board[$0] } == Piece(.pawn, mover)
            && target.offset(-forward).map { board[$0] == nil && Position.pawnStarts(mover).contains($0) } == true
    }
}
