import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class AppManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var branch: String = ""
    @Published var branches: [String] = []
}

#Preview {
    AppPreview()
}
