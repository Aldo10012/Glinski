/// One of the 91 hexagonal cells, in axial coordinates.
/// `q` is the file offset from the centre file f (-5...5); `r` grows downward, towards White.
public struct Cell: Hashable, Sendable {
    public let q: Int
    public let r: Int

    public init?(q: Int, r: Int) {
        guard abs(q) <= 5, abs(r) <= 5, abs(q + r) <= 5 else { return nil }
        self.q = q
        self.r = r
    }

    /// Parses Gliński notation such as "f6".
    public init?(_ notation: String) {
        let digits = notation.dropFirst()
        guard let letter = notation.first,
              let fileIndex = Cell.files.firstIndex(of: letter),
              !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }),
              let rank = Int(digits) else { return nil }
        let q = fileIndex - 5
        self.init(q: q, r: 6 - max(q, 0) - rank)
    }

    public static let files: [Character] = Array("abcdefghikl")

    /// Every cell, ordered by file then rank; `all[c.index] == c`.
    public static let all: [Cell] = (-5...5).flatMap { q in
        (1...(11 - abs(q))).map { rank in Cell(q: q, r: 6 - max(q, 0) - rank)! }
    }

    private static let columnStart: [Int] = (-5...5).reduce(into: [0]) { starts, q in
        starts.append(starts.last! + 11 - abs(q))
    }

    public var file: Character { Cell.files[q + 5] }
    public var rank: Int { 6 - max(q, 0) - r }
    public var notation: String { "\(file)\(rank)" }

    /// Dense index 0..<91, used for array-backed boards and lookup tables.
    public var index: Int { Cell.columnStart[q + 5] + rank - 1 }

    /// Which of the three board colours (0...2). Orthogonal neighbours differ; diagonal ones match.
    public var shade: Int { ((q - r) % 3 + 3) % 3 }
}

extension Cell: CustomStringConvertible {
    public var description: String { notation }
}

extension Cell: Codable {
    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let cell = Cell(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid cell \(text)"))
        }
        self = cell
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(notation)
    }
}
