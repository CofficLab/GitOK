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

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
