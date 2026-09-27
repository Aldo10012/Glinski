import CoreGraphics
import GlinskiEngine
import Testing
@testable import BoardUI

func c(_ notation: String) -> Cell {
    guard let cell = Cell(notation) else { fatalError("bad cell \(notation)") }
    return cell
}

struct HexLayoutTests {
    let layout = HexLayout(fitting: CGSize(width: 340, height: 400))

    @Test func radiusFitsTheLimitingDimension() {
        #expect(layout.cellRadius == 20)   // 340 / 17 = 20 < 400 / (11√3) ≈ 21
        #expect(HexLayout(fitting: CGSize(width: 1000, height: 11 * 3.0.squareRoot() * 10)).cellRadius == 10)
    }

    @Test func centreCellIsInTheMiddle() {
        #expect(layout.center(of: c("f6")) == CGPoint(x: 170, y: 200))
    }

    @Test func whiteIsAtTheBottomUnlessFlipped() {
        #expect(layout.center(of: c("f1")).y > layout.center(of: c("f11")).y)
        #expect(layout.center(of: c("f1"), flipped: true).y < layout.center(of: c("f11"), flipped: true).y)
        #expect(layout.center(of: c("a1")).x < layout.center(of: c("l1")).x)
    }

    @Test func flippingRotatesAboutTheCentre() {
        for cell in Cell.all {
            let p = layout.center(of: cell), f = layout.center(of: cell, flipped: true)
            #expect(abs(p.x + f.x - 340) < 1e-9 && abs(p.y + f.y - 400) < 1e-9)
        }
    }

    @Test func orthogonalNeighboursAreOneCellApart() {
        let d = hypot(layout.center(of: c("f6")).x - layout.center(of: c("g6")).x,
                      layout.center(of: c("f6")).y - layout.center(of: c("g6")).y)
        #expect(abs(d - 20 * 3.0.squareRoot()) < 1e-9)
    }

    @Test func everyCellFitsInside() {
        for cell in Cell.all {
            let p = layout.center(of: cell)
            #expect(p.x - 20 >= -1e-9 && p.x + 20 <= 340 + 1e-9)
            #expect(p.y - 20 * 3.0.squareRoot() / 2 >= 0 && p.y + 20 * 3.0.squareRoot() / 2 <= 400)
        }
    }

    @Test func hexShapeIsFlatTopped() {
        let path = HexShape().path(in: CGRect(x: 0, y: 0, width: 40, height: 40 * 3.0.squareRoot() / 2))
        #expect(path.contains(CGPoint(x: 20, y: 17)))
        #expect(!path.contains(CGPoint(x: 1, y: 1)))   // top-left corner is cut off
    }
}
