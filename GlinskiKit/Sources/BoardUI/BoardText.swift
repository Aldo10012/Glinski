import Foundation
import GlinskiEngine
import GlinskiFeature

/// Every user-facing sentence about the game, kept out of views so it is testable and localizable.
enum BoardText {
    static func status(_ state: GameFeature.State) -> String {
        if let ended = state.game.result { return result(ended) }
        let side = name(state.sideToMove)
        return state.checkedKing == nil
            ? String(localized: "\(side) to move", bundle: .module)
            : String(localized: "\(side) to move — check", bundle: .module)
    }

    static func result(_ result: GameResult) -> String {
        switch result {
        case .checkmate(let winner):
            String(localized: "Checkmate — \(name(winner)) wins", bundle: .module)
        case .stalemate(let winner):
            // Gliński scoring: stalemate is worth ¾ to the side that delivers it.
            String(localized: "Stalemate — \(name(winner)) ¾, \(name(winner.opponent)) ¼", bundle: .module)
        case .resignation(let winner):
            String(localized: "\(name(winner.opponent)) resigns — \(name(winner)) wins", bundle: .module)
        case .draw(.agreement):
            String(localized: "Draw by agreement", bundle: .module)
        case .draw(.repetition):
            String(localized: "Draw by threefold repetition", bundle: .module)
        case .draw(.fiftyMove):
            String(localized: "Draw by the 50-move rule", bundle: .module)
        }
    }

    /// "1. e4-e6  f7-f6" — one row per full move.
    static func moveRows(_ moves: [String]) -> [String] {
        stride(from: 0, to: moves.count, by: 2).map { i in
            "\(i / 2 + 1). " + moves[i..<min(i + 2, moves.count)].joined(separator: "  ")
        }
    }

    static func cellLabel(_ cell: Cell, piece: Piece?) -> String {
        guard let piece else { return String(localized: "\(cell.notation), empty", bundle: .module) }
        let colour = piece.side == .white ? String(localized: "white", bundle: .module) : String(localized: "black", bundle: .module)
        return "\(cell.notation), \(colour) \(name(piece.kind))"
    }

    static func name(_ side: Side) -> String {
        side == .white ? String(localized: "White", bundle: .module) : String(localized: "Black", bundle: .module)
    }

    static func name(_ kind: PieceKind) -> String {
        switch kind {
        case .pawn: String(localized: "pawn", bundle: .module)
        case .knight: String(localized: "knight", bundle: .module)
        case .bishop: String(localized: "bishop", bundle: .module)
        case .rook: String(localized: "rook", bundle: .module)
        case .queen: String(localized: "queen", bundle: .module)
        case .king: String(localized: "king", bundle: .module)
        }
    }
}
