import SwiftUI

enum FontVariant: String, CaseIterable, Identifiable {
    case custom
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .custom: return "Свой шрифт"
        case .system: return "Системный"
        }
    }
}

/// The bundled font (Resources/Fonts/SpikeSegment.ttf, listed in UIAppFonts of BOTH Info.plists)
/// draws digits as 7-segment bars, so it cannot be confused with the system font.
/// If the extension fails to load it, SwiftUI silently falls back to the system font — that is
/// exactly what the tester compares against the "system" variant.
enum SpikeFont {
    static let postScriptName = "SpikeSegment-Regular"

    static func timer(variant: String, size: CGFloat) -> Font {
        if variant == FontVariant.system.rawValue {
            return Font.system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
        }
        return Font.custom(postScriptName, size: size)
    }
}
