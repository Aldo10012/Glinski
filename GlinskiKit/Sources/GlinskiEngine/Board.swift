/// 91 slots indexed by `Cell.index`.
public struct Board: Sendable, Hashable {
    private var slots: [Piece?]

    public init() {
        slots = Array(repeating: nil, count: Cell.all.count)
    }

    /// Space-separated `<letter><cell>` tokens; uppercase is White, lowercase Black. E.g. "Kg1 qe10 Pf5".
    public init?(placement: String) {
        self.init()
        for token in placement.split(separator: " ") {
            guard let letter = token.first,
                  let kind = PieceKind(letter: letter),
                  let cell = Cell(String(token.dropFirst())),
                  self[cell] == nil else { return nil }
            self[cell] = Piece(kind, letter.isUppercase ? .white : .black)
        }
    }

    public var placement: String {
        Cell.all.compactMap { c in
            self[c].map { p in
                let letter = p.side == .white ? String(p.kind.letter) : p.kind.letter.lowercased()
                return letter + c.notation
            }
        }.joined(separator: " ")
    }

    public subscript(cell: Cell) -> Piece? {
        get { slots[cell.index] }
        set { slots[cell.index] = newValue }
    }

    subscript(index: Int) -> Piece? { slots[index] }

    var indices: Range<Int> { slots.indices }

    func firstIndex(of piece: Piece) -> Int? { slots.firstIndex(of: piece) }

    public static let initial = Board(placement: """
        Kg1 Qe1 Rc1 Ri1 Nd1 Nh1 Bf1 Bf2 Bf3 Pb1 Pc2 Pd3 Pe4 Pf5 Pg4 Ph3 Pi2 Pk1 \
        kg10 qe10 rc8 ri8 nd9 nh9 bf9 bf10 bf11 pb7 pc7 pd7 pe7 pf7 pg7 ph7 pi7 pk7
        """)!
}

extension Board: Codable {
    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let board = Board(placement: text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid placement \(text)"))
        }
        self = board
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(placement)
    }
}
