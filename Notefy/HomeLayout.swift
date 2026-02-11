import SwiftUI

enum HomeLayout: String, CaseIterable, Codable, Identifiable {
    case list
    case gallery

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .list: return "List"
        case .gallery: return "Gallery"
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .gallery: return "square.grid.2x2"
        }
    }
}
