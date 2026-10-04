import GlinskiEngine
import GlinskiFeature
import SwiftUI

enum CellHighlight: Hashable, CaseIterable {
    case selected, target, lastMove, check

    /// Every highlighted cell, worked out once per render (the displayed position may be a replay).
    static func all(in state: GameFeature.State) -> [Cell: Set<CellHighlight>] {
        var map: [Cell: Set<CellHighlight>] = [:]
        if let selection = state.selection { map[selection, default: []].insert(.selected) }
        for target in state.targets { map[target, default: []].insert(.target) }
        if let last = state.displayedLastMove {
            map[last.from, default: []].insert(.lastMove)
            map[last.to, default: []].insert(.lastMove)
        }
        if let king = state.checkedKing { map[king, default: []].insert(.check) }
        return map
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

/// One hexagon: its wood shade, highlight, coordinate labels and piece. A tap anywhere inside the hexagon counts.
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
            HexShape().fill(fill)
            if highlights.contains(.check) {
                HexShape().fill(RadialGradient(colors: [Palette.check.opacity(0.85), Palette.check.opacity(0)], center: .center, startRadius: 0, endRadius: size.width * 0.5))
            }
            HexShape().stroke(Palette.gap(scheme), lineWidth: size.width * 0.035)
            coordinates
            if highlights.contains(.target) {
                if piece == nil {
                    Circle().fill(Palette.targetDot).frame(width: size.height * 0.28, height: size.height * 0.28)
                } else {
                    Circle().stroke(Palette.targetDot, lineWidth: size.height * 0.07).padding(size.height * 0.06)
                }
            }
            if let piece {
                Image(Self.assetName(piece), bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .padding(size.height * 0.12)
                    .shadow(color: .black.opacity(0.3), radius: size.height * 0.03, y: size.height * 0.025)
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

    private var fill: Color {
        if highlights.contains(.selected) { return Palette.selected }
        if highlights.contains(.lastMove) { return Palette.lastMove }
        return Palette.cell(cell.shade, scheme)
    }

    /// Rank numbers on the first cell of each rank, file letters on the bottom cell of each file.
    private var coordinates: some View {
        let ink = cell.shade == 2 ? Palette.hex(0xF3E6CF).opacity(0.85) : Palette.hex(0x6B4A2C).opacity(0.75)
        let font = Font.system(size: max(size.height * 0.15, 7), weight: .semibold, design: .rounded)
        return ZStack {
            if Self.showsRank(cell) {
                Text(verbatim: "\(cell.rank)").font(font).foregroundStyle(ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, size.width * 0.27).padding(.top, size.height * 0.08)
            }
            if Self.showsFile(cell) {
                Text(verbatim: String(cell.file)).font(font).foregroundStyle(ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, size.width * 0.27).padding(.bottom, size.height * 0.06)
            }
        }
        .accessibilityHidden(true)
    }

    /// Ranks 1–6 start on file a; rank 7 on b, … rank 11 on f.
    static func showsRank(_ cell: Cell) -> Bool { cell.q == (cell.rank <= 6 ? -5 : cell.rank - 11) }
    static func showsFile(_ cell: Cell) -> Bool { cell.rank == 1 }

    static func assetName(_ piece: Piece) -> String {
        (piece.side == .white ? "w" : "b") + String(piece.kind.letter)
    }
}
