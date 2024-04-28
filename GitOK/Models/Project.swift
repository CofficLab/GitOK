import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var timestamp: Date
    var url: URL
    
    var title: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
    
    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }
    
    func getCommits() -> [GitCommit] {
        try! Git.logs(path)
    }
    
    func getCommitsWithHead() -> [GitCommit] {
        [GitCommit.headFor(path)] + getCommits()
    }
}

extension Project: Identifiable {
    var id: URL {
        self.url
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
