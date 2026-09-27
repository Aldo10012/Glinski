import GlinskiEngine
import GlinskiFeature
import SwiftUI

enum CellHighlight: Hashable, CaseIterable {
    case selected, target, lastMove, check

    static func all(for cell: Cell, in state: GameFeature.State) -> Set<CellHighlight> {
        var set: Set<CellHighlight> = []
        if state.selection == cell { set.insert(.selected) }
        if state.targets.contains(cell) { set.insert(.target) }
        if let last = state.lastMove, last.from == cell || last.to == cell { set.insert(.lastMove) }
        if state.checkedKing == cell { set.insert(.check) }
        return set
    }

    var color: Color {
        switch self {
        case .selected: Palette.selected
        case .target: Palette.target
        case .lastMove: Palette.lastMove
        case .check: Palette.check
        }
    }

    var spoken: String {
        switch self {
        case .selected: String(localized: "selected", bundle: .module)
        case .target: String(localized: "legal move", bundle: .module)
        case .lastMove: String(localized: "last move", bundle: .module)
        case .check: String(localized: "in check", bundle: .module)
        }
    }
}

/// One hexagon: its wood shade, highlight tint and piece. A tap anywhere inside the hexagon counts.
struct CellView: View {
    let cell: Cell
    let piece: Piece?
    let highlights: Set<CellHighlight>
    let size: CGSize
    let onTap: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let ordered = CellHighlight.allCases.filter(highlights.contains)
        ZStack {
            HexShape().fill(Palette.cell(cell.shade, scheme))
            ForEach(ordered, id: \.self) { HexShape().fill($0.color) }
            if let piece {
                Image(Self.assetName(piece), bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .padding(size.height * 0.1)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(HexShape())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BoardText.cellLabel(cell, piece: piece))
        .accessibilityValue(ordered.map(\.spoken).joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("cell.\(cell.notation)")
    }

    static func assetName(_ piece: Piece) -> String {
        (piece.side == .white ? "w" : "b") + String(piece.kind.letter)
    }
}
