import SwiftUI

/// Classic three-tone wood board, slightly deepened in dark mode.
enum Palette {
    static func cell(_ shade: Int, _ scheme: ColorScheme) -> Color {
        let light: [(Double, Double, Double)] = [(0.91, 0.80, 0.63), (0.80, 0.62, 0.42), (0.62, 0.44, 0.28)]
        let dark: [(Double, Double, Double)] = [(0.72, 0.60, 0.45), (0.58, 0.43, 0.29), (0.42, 0.29, 0.18)]
        let (r, g, b) = (scheme == .dark ? dark : light)[shade]
        return Color(red: r, green: g, blue: b)
    }

    static let selected = Color.yellow.opacity(0.55)
    static let target = Color.green.opacity(0.45)
    static let lastMove = Color.orange.opacity(0.35)
    static let check = Color.red.opacity(0.6)
}
