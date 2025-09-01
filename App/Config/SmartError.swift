import Foundation
import SwiftUI

enum SmartError: Error,LocalizedError {
    case ShellError(output: String)
    
    var errorDescription: String? {
        switch self {
        case .ShellError(let output):
            output
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
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

