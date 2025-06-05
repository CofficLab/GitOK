import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

class GitProvider: NSObject, ObservableObject, SuperLog {
    // MARK: - Properties
    
    static let shared = GitProvider()
    
    @Published private(set) var branches: [Branch] = []
    @Published var branch: Branch? = nil
    @Published private(set) var commit: GitCommit? = nil
    @Published private(set) var file: File? = nil

    static let emoji = "🐝"
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Previews

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
