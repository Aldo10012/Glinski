public enum Side: String, Sendable, Hashable, Codable {
    case white, black

    public var opponent: Side { self == .white ? .black : .white }
}

public enum PieceKind: String, Sendable, Hashable, Codable, CaseIterable {
    case pawn, knight, bishop, rook, queen, king

    public var letter: Character {
        switch self {
        case .pawn: "P"
        case .knight: "N"
        case .bishop: "B"
        case .rook: "R"
        case .queen: "Q"
        case .king: "K"
        }
    }

    /// Case-insensitive: "n" and "N" are both knights.
    public init?(letter: Character) {
        guard let kind = PieceKind.allCases.first(where: { String($0.letter) == letter.uppercased() }) else { return nil }
        self = kind
    }
}

public struct Piece: Sendable, Hashable, Codable {
    public let kind: PieceKind
    public let side: Side

    public init(_ kind: PieceKind, _ side: Side) {
        self.kind = kind
        self.side = side
    }
}
