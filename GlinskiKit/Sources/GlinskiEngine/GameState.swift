public enum DrawReason: String, Sendable, Hashable, Codable {
    case agreement, repetition, fiftyMove
}

public enum GameResult: Sendable, Hashable, Codable {
    case checkmate(winner: Side)
    /// Not a draw in Gliński's chess: the stalemating side scores ¾, the stalemated side ¼.
    case stalemate(winner: Side)
    case resignation(winner: Side)
    case draw(DrawReason)
}

public enum GameError: Error, Equatable {
    case illegalMove(Move)
    case gameOver
}

/// Positions that count as "the same" for threefold repetition.
struct RepetitionKey: Hashable, Sendable {
    let board: Board
    let sideToMove: Side
    let enPassantTarget: Cell?

    init(_ p: Position) {
        board = p.board
        sideToMove = p.sideToMove
        enPassantTarget = p.enPassantTarget
    }
}

/// A game from a starting position: its moves, the current position and the result.
public struct GameState: Sendable, Hashable {
    public let start: Position
    public private(set) var moves: [Move] = []
    public private(set) var position: Position
    public private(set) var result: GameResult?
    private var seen: [RepetitionKey: Int]

    public init(start: Position = .initial) {
        self.start = start
        position = start
        seen = [RepetitionKey(start): 1]
        result = outcome()
    }

    public var legalMoves: [Move] { result == nil ? position.legalMoves() : [] }

    public func legalMoves(from cell: Cell) -> [Move] {
        result == nil ? position.legalMoves(from: cell) : []
    }

    public mutating func play(_ move: Move) throws(GameError) {
        guard result == nil else { throw .gameOver }
        guard let next = position.applying(move) else { throw .illegalMove(move) }
        position = next
        moves.append(move)
        seen[RepetitionKey(next), default: 0] += 1
        result = outcome()
    }

    public mutating func resign(_ side: Side) throws(GameError) {
        guard result == nil else { throw .gameOver }
        result = .resignation(winner: side.opponent)
    }

    public mutating func agreeDraw() throws(GameError) {
        guard result == nil else { throw .gameOver }
        result = .draw(.agreement)
    }

    /// The game with its last move taken back, replayed from the start; any result is cleared.
    public func undoingLastMove() -> GameState? {
        guard !moves.isEmpty else { return nil }
        var game = GameState(start: start)
        for move in moves.dropLast() { try! game.play(move) }   // already played once, so legal
        return game
    }

    /// Checkmate and stalemate take precedence over the 50-move and repetition draws.
    private func outcome() -> GameResult? {
        let mover = position.sideToMove.opponent
        if position.legalMoves().isEmpty {
            return position.isInCheck ? .checkmate(winner: mover) : .stalemate(winner: mover)
        }
        if position.halfmoveClock >= 100 { return .draw(.fiftyMove) }
        if seen[RepetitionKey(position)]! >= 3 { return .draw(.repetition) }
        // ponytail: no insufficient-material rule; hex dead-material table unresearched, 50-move rule ends dead games.
        return nil
    }
}

extension GameState: Codable {
    private enum CodingKeys: String, CodingKey { case start, moves, result }

    /// Replays the stored moves, so a tampered move list throws instead of producing an impossible game.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(start: try container.decode(Position.self, forKey: .start))
        for move in try container.decode([Move].self, forKey: .moves) { try play(move) }
        // Only results that can't be derived from the moves are trusted from storage.
        switch try container.decodeIfPresent(GameResult.self, forKey: .result) {
        case let stored? where result == nil && (stored == .draw(.agreement) || stored.isResignation):
            result = stored
        default:
            break
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encode(moves, forKey: .moves)
        try container.encodeIfPresent(result, forKey: .result)
    }
}

private extension GameResult {
    var isResignation: Bool {
        if case .resignation = self { true } else { false }
    }
}
