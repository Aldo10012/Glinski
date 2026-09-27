import CoreGraphics
import GlinskiEngine
import SwiftUI

/// Where each flat-topped cell sits inside a view of a given size. Pure, so taps and drawing agree.
struct HexLayout: Equatable {
    let size: CGSize
    /// Centre-to-corner distance of one cell.
    let cellRadius: CGFloat

    /// The board spans 17 radii across and 11√3 radii tall.
    init(fitting size: CGSize) {
        self.size = size
        cellRadius = min(size.width / 17, size.height / (11 * 3.0.squareRoot()))
    }

    /// Flipped rotates the board 180° so Black sits at the bottom.
    func center(of cell: Cell, flipped: Bool = false) -> CGPoint {
        let sign: CGFloat = flipped ? -1 : 1
        let x = 1.5 * cellRadius * CGFloat(cell.q)
        let y = 3.0.squareRoot() * cellRadius * (CGFloat(cell.r) + CGFloat(cell.q) / 2)
        return CGPoint(x: size.width / 2 + sign * x, y: size.height / 2 + sign * y)
    }

    var cellSize: CGSize { CGSize(width: 2 * cellRadius, height: 3.0.squareRoot() * cellRadius) }
}

/// A flat-topped regular hexagon filling its rect's width.
struct HexShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.width / 2
        let h = 3.0.squareRoot() / 2 * r
        return Path { p in
            p.move(to: CGPoint(x: rect.midX - r, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX - r / 2, y: rect.midY - h))
            p.addLine(to: CGPoint(x: rect.midX + r / 2, y: rect.midY - h))
            p.addLine(to: CGPoint(x: rect.midX + r, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX + r / 2, y: rect.midY + h))
            p.addLine(to: CGPoint(x: rect.midX - r / 2, y: rect.midY + h))
            p.closeSubpath()
        }
    }
}
