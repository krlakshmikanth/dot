import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

enum AppTab: Hashable {
    case home
    case history
    case settings
}
