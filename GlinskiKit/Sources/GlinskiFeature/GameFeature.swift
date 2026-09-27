import GlinskiEngine

/// MVI for pass-and-play: views render `State` and send `Intent`s; `reduce` holds all interaction logic.
public enum GameFeature {
    public struct State: Equatable, Sendable {
        public internal(set) var game: GameState
        public internal(set) var selection: Cell?
        /// Legal destinations of the selected piece.
        public internal(set) var targets: Set<Cell> = []
        /// A pawn move waiting for the player to pick Q/R/B/N.
        public internal(set) var pendingPromotion: PendingPromotion?
        /// The side that offered a draw; the other player must respond before play continues.
        public internal(set) var drawOfferedBy: Side?

        public init(game: GameState = GameState()) {
            self.game = game
        }

        public var sideToMove: Side { game.position.sideToMove }
        public var moveList: [String] { game.notation }
        public var lastMove: Move? { game.moves.last }

        /// The king of the side to move, when it is in check.
        public var checkedKing: Cell? {
            guard game.position.isInCheck else { return nil }
            return Cell.all.first { game.position.board[$0] == Piece(.king, sideToMove) }
        }

        /// Resignation and agreed draws are deliberate, so they can't be undone.
        public var canUndo: Bool {
            if pendingPromotion != nil { return true }
            switch game.result {
            case .resignation, .draw(.agreement): return false
            default: return !game.moves.isEmpty
            }
        }
    }

    public struct PendingPromotion: Equatable, Sendable {
        public let from: Cell
        public let to: Cell
    }

    public enum Intent: Equatable, Sendable {
        case cellTapped(Cell)
        case promotionChosen(PieceKind)
        case undo
        case newGame
        case resign
        case offerDraw
        case respondToDraw(accept: Bool)
    }

    public static func reduce(_ state: inout State, _ intent: Intent) {
        switch intent {
        case .cellTapped(let cell): tap(cell, &state)
        case .promotionChosen(let kind): promote(to: kind, &state)
        case .undo: undo(&state)
        case .newGame: state = State()
        case .resign: try? state.game.resign(state.sideToMove)
        case .offerDraw: offerDraw(&state)
        case .respondToDraw(let accept): respondToDraw(accept: accept, &state)
        }
        // A finished game keeps no pickers, prompts or highlights, whichever intent ended it.
        if state.game.result != nil {
            state.selection = nil
            state.targets = []
            state.pendingPromotion = nil
            state.drawOfferedBy = nil
        }
    }

    private static func tap(_ cell: Cell, _ state: inout State) {
        guard state.game.result == nil, state.pendingPromotion == nil, state.drawOfferedBy == nil else { return }
        if let from = state.selection, state.targets.contains(cell) {
            let moves = state.game.legalMoves(from: from).filter { $0.to == cell }
            state.selection = nil
            state.targets = []
            if moves.count > 1 {
                state.pendingPromotion = PendingPromotion(from: from, to: cell)
            } else {
                try? state.game.play(moves[0])
            }
            return
        }
        let piece = state.game.position.board[cell]
        if piece?.side == state.sideToMove, cell != state.selection {
            state.selection = cell
            state.targets = Set(state.game.legalMoves(from: cell).map(\.to))
        } else {
            state.selection = nil
            state.targets = []
        }
    }

    private static func promote(to kind: PieceKind, _ state: inout State) {
        guard let pending = state.pendingPromotion else { return }
        do {
            try state.game.play(Move(from: pending.from, to: pending.to, promotion: kind))
            state.pendingPromotion = nil
        } catch {}   // king or pawn: keep waiting for a valid choice
    }

    private static func undo(_ state: inout State) {
        guard state.canUndo else { return }
        if state.pendingPromotion != nil {
            state.pendingPromotion = nil
            return
        }
        state.game = state.game.undoingLastMove()!   // canUndo guarantees a move
        state.selection = nil
        state.targets = []
        state.drawOfferedBy = nil
    }

    private static func offerDraw(_ state: inout State) {
        guard state.game.result == nil, state.drawOfferedBy == nil, state.pendingPromotion == nil else { return }
        state.drawOfferedBy = state.sideToMove
        state.selection = nil
        state.targets = []
    }

    private static func respondToDraw(accept: Bool, _ state: inout State) {
        guard state.drawOfferedBy != nil else { return }
        state.drawOfferedBy = nil
        if accept { try? state.game.agreeDraw() }
    }
}
