import GlinskiEngine
import GlinskiFeature
import SwiftUI

/// The 91 cells, positioned by `HexLayout`. Renders state; every tap becomes an intent.
struct BoardView: View {
    let state: GameFeature.State
    let flipped: Bool
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        GeometryReader { geometry in
            let layout = HexLayout(fitting: geometry.size)
            ZStack {
                ForEach(Cell.all, id: \.self) { cell in
                    CellView(
                        cell: cell,
                        piece: state.game.position.board[cell],
                        highlights: CellHighlight.all(for: cell, in: state),
                        size: layout.cellSize,
                        onTap: { send(.cellTapped(cell)) }
                    )
                    .position(layout.center(of: cell, flipped: flipped))
                }
            }
        }
        .aspectRatio(17 / (11 * 3.0.squareRoot()), contentMode: .fit)
    }
}
