import GlinskiEngine
import GlinskiFeature
import SwiftUI

/// A rounded panel in the page's card colour.
struct Card: ViewModifier {
    var highlighted = false
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(highlighted ? Palette.accent : Palette.cardStroke(scheme), lineWidth: highlighted ? 1.5 : 1)
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.05), radius: 6, y: 2)
    }
}

extension View {
    func card(highlighted: Bool = false) -> some View { modifier(Card(highlighted: highlighted)) }
}

@MainActor func pieceImage(_ piece: Piece, size: CGFloat) -> some View {
    Image(CellView.assetName(piece), bundle: .module).resizable().scaledToFit().frame(width: size, height: size)
}

/// One player: avatar, name and the pieces they have captured. Gold-bordered while it is their move.
struct PlayerCard: View {
    let side: Side
    let state: GameFeature.State
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let active = state.game.result == nil && state.displayedPosition.sideToMove == side
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(side == .black ? Palette.hex(0x1F1B17) : Palette.hex(0xF4EFE7))
                Circle().strokeBorder(Palette.cardStroke(scheme))
                pieceImage(Piece(.king, .white), size: 26)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(BoardText.name(side)).font(.headline).foregroundStyle(Palette.ink(scheme))
                HStack(spacing: 1) {
                    ForEach(Array(state.captured(by: side).enumerated()), id: \.offset) { _, kind in
                        pieceImage(Piece(kind, side.opponent), size: 16)
                    }
                }
                .frame(height: 16)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .card(highlighted: active)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BoardText.playerLabel(side, captured: state.captured(by: side)))
        .accessibilityIdentifier("player.\(side)")
    }
}

/// "● Black to move" in serif italic, with the move number or review position underneath.
struct StatusView: View {
    let state: GameFeature.State
    var centered = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 4) {
            HStack(spacing: 10) {
                if state.game.result == nil && !centered {
                    Circle()
                        .fill(state.sideToMove == .black ? Palette.ink(scheme) : .clear)
                        .strokeBorder(Palette.ink(scheme), lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                }
                Text(BoardText.status(state))
                    .font(.system(.title, design: .serif).italic())
                    .foregroundStyle(Palette.ink(scheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(centered ? .center : .leading)
                    .accessibilityIdentifier("status")
            }
            Text(BoardText.detail(state)).font(.subheadline).foregroundStyle(Palette.secondaryInk(scheme))
        }
    }
}

/// The wide move table: one row per ply — number, from, to, and the piece that moved.
struct MoveTableView: View {
    let state: GameFeature.State
    let send: @MainActor (GameFeature.Intent) -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let history = state.history
        VStack(spacing: 0) {
            HStack {
                Text("MOVES", bundle: .module).font(.caption.weight(.semibold)).tracking(1)
                Spacer()
                Text(BoardText.counter(state)).font(.caption)
            }
            .foregroundStyle(Palette.secondaryInk(scheme))
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            if history.isEmpty {
                Text("No moves yet", bundle: .module)
                    .foregroundStyle(Palette.secondaryInk(scheme))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(history, id: \.number) { row($0) }
                        }
                        .padding(6)
                    }
                    .onChange(of: state.displayedPly) { _, ply in
                        withAnimation { proxy.scrollTo(ply) }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .card()
        .accessibilityIdentifier("moveList")
    }

    private func row(_ record: GameFeature.PlyRecord) -> some View {
        let current = record.number == state.displayedPly
        return Button { send(.review(record.number)) } label: {
            HStack(spacing: 0) {
                Text(verbatim: "\(record.number).").foregroundStyle(Palette.secondaryInk(scheme)).frame(width: 40, alignment: .leading)
                Text(verbatim: record.from.notation).frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: record.to.notation).frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 2) {
                    pieceImage(record.piece, size: 22)
                    if let promotion = record.promotion {
                        Image(systemName: "arrow.right").font(.caption2)
                        pieceImage(Piece(promotion, record.piece.side), size: 22)
                    }
                }
                .frame(width: 64, alignment: .leading)
            }
            .font(.body.monospaced().weight(current ? .semibold : .regular))
            .foregroundStyle(current ? Palette.accentText(scheme) : Palette.ink(scheme))
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(current ? Palette.accentWash(scheme) : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(record.number)
        .accessibilityLabel(BoardText.plyLabel(record))
        .accessibilityIdentifier("move.\(record.number)")
    }
}

/// The narrow move strip: one chip per ply, tap to review.
struct MoveChipsView: View {
    let state: GameFeature.State
    let send: @MainActor (GameFeature.Intent) -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let history = state.history
        Group {
            if history.isEmpty {
                Text("No moves yet", bundle: .module).foregroundStyle(Palette.secondaryInk(scheme)).frame(height: 40)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) { ForEach(history, id: \.number) { chip($0) } }
                    }
                    .onAppear { proxy.scrollTo(state.displayedPly) }
                    .onChange(of: state.displayedPly) { _, ply in withAnimation { proxy.scrollTo(ply) } }
                }
            }
        }
        .accessibilityIdentifier("moveList")
    }

    private func chip(_ record: GameFeature.PlyRecord) -> some View {
        let current = record.number == state.displayedPly
        return Button { send(.review(record.number)) } label: {
            HStack(spacing: 6) {
                Text(verbatim: "\(record.number).").foregroundStyle(Palette.secondaryInk(scheme))
                pieceImage(record.piece, size: 20)
                Text(verbatim: "\(record.from.notation)-\(record.to.notation)")
            }
            .font(.callout.monospaced().weight(current ? .semibold : .regular))
            .foregroundStyle(current ? Palette.accentText(scheme) : Palette.ink(scheme))
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(current ? Palette.accentWash(scheme) : Palette.card(scheme), in: Capsule())
        }
        .buttonStyle(.plain)
        .id(record.number)
        .accessibilityLabel(BoardText.plyLabel(record))
        .accessibilityIdentifier("move.\(record.number)")
    }
}

