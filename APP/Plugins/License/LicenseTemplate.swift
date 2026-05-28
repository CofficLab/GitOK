import Foundation
import SwiftUI

enum LicenseTemplate: String, CaseIterable, Identifiable {
    case mit
    case apache2
    case gpl3

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mit: return String(localized: "MIT License", table: "License")
        case .apache2: return String(localized: "Apache License 2.0", table: "License")
        case .gpl3: return String(localized: "GPL v3", table: "License")
        }
    }

    var content: String {
        switch self {
        case .mit: return MITLicense.template
        case .apache2: return Apache2License.template
        case .gpl3: return GPL3License.template
        }
    }

    var description: String {
        switch self {
        case .mit: return MITLicense.description
        case .apache2: return Apache2License.description
        case .gpl3: return GPL3License.description
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

