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

    /// The line under the status: the move number, plus what is selected or being reviewed.
    static func detail(_ state: GameFeature.State) -> String {
        if let ply = state.reviewPly {
            return String(localized: "Reviewing move \(ply) of \(state.game.moves.count)", bundle: .module)
        }
        let move = String(localized: "Move \(state.game.moves.count / 2 + 1)", bundle: .module)
        guard let cell = state.selection, let piece = state.game.position.board[cell] else { return move }
        let name = name(piece.kind).capitalized
        return move + " · " + String(localized: "\(name) on \(cell.notation) selected", bundle: .module)
    }

    /// "3 of 7": the displayed ply out of all plies, above the move table.
    static func counter(_ state: GameFeature.State) -> String {
        String(localized: "\(state.displayedPly) of \(state.game.moves.count)", bundle: .module)
    }

    /// Spoken form of one move-table row: "1, white pawn, e4 to e6".
    static func plyLabel(_ record: GameFeature.PlyRecord) -> String {
        let side = record.piece.side == .white ? String(localized: "white", bundle: .module) : String(localized: "black", bundle: .module)
        let base = "\(record.number), \(side) \(name(record.piece.kind)), " + String(localized: "\(record.from.notation) to \(record.to.notation)", bundle: .module)
        guard let promotion = record.promotion else { return base }
        return base + ", " + String(localized: "promotes to \(name(promotion))", bundle: .module)
    }

    /// "Black, captured pawn, knight".
    static func playerLabel(_ side: Side, captured: [PieceKind]) -> String {
        guard !captured.isEmpty else { return name(side) }
        return name(side) + ", " + String(localized: "captured \(captured.map(name).joined(separator: ", "))", bundle: .module)
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
