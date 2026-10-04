import SwiftUI

/// Warm wood-and-cream palette from the design mocks, with light and dark variants.
enum Palette {
    static func cell(_ shade: Int, _ scheme: ColorScheme) -> Color {
        let light: [UInt32] = [0xEBD9B8, 0xCFA174, 0x97643D]
        let dark: [UInt32] = [0xE6D2AE, 0xC69769, 0x8C5B37]
        return hex((scheme == .dark ? dark : light)[shade])
    }

    /// The thin line between cells, the colour of the page behind the board.
    static func gap(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0x14110F) : hex(0xEDE6DA) }
    static func background(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0x141210) : hex(0xEFEAE2) }
    static func card(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0x1E1B18) : .white }
    static func cardStroke(_ scheme: ColorScheme) -> Color { scheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06) }
    static func ink(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0xF1ECE4) : hex(0x1F1B17) }
    static func secondaryInk(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0x9C948A) : hex(0x756D63) }

    static let accent = hex(0xD4A453)
    /// The current move in the table: pale gold on light, deep gold on dark.
    static func accentWash(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0x3A2E1C) : hex(0xF3E3C8) }
    static func accentText(_ scheme: ColorScheme) -> Color { scheme == .dark ? hex(0xE2B466) : hex(0x8A5A12) }

    static let selected = hex(0xF2C55C)
    static let lastMove = hex(0xF3D98F)
    static let targetDot = Color.black.opacity(0.2)
    static let check = Color(red: 0.86, green: 0.18, blue: 0.14)

    static func hex(_ value: UInt32) -> Color {
        Color(red: Double(value >> 16 & 0xFF) / 255, green: Double(value >> 8 & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}
