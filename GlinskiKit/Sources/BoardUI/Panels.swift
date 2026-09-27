import GlinskiEngine
import GlinskiFeature
import SwiftUI

struct MoveListView: View {
    let rows: [String]
    /// A horizontal strip under the board on narrow layouts; a column beside it on wide ones.
    let horizontal: Bool

    var body: some View {
        Group {
            if rows.isEmpty {
                Text("No moves yet", bundle: .module).foregroundStyle(.secondary)
            } else if horizontal {
                ScrollView(.horizontal) {
                    HStack(spacing: 16) { ForEach(rows, id: \.self) { Text($0).monospaced() } }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) { ForEach(rows, id: \.self) { Text($0).monospaced() } }
                }
            }
        }
        .accessibilityIdentifier("moveList")
    }
}

struct PromotionPicker: View {
    let side: Side
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        HStack {
            ForEach([PieceKind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                Button { send(.promotionChosen(kind)) } label: {
                    Image(CellView.assetName(Piece(kind, side)), bundle: .module).resizable().scaledToFit().frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("Promote to \(BoardText.name(kind))", bundle: .module))
                .accessibilityIdentifier("promote.\(kind)")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DrawOfferView: View {
    let offeredBy: Side
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("\(BoardText.name(offeredBy)) offers a draw", bundle: .module).font(.headline)
            HStack {
                Button { send(.respondToDraw(accept: false)) } label: { Text("Decline", bundle: .module) }
                Button { send(.respondToDraw(accept: true)) } label: { Text("Accept", bundle: .module) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GameOverView: View {
    let text: String
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(text).font(.title2.bold()).multilineTextAlignment(.center)
            Button { send(.newGame) } label: { Text("New Game", bundle: .module) }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("gameOver")
    }
}

struct SettingsView: View {
    @Binding var autoRotate: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Toggle(isOn: $autoRotate) { Text("Rotate the board for the player to move", bundle: .module) }
            Section {
                Text("Chess pieces by Cburnett, via Wikimedia Commons, used under the BSD licence.", bundle: .module)
                    .font(.footnote)
                DisclosureGroup {
                    ScrollView { Text(verbatim: Self.piecesLicence).font(.caption.monospaced()) }.frame(maxHeight: 240)
                } label: {
                    Text("Acknowledgements", bundle: .module)
                }
            }
            Button { dismiss() } label: { Text("Done", bundle: .module) }
        }
        .padding()
    }

    /// Shipped verbatim, as the BSD licence requires for binary redistribution.
    static let piecesLicence: String = {
        guard let url = Bundle.module.url(forResource: "Pieces-LICENSE", withExtension: "txt") else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }()
}
