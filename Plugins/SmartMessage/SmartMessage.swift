import Foundation
import SwiftUI

struct SmartMessage: Hashable, Identifiable {
    var id: Date
    var duration: Int
    var shouldAlert: Bool = false
    var description: String
    var createdAt: Date
    
    init(duration: Int = 3, shouldAlert: Bool = false, description: String) {
        self.duration = duration
        self.shouldAlert = shouldAlert
        self.description = description
        self.id = Date()
        self.createdAt = Date()
    }
}
