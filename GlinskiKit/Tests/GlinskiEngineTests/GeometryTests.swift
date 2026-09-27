import Testing
@testable import GlinskiEngine

struct GeometryTests {
    private func names(_ indices: [Int]) -> [String] { indices.map { Cell.all[$0].notation } }
    private func pairs(_ vs: [Vector]) -> Set<[Int]> { Set(vs.map { [$0.dq, $0.dr] }) }

    @Test func diagonalsAreSumsOfAdjacentOrthogonals() {
        #expect(pairs(Geometry.diagonal) == [[1, -2], [2, -1], [1, 1], [-1, 2], [-2, 1], [-1, -1]])
    }

    @Test func knightHasTwelveJumps() {
        #expect(pairs(Geometry.knight) == [
            [1, -3], [2, -3], [3, -2], [3, -1], [2, 1], [1, 2],
            [-1, 3], [-2, 3], [-3, 2], [-3, 1], [-2, -1], [-1, -2],
        ])
    }

    @Test func centreRaysReachTheEdge() {
        let f6 = cell("f6").index
        #expect(Geometry.orthogonalRays[f6].map(\.count) == [5, 5, 5, 5, 5, 5])
        #expect(Geometry.diagonalRays[f6].map(\.count) == [2, 2, 2, 2, 2, 2])
        #expect(names(Geometry.orthogonalRays[f6][0]) == ["f7", "f8", "f9", "f10", "f11"])
        #expect(names(Geometry.diagonalRays[f6][0]) == ["g7", "h8"])
    }

    @Test func knightFromD1() {
        #expect(Set(names(Geometry.knightTargets[cell("d1").index])) == ["b2", "c3", "e4", "f4", "g2", "g1"])
    }

    @Test func knightFromCentreHasTwelveTargets() {
        #expect(Geometry.knightTargets[cell("f6").index].count == 12)
    }

    @Test func kingFromCornerA1() {
        #expect(Set(names(Geometry.kingTargets[cell("a1").index])) == ["a2", "b1", "b2", "b3", "c2"])
    }

    @Test func offsetOffBoardIsNil() {
        #expect(cell("a1").offset(Vector(dq: 0, dr: 1)) == nil)
        #expect(cell("a1").offset(-Vector(dq: 0, dr: -1)) == nil)
    }
}