/// |<  <  >  >| — step through the game's positions.
struct HistoryNavView: View {
    let state: GameFeature.State
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        let ply = state.displayedPly
        let atStart = ply == 0
        let atEnd = state.reviewPly == nil
        HStack(spacing: 8) {
            navButton("First Move", "arrow.left.to.line", .review(0), disabled: atStart)
            navButton("Previous Move", "chevron.left", .review(ply - 1), disabled: atStart)
            navButton("Next Move", "chevron.right", .review(ply + 1), disabled: atEnd)
            navButton("Latest Move", "arrow.right.to.line", .review(nil), disabled: atEnd)
        }
    }

    private func navButton(_ title: LocalizedStringResource, _ icon: String, _ intent: GameFeature.Intent, disabled: Bool) -> some View {
        Button { send(intent) } label: {
            Label { Text(title) } icon: { Image(systemName: icon) }
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity, minHeight: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card()
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
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
        .card()
    }
}

struct DrawOfferView: View {
    let offeredBy: Side
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("\(BoardText.name(offeredBy)) offers a draw", bundle: .module).font(.headline)
            // Buttons take their natural width; otherwise the title's width squeezes "Accept" to "Acc…".
            HStack(spacing: 12) {
                Button { send(.respondToDraw(accept: false)) } label: { Text("Decline", bundle: .module).padding(.horizontal, 6) }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                Button { send(.respondToDraw(accept: true)) } label: { Text("Accept", bundle: .module).padding(.horizontal, 6) }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.accent)
            }
            .controlSize(.large)
            .fixedSize()
        }
        .padding(20)
        .card()
    }
}

struct GameOverView: View {
    let text: String
    let send: @MainActor (GameFeature.Intent) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(text).font(.system(.title2, design: .serif).italic()).multilineTextAlignment(.center)
            Button { send(.newGame) } label: { Text("New Game", bundle: .module) }
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
        }
        .padding(24)
        .card()
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
