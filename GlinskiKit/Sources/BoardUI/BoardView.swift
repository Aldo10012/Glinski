import GlinskiEngine
import GlinskiFeature
import SwiftUI

/// The 91 cells of the displayed position, positioned by `HexLayout`. Every tap becomes an intent.
struct BoardView: View {
    let state: GameFeature.State
    let flipped: Bool
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        GeometryReader { geometry in
            let layout = HexLayout(fitting: geometry.size)
            let position = state.displayedPosition
            let highlights = CellHighlight.all(in: state)
            ZStack {
                ForEach(Cell.all, id: \.self) { cell in
                    CellView(
                        cell: cell,
                        piece: position.board[cell],
                        highlights: highlights[cell] ?? [],
                        size: layout.cellSize,
                        onTap: { send(.cellTapped(cell)) }
                    )
                    .position(layout.center(of: cell, flipped: flipped))
                }
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.18), radius: layout.cellRadius * 0.9, y: layout.cellRadius * 0.4)
        }
        .aspectRatio(17 / (11 * 3.0.squareRoot()), contentMode: .fit)
    }
}
