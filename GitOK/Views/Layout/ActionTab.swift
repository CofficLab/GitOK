import SwiftUI

enum ActionTab: String, CaseIterable {
    case Git
    case Banner
    case Icon
    
    var imageName: String {
        switch self {
        case .Git:
            "tree"
        case .Banner:
            "photo.artframe"
        case .Icon:
            "tray.circle"
        }
    }
}

#Preview {
    AppPreview()
}
