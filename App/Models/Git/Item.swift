import Foundation
import SwiftData
import SwiftUI

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
