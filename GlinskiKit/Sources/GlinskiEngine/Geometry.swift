/// A step in axial coordinates.
struct Vector: Sendable, Equatable {
    let dq: Int
    let dr: Int

    static func + (a: Vector, b: Vector) -> Vector { Vector(dq: a.dq + b.dq, dr: a.dr + b.dr) }
    static func * (v: Vector, k: Int) -> Vector { Vector(dq: v.dq * k, dr: v.dr * k) }
    static prefix func - (v: Vector) -> Vector { v * -1 }
}

extension Cell {
    func offset(_ v: Vector) -> Cell? { Cell(q: q + v.dq, r: r + v.dr) }
}

/// Direction sets and lookup tables, computed once. Tables are indexed by `Cell.index`.
enum Geometry {
    /// Through a cell edge, clockwise from up.
    static let orthogonal: [Vector] = [
        Vector(dq: 0, dr: -1), Vector(dq: 1, dr: -1), Vector(dq: 1, dr: 0),
        Vector(dq: 0, dr: 1), Vector(dq: -1, dr: 1), Vector(dq: -1, dr: 0),
    ]
    /// Through a vertex: the sum of two adjacent orthogonals.
    static let diagonal: [Vector] = (0..<6).map { orthogonal[$0] + orthogonal[($0 + 1) % 6] }
    /// Two orthogonal steps, then one at 60° either side.
    static let knight: [Vector] = (0..<6).flatMap { (i: Int) -> [Vector] in
        let twice: Vector = orthogonal[i] * 2
        return [twice + orthogonal[(i + 1) % 6], twice + orthogonal[(i + 5) % 6]]
    }

    static let orthogonalRays = rays(orthogonal)
    static let diagonalRays = rays(diagonal)
    static let knightTargets = jumps(knight)
    static let kingTargets = jumps(orthogonal + diagonal)

    private static func rays(_ directions: [Vector]) -> [[[Int]]] {
        Cell.all.map { start in
            directions.map { d in
                var ray: [Int] = []
                var current = start
                while let next = current.offset(d) {
                    ray.append(next.index)
                    current = next
                }
                return ray
            }
        }
    }

    private static func jumps(_ vectors: [Vector]) -> [[Int]] {
        Cell.all.map { start in vectors.compactMap { start.offset($0)?.index } }
    }
}
