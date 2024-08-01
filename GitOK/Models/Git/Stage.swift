import Foundation
import SwiftUI

enum Stage: String, CaseIterable, Identifiable {
    var id: String {
        self.rawValue
    }
    
    case Head
    case History
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
