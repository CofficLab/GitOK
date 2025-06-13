import Foundation
import SwiftData
import SwiftUI

@Model
final class GitUserConfig {
    var name: String
    var email: String
    var timestamp: Date
    var isDefault: Bool
    
    var title: String {
        name.isEmpty ? email : name
    }
    
    init(name: String, email: String, isDefault: Bool = false) {
        self.name = name
        self.email = email
        self.isDefault = isDefault
        self.timestamp = .now
    }
}

extension GitUserConfig: Identifiable {
    var id: String {
        "\(name)_\(email)"
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
} 