import SwiftUI

enum ActionTab: String, CaseIterable {
    case Git
    case Banner
    case Icon
    
    var imageName: String {
        switch self {
        case .Git:
            "tree.circle"
        case .Banner:
            "photo.circle"
        case .Icon:
            "flame.circle"
        }
    }
}

#Preview {
    AppPreview()
}
