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
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 1200)
}
