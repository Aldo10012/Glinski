public struct Move: Sendable, Hashable, Codable, CustomStringConvertible {
    public let from: Cell
    public let to: Cell
    /// Set exactly when a pawn reaches a promotion cell.
    public let promotion: PieceKind?

    public init(from: Cell, to: Cell, promotion: PieceKind? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }

    public var description: String {
        "\(from)-\(to)" + (promotion.map { "=\($0.letter)" } ?? "")
    }
}
