import Foundation
import SwiftUI

enum GitError: Error {
    case credentialsNotConfigured
    case unknownError
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
