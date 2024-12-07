import SwiftUI

enum ActionTab: String, CaseIterable {
    case Git
    case Banner
    case Icon
    
    var imageName: String {
        switch self {
        case .Git:
            "folder"
        case .Banner:
            "camera"
        case .Icon:
            "globe.europe.africa"
        }
    }
}

#Preview {
    AppPreview()
}
