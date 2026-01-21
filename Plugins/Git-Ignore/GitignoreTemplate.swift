import Foundation
import SwiftUI

enum GitignoreTemplate {
    case xcode
    case flutter

    var header: String {
        switch self {
        case .xcode: return "# Xcode"
        case .flutter: return "# Flutter"
        }
    }

    var lines: [String] {
        switch self {
        case .xcode:
            return [
                "# Xcode",
                "DerivedData/",
                "*.xcuserstate",
                "xcuserdata/",
                "*.xccheckout",
                "*.moved-aside",
                "*.xcscmblueprint",
            ]
        case .flutter:
            return [
                "# Flutter",
                ".dart_tool/",
                ".flutter-plugins",
                ".flutter-plugins-dependencies",
                ".packages",
                "Flutter.podspec",
                ".symlinks/",
                "pubspec.lock",
                ".generated/",
                "ios/Flutter/Flutter.framework",
                "ios/Flutter/Flutter.podspec",
                "ios/ServiceDefinitions.json",
            ]
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

