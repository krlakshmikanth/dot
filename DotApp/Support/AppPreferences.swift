import SwiftUI

enum HomeAction: String, CaseIterable, Identifiable {
    case dot
    case direct

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dot: "Dot"
        case .direct: "Direct action"
        }
    }
}

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
    case status
    case settings
}
