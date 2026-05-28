import Foundation

enum GitIgnoreTemplate: Hashable {
    case xcode
    case flutter

    var header: String {
        switch self {
        case .xcode: return "# Xcode"
        case .flutter: return "# Flutter"
        }
    }

    var title: String {
        switch self {
        case .xcode: return PluginGitIgnoreLocalization.string("Xcode Template")
        case .flutter: return PluginGitIgnoreLocalization.string("Flutter Template")
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
